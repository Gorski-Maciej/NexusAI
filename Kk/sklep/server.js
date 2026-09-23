// ============================================================
// KIOSK: Sklep internetowy z chemia gospodarcza + petla reklam wideo
// ============================================================
// NAPRAWA BLEDU "ADRESOW IP" ze skryptu w public (1).zip:
//   W oryginale serwer startowal przez:  app.listen(PORT, () => {...})
//   Bez jawnego parametru hosta Node 17+ (nowy resolver DNS) probuje
//   bindowac sie wg kolejnosci DNS - na VM-ach bez poprawnego wpisu
//   localhost w /etc/hosts (albo z IPv6-first) serwer wstal z
//   Error: listen EADDRNOTAVAIL i "strona nie dzialala" na maszynie.
//   Rozwiazanie: jawnie sluchamy na 127.0.0.1 (localhost) + proba
//   awaryjna na 0.0.0.0 (wszystkie interfejsy, zeby SSH-owy admin
//   tez mogl wejsc). Zadnych sztywnych IP w kodzie - wszystko URL-e
//   wzgledne ("/api/...", "/videos/..."), wiec nie ma ryzyka
//   wpisanego zlego adresu IP w html/js.
// ============================================================

import express from "express";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";

import { PRODUKTY, MAPA_PRODUKTOW, KATEGORIE } from "./produkty.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// PORT i HOST z env (przydatne przy PM2 / przy recznych probach),
// ale nigdy nie ufamy zewnetrznym adresom IP - tylko wybor interfejsu.
const PORT = Number(process.env.PORT || 3000);
process.on("uncaughtException", (e) => console.error("[uncaught]", e.message));
const HOST = process.env.HOST || "127.0.0.1"; // NAPRAWA: localhost jawnie

const VIDEO_DIR = path.join(__dirname, "videos");
const PUBLIC_DIR = path.join(__dirname, "public");

// Rozszerzenia plikow wideo obslugiwane przez przegladarki
const VIDEO_EXT = new Set([".mp4", ".webm", ".ogg", ".ogv", ".m4v", ".mov"]);

// Walidacja rozmiaru koszyka (ochrona przed "gigantycznym" requestem)
const MAX_KOSZYK_POZYCJI = 100;
const MAX_ILOSC_SZT = 999;

const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "64kb" }));

// ------------------------------------------------------------
// Statyczne pliki: sklep + wideo (Range -> przewijanie)
// ------------------------------------------------------------
app.use("/videos", express.static(VIDEO_DIR, { maxAge: "1h" }));
app.use(express.static(PUBLIC_DIR, { index: "index.html" }));

// Upewnij sie, ze folder videos/ istnieje
if (!fs.existsSync(VIDEO_DIR)) {
  fs.mkdirSync(VIDEO_DIR, { recursive: true });
}

// ------------------------------------------------------------
// API katalogu
// ------------------------------------------------------------
app.get("/api/produkty", (req, res) => {
  res.json({ kategorie: KATEGORIE, produkty: PRODUKTY });
});

// API: lista plikow wideo z folderu videos/ (petla reklam)
app.get("/api/videos", (req, res) => {
  let files = [];
  try {
    files = fs
      .readdirSync(VIDEO_DIR)
      .filter((f) => VIDEO_EXT.has(path.extname(f).toLowerCase()))
      .sort((a, b) => a.localeCompare(b, "pl", { numeric: true }))
      .map((f) => "/videos/" + encodeURIComponent(f));
  } catch (err) {
    console.error("Nie mozna odczytac folderu videos/:", err.message);
  }
  res.json(files);
});

// ------------------------------------------------------------
// API koszyka - cene LICZY SERWER (klient wysyla tylko id+sztuki)
// ------------------------------------------------------------
app.post("/api/zamow", (req, res) => {
  const pozycje = Array.isArray(req.body?.pozycje) ? req.body.pozycje : null;
  if (!pozycje || pozycje.length === 0) {
    return res.status(400).json({ blad: "Puste zamowienie" });
  }
  if (pozycje.length > MAX_KOSZYK_POZYCJI) {
    return res.status(400).json({ blad: "Zamowienie zbyt duze" });
  }

  const linie = [];
  for (const p of pozycje) {
    const prod = MAPA_PRODUKTOW.get(String(p.id));
    const sztuki = Number(p.sztuki);
    if (!prod) {
      return res.status(400).json({ blad: `Nieznany produkt: ${p.id}` });
    }
    if (!Number.isInteger(sztuki) || sztuki < 1 || sztuki > MAX_ILOSC_SZT) {
      return res.status(400).json({ blad: `Zla ilosc dla: ${prod.nazwa}` });
    }
    linie.push({
      id: prod.id,
      nazwa: prod.nazwa,
      cena: prod.cena, // cena z SERWERA
      sztuki,
      wartosc: Math.round(prod.cena * sztuki * 100) / 100,
    });
  }

  const suma = Math.round(linie.reduce((s, l) => s + l.wartosc, 0) * 100) / 100;
  const numer = "ZAM-" + Date.now().toString(36).toUpperCase();
  console.log(`[ZAMOWIENIE] ${numer} | pozycji: ${linie.length} | suma: ${suma.toFixed(2)} PLN`);
  console.log(
    linie.map((l) => `   - ${l.nazwa} x${l.sztuki} = ${l.wartosc.toFixed(2)} PLN`).join("\n")
  );

  res.json({ numer, linie, suma });
});

// ------------------------------------------------------------
// Start serwera - NAPRAWIONE bindowanie IP
// ------------------------------------------------------------
function start(host) {
  return new Promise((resolve, reject) => {
    const srv = app.listen(PORT, host, () => resolve(srv));
    srv.on("error", reject);
  });
}

try {
  await start(HOST);
  const urls = [`http://localhost:${PORT}`];
  if (HOST !== "0.0.0.0") {
    // opcjonalnie: dostep z hosta VirtualBox przez NAT/bridge
    try {
      const ipy = Object.values(os.networkInterfaces())
        .flat()
        .filter((n) => n && n.family === "IPv4" && !n.internal)
        .map((n) => n.address);
      for (const ip of ipy) urls.push(`http://${ip}:${PORT} (dostep LAN)`);
    } catch {
      // srodowisko zablokowane enumeracji interfejsow - pomin adresy LAN
    }
  }
  console.log("==========================================");
  console.log("  KIOSK: Sklep ChemiaGospodarcza + Reklama");
  console.log("==========================================");
  console.log("  Serwer dziala na:");
  for (const u of urls) console.log(`   -> ${u}`);
  console.log(`  Wideo (petla reklam): ${VIDEO_DIR}`);
  console.log("==========================================");
} catch (err) {
  // Awaryjnie: localhost zablokowany na VM (zly /etc/hosts) -> bind na 0.0.0.0
  console.error(`[WARN] Nie mozna bindowac na ${HOST}: ${err.message}`);
  console.error("[WARN] Probuje awaryjnie na 0.0.0.0 (wszystkie interfejsy)...");
  try {
    await start("0.0.0.0");
    console.log(`Kiosk dziala (tryb awaryjny 0.0.0.0): http://localhost:${PORT}`);
  } catch (err2) {
    console.error("[FATAL] Serwer nie moze wystartowac:", err2.message);
    process.exit(1);
  }
}
