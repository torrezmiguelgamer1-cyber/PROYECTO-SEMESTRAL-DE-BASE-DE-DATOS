import PySimpleGUI as sg
import random
import pyodbc

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

# ================== Clase Jugador (CORRECTA) ==================
class Jugador:
    def _init(self, nombre, vidas):   # <-- CORRECTO: __init_ con DOS guiones bajos
        self.nombre = nombre
        self.vidas = vidas
        self.puntuacion = 0

    def sumar_punto(self):
        self.puntuacion += 1

    def perder_vida(self):
        self.vidas -= 1

# (opcional) debug: confirma que la clase está bien definida
# print("Clase Jugador definida como:", Jugador)

# ================== Conexión SQL Server ==================
def get_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"   # Usa "localhost\\SQLEXPRESS" si tu SQL es Express
        "DATABASE=TriviaGame;"
        "Trusted_Connection=yes;"
    )

def guardar_usuario(nombre):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Usuarios (nombre) VALUES (?)", (nombre,))
        conn.commit()
        cursor.close()
        conn.close()
        print(f"✅ Usuario {nombre} guardado correctamente")
    except Exception as e:
        print("❌ Error al guardar usuario:", e)

# ================== Funciones de juego ==================
def seleccionar_dificultad():
    layout = [
        [sg.Text("Selecciona dificultad:")],
        [sg.Button("Facil"), sg.Button("Medio"), sg.Button("Dificil"), sg.Button("Cancelar")]
    ]
    window = sg.Window("Dificultad", layout)
    evento, _ = window.read()
    window.close()

    if evento == "Facil":
        return "facil", 5
    elif evento == "Medio":
        return "medio", 3
    elif evento == "Dificil":
        return "dificil", 1
    else:
        return None, 0

def jugar(dificultad, jugadores):
    preguntas_sel = preguntas[dificultad][:]
    random.shuffle(preguntas_sel)

    # Ventana para ingresar nombres
    layout_nombres = [[sg.Text("Nombre Jugador 1:"), sg.Input(key="J1")]]
    if jugadores == 2:
        layout_nombres.append([sg.Text("Nombre Jugador 2:"), sg.Input(key="J2")])
    layout_nombres.append([sg.Button("OK"), sg.Button("Cancelar")])

    win_nombres = sg.Window("Nombres", layout_nombres)
    evento, vals = win_nombres.read()
    win_nombres.close()

    if evento is None or evento == "Cancelar":
        return
    if not vals or "J1" not in vals or vals["J1"].strip() == "":
        sg.popup("Debe ingresar al menos el nombre del Jugador 1")
        return

    # Crear objetos Jugador y guardar en BD
    j1 = Jugador(vals["J1"].strip(), vidas_iniciales)
    guardar_usuario(j1.nombre)

    if jugadores == 2:
        nombre_j2 = vals.get("J2", "").strip()
        if nombre_j2 == "":
            nombre_j2 = "Jugador2"
        j2 = Jugador(nombre_j2, vidas_iniciales)
        guardar_usuario(j2.nombre)
    else:
        j2 = None

    turno = 0
    for preg in preguntas_sel:
        jugador_actual = j1 if (turno % 2 == 0 or j2 is None) else j2
        if jugador_actual and jugador_actual.vidas > 0:
            # Crear ventana de la pregunta
            botones = [sg.Button(op) for op in preg["opciones"]]
            layout_preg = [
                [sg.Text(f"Turno de {jugador_actual.nombre}")],
                [sg.Text(preg["pregunta"])],
                botones,
                [sg.Button("Salir")]
            ]
            win_preg = sg.Window("Pregunta", layout_preg)
            ev, _ = win_preg.read()
            win_preg.close()

            if ev is None or ev == "Salir":
                break

            if ev == preg["respuesta"]:
                sg.popup("✅ Correcto!")
                jugador_actual.sumar_punto()
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

# ================== Main ==================
if __name__ == "__main__":
    # IMPORTANTE: Si sigues viendo el mismo error después de reemplazar el archivo,
    # 1) Asegúrate de haber guardado el archivo antes de ejecutarlo.
    # 2) Reinicia el intérprete/IDE (a veces quedan .pyc antiguos o la sesión sigue corriendo).
    # 3) Busca en tu proyecto otras ocurrencias de "class Jugador" (si existe otra definición sin _init_).
    try:
        conn = get_connection()
        print("✅ Conexión exitosa con autenticación de Windows")
        conn.close()
    except Exception as e:
        print("❌ Error de conexión:", e)

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