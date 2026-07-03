const express = require('express');
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const qrImage = require('qr-image');
const path = require('path');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;

let connectionStatus = 'INITIALIZING';
let lastQr = null;
let qrVersion = 0;
let reconnectTimer = null;

// Inicialización del cliente de WhatsApp con almacenamiento de sesión persistente
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: path.join(__dirname, 'session')
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox', 
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu',
            '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
        ]
    }
});

// Eventos de WhatsApp Web
client.on('qr', (qr) => {
    lastQr = qr;
    qrVersion += 1;
    connectionStatus = 'QR_READY';
    console.log('\n======================================================');
    console.log('CÓDIGO QR GENERADO. Escanéalo con WhatsApp en tu celular:');
    qrcode.generate(qr, { small: true });
    console.log('======================================================\n');
});

client.on('ready', () => {
    connectionStatus = 'CONNECTED';
    lastQr = null;
    console.log('¡WhatsApp Web conectado exitosamente y listo para enviar mensajes!');
});

client.on('authenticated', () => {
    connectionStatus = 'AUTHENTICATING';
    lastQr = null;
    console.log('Autenticación con WhatsApp Web exitosa.');
});

client.on('change_state', (state) => {
    console.log('Estado interno de WhatsApp Web:', state);
    if (state === 'CONNECTED') {
        connectionStatus = 'CONNECTED';
        lastQr = null;
    } else if (!lastQr && connectionStatus !== 'AUTHENTICATING') {
        connectionStatus = 'INITIALIZING';
    }
});

client.on('auth_failure', (msg) => {
    connectionStatus = 'DISCONNECTED';
    lastQr = null;
    console.error('Fallo en la autenticación de sesión:', msg);
});

client.on('disconnected', (reason) => {
    connectionStatus = 'DISCONNECTED';
    lastQr = null;
    console.log('Sesión desconectada. Razón:', reason);
    scheduleReconnect();
});

function scheduleReconnect() {
    if (reconnectTimer) return;

    reconnectTimer = setTimeout(async () => {
        reconnectTimer = null;
        connectionStatus = 'INITIALIZING';
        try {
            await client.destroy();
        } catch (_) {
            // El navegador puede estar cerrado ya; LocalAuth permanece guardado.
        }

        try {
            await client.initialize();
        } catch (err) {
            connectionStatus = 'DISCONNECTED';
            console.error('Error al re-inicializar cliente:', err);
            scheduleReconnect();
        }
    }, 5000);
}

// Inicializar el cliente al arrancar el servidor
client.initialize().catch(err => {
    console.error('Error crítico al inicializar cliente de WhatsApp:', err);
});

// ============================================================================
// Endpoints API
// ============================================================================

// Obtener estado actual de conexión
app.get('/status', async (req, res) => {
    // Verifica la sesion real al regresar a la pantalla. Durante el arranque,
    // conserva el ultimo evento conocido para no mostrar falsos desconectados.
    try {
        const realState = await client.getState();
        if (realState === 'CONNECTED') {
            connectionStatus = 'CONNECTED';
            lastQr = null;
        }
    } catch (_) {
        // getState puede fallar brevemente mientras Puppeteer inicia.
    }

    let qrBase64 = null;
    if (lastQr) {
        try {
            const qrPng = qrImage.imageSync(lastQr, { type: 'png', size: 6 });
            qrBase64 = qrPng.toString('base64');
        } catch (e) {
            console.error('Error generating base64 QR:', e);
        }
    }

    res.json({
        status: connectionStatus,
        hasQr: !!lastQr,
        qrVersion,
        qrBase64: qrBase64,
        authenticated: connectionStatus === 'CONNECTED'
    });
});

// Obtener la imagen PNG del código QR
app.get('/qr', (req, res) => {
    if (!lastQr) {
        return res.status(404).send('Código QR no disponible. WhatsApp ya está conectado o iniciándose.');
    }
    try {
        const qrPng = qrImage.image(lastQr, { type: 'png', size: 6 });
        res.setHeader('Content-Type', 'image/png');
        qrPng.pipe(res);
    } catch (e) {
        res.status(500).send('Error generando imagen QR');
    }
});

// Enviar un mensaje
app.post('/send', async (req, res) => {
    const { phone, message } = req.body;
    
    if (!phone || !message) {
        return res.status(400).json({ error: 'Faltan parámetros: "phone" o "message"' });
    }
    
    if (connectionStatus !== 'CONNECTED') {
        return res.status(503).json({ 
            error: 'WhatsApp no está conectado en el servidor',
            status: connectionStatus 
        });
    }

    try {
        // Limpiamos el número de cualquier caracter no numérico
        let cleanPhone = phone.replace(/\D/g, '');
        
        // Formato para Colombia: si tiene 10 dígitos (ej: 3123456789), le agregamos el indicativo de país (57)
        if (cleanPhone.length === 10 && cleanPhone.startsWith('3')) {
            cleanPhone = '57' + cleanPhone;
        }

        // WhatsApp requiere que el identificador termine con @c.us para contactos individuales
        if (!cleanPhone.endsWith('@c.us')) {
            cleanPhone = `${cleanPhone}@c.us`;
        }

        console.log(`[API] Enviando mensaje a: ${cleanPhone}`);
        const result = await client.sendMessage(cleanPhone, message);
        
        res.json({
            success: true,
            messageId: result.id.id,
            timestamp: result.timestamp
        });
    } catch (err) {
        console.error('Error al enviar mensaje por WhatsApp Web:', err);
        res.status(500).json({ 
            error: 'No se pudo enviar el mensaje', 
            details: err.message 
        });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Microservicio de WhatsApp corriendo en http://localhost:${PORT}`);
});
