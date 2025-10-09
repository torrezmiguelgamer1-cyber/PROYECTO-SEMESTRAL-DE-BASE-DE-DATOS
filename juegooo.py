import PySimpleGUI as sg
import json
import random

# ================== Datos de preguntas ==================
preguntas = {
    "facil": [
        {"pregunta": "Capital de Francia?", "opciones": ["Paris", "Madrid", "Roma"], "respuesta": "Paris"},
        {"pregunta": "5 + 3 = ?", "opciones": ["6", "8", "9"], "respuesta": "8"}
    ],
    "medio": [
        {"pregunta": "¿Quién pintó la Mona Lisa?", "opciones": ["Picasso", "Da Vinci", "Van Gogh"], "respuesta": "Da Vinci"},
        {"pregunta": "Raíz cuadrada de 81?", "opciones": ["7", "8", "9"], "respuesta": "9"}
    ],
    "dificil": [
        {"pregunta": "Año de la caída de Constantinopla?", "opciones": ["1453", "1492", "1415"], "respuesta": "1453"},
        {"pregunta": "¿Quién formuló la teoría de la relatividad?", "opciones": ["Newton", "Einstein", "Galileo"], "respuesta": "Einstein"}
    ]
}

# ================== Clase Jugador ==================
class Jugador:
    def __init__(self, nombre, vidas):   
        self.nombre = nombre
        self.vidas = vidas
        self.puntuacion = 0

    def sumar_punto(self):
        self.puntuacion += 1

    def perder_vida(self):
        self.vidas -= 1

# ================== Funciones de juego ==================
def seleccionar_dificultad():
    layout = [
        [sg.Text("Selecciona dificultad:")],
        [sg.Button("Facil"), sg.Button("Medio"), sg.Button("Dificil")]
    ]
    window = sg.Window("Dificultad", layout)
    dificultad, _ = window.read()
    window.close()

    if dificultad == "Facil":
        return "facil", 5
    elif dificultad == "Medio":
        return "medio", 3
    elif dificultad == "Dificil":
        return "dificil", 1
    else:
        return None, 0


def jugar(dificultad, jugadores):
    preguntas_sel = preguntas[dificultad][:]
    random.shuffle(preguntas_sel)

    # Inicializar jugadores
    layout_nombres = [[sg.Text("Nombre Jugador 1:"), sg.Input(key="J1")]]
    if jugadores == 2:
        layout_nombres.append([sg.Text("Nombre Jugador 2:"), sg.Input(key="J2")])
    layout_nombres.append([sg.Button("OK")])

    win_nombres = sg.Window("Nombres", layout_nombres)
    ev, vals = win_nombres.read()
    win_nombres.close()

    if not vals or "J1" not in vals:
        return

    j1 = Jugador(vals["J1"], vidas_iniciales)
    j2 = Jugador(vals.get("J2", "IA"), vidas_iniciales) if jugadores == 2 else None

    turno = 0
    for preg in preguntas_sel:
        jugador_actual = j1 if (turno % 2 == 0 or j2 is None) else j2
        if jugador_actual and jugador_actual.vidas > 0:
            layout_preg = [
                [sg.Text(f"Turno de {jugador_actual.nombre}")],
                [sg.Text(preg["pregunta"])],
                [sg.Button(op) for op in preg["opciones"]]
            ]
            win_preg = sg.Window("Pregunta", layout_preg)
            ev, _ = win_preg.read()
            win_preg.close()

            if ev == preg["respuesta"]:
                sg.popup("✅ Correcto!")
                jugador_actual.sumar_punto()
            elif ev is None:
                break
            else:
                sg.popup("❌ Incorrecto!")
                jugador_actual.perder_vida()
        turno += 1

    # Mostrar resultados
    res_layout = [[sg.Text(f"{j1.nombre}: {j1.puntuacion} puntos, {j1.vidas} vidas")]]
    if j2:
        res_layout.append([sg.Text(f"{j2.nombre}: {j2.puntuacion} puntos, {j2.vidas} vidas")])
    res_layout.append([sg.Button("Salir")])
    win_res = sg.Window("Resultados", res_layout)
    win_res.read()
    win_res.close()

# ================== Menú principal ==================
while True:
    layout_menu = [
        [sg.Text("Juego de Preguntas", font=("Any", 16))],
        [sg.Button("Un Jugador"), sg.Button("Dos Jugadores"), sg.Button("Salir")]
    ]
    win_menu = sg.Window("Menu", layout_menu)
    ev, _ = win_menu.read()
    win_menu.close()

    if ev == "Salir" or ev is None:
        break
    elif ev in ["Un Jugador", "Dos Jugadores"]:
        dificultad, vidas_iniciales = seleccionar_dificultad()
        if dificultad:
            jugar(dificultad, 1 if ev == "Un Jugador" else 2)

import pyodbc

def get_connection():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"   # Usa \\SQLEXPRESS si tu SQL es Express
        "DATABASE=TriviaGame;"
        "Trusted_Connection=yes;"
    )
    return conn

# Prueba de conexión
if __name__ == "__main__":
    try:
        conn = get_connection()
        print("✅ Conexión exitosa con autenticación de Windows")
        conn.close()
    except Exception as e:
        print("❌ Error de conexión:", e)

def guardar_usuario(nombre):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Usuarios (nombre) VALUES (?)", (nombre,))
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Usuario guardado correctamente")
    except Exception as e:
        print("❌ Error al guardar usuario:", e)

if __name__ == "__main__":
    guardar_usuario("JugadorWindows")
