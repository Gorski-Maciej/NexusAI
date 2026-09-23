// Konfiguracja PM2 dla kiosku wideo
// Uruchomienie:  pm2 start ecosystem.config.cjs
// Autostart po restarcie systemu:  pm2 save  ->  pm2 startup
module.exports = {
  apps: [
    {
      name: "kiosk-video",
      script: "server.js",
      cwd: __dirname,

      // Autostart / odpornosc na awarie
      autorestart: true, // restartuj proces po nieoczekiwanym zamknieciu
      restart_delay: 2000, // odczekaj 2s przed ponownym uruchomieniem
      max_restarts: 50, // limit restartow w krotkim czasie (ochrona przed petla)
      min_uptime: 5000, // proces musi dzialac >5s, by uznac start za udany

      // Watch - automatyczny restart przy zmianie kodu
      watch: ["server.js", "public"],
      ignore_watch: ["node_modules", "videos", "logs", ".git"],
      watch_delay: 1000,

      // Srodowisko
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },

      // Logi
      out_file: "logs/out.log",
      error_file: "logs/error.log",
      merge_logs: true,
      time: true,
    },
  ],
};
