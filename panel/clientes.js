const API_URL = "http://127.0.0.1:8000";

const form = document.getElementById("clienteForm");
const tablaClientes = document.getElementById("tablaClientes");
const mensaje = document.getElementById("mensaje");
const busquedaCliente = document.getElementById("busquedaCliente");

const modalMembresia = document.getElementById("modalMembresia");
const modalClienteInfo = document.getElementById("modalClienteInfo");
const modalFechaInicio = document.getElementById("modalFechaInicio");
const modalPlanNombre = document.getElementById("modalPlanNombre");
const modalFechaFin = document.getElementById("modalFechaFin");
const btnCancelarModal = document.getElementById("btnCancelarModal");
const btnCrearMembresiaModal = document.getElementById("btnCrearMembresiaModal");
const botonesPlan = document.querySelectorAll(".btn-plan");

const modalPago = document.getElementById("modalPago");
const modalPagoClienteInfo = document.getElementById("modalPagoClienteInfo");
const modalPagoMembresiaInfo = document.getElementById("modalPagoMembresiaInfo");
const modalPagoValor = document.getElementById("modalPagoValor");
const modalPagoMetodo = document.getElementById("modalPagoMetodo");
const modalPagoReferencia = document.getElementById("modalPagoReferencia");
const modalPagoObservaciones = document.getElementById("modalPagoObservaciones");
const btnCancelarModalPago = document.getElementById("btnCancelarModalPago");
const btnGuardarPagoModal = document.getElementById("btnGuardarPagoModal");

let clientesCache = [];
let membresiasCache = [];
let clienteSeleccionadoMembresia = null;
let planSeleccionado = null;
let clienteSeleccionadoPago = null;
let membresiaSeleccionadaPago = null;

const PLANES_DURACION = {
    1: 1,
    2: 7,
    3: 15,
    4: 30,
    5: 90
};

const PLANES_NOMBRE = {
    1: "DIARIO",
    2: "SEMANAL",
    3: "QUINCENAL",
    4: "MENSUAL",
    5: "TRIMESTRAL"
};

function limpiarNumero(numero) {
    if (!numero) return "";
    return numero.replace(/\D/g, "");
}

function construirMensajeGeneral(cliente) {
    return `Hola ${cliente.nombres} ${cliente.apellidos}, te escribimos de Gym Style Life. Queremos brindarte información sobre tu proceso en el gimnasio, membresía y pagos.`;
}

function construirMensajePago(cliente) {
    return `Hola ${cliente.nombres} ${cliente.apellidos}, te escribimos de Gym Style Life para recordarte tu pago o renovación de membresía. Si deseas, te compartimos la información de inmediato.`;
}

function construirMensajeVencimiento(cliente) {
    return `Hola ${cliente.nombres} ${cliente.apellidos}, te escribimos de Gym Style Life para informarte que tu membresía está próxima a vencer o requiere renovación.`;
}

function abrirWhatsApp(cliente, tipo = "general") {
    const numero = limpiarNumero(cliente.whatsapp || cliente.telefono);

    if (!numero) {
        alert("Este cliente no tiene número de WhatsApp o teléfono registrado.");
        return;
    }

    let texto = "";

    if (tipo === "pago") {
        texto = construirMensajePago(cliente);
    } else if (tipo === "vencimiento") {
        texto = construirMensajeVencimiento(cliente);
    } else {
        texto = construirMensajeGeneral(cliente);
    }

    const url = `https://wa.me/57${numero}?text=${encodeURIComponent(texto)}`;
    window.open(url, "_blank");
}

function formatearFechaISO(fecha) {
    const anio = fecha.getFullYear();
    const mes = String(fecha.getMonth() + 1).padStart(2, "0");
    const dia = String(fecha.getDate()).padStart(2, "0");
    return `${anio}-${mes}-${dia}`;
}

function calcularFechaFin(fechaInicio, duracionDias) {
    const fecha = new Date(`${fechaInicio}T00:00:00`);
    fecha.setDate(fecha.getDate() + duracionDias);
    return formatearFechaISO(fecha);
}

function obtenerHoyISO() {
    return formatearFechaISO(new Date());
}

function ordenarPorIdDesc(lista) {
    return [...lista].sort((a, b) => (b.id || 0) - (a.id || 0));
}

async function cargarMembresias() {
    try {
        const response = await fetch(`${API_URL}/membresias/`);
        if (!response.ok) {
            membresiasCache = [];
            return;
        }
        const data = await response.json();
        membresiasCache = Array.isArray(data) ? data : [];
    } catch (error) {
        console.error("Error cargando membresías:", error);
        membresiasCache = [];
    }
}

function obtenerMembresiasDeCliente(clienteId) {
    return membresiasCache.filter(m => m.cliente_id === clienteId);
}

