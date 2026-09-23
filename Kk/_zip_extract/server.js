import express from "express";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;
const VIDEO_DIR = path.join(__dirname, "videos");

// Rozszerzenia plikow wideo obslugiwane przez przegladarki
const VIDEO_EXT = new Set([".mp4", ".webm", ".ogg", ".ogv", ".m4v", ".mov"]);

const app = express();

// Statyczny dostep do plikow wideo (z obsluga Range -> przewijanie/strumieniowanie)
app.use("/videos", express.static(VIDEO_DIR));

// Strona kiosku
app.use(express.static(path.join(__dirname, "public")));

// API: lista plikow wideo z folderu videos/
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

// Upewnij sie, ze folder videos/ istnieje
if (!fs.existsSync(VIDEO_DIR)) {
  fs.mkdirSync(VIDEO_DIR, { recursive: true });
}

app.listen(PORT, () => {
  console.log(`Kiosk wideo dziala: http://localhost:${PORT}`);
  console.log(`Wrzuc pliki wideo do folderu: ${VIDEO_DIR}`);
});
