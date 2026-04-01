const API_URL = "http://127.0.0.1:8000";

const form = document.getElementById("membresiaForm");
const tablaMembresias = document.getElementById("tablaMembresias");
const mensaje = document.getElementById("mensaje");

async function cargarMembresias() {
    try {
        const response = await fetch(`${API_URL}/membresias/`);
        const data = await response.json();

        tablaMembresias.innerHTML = "";

        data.forEach(item => {
            const fila = `
                <tr>
                    <td>${item.id}</td>
                    <td>${item.cliente_id}</td>
                    <td>${item.plan_id}</td>
                    <td>${item.fecha_inicio}</td>
                    <td>${item.fecha_fin}</td>
                    <td>${item.estado}</td>
                </tr>
            `;
            tablaMembresias.innerHTML += fila;
        });
    } catch (error) {
        mensaje.innerText = "Error cargando membresías";
        console.error(error);
    }
}

form.addEventListener("submit", async function (e) {
    e.preventDefault();

    const payload = {
        cliente_id: parseInt(document.getElementById("cliente_id").value),
        plan_id: parseInt(document.getElementById("plan_id").value),
        fecha_inicio: document.getElementById("fecha_inicio").value,
        fecha_fin: document.getElementById("fecha_fin").value,
        estado: document.getElementById("estado").value,
        observaciones: document.getElementById("observaciones").value || null
    };

    try {
        const response = await fetch(`${API_URL}/membresias/`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json();
            mensaje.innerText = errorData.detail || "Error al guardar membresía";
            return;
        }

        mensaje.innerText = "Membresía guardada correctamente";
        form.reset();
        document.getElementById("estado").value = "ACTIVA";
        cargarMembresias();
    } catch (error) {
        mensaje.innerText = "Error de conexión con la API";
        console.error(error);
    }
});

cargarMembresias();