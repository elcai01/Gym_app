#!/bin/bash
# start_services.sh

echo "Iniciando servicio de WhatsApp (Node.js)..."
cd /app/whatsapp_service
npm install
# Iniciar en segundo plano
node index.js &

echo "Iniciando backend FastAPI (Python)..."
cd /app/backend
# Uvicorn es bloqueante, así que se ejecutará en primer plano
uvicorn app.main:app --host 0.0.0.0 --port $PORT
