// ============================================================
// prestart.js - npm uruchamia to AUTOMATYCZNIE przed "npm start"
// ------------------------------------------------------------
// Cel: "npm start" ma dzialac ZAWSZE, nawet przy PIERWSZYM
// starcie bez folderu node_modules (np. ZIP bez bibliotek).
// Sprawdza czy jest express; gdy brak - sam robi npm install.
// Dzieki temu nie trzeba pisac "npm install && npm start"
// (a operator && i tak nie dziala w PowerShell 5.1 na szkolnych
// komputerach z Windows 10).
// ============================================================

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function maExpressa() {
  try {
    return fs.existsSync(path.join(__dirname, "node_modules", "express", "package.json"));
  } catch {
    return false;
  }
}

if (!maExpressa()) {
  console.log("[prestart] Pierwszy start - instaluje biblioteki sklepu (npm install)...");
  console.log("[prestart] To trwa 1-2 minuty, czekaj...");
  try {
    execSync("npm install --no-audit --no-fund", { cwd: __dirname, stdio: "inherit" });
    console.log("[prestart] Biblioteki zainstalowane. Startuje sklep...");
  } catch (err) {
    console.error("[prestart] BLAD: nie udalo sie zainstalowac bibliotek.");
    console.error("[prestart] Najczestsza przyczyna: brak internetu na tym komputerze.");
    console.error("[prestart] " + (err && err.message ? err.message : err));
    console.error("[prestart] Rozwiazanie: wyslij ZIP z folderem node_modules (patrz instrukcja).");
    process.exit(1);
  }
}
