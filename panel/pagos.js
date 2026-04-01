const API_URL = "http://127.0.0.1:8000";

const form = document.getElementById("pagoForm");
const tablaPagos = document.getElementById("tablaPagos");
const mensaje = document.getElementById("mensaje");

async function cargarPagos() {
    try {
        const response = await fetch(`${API_URL}/pagos/`);
        const data = await response.json();

        tablaPagos.innerHTML = "";

        data.forEach(item => {
            const fila = `
                <tr>
                    <td>${item.id}</td>
                    <td>${item.cliente_id}</td>
                    <td>${item.membresia_id ?? ""}</td>
                    <td>${item.valor_pagado}</td>
                    <td>${item.metodo_pago}</td>
                    <td>${item.referencia || ""}</td>
                    <td>${new Date(item.fecha_pago).toLocaleString()}</td>
                </tr>
            `;
            tablaPagos.innerHTML += fila;
        });
    } catch (error) {
        mensaje.innerText = "Error cargando pagos";
        console.error(error);
    }
}

form.addEventListener("submit", async function (e) {
    e.preventDefault();

    const membresiaInput = document.getElementById("membresia_id").value;

    const payload = {
        cliente_id: parseInt(document.getElementById("cliente_id").value),
        membresia_id: membresiaInput ? parseInt(membresiaInput) : null,
        usuario_id: null,
        valor_pagado: parseFloat(document.getElementById("valor_pagado").value),
        descuento: parseFloat(document.getElementById("descuento").value || 0),
        recargo: parseFloat(document.getElementById("recargo").value || 0),
        metodo_pago: document.getElementById("metodo_pago").value,
        referencia: document.getElementById("referencia").value || null,
        observaciones: document.getElementById("observaciones").value || null
    };

    try {
        const response = await fetch(`${API_URL}/pagos/`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json();
            mensaje.innerText = errorData.detail || "Error al guardar pago";
            return;
        }

        mensaje.innerText = "Pago guardado correctamente";
        form.reset();
        document.getElementById("descuento").value = 0;
        document.getElementById("recargo").value = 0;
        document.getElementById("metodo_pago").value = "EFECTIVO";
        cargarPagos();
    } catch (error) {
        mensaje.innerText = "Error de conexión con la API";
        console.error(error);
    }
});

cargarPagos();