const express = require('express');
const { default: makeWASocket, initAuthCreds, BufferJSON, DisconnectReason, proto } = require('@whiskeysockets/baileys');
const pino = require('pino');
const { Pool } = require('pg');
const qrcode = require('qrcode-terminal');
const qrImage = require('qr-image');

const app = express();
app.use(express.json());

const PORT = process.env.WHATSAPP_PORT || 3001;
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

let connectionStatus = 'INITIALIZING';
let lastQr = null;
let qrVersion = 0;
let sock = null;

// ==========================================
// Postgres Auth State Adapter for Baileys
// ==========================================
async function usePostgresAuthState(pool, sessionName = 'baileys_auth') {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS auth_state (
            session_name TEXT,
            key TEXT,
            value TEXT,
            PRIMARY KEY (session_name, key)
        )
    `);

    const writeData = async (data, key) => {
        try {
            await pool.query(
                `INSERT INTO auth_state (session_name, key, value) VALUES ($1, $2, $3)
                 ON CONFLICT (session_name, key) DO UPDATE SET value = $3`,
                [sessionName, key, JSON.stringify(data, BufferJSON.replacer)]
            );
        } catch (e) { console.error('Error writing auth data', e); }
    };

    const readData = async (key) => {
        try {
            const res = await pool.query(
                `SELECT value FROM auth_state WHERE session_name = $1 AND key = $2`,
                [sessionName, key]
            );
            if (res.rows.length > 0) {
                return JSON.parse(res.rows[0].value, BufferJSON.reviver);
            }
        } catch (e) { console.error('Error reading auth data', e); }
        return null;
    };

    const removeData = async (key) => {
        try {
            await pool.query(
                `DELETE FROM auth_state WHERE session_name = $1 AND key = $2`,
                [sessionName, key]
            );
        } catch (e) { console.error('Error removing auth data', e); }
    };

    let creds = await readData('creds');
    if (!creds) {
        creds = initAuthCreds();
        await writeData(creds, 'creds');
    }

    return {
        state: {
            creds,
            keys: {
                get: async (type, ids) => {
                    const data = {};
                    await Promise.all(
                        ids.map(async id => {
                            let value = await readData(`${type}-${id}`);
                            if (type === 'app-state-sync-key' && value) {
                                value = proto.Message.AppStateSyncKeyData.fromObject(value);
                            }
                            data[id] = value;
                        })
                    );
                    return data;
                },
                set: async (data) => {
                    const tasks = [];
                    for (const category in data) {
                        for (const id in data[category]) {
                            const value = data[category][id];
                            const key = `${category}-${id}`;
                            tasks.push(value ? writeData(value, key) : removeData(key));
                        }
                    }
                    await Promise.all(tasks);
                }
            }
        },
        saveCreds: () => {
            return writeData(creds, 'creds');
        }
    };
}

// ==========================================
// Baileys Connection Setup
// ==========================================
async function connectToWhatsApp() {
    connectionStatus = 'INITIALIZING';
    const { state, saveCreds } = await usePostgresAuthState(pool, 'gym_whatsapp');

    sock = makeWASocket({
        auth: state,
        logger: pino({ level: 'silent' }), // Reduce logs to save memory/disk
        printQRInTerminal: false,
        browser: ['Gym Style Life', 'Chrome', '1.0.0'],
        syncFullHistory: false, // Don't download entire history
        generateHighQualityLinkPreview: false
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
            lastQr = qr;
            qrVersion += 1;
            connectionStatus = 'QR_READY';
            console.log('\n======================================================');
            console.log('CÓDIGO QR GENERADO. Escanéalo con WhatsApp en tu celular:');
            qrcode.generate(qr, { small: true });
            console.log('======================================================\n');
        }

        if (connection === 'close') {
            connectionStatus = 'DISCONNECTED';
            const statusCode = lastDisconnect?.error?.output?.statusCode;
            const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
            console.log('Conexión cerrada. Status:', statusCode, 'Reconectar:', shouldReconnect);
            
            if (shouldReconnect) {
                setTimeout(connectToWhatsApp, 5000);
            } else {
                console.log('Sesión cerrada manualmente. Esperando nuevo QR...');
                pool.query(`DELETE FROM auth_state WHERE session_name = 'gym_whatsapp'`).then(() => {
                    setTimeout(connectToWhatsApp, 2000);
                });
            }
        } else if (connection === 'open') {
            connectionStatus = 'CONNECTED';
            lastQr = null;
            console.log('¡WhatsApp conectado exitosamente y listo para enviar mensajes!');
        }
    });
}

connectToWhatsApp().catch(err => console.error('Error inicializando WhatsApp:', err));

// ============================================================================
// Endpoints API
// ============================================================================
app.get('/status', (req, res) => {
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

app.get('/qr', (req, res) => {
    if (!lastQr) {
        return res.status(404).send('Código QR no disponible.');
    }
    try {
        const qrPng = qrImage.image(lastQr, { type: 'png', size: 6 });
        res.setHeader('Content-Type', 'image/png');
        qrPng.pipe(res);
    } catch (e) {
        res.status(500).send('Error generando imagen QR');
    }
});

app.post('/send', async (req, res) => {
    const { phone, message } = req.body;
    
    if (!phone || !message) {
        return res.status(400).json({ error: 'Faltan parámetros: "phone" o "message"' });
    }
    
    if (connectionStatus !== 'CONNECTED' || !sock) {
        return res.status(503).json({ 
            error: 'WhatsApp no está conectado en el servidor',
            status: connectionStatus 
        });
    }

    try {
        let cleanPhone = phone.replace(/\D/g, '');
        if (cleanPhone.length === 10 && cleanPhone.startsWith('3')) {
            cleanPhone = '57' + cleanPhone;
        }
        
        // Baileys requiere jid en formato número@s.whatsapp.net
        const jid = `${cleanPhone}@s.whatsapp.net`;

        console.log(`[API] Enviando mensaje a: ${jid}`);
        const result = await sock.sendMessage(jid, { text: message });
        
        res.json({
            success: true,
            messageId: result?.key?.id,
            timestamp: Date.now()
        });
    } catch (err) {
        console.error('Error al enviar mensaje:', err);
        res.status(500).json({ 
            error: 'No se pudo enviar el mensaje', 
            details: err.message 
        });
    }
});

app.post('/logout', async (req, res) => {
    if (sock) {
        try {
            console.log('Cerrando sesión de WhatsApp por petición de la API...');
            await sock.logout();
            connectionStatus = 'INITIALIZING';
            lastQr = null;
            res.json({ success: true, message: 'Sesión cerrada exitosamente' });
        } catch (e) {
            console.error('Error al hacer logout:', e);
            res.status(500).json({ error: 'Error al cerrar sesión', details: e.message });
        }
    } else {
        res.status(400).json({ error: 'No hay conexión activa' });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Microservicio de WhatsApp (Baileys) corriendo en http://localhost:${PORT}`);
});
