#!/bin/bash
cd ~/NexusAI
git pull origin main
fastcode
git add .
git commit -m "FastCode: auto-commit $(date +'%Y-%m-%d %H:%M')" || true
git push origin main