function obtenerMembresiasActivas(clienteId) {
    return membresiasCache.filter(
        m => m.cliente_id === clienteId && (m.estado || "").toUpperCase() === "ACTIVA"
    );
}

function obtenerMembresiaPrincipal(clienteId) {
    const membresiasCliente = obtenerMembresiasDeCliente(clienteId);

    if (!membresiasCliente.length) return null;

    const activas = membresiasCliente.filter(m => (m.estado || "").toUpperCase() === "ACTIVA");
    if (activas.length) {
        return ordenarPorIdDesc(activas)[0];
    }

    return ordenarPorIdDesc(membresiasCliente)[0];
}

function obtenerEstadoVisualMembresia(clienteId) {
    const membresia = obtenerMembresiaPrincipal(clienteId);

    if (!membresia) {
        return {
            texto: "SIN MEMBRESÍA",
            clase: "estado-sin-membresia",
            detalle: "Sin membresía registrada"
        };
    }

    const hoy = obtenerHoyISO();
    const estado = (membresia.estado || "").toUpperCase();

    if (estado === "CANCELADA") {
        return {
            texto: "CANCELADA",
            clase: "estado-vencido",
            detalle: `Membresía ${membresia.id} - Fin: ${membresia.fecha_fin}`
        };
    }

    if (estado === "VENCIDA" || membresia.fecha_fin < hoy) {
        return {
            texto: "VENCIDO",
            clase: "estado-vencido",
            detalle: `Membresía ${membresia.id} - Fin: ${membresia.fecha_fin}`
        };
    }

    if (estado === "ACTIVA") {
        return {
            texto: "ACTIVO",
            clase: "estado-activo",
            detalle: `Membresía ${membresia.id} - Fin: ${membresia.fecha_fin}`
        };
    }

    return {
        texto: estado || "SIN ESTADO",
        clase: "estado-sin-membresia",
        detalle: `Membresía ${membresia.id} - Fin: ${membresia.fecha_fin}`
    };
}

function renderClientes(lista) {
    tablaClientes.innerHTML = "";

    lista.forEach(cliente => {
        const estadoMembresia = obtenerEstadoVisualMembresia(cliente.id);

        const fila = document.createElement("tr");

        fila.innerHTML = `
            <td>${cliente.id}</td>
            <td>${cliente.documento}</td>
            <td>${cliente.nombres}</td>
            <td>
                ${cliente.apellidos}
                <br>
                <span class="badge-estado ${estadoMembresia.clase}">${estadoMembresia.texto}</span>
                <br>
                <small>${estadoMembresia.detalle}</small>
            </td>
            <td>${cliente.telefono || ""}</td>
            <td>${cliente.whatsapp || ""}</td>
            <td>${cliente.estado}</td>
            <td>
                <div class="acciones-wsp">
                    <button class="btn-wsp btn-general">WhatsApp</button>
                    <button class="btn-wsp btn-pago">Recordar pago</button>
                    <button class="btn-wsp btn-vencimiento">Avisar vencimiento</button>
                    <button class="btn-secundario btn-membresia">Nueva membresía</button>
                    <button class="btn-secundario btn-pago-rapido">Registrar pago</button>
                </div>
            </td>
        `;

        fila.querySelector(".btn-general").addEventListener("click", () => abrirWhatsApp(cliente, "general"));
        fila.querySelector(".btn-pago").addEventListener("click", () => abrirWhatsApp(cliente, "pago"));
        fila.querySelector(".btn-vencimiento").addEventListener("click", () => abrirWhatsApp(cliente, "vencimiento"));
        fila.querySelector(".btn-membresia").addEventListener("click", () => abrirModalMembresia(cliente));
        fila.querySelector(".btn-pago-rapido").addEventListener("click", () => abrirModalPago(cliente));

        tablaClientes.appendChild(fila);
    });
}

async function cargarClientes() {
    try {
        const [clientesResp, membresiasResp] = await Promise.all([
            fetch(`${API_URL}/clientes/`),
            fetch(`${API_URL}/membresias/`)
        ]);

        const clientesData = await clientesResp.json();
        const membresiasData = membresiasResp.ok ? await membresiasResp.json() : [];

        clientesCache = Array.isArray(clientesData) ? clientesData : [];
        membresiasCache = Array.isArray(membresiasData) ? membresiasData : [];

        aplicarFiltro();
    } catch (error) {
        mensaje.innerText = "Error cargando clientes";
        console.error(error);
    }
}

function aplicarFiltro() {
    const texto = (busquedaCliente.value || "").toLowerCase().trim();

    if (!texto) {
        renderClientes(clientesCache);
        return;
    }

    const filtrados = clientesCache.filter(cliente =>
        (cliente.documento || "").toLowerCase().includes(texto) ||
        (cliente.nombres || "").toLowerCase().includes(texto) ||
        (cliente.apellidos || "").toLowerCase().includes(texto)
    );

    renderClientes(filtrados);
}

