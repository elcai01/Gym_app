
import random
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.rutina import Rutina, RutinaEjercicio, ClienteRutina, ClienteRutinaProgreso
from app.models.ejercicio import Ejercicio
from app.models.cliente import Cliente
from app.schemas.rutina import (
    RutinaCreate,
    RutinaUpdate,
    RutinaResponse,
    RutinaEjercicioCreate,
    RutinaDetalleResponse,
    RutinaEjercicioResponse,
    ClienteRutinaAssign,
    ClienteRutinaResponse,
)

router = APIRouter(prefix="/rutinas", tags=["Rutinas"])


def ej(nombre, grupo, descripcion, instrucciones, dia, orden, series, repeticiones, descanso, imagen_url="", gif_url=""):
    return {
        "nombre": nombre,
        "grupo_muscular": grupo,
        "descripcion": descripcion,
        "instrucciones": instrucciones,
        "imagen_url": imagen_url,
        "gif_url": gif_url,
        "dia": dia,
        "orden": orden,
        "series": series,
        "repeticiones": repeticiones,
        "descanso": descanso,
    }


CATALOGO_PREDEFINIDO = {
    "pierna": {
        "fuerza": [
            {"nombre": "Pierna Fuerza A", "objetivo": "Fuerza e hipertrofia", "descripcion": "Rutina automática enfocada en pierna.", "nivel": "Principiante", "ejercicios": [
                ej("Sentadilla con barra", "Pierna", "Trabajo base de cuádriceps y glúteos.", "Baja controlado y sube empujando con los talones.", "Pierna", 1, "4", "10-12", "60 segundos"),
                ej("Prensa de pierna", "Pierna", "Trabajo guiado de tren inferior.", "Empuja con control y evita bloquear las rodillas.", "Pierna", 2, "4", "12-15", "45 segundos"),
                ej("Curl femoral", "Pierna", "Trabajo específico de femoral.", "Controla la fase de subida y bajada.", "Pierna", 3, "4", "12", "45 segundos"),
            ]},
            {"nombre": "Pierna Fuerza B", "objetivo": "Fuerza e hipertrofia", "descripcion": "Variación automática para pierna.", "nivel": "Intermedio", "ejercicios": [
                ej("Desplantes con mancuernas", "Pierna", "Trabajo unilateral de pierna.", "Paso largo, tronco recto y control en la bajada.", "Pierna", 1, "4", "12 por pierna", "60 segundos"),
                ej("Extensión de cuádriceps", "Pierna", "Aislamiento de cuádriceps.", "Sube controlado y no golpees el peso.", "Pierna", 2, "4", "15", "45 segundos"),
                ej("Peso muerto rumano", "Pierna", "Trabajo de femoral y glúteo.", "Espalda recta y recorrido controlado.", "Pierna", 3, "4", "10-12", "60 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Pierna Funcional A", "objetivo": "Resistencia y coordinación", "descripcion": "Rutina funcional de pierna.", "nivel": "Principiante", "ejercicios": [
                ej("Sentadilla libre", "Pierna", "Sentadilla con peso corporal.", "Activa abdomen y baja con control.", "Pierna", 1, "4", "20", "30 segundos"),
                ej("Step ups", "Pierna", "Subidas al cajón.", "Apoya todo el pie y sube estable.", "Pierna", 2, "4", "15 por pierna", "30 segundos"),
                ej("Jump squats", "Pierna", "Sentadilla con salto.", "Aterriza suave y controla rodillas.", "Pierna", 3, "4", "12", "30 segundos"),
            ]},
            {"nombre": "Pierna Funcional B", "objetivo": "Explosividad y resistencia", "descripcion": "Rutina dinámica para tren inferior.", "nivel": "General", "ejercicios": [
                ej("Zancadas caminando", "Pierna", "Trabajo funcional unilateral.", "Paso amplio y torso recto.", "Pierna", 1, "4", "14 por pierna", "30 segundos"),
                ej("Sentadilla sumo", "Pierna", "Enfoque interno y glúteo.", "Punta de pies abierta y pecho arriba.", "Pierna", 2, "4", "18", "30 segundos"),
                ej("Skipping alto", "Pierna", "Trabajo cardiovascular y coordinación.", "Eleva rodillas y mantén ritmo.", "Pierna", 3, "4", "40 segundos", "20 segundos"),
            ]},
        ],
        "mixta": [
            {"nombre": "Pierna Mixta A", "objetivo": "Combinada", "descripcion": "Mezcla de fuerza y funcional.", "nivel": "General", "ejercicios": [
                ej("Prensa de pierna", "Pierna", "Trabajo guiado de pierna.", "Empuja con control.", "Pierna", 1, "4", "15", "45 segundos"),
                ej("Zancadas caminando", "Pierna", "Trabajo funcional unilateral.", "Paso amplio y torso recto.", "Pierna", 2, "4", "12 por pierna", "30 segundos"),
                ej("Puente de glúteo", "Glúteo", "Activación posterior.", "Aprieta glúteos arriba.", "Pierna", 3, "4", "20", "30 segundos"),
            ]},
            {"nombre": "Pierna Mixta B", "objetivo": "Potencia y estabilidad", "descripcion": "Rutina variada de pierna y glúteo.", "nivel": "General", "ejercicios": [
                ej("Sentadilla goblet", "Pierna", "Trabajo global con mancuerna.", "Mantén el peso cerca al pecho.", "Pierna", 1, "4", "12", "45 segundos"),
                ej("Step ups", "Pierna", "Subidas al banco.", "Sube estable y baja controlado.", "Pierna", 2, "4", "12 por pierna", "30 segundos"),
                ej("Peso muerto rumano", "Pierna", "Posterior de pierna y glúteo.", "No redondees espalda.", "Pierna", 3, "4", "10", "60 segundos"),
            ]},
        ],
    },
    "pecho": {
        "fuerza": [
            {"nombre": "Pecho Fuerza A", "objetivo": "Hipertrofia", "descripcion": "Rutina automática de pecho.", "nivel": "General", "ejercicios": [
                ej("Press de banca", "Pecho", "Ejercicio base para pecho.", "Baja controlado y sube fuerte.", "Pecho", 1, "4", "8-10", "60 segundos"),
                ej("Press inclinado con mancuernas", "Pecho", "Enfoque en pectoral superior.", "Recorrido completo y controlado.", "Pecho", 2, "4", "10-12", "45 segundos"),
                ej("Aperturas con mancuernas", "Pecho", "Trabajo de aislamiento.", "No flexiones de más el codo.", "Pecho", 3, "4", "12-15", "45 segundos"),
            ]},
            {"nombre": "Pecho Fuerza B", "objetivo": "Fuerza superior", "descripcion": "Segunda rutina de pecho para rotación.", "nivel": "Intermedio", "ejercicios": [
                ej("Press declinado", "Pecho", "Trabajo del pectoral inferior.", "Controla el recorrido.", "Pecho", 1, "4", "10", "60 segundos"),
                ej("Fondos en paralelas", "Pecho", "Compuesto para pecho y tríceps.", "Inclina un poco el torso.", "Pecho", 2, "4", "8-12", "60 segundos"),
                ej("Cruce en poleas", "Pecho", "Aislamiento final.", "Cierra con control al frente.", "Pecho", 3, "4", "15", "45 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Pecho Funcional A", "objetivo": "Resistencia", "descripcion": "Rutina funcional de pecho.", "nivel": "General", "ejercicios": [
                ej("Flexiones", "Pecho", "Trabajo funcional de pecho.", "Cuerpo recto y core activo.", "Pecho", 1, "4", "15-20", "30 segundos"),
                ej("Flexiones inclinadas", "Pecho", "Variante asistida.", "Controla el descenso.", "Pecho", 2, "4", "20", "30 segundos"),
                ej("Burpees", "Funcional", "Trabajo global funcional.", "Mantén ritmo constante.", "Pecho", 3, "4", "12", "30 segundos"),
            ]},
            {"nombre": "Pecho Funcional B", "objetivo": "Acondicionamiento", "descripcion": "Trabajo dinámico de empuje.", "nivel": "General", "ejercicios": [
                ej("Flexiones con pausa", "Pecho", "Mayor control en el fondo.", "Pausa un segundo abajo.", "Pecho", 1, "4", "12", "30 segundos"),
                ej("Mountain climbers", "Funcional", "Cardio con activación superior.", "Mantén el abdomen fuerte.", "Pecho", 2, "4", "30 segundos", "20 segundos"),
                ej("Plank shoulder taps", "Funcional", "Estabilidad de empuje.", "Evita mover demasiado la cadera.", "Pecho", 3, "4", "20", "20 segundos"),
            ]},
        ],
        "mixta": [
            {"nombre": "Pecho Mixta A", "objetivo": "Combinada", "descripcion": "Rutina mixta de pecho.", "nivel": "General", "ejercicios": [
                ej("Press de banca", "Pecho", "Ejercicio base.", "Sube con fuerza.", "Pecho", 1, "4", "10", "60 segundos"),
                ej("Flexiones", "Pecho", "Trabajo funcional.", "Mantén el cuerpo alineado.", "Pecho", 2, "4", "15", "30 segundos"),
            ]},
            {"nombre": "Pecho Mixta B", "objetivo": "Empuje y resistencia", "descripcion": "Rutina variada de pecho.", "nivel": "General", "ejercicios": [
                ej("Press inclinado con mancuernas", "Pecho", "Trabajo superior.", "Recorrido completo.", "Pecho", 1, "4", "12", "45 segundos"),
                ej("Flexiones con pausa", "Pecho", "Control del movimiento.", "Pausa abajo.", "Pecho", 2, "4", "12", "30 segundos"),
                ej("Aperturas con mancuernas", "Pecho", "Estiramiento y aislamiento.", "No bajes de más.", "Pecho", 3, "4", "15", "45 segundos"),
            ]},
        ],
    },
    "espalda": {
        "fuerza": [
            {"nombre": "Espalda Fuerza A", "objetivo": "Hipertrofia", "descripcion": "Rutina automática de espalda.", "nivel": "General", "ejercicios": [
                ej("Jalón al pecho", "Espalda", "Trabajo de dorsal.", "Lleva al pecho sin balancearte.", "Espalda", 1, "4", "12", "45 segundos"),
                ej("Remo en polea", "Espalda", "Trabajo medio de espalda.", "Pecho arriba y retrae escápulas.", "Espalda", 2, "4", "12", "45 segundos"),
                ej("Pullover", "Espalda", "Complementario para dorsal.", "Recorrido largo y controlado.", "Espalda", 3, "4", "15", "45 segundos"),
            ]},
            {"nombre": "Espalda Fuerza B", "objetivo": "Potencia de tracción", "descripcion": "Segunda rutina pesada de espalda.", "nivel": "Intermedio", "ejercicios": [
                ej("Remo con barra", "Espalda", "Trabajo compuesto.", "Espalda neutra y jalón al abdomen.", "Espalda", 1, "4", "10", "60 segundos"),
                ej("Jalón cerrado", "Espalda", "Mayor enfoque interno.", "No te impulses.", "Espalda", 2, "4", "12", "45 segundos"),
                ej("Face pull", "Espalda", "Trabajo posterior y escápulas.", "Lleva hacia la cara.", "Espalda", 3, "4", "15", "30 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Espalda Funcional A", "objetivo": "Resistencia", "descripcion": "Rutina funcional de espalda.", "nivel": "General", "ejercicios": [
                ej("Superman", "Espalda", "Activación lumbar.", "Sostén arriba un segundo.", "Espalda", 1, "4", "20", "30 segundos"),
                ej("Bird dog", "Espalda", "Estabilidad de core y espalda.", "Mantén la pelvis estable.", "Espalda", 2, "4", "12 por lado", "30 segundos"),
                ej("Remo con banda", "Espalda", "Trabajo funcional de tracción.", "Controla la vuelta.", "Espalda", 3, "4", "20", "30 segundos"),
            ]},
            {"nombre": "Espalda Funcional B", "objetivo": "Movilidad y control", "descripcion": "Rutina dinámica posterior.", "nivel": "General", "ejercicios": [
                ej("Good mornings sin peso", "Espalda", "Bisagra de cadera controlada.", "Activa abdomen.", "Espalda", 1, "4", "15", "30 segundos"),
                ej("Bird dog", "Espalda", "Control motor.", "Hazlo lento.", "Espalda", 2, "4", "14 por lado", "20 segundos"),
                ej("Pull apart con banda", "Espalda", "Postura y retracción.", "No subas hombros.", "Espalda", 3, "4", "20", "20 segundos"),
            ]},
        ],
        "mixta": [
            {"nombre": "Espalda Mixta A", "objetivo": "Combinada", "descripcion": "Rutina mixta de espalda.", "nivel": "General", "ejercicios": [
                ej("Jalón al pecho", "Espalda", "Trabajo principal.", "Lleva al pecho.", "Espalda", 1, "4", "12", "45 segundos"),
                ej("Bird dog", "Espalda", "Estabilidad funcional.", "Controla el movimiento.", "Espalda", 2, "4", "12 por lado", "30 segundos"),
            ]},
            {"nombre": "Espalda Mixta B", "objetivo": "Tracción y estabilidad", "descripcion": "Rutina variada de espalda.", "nivel": "General", "ejercicios": [
                ej("Remo con barra", "Espalda", "Trabajo fuerte.", "Jala al abdomen.", "Espalda", 1, "4", "10", "60 segundos"),
                ej("Remo con banda", "Espalda", "Trabajo funcional.", "Controla la fase negativa.", "Espalda", 2, "4", "20", "30 segundos"),
                ej("Face pull", "Espalda", "Posterior del hombro y escápula.", "Lleva a la cara.", "Espalda", 3, "4", "15", "30 segundos"),
            ]},
        ],
    },
    "hombro": {
        "fuerza": [
            {"nombre": "Hombro Fuerza A", "objetivo": "Hipertrofia de hombro", "descripcion": "Rutina automática de hombro.", "nivel": "General", "ejercicios": [
                ej("Press militar", "Hombro", "Trabajo compuesto de hombro.", "Sube vertical sin arquear la espalda.", "Hombro", 1, "4", "10", "60 segundos"),
                ej("Elevaciones laterales", "Hombro", "Aislamiento lateral.", "Sube hasta línea del hombro.", "Hombro", 2, "4", "15", "30 segundos"),
                ej("Pájaros", "Hombro", "Trabajo posterior.", "Espalda neutra y movimiento limpio.", "Hombro", 3, "4", "15", "30 segundos"),
            ]},
            {"nombre": "Hombro Fuerza B", "objetivo": "Potencia y volumen", "descripcion": "Variación de hombro.", "nivel": "Intermedio", "ejercicios": [
                ej("Press Arnold", "Hombro", "Trabajo completo de deltoides.", "Gira la mancuerna con control.", "Hombro", 1, "4", "10-12", "45 segundos"),
                ej("Elevación frontal", "Hombro", "Enfoque anterior.", "No balancees el cuerpo.", "Hombro", 2, "4", "12", "30 segundos"),
                ej("Face pull", "Hombro", "Posterior y estabilidad.", "Lleva la cuerda a la cara.", "Hombro", 3, "4", "15", "30 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Hombro Funcional A", "objetivo": "Resistencia y control", "descripcion": "Rutina funcional de hombro.", "nivel": "General", "ejercicios": [
                ej("Wall slides", "Hombro", "Movilidad y control escapular.", "Desliza brazos en pared.", "Hombro", 1, "4", "15", "20 segundos"),
                ej("Plank shoulder taps", "Hombro", "Estabilidad superior.", "Evita rotar la cadera.", "Hombro", 2, "4", "20", "20 segundos"),
                ej("Círculos de brazos", "Hombro", "Trabajo ligero y continuo.", "Mantén tensión constante.", "Hombro", 3, "4", "30 segundos", "20 segundos"),
            ]},
            {"nombre": "Hombro Funcional B", "objetivo": "Movilidad activa", "descripcion": "Trabajo dinámico para hombro.", "nivel": "General", "ejercicios": [
                ej("Band pull apart", "Hombro", "Postura y apertura.", "Controla la banda.", "Hombro", 1, "4", "20", "20 segundos"),
                ej("Y raises", "Hombro", "Activación escapular.", "Sube en forma de Y.", "Hombro", 2, "4", "15", "20 segundos"),
                ej("Bear shoulder taps", "Hombro", "Estabilidad funcional.", "Mantén rodillas cerca del piso.", "Hombro", 3, "4", "16", "20 segundos"),
            ]},
        ],
        "mixta": [
            {"nombre": "Hombro Mixta A", "objetivo": "Combinada", "descripcion": "Fuerza más control escapular.", "nivel": "General", "ejercicios": [
                ej("Press militar", "Hombro", "Compuesto principal.", "Sube vertical.", "Hombro", 1, "4", "10", "60 segundos"),
                ej("Band pull apart", "Hombro", "Postura y control.", "Controla la banda.", "Hombro", 2, "4", "20", "20 segundos"),
                ej("Elevaciones laterales", "Hombro", "Aislamiento lateral.", "No uses impulso.", "Hombro", 3, "4", "15", "30 segundos"),
            ]}
        ],
    },
    "brazo": {
        "fuerza": [
            {"nombre": "Brazo Fuerza A", "objetivo": "Bíceps y tríceps", "descripcion": "Rutina automática de brazo.", "nivel": "General", "ejercicios": [
                ej("Curl con barra", "Brazo", "Trabajo principal de bíceps.", "No balancees el torso.", "Brazo", 1, "4", "12", "45 segundos"),
                ej("Extensión de tríceps en polea", "Brazo", "Aislamiento de tríceps.", "Codos pegados al cuerpo.", "Brazo", 2, "4", "12", "45 segundos"),
                ej("Curl martillo", "Brazo", "Trabajo de braquial y antebrazo.", "Sube controlado.", "Brazo", 3, "4", "12", "30 segundos"),
            ]},
            {"nombre": "Brazo Fuerza B", "objetivo": "Volumen", "descripcion": "Segunda variante de brazo.", "nivel": "Intermedio", "ejercicios": [
                ej("Curl alterno", "Brazo", "Trabajo unilateral de bíceps.", "Evita girar el hombro.", "Brazo", 1, "4", "12", "30 segundos"),
                ej("Fondos en banco", "Brazo", "Trabajo de tríceps.", "Baja controlado.", "Brazo", 2, "4", "15", "30 segundos"),
                ej("Patada de tríceps", "Brazo", "Aislamiento posterior.", "Extiende completo.", "Brazo", 3, "4", "15", "30 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Brazo Funcional A", "objetivo": "Resistencia", "descripcion": "Rutina funcional de brazo.", "nivel": "General", "ejercicios": [
                ej("Fondos en banco", "Brazo", "Trabajo con peso corporal.", "Controla la bajada.", "Brazo", 1, "4", "15", "30 segundos"),
                ej("Curl con banda", "Brazo", "Bíceps funcional con banda.", "No uses impulso.", "Brazo", 2, "4", "20", "20 segundos"),
                ej("Planchas con apoyo de antebrazos", "Brazo", "Trabajo isométrico y estabilidad.", "Mantén el abdomen fuerte.", "Brazo", 3, "4", "30 segundos", "20 segundos"),
            ]}
        ],
        "mixta": [
            {"nombre": "Brazo Mixta A", "objetivo": "Combinada", "descripcion": "Brazo variado.", "nivel": "General", "ejercicios": [
                ej("Curl con barra", "Brazo", "Trabajo principal.", "No balancees.", "Brazo", 1, "4", "12", "45 segundos"),
                ej("Fondos en banco", "Brazo", "Trabajo funcional de tríceps.", "Baja con control.", "Brazo", 2, "4", "15", "30 segundos"),
                ej("Curl martillo", "Brazo", "Bíceps y antebrazo.", "Sube controlado.", "Brazo", 3, "4", "12", "30 segundos"),
            ]}
        ],
    },
    "abdomen": {
        "fuerza": [
            {"nombre": "Abdomen Fuerza A", "objetivo": "Core fuerte", "descripcion": "Rutina de abdomen y core.", "nivel": "General", "ejercicios": [
                ej("Crunch con disco", "Abdomen", "Trabajo anterior.", "Sube redondeando el abdomen.", "Abdomen", 1, "4", "15", "30 segundos"),
                ej("Elevación de piernas", "Abdomen", "Trabajo inferior.", "No despegues demasiado la espalda.", "Abdomen", 2, "4", "12", "30 segundos"),
                ej("Plancha", "Abdomen", "Estabilidad de core.", "Mantén el cuerpo recto.", "Abdomen", 3, "4", "40 segundos", "20 segundos"),
            ]}
        ],
        "funcional": [
            {"nombre": "Abdomen Funcional A", "objetivo": "Resistencia y control", "descripcion": "Rutina funcional de core.", "nivel": "General", "ejercicios": [
                ej("Mountain climbers", "Abdomen", "Cardio y abdomen.", "Rodillas al pecho con ritmo.", "Abdomen", 1, "4", "30 segundos", "20 segundos"),
                ej("Plancha lateral", "Abdomen", "Trabajo oblicuo.", "Mantén la cadera arriba.", "Abdomen", 2, "4", "30 segundos por lado", "20 segundos"),
                ej("Dead bug", "Abdomen", "Control lumbopélvico.", "Hazlo lento.", "Abdomen", 3, "4", "14", "20 segundos"),
            ]}
        ],
        "mixta": [
            {"nombre": "Abdomen Mixta A", "objetivo": "Core completo", "descripcion": "Rutina mixta de abdomen.", "nivel": "General", "ejercicios": [
                ej("Crunch con disco", "Abdomen", "Trabajo anterior.", "Sube controlado.", "Abdomen", 1, "4", "15", "30 segundos"),
                ej("Mountain climbers", "Abdomen", "Trabajo funcional.", "Mantén ritmo.", "Abdomen", 2, "4", "30 segundos", "20 segundos"),
                ej("Plancha", "Abdomen", "Estabilidad.", "Cuerpo recto.", "Abdomen", 3, "4", "40 segundos", "20 segundos"),
            ]}
        ],
    },
    "gluteo": {
        "fuerza": [
            {"nombre": "Glúteo Fuerza A", "objetivo": "Hipertrofia de glúteo", "descripcion": "Rutina de glúteo automática.", "nivel": "General", "ejercicios": [
                ej("Hip thrust", "Glúteo", "Trabajo principal de glúteo.", "Aprieta glúteos arriba.", "Glúteo", 1, "4", "12", "45 segundos"),
                ej("Patada de glúteo en polea", "Glúteo", "Aislamiento posterior.", "Extiende completo.", "Glúteo", 2, "4", "15", "30 segundos"),
                ej("Abducción en máquina", "Glúteo", "Trabajo lateral.", "Abre con control.", "Glúteo", 3, "4", "20", "30 segundos"),
            ]},
            {"nombre": "Glúteo Fuerza B", "objetivo": "Volumen y activación", "descripcion": "Segunda rutina de glúteo.", "nivel": "General", "ejercicios": [
                ej("Puente de glúteo", "Glúteo", "Activación posterior.", "Aprieta arriba.", "Glúteo", 1, "4", "20", "30 segundos"),
                ej("Peso muerto rumano", "Glúteo", "Posterior y glúteo.", "Espalda recta.", "Glúteo", 2, "4", "10-12", "60 segundos"),
                ej("Sentadilla sumo", "Glúteo", "Trabajo combinado.", "Punta de pies abierta.", "Glúteo", 3, "4", "15", "45 segundos"),
            ]},
        ],
        "funcional": [
            {"nombre": "Glúteo Funcional A", "objetivo": "Resistencia y estabilidad", "descripcion": "Rutina funcional de glúteo.", "nivel": "General", "ejercicios": [
                ej("Puente de glúteo", "Glúteo", "Trabajo con peso corporal.", "Aprieta arriba.", "Glúteo", 1, "4", "20", "20 segundos"),
                ej("Patada de glúteo en cuadrupedia", "Glúteo", "Trabajo unilateral.", "No arquee la espalda.", "Glúteo", 2, "4", "18 por pierna", "20 segundos"),
                ej("Fire hydrants", "Glúteo", "Trabajo lateral de cadera.", "Controla la apertura.", "Glúteo", 3, "4", "16 por lado", "20 segundos"),
            ]}
        ],
        "mixta": [
            {"nombre": "Glúteo Mixta A", "objetivo": "Combinada", "descripcion": "Fuerza más funcional de glúteo.", "nivel": "General", "ejercicios": [
                ej("Hip thrust", "Glúteo", "Trabajo principal.", "Aprieta arriba.", "Glúteo", 1, "4", "12", "45 segundos"),
                ej("Fire hydrants", "Glúteo", "Estabilidad lateral.", "No gires el torso.", "Glúteo", 2, "4", "16 por lado", "20 segundos"),
                ej("Sentadilla sumo", "Glúteo", "Trabajo combinado.", "Punta abierta.", "Glúteo", 3, "4", "15", "30 segundos"),
            ]}
        ],
    },
}


class AsignacionAutomaticaRequest(BaseModel):
    cliente_id: Optional[int] = None
    cedula: Optional[str] = None
    grupo_muscular: str
    tipo: str = "mixta"


def construir_detalle_rutina(db: Session, rutina: Rutina, cliente_rutina_id: int = None) -> RutinaDetalleResponse:
    items = (
        db.query(RutinaEjercicio, Ejercicio)
        .join(Ejercicio, Ejercicio.id == RutinaEjercicio.ejercicio_id)
        .filter(RutinaEjercicio.rutina_id == rutina.id)
        .order_by(RutinaEjercicio.dia.asc(), RutinaEjercicio.orden.asc(), RutinaEjercicio.id.asc())
        .all()
    )

    progreso_dict = {}
    if cliente_rutina_id:
        progresos = db.query(ClienteRutinaProgreso).filter(ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id).all()
        for p in progresos:
            progreso_dict[p.rutina_ejercicio_id] = p.cumplido

    ejercicios = []
    for re_obj, ejr in items:
        cumplido = progreso_dict.get(re_obj.id, False)
        ejercicios.append(
            RutinaEjercicioResponse(
                id=re_obj.id,
                ejercicio_id=ejr.id,
                nombre=ejr.nombre,
                grupo_muscular=ejr.grupo_muscular,
                descripcion=ejr.descripcion,
                instrucciones=ejr.instrucciones,
                imagen_url=ejr.imagen_url,
                gif_url=ejr.gif_url,
                video_url=ejr.video_url,
                dia=re_obj.dia,
                orden=re_obj.orden,
                series=re_obj.series,
                repeticiones=re_obj.repeticiones,
                descanso=re_obj.descanso,
                observaciones=re_obj.observaciones,
                cumplido=cumplido,
            )
        )

    return RutinaDetalleResponse(
        id=rutina.id,
        nombre=rutina.nombre,
        objetivo=rutina.objetivo,
        descripcion=rutina.descripcion,
        nivel=rutina.nivel,
        activa=rutina.activa,
        ejercicios=ejercicios,
    )


def obtener_o_crear_ejercicio(db: Session, data: dict) -> Ejercicio:
    ejercicio = db.query(Ejercicio).filter(Ejercicio.nombre == data["nombre"]).first()
    if ejercicio:
        return ejercicio

    ejercicio = Ejercicio(
        nombre=data["nombre"],
        grupo_muscular=data.get("grupo_muscular"),
        descripcion=data.get("descripcion"),
        instrucciones=data.get("instrucciones"),
        imagen_url=data.get("imagen_url"),
        gif_url=data.get("gif_url"),
        video_url=data.get("video_url"),
        nivel="General",
        activo=True,
    )
    db.add(ejercicio)
    db.commit()
    db.refresh(ejercicio)
    return ejercicio


def crear_rutina_desde_catalogo(db: Session, plantilla: dict) -> Rutina:
    sufijo = random.randint(1000, 9999)
    rutina_kwargs = {
        "nombre": f"{plantilla['nombre']} #{sufijo}",
        "objetivo": plantilla.get("objetivo"),
        "descripcion": plantilla.get("descripcion"),
        "nivel": plantilla.get("nivel"),
        "activa": True,
        "creado_por": None,
    }

    if hasattr(Rutina, "cliente_id"):
        columna = getattr(Rutina, "cliente_id")
        rutina_kwargs["cliente_id"] = 0 if getattr(columna, "nullable", True) is False else None

    rutina = Rutina(**rutina_kwargs)
    db.add(rutina)
    db.commit()
    db.refresh(rutina)

    for item in plantilla["ejercicios"]:
        ejercicio = obtener_o_crear_ejercicio(db, item)
        detalle = RutinaEjercicio(
            rutina_id=rutina.id,
            ejercicio_id=ejercicio.id,
            dia=item.get("dia"),
            orden=item.get("orden", 1),
            series=item.get("series"),
            repeticiones=item.get("repeticiones"),
            descanso=item.get("descanso"),
            observaciones=item.get("observaciones"),
        )
        db.add(detalle)

    db.commit()
    return rutina


@router.get("/", response_model=List[RutinaResponse])
def listar_rutinas(db: Session = Depends(get_db)):
    return db.query(Rutina).order_by(Rutina.id.desc()).all()


@router.get("/{rutina_id}", response_model=RutinaResponse)
def obtener_rutina(rutina_id: int, db: Session = Depends(get_db)):
    rutina = db.query(Rutina).filter(Rutina.id == rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")
    return rutina


@router.put("/{rutina_id}", response_model=RutinaResponse)
def actualizar_rutina(rutina_id: int, datos: RutinaUpdate, db: Session = Depends(get_db)):
    rutina = db.query(Rutina).filter(Rutina.id == rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(rutina, campo, valor)

    db.commit()
    db.refresh(rutina)
    return rutina


@router.post("/{rutina_id}/ejercicios")
def agregar_ejercicio_a_rutina(rutina_id: int, datos: RutinaEjercicioCreate, db: Session = Depends(get_db)):
    rutina = db.query(Rutina).filter(Rutina.id == rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")

    ejercicio = db.query(Ejercicio).filter(Ejercicio.id == datos.ejercicio_id).first()
    if not ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado")

    nuevo = RutinaEjercicio(
        rutina_id=rutina_id,
        ejercicio_id=datos.ejercicio_id,
        dia=datos.dia,
        orden=datos.orden or 1,
        series=datos.series,
        repeticiones=datos.repeticiones,
        descanso=datos.descanso,
        observaciones=datos.observaciones,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return {"mensaje": "Ejercicio agregado a la rutina", "id": nuevo.id}


@router.get("/{rutina_id}/detalle", response_model=RutinaDetalleResponse)
def detalle_rutina(rutina_id: int, db: Session = Depends(get_db)):
    rutina = db.query(Rutina).filter(Rutina.id == rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")
    return construir_detalle_rutina(db, rutina)


@router.post("/asignar", response_model=ClienteRutinaResponse)
def asignar_rutina(data: ClienteRutinaAssign, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == data.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    rutina = db.query(Rutina).filter(Rutina.id == data.rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")

    activas = db.query(ClienteRutina).filter(
        ClienteRutina.cliente_id == data.cliente_id,
        ClienteRutina.activa == True
    ).all()

    for item in activas:
        item.activa = False

    nueva = ClienteRutina(
        cliente_id=data.cliente_id,
        rutina_id=data.rutina_id,
        fecha_inicio=data.fecha_inicio,
        fecha_fin=data.fecha_fin,
        activa=True,
        observaciones=data.observaciones,
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)

    return ClienteRutinaResponse(
        id=nueva.id,
        cliente_id=nueva.cliente_id,
        rutina_id=nueva.rutina_id,
        fecha_inicio=nueva.fecha_inicio,
        fecha_fin=nueva.fecha_fin,
        activa=nueva.activa,
        observaciones=nueva.observaciones,
        rutina=construir_detalle_rutina(db, rutina, nueva.id),
    )


@router.post("/asignar-automatica", response_model=ClienteRutinaResponse)
def asignar_rutina_automatica(data: AsignacionAutomaticaRequest, db: Session = Depends(get_db)):
    cliente = None
    if data.cliente_id is not None:
        cliente = db.query(Cliente).filter(Cliente.id == data.cliente_id).first()
    elif data.cedula:
        cliente = db.query(Cliente).filter(Cliente.documento == data.cedula).first()

    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    grupo = data.grupo_muscular.strip().lower()
    tipo = data.tipo.strip().lower()

    if grupo not in CATALOGO_PREDEFINIDO:
        raise HTTPException(status_code=400, detail="Grupo muscular no soportado")
    if tipo not in CATALOGO_PREDEFINIDO[grupo]:
        raise HTTPException(status_code=400, detail="Tipo de rutina no soportado")

    opciones = CATALOGO_PREDEFINIDO[grupo][tipo]
    if not opciones:
        raise HTTPException(status_code=404, detail="No hay rutinas precargadas para esa categoría")

    plantilla = random.choice(opciones)
    rutina = crear_rutina_desde_catalogo(db, plantilla)

    for item in db.query(ClienteRutina).filter(
        ClienteRutina.cliente_id == cliente.id,
        ClienteRutina.activa == True
    ).all():
        item.activa = False

    asignacion = ClienteRutina(
        cliente_id=cliente.id,
        rutina_id=rutina.id,
        fecha_inicio=None,
        fecha_fin=None,
        activa=True,
        observaciones=f"Asignación automática: {grupo}/{tipo}",
    )
    db.add(asignacion)
    db.commit()
    db.refresh(asignacion)

    return ClienteRutinaResponse(
        id=asignacion.id,
        cliente_id=asignacion.cliente_id,
        rutina_id=asignacion.rutina_id,
        fecha_inicio=asignacion.fecha_inicio,
        fecha_fin=asignacion.fecha_fin,
        activa=asignacion.activa,
        observaciones=asignacion.observaciones,
        rutina=construir_detalle_rutina(db, rutina, asignacion.id),
    )


@router.get("/cliente/{cliente_id}/actual", response_model=ClienteRutinaResponse)
def rutina_actual_cliente(cliente_id: int, db: Session = Depends(get_db)):
    cliente_rutina = (
        db.query(ClienteRutina)
        .filter(ClienteRutina.cliente_id == cliente_id, ClienteRutina.activa == True, ClienteRutina.completada == False)
        .order_by(ClienteRutina.id.desc())
        .first()
    )
    if not cliente_rutina:
        raise HTTPException(status_code=404, detail="El cliente no tiene rutina activa")

    rutina = db.query(Rutina).filter(Rutina.id == cliente_rutina.rutina_id).first()
    if not rutina:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")

    return ClienteRutinaResponse(
        id=cliente_rutina.id,
        cliente_id=cliente_rutina.cliente_id,
        rutina_id=cliente_rutina.rutina_id,
        fecha_inicio=cliente_rutina.fecha_inicio,
        fecha_fin=cliente_rutina.fecha_fin,
        activa=cliente_rutina.activa,
        observaciones=cliente_rutina.observaciones,
        rutina=construir_detalle_rutina(db, rutina, cliente_rutina.id),
    )
@router.put("/completar/{cliente_rutina_id}")
def completar_rutina(cliente_rutina_id: int, db: Session = Depends(get_db)):
    rutina_cliente = (
        db.query(ClienteRutina)
        .filter(ClienteRutina.id == cliente_rutina_id)
        .first()
    )

    if not rutina_cliente:
        raise HTTPException(status_code=404, detail="Rutina no encontrada")

    rutina_cliente.completada = True
    db.commit()

    return {"ok": True, "mensaje": "Rutina marcada como completada"}

@router.post("/cliente-rutina/{cliente_rutina_id}/ejercicio/{rutina_ejercicio_id}/cumplir")
def cumplir_ejercicio_cliente(
    cliente_rutina_id: int,
    rutina_ejercicio_id: int,
    db: Session = Depends(get_db),
):
    cliente_rutina = (
        db.query(ClienteRutina)
        .filter(ClienteRutina.id == cliente_rutina_id)
        .first()
    )

    if not cliente_rutina:
        raise HTTPException(status_code=404, detail="Asignación de rutina no encontrada")

    rutina_ejercicio = (
        db.query(RutinaEjercicio)
        .filter(
            RutinaEjercicio.id == rutina_ejercicio_id,
            RutinaEjercicio.rutina_id == cliente_rutina.rutina_id,
        )
        .first()
    )

    if not rutina_ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado en la rutina")

    # Guardar en ClienteRutinaProgreso
    from sqlalchemy.sql import func
    progreso = db.query(ClienteRutinaProgreso).filter(
        ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id,
        ClienteRutinaProgreso.rutina_ejercicio_id == rutina_ejercicio_id
    ).first()

    if progreso:
        progreso.cumplido = True
        progreso.fecha_cumplido = func.now()
    else:
        nuevo_progreso = ClienteRutinaProgreso(
            cliente_rutina_id=cliente_rutina_id,
            rutina_ejercicio_id=rutina_ejercicio_id,
            cumplido=True,
            fecha_cumplido=func.now()
        )
        db.add(nuevo_progreso)

    db.commit()

    # Verificar si todos están cumplidos
    total_ejercicios = db.query(RutinaEjercicio).filter(RutinaEjercicio.rutina_id == cliente_rutina.rutina_id).count()
    cumplidos = db.query(ClienteRutinaProgreso).filter(
        ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id,
        ClienteRutinaProgreso.cumplido == True
    ).count()

    if cumplidos >= total_ejercicios and total_ejercicios > 0:
        cliente_rutina.completada = True
        db.commit()

    return {"ok": True, "mensaje": "Ejercicio marcado como cumplido"}
