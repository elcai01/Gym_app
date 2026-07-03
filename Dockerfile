FROM python:3.12-slim

# Instalar dependencias del sistema, Node.js y Chromium para Puppeteer
RUN apt-get update && apt-get install -y curl gnupg chromium \
    libnss3 libatk-bridge2.0-0 libx11-xcb1 libxcb-dri3-0 libxcomposite1 \
    libxdamage1 libxfixes3 libcups2 libdrm2 libxrandr2 libgbm1 libasound2 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

# Copiar directorios
COPY backend/ /app/backend/
COPY whatsapp_service/ /app/whatsapp_service/
COPY start_services.sh /app/start_services.sh

# Dar permisos de ejecución al script
RUN chmod +x /app/start_services.sh

# Instalar dependencias de Python
WORKDIR /app/backend
# Dependiendo de si usan requirements.txt o algo más. Asumimos requirements.txt.
# Pero me aseguraré instalando manualmente si falta algo
RUN pip install --no-cache-dir -r requirements.txt || pip install fastapi uvicorn sqlalchemy psycopg2-binary requests pydantic pydantic-settings python-multipart python-jose passlib bcrypt

# Instalar dependencias de Node.js
WORKDIR /app/whatsapp_service
RUN npm install

# Exponer el puerto
# Render usa PORT, uvicorn usará $PORT. WhatsApp usa 3001 internamente.
EXPOSE $PORT
EXPOSE 3001

# Ejecutar el script que levanta ambos
WORKDIR /app
CMD ["/app/start_services.sh"]