function resetModalMembresia() {
    clienteSeleccionadoMembresia = null;
    planSeleccionado = null;
    modalClienteInfo.innerText = "";
    modalFechaInicio.value = new Date().toISOString().split("T")[0];
    modalPlanNombre.value = "";
    modalFechaFin.value = "";
    botonesPlan.forEach(btn => btn.classList.remove("btn-plan-activo"));
}

function abrirModalMembresia(cliente) {
    resetModalMembresia();
    clienteSeleccionadoMembresia = cliente;
    modalClienteInfo.innerText = `Cliente: ${cliente.nombres} ${cliente.apellidos} | Cédula: ${cliente.documento}`;
    modalMembresia.classList.remove("hidden");
}

function cerrarModalMembresia() {
    modalMembresia.classList.add("hidden");
    resetModalMembresia();
}

function actualizarResumenModal() {
    if (!planSeleccionado || !modalFechaInicio.value) {
        modalPlanNombre.value = "";
        modalFechaFin.value = "";
        return;
    }

    modalPlanNombre.value = PLANES_NOMBRE[planSeleccionado];
    modalFechaFin.value = calcularFechaFin(modalFechaInicio.value, PLANES_DURACION[planSeleccionado]);
}

async function cancelarMembresiasActivas(cliente) {
    await cargarMembresias();

    const activas = obtenerMembresiasActivas(cliente.id);

    for (const membresia of activas) {
        const payload = {
            estado: "CANCELADA",
            observaciones: `Membresía cancelada automáticamente al crear una nueva para la cédula ${cliente.documento}`
        };

        const response = await fetch(`${API_URL}/membresias/${membresia.id}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.detail || `No se pudo cancelar la membresía ${membresia.id}`);
        }
    }
}

async function crearMembresiaDesdeModal() {
    if (!clienteSeleccionadoMembresia) {
        alert("No hay cliente seleccionado.");
        return;
    }

    if (!planSeleccionado) {
        alert("Debes seleccionar un plan.");
        return;
    }

    if (!modalFechaInicio.value) {
        alert("Debes seleccionar la fecha de inicio.");
        return;
    }

    const cliente = clienteSeleccionadoMembresia;
    const fechaInicio = modalFechaInicio.value;
    const fechaFin = calcularFechaFin(fechaInicio, PLANES_DURACION[planSeleccionado]);
    const nombrePlan = PLANES_NOMBRE[planSeleccionado];

    const confirmar = confirm(
        `Vas a crear esta membresía:\n\n` +
        `Cliente: ${cliente.nombres} ${cliente.apellidos}\n` +
        `Cédula: ${cliente.documento}\n` +
        `Plan: ${nombrePlan}\n` +
        `Fecha inicio: ${fechaInicio}\n` +
        `Fecha fin: ${fechaFin}\n\n` +
        `Si el cliente tiene membresías ACTIVAS, se marcarán como CANCELADAS.\n\n` +
        `¿Deseas continuar?`
    );

    if (!confirmar) return;

    try {
        await cancelarMembresiasActivas(cliente);

        const payload = {
            cliente_id: cliente.id,
            plan_id: planSeleccionado,
            fecha_inicio: fechaInicio,
            fecha_fin: fechaFin,
            estado: "ACTIVA",
            observaciones: `Membresía ${nombrePlan} creada automáticamente desde módulo principal para cédula ${cliente.documento}`
        };

        const response = await fetch(`${API_URL}/membresias/`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (!response.ok) {
            alert(data.detail || "Error al crear membresía");
            return;
        }

        alert(
            `Membresía creada correctamente.\n` +
            `Cédula: ${cliente.documento}\n` +
            `Plan: ${nombrePlan}\n` +
            `Inicio: ${fechaInicio}\n` +
            `Fin: ${fechaFin}\n` +
            `ID Membresía: ${data.id}`
        );

        cerrarModalMembresia();
        await cargarClientes();
    } catch (error) {
        console.error(error);
        alert(error.message || "Error de conexión al crear membresía");
    }
}

function resetModalPago() {
    clienteSeleccionadoPago = null;
    membresiaSeleccionadaPago = null;
    modalPagoClienteInfo.innerText = "";
    modalPagoMembresiaInfo.value = "";
    modalPagoValor.value = "";
    modalPagoMetodo.value = "EFECTIVO";
    modalPagoReferencia.value = "";
    modalPagoObservaciones.value = "";
}

async function abrirModalPago(cliente) {
    await cargarMembresias();

    const membresia = obtenerMembresiaPrincipal(cliente.id);

    if (!membresia || (membresia.estado || "").toUpperCase() !== "ACTIVA") {
        alert(`El cliente con cédula ${cliente.documento} no tiene una membresía activa.`);
        return;
    }

    resetModalPago();
    clienteSeleccionadoPago = cliente;
    membresiaSeleccionadaPago = membresia;

    modalPagoClienteInfo.innerText = `Cliente: ${cliente.nombres} ${cliente.apellidos} | Cédula: ${cliente.documento}`;
    modalPagoMembresiaInfo.value = `ID ${membresia.id} | Estado: ${membresia.estado} | Fin: ${membresia.fecha_fin}`;
    modalPagoReferencia.value = `CED-${cliente.documento}`;
    modalPagoObservaciones.value = `Pago registrado desde módulo principal para cédula ${cliente.documento}`;

    modalPago.classList.remove("hidden");
}

function cerrarModalPago() {
    modalPago.classList.add("hidden");
    resetModalPago();
}

async function guardarPagoDesdeModal() {
    if (!clienteSeleccionadoPago || !membresiaSeleccionadaPago) {
        alert("No hay cliente o membresía seleccionada.");
        return;
    }

    const valor = parseFloat(modalPagoValor.value);
    if (isNaN(valor) || valor <= 0) {
        alert("Debes ingresar un valor pagado válido.");
        return;
    }

    const metodo = modalPagoMetodo.value.trim();
    if (!metodo) {
        alert("Debes ingresar el método de pago.");
        return;
    }

    const payload = {
        cliente_id: clienteSeleccionadoPago.id,
        membresia_id: membresiaSeleccionadaPago.id,
        usuario_id: null,
        valor_pagado: valor,
        descuento: 0,
        recargo: 0,
        metodo_pago: metodo,
        referencia: modalPagoReferencia.value.trim() || null,
        observaciones: modalPagoObservaciones.value.trim() || null
    };

    try {
        const response = await fetch(`${API_URL}/pagos/`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (!response.ok) {
            alert(data.detail || "Error al registrar pago");
            return;
        }

        alert(
            `Pago registrado correctamente.\n` +
            `Cédula: ${clienteSeleccionadoPago.documento}\n` +
            `ID Pago: ${data.id}\n` +
            `Membresía usada: ${membresiaSeleccionadaPago.id}`
        );

        cerrarModalPago();
    } catch (error) {
        console.error(error);
        alert("Error de conexión al registrar pago");
    }
}

form.addEventListener("submit", async function (e) {
    e.preventDefault();

    const payload = {
        tipo_documento: document.getElementById("tipo_documento").value,
        documento: document.getElementById("documento").value,
        nombres: document.getElementById("nombres").value,
        apellidos: document.getElementById("apellidos").value,
        fecha_nacimiento: document.getElementById("fecha_nacimiento").value || null,
        genero: document.getElementById("genero").value || null,
        telefono: document.getElementById("telefono").value || null,
        whatsapp: document.getElementById("whatsapp").value || null,
        email: document.getElementById("email").value || null,
        direccion: document.getElementById("direccion").value || null,
        contacto_emergencia_nombre: document.getElementById("contacto_emergencia_nombre").value || null,
        contacto_emergencia_telefono: document.getElementById("contacto_emergencia_telefono").value || null,
        foto_url: null,
        fecha_ingreso: document.getElementById("fecha_ingreso").value,
        estado: document.getElementById("estado").value,
        observaciones: document.getElementById("observaciones").value || null
    };

    try {
        const response = await fetch(`${API_URL}/clientes/`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json();
            mensaje.innerText = errorData.detail || "Error al guardar cliente";
            return;
        }

        mensaje.innerText = "Cliente guardado correctamente";
        form.reset();
        document.getElementById("tipo_documento").value = "CC";
        document.getElementById("estado").value = "ACTIVO";
        await cargarClientes();
    } catch (error) {
        mensaje.innerText = "Error de conexión con la API";
        console.error(error);
    }
});

botonesPlan.forEach(btn => {
    btn.addEventListener("click", function () {
        botonesPlan.forEach(b => b.classList.remove("btn-plan-activo"));
        this.classList.add("btn-plan-activo");
        planSeleccionado = parseInt(this.dataset.plan);
        actualizarResumenModal();
    });
});

modalFechaInicio.addEventListener("change", actualizarResumenModal);
btnCancelarModal.addEventListener("click", cerrarModalMembresia);
btnCrearMembresiaModal.addEventListener("click", crearMembresiaDesdeModal);

modalMembresia.addEventListener("click", function (e) {
    if (e.target === modalMembresia) {
        cerrarModalMembresia();
    }
});

btnCancelarModalPago.addEventListener("click", cerrarModalPago);
btnGuardarPagoModal.addEventListener("click", guardarPagoDesdeModal);

modalPago.addEventListener("click", function (e) {
    if (e.target === modalPago) {
        cerrarModalPago();
    }
});

busquedaCliente.addEventListener("input", aplicarFiltro);

cargarClientes();