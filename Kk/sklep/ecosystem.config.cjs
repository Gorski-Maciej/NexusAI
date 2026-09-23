// Konfiguracja PM2 dla kiosku (sklep + reklama)
// Uruchomienie:  pm2 start ecosystem.config.cjs
// Autostart po restarcie:  pm2 save  ->  pm2 startup
module.exports = {
  apps: [
    {
      name: "kiosk-sklep",
      script: "server.js",
      cwd: __dirname,

      autorestart: true,
      restart_delay: 2000,
      max_restarts: 50,
      min_uptime: 5000,

      watch: ["server.js", "produkty.js", "public"],
      ignore_watch: ["node_modules", "videos", "logs", ".git"],
      watch_delay: 1000,

      // NAPRAWA IP: jawne HOST=localhost; serwer sam zrobi fallback na 0.0.0.0
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "127.0.0.1",
      },

      out_file: "logs/out.log",
      error_file: "logs/error.log",
      merge_logs: true,
      time: true,
    },
  ],
};
