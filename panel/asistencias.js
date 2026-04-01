const API_URL = "http://127.0.0.1:8000";

const form = document.getElementById("asistenciaForm");
const tablaAsistencias = document.getElementById("tablaAsistencias");
const mensaje = document.getElementById("mensaje");

async function cargarAsistencias() {
    try {
        const response = await fetch(`${API_URL}/asistencias/`);
        const data = await response.json();

        tablaAsistencias.innerHTML = "";

        data.forEach(item => {
            const fila = `
                <tr>
                    <td>${item.id}</td>
                    <td>${item.cliente_id}</td>
                    <td>${new Date(item.fecha_hora_ingreso).toLocaleString()}</td>
                    <td>${item.metodo_ingreso}</td>
                    <td>${item.observaciones || ""}</td>
                </tr>
            `;
            tablaAsistencias.innerHTML += fila;
        });
    } catch (error) {
        mensaje.innerText = "Error cargando asistencias";
        console.error(error);
    }
}

form.addEventListener("submit", async function (e) {
    e.preventDefault();

    const payload = {
        cliente_id: parseInt(document.getElementById("cliente_id").value),
        fecha_hora_salida: null,
        metodo_ingreso: document.getElementById("metodo_ingreso").value,
        observaciones: document.getElementById("observaciones").value || null
    };

    try {
        const response = await fetch(`${API_URL}/asistencias/`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json();
            mensaje.innerText = errorData.detail || "Error al guardar asistencia";
            return;
        }

        mensaje.innerText = "Asistencia guardada correctamente";
        form.reset();
        document.getElementById("metodo_ingreso").value = "MANUAL";
        cargarAsistencias();
    } catch (error) {
        mensaje.innerText = "Error de conexión con la API";
        console.error(error);
    }
});

cargarAsistencias();