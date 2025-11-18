import tkinter as tk
from tkinter import messagebox
import pyodbc
import subprocess
import webbrowser
import threading
import time
import os
import random

# ===================== COLORES =====================
COLOR_FONDO = "#2E2E2E"        # gris oscuro
COLOR_BOTON_PRINCIPAL = "#1E90FF"  # azul
COLOR_BOTON_SECUNDARIO = "#F7D358" # amarillo
COLOR_BOTON_PELIGRO = "#FF3B3B"    # rojo
COLOR_TEXTO = "#FFFFFF"        # blanco


# ------------------ CONEXIÓN A SQL SERVER ------------------
def get_connection():
    try:
        conn = pyodbc.connect(
            "Driver={ODBC Driver 17 for SQL Server};"
            "Server=LOCALHOST;"
            "Database=ProyectoCui;"
            "Trusted_Connection=yes;"
        )
        return conn
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo conectar a BD:\n{e}")
        return None


# ------------------ FUNCIONES DE USUARIO ------------------
def registrar_usuario(nombre, contrasena):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Usuarios WHERE nombre=?", (nombre,))
        if cursor.fetchone():
            messagebox.showerror("Error", "El usuario ya existe.")
            conn.close()
            return False

        cursor.execute("INSERT INTO Usuarios (nombre, contrasena) VALUES (?, ?)", (nombre, contrasena))
        conn.commit()

        cursor.execute("SELECT id FROM Usuarios WHERE nombre=?", (nombre,))
        usuario_id = cursor.fetchone()[0]

        cursor.execute("INSERT INTO Puntuaciones (usuario_id, puntuacion) VALUES (?, 0)", (usuario_id,))
        conn.commit()
        conn.close()

        messagebox.showinfo("Éxito", "Usuario registrado correctamente.")
        return True
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo registrar:\n{e}")
        return False


def iniciar_sesion(nombre, contrasena):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, contrasena FROM Usuarios WHERE nombre=?", (nombre,))
        row = cursor.fetchone()

        if row and row[1] == contrasena:
            usuario_id = row[0]
            cursor.execute("SELECT puntuacion FROM Puntuaciones WHERE usuario_id=?", (usuario_id,))
            puntuacion = cursor.fetchone()[0]
            conn.close()
            return usuario_id, puntuacion
        else:
            conn.close()
            messagebox.showerror("Error", "Usuario o contraseña incorrectos.")
            return None, 0
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo iniciar sesión:\n{e}")
        return None, 0


def actualizar_puntuacion(usuario_id, puntos):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE Puntuaciones SET puntuacion = puntuacion + ? WHERE usuario_id=?",
            (puntos, usuario_id)
        )
        conn.commit()
        conn.close()
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo actualizar:\n{e}")


# ------------------ CAPTCHA ------------------
def eliminar_archivo_seguro(ruta_resultado):
    for _ in range(5):
        try:
            if os.path.exists(ruta_resultado):
                os.remove(ruta_resultado)
            break
        except PermissionError:
            time.sleep(0.5)


def iniciar_verificador():
    ruta_verificador = os.path.join(os.path.dirname(__file__), "verificador.py")
    subprocess.Popen(["python", ruta_verificador], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    messagebox.showinfo("Servidor", "Servidor iniciado correctamente.")


def abrir_captcha():
    webbrowser.open("http://127.0.0.1:5000/")


def verificar_captcha(callback):
    """Verifica si el captcha fue completado correctamente antes de iniciar el juego."""
    ruta_resultado = os.path.join(os.path.dirname(__file__), "captcha_result.txt")

    def esperar_resultado():
        for _ in range(20):  # Espera hasta 20 segundos
            if os.path.exists(ruta_resultado):
                with open(ruta_resultado, "r") as f:
                    if f.read().strip() == "ok":
                        eliminar_archivo_seguro(ruta_resultado)

                        # ⬅️ Se ejecuta en el hilo principal
                        ventana.after(0, lambda: [
                            messagebox.showinfo("Correcto", "Captcha verificado!"),
                            callback()
                        ])
                        return
            time.sleep(1)

        # ⬅️ Error también debe ir al hilo principal
        ventana.after(0, lambda: messagebox.showerror("Error", "No se completo el captcha a tiempo."))

    threading.Thread(target=esperar_resultado, daemon=True).start()


def ventana_captcha(callback):
    cap = tk.Toplevel()
    cap.title("Verificación Captcha")
    cap.geometry("1280x720")
    cap.config(bg=COLOR_FONDO)

    tk.Label(cap, text="Verifica que eres humano", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 24)).pack(pady=40)

    tk.Button(cap, text="Iniciar verificador", bg=COLOR_BOTON_PRINCIPAL, fg="white",
              font=("Arial", 16), width=20, command=iniciar_verificador).pack(pady=20)

    tk.Button(cap, text="Abrir Captcha", bg=COLOR_BOTON_SECUNDARIO, fg="black",
              font=("Arial", 16), width=20, command=abrir_captcha).pack(pady=20)

    tk.Button(
    cap,
    text="Verificar",
    bg=COLOR_BOTON_PRINCIPAL,
    fg="white",
    font=("Arial", 16),
    width=20,
    command=lambda: verificar_captcha(
        lambda: (cap.destroy(), callback())
    )
     ).pack(pady=20)

# ------------------ PREGUNTAS ------------------
PREGUNTAS = {
    "facil": [
        {"pregunta": "¿Cuántos sacramentos tiene la Iglesia Católica?",
         "opciones": ["5", "7", "3"], "respuesta": "7"},

        {"pregunta": "¿Qué sacramento nos hace hijos de Dios?",
         "opciones": ["Confirmación", "Bautismo", "Eucaristía"], "respuesta": "Bautismo"},

        {"pregunta": "¿Qué significa la palabra 'Iglesia'?",
         "opciones": ["Asamblea", "Templo", "Sacerdote"], "respuesta": "Asamblea"},

        {"pregunta": "¿Quién es el autor principal de la Biblia?",
         "opciones": ["Dios", "Moisés", "San Pablo"], "respuesta": "Dios"},

        {"pregunta": "¿Qué virtud teologal permite creer?",
         "opciones": ["Fe", "Esperanza", "Caridad"], "respuesta": "Fe"},
    ],

    "medio": [
        {"pregunta": "¿Qué sacramento perdona los pecados después del Bautismo?",
         "opciones": ["Confirmación", "Reconciliación", "Matrimonio"], "respuesta": "Reconciliación"},

        {"pregunta": "¿Cuál es el sacramento del Cuerpo y Sangre de Cristo?",
         "opciones": ["Eucaristía", "Orden", "Unción"], "respuesta": "Eucaristía"},

        {"pregunta": "¿Qué virtud teologal permite amar como Dios?",
         "opciones": ["Fe", "Caridad", "Fortaleza"], "respuesta": "Caridad"},

        {"pregunta": "¿Qué libro narra la creación del mundo?",
         "opciones": ["Éxodo", "Génesis", "Salmos"], "respuesta": "Génesis"},

        {"pregunta": "¿Quién recibió los Diez Mandamientos?",
         "opciones": ["Abraham", "David", "Moisés"], "respuesta": "Moisés"},

        {"pregunta": "¿Cuál es la misión de la Iglesia según Hechos 1?",
         "opciones": ["Construir templos", "Evangelizar", "Guardar silencio"], "respuesta": "Evangelizar"},

        {"pregunta": "¿Qué sacramento fortalece con los dones del Espíritu Santo?",
         "opciones": ["Confirmación", "Bautismo", "Reconciliación"], "respuesta": "Confirmación"},

        {"pregunta": "¿Cuál es la máxima expresión del amor cristiano?",
         "opciones": ["Amar al enemigo", "Ayunar", "Ir a misa"], "respuesta": "Amar al enemigo"},

        {"pregunta": "¿Qué parte de la Biblia narra la vida de Jesús?",
         "opciones": ["Evangelios", "Cartas", "Profetas"], "respuesta": "Evangelios"},

        {"pregunta": "¿Qué significa la palabra 'Revelación'?",
         "opciones": ["Manifestación de Dios", "Escribir libros", "Cambio espiritual"],
         "respuesta": "Manifestación de Dios"},
    ],

    "dificil": [
        {"pregunta": "¿Cuántos libros tiene la Biblia Católica?",
         "opciones": ["66", "72", "73"], "respuesta": "73"},

        {"pregunta": "¿Qué sacramento confiere el poder sacerdotal?",
         "opciones": ["Orden Sagrado", "Confirmación", "Unción"], "respuesta": "Orden Sagrado"},

        {"pregunta": "¿Cuál es el fin principal del matrimonio cristiano?",
         "opciones": ["Compañía", "Procreación y unidad", "Divertirse"],
         "respuesta": "Procreación y unidad"},

        {"pregunta": "¿Cómo se llama el poder del Papa de enseñar sin error?",
         "opciones": ["Infalibilidad", "Dogma", "Profecía"], "respuesta": "Infalibilidad"},

        {"pregunta": "¿Cuál es el primer mandamiento?",
         "opciones": ["No matarás", "Santificarás las fiestas", "Amarás a Dios sobre todas las cosas"],
         "respuesta": "Amarás a Dios sobre todas las cosas"},

        {"pregunta": "¿Qué profeta anunció al Mesías diciendo 'una virgen concebirá'?",
         "opciones": ["Isaías", "Ezequiel", "Daniel"], "respuesta": "Isaías"},

        {"pregunta": "¿Qué sacramento se da con aceite bendito?",
         "opciones": ["Eucaristía", "Unción de los enfermos", "Confirmación"],
         "respuesta": "Unción de los enfermos"},

        {"pregunta": "¿Qué apóstol negó a Jesús tres veces?",
         "opciones": ["Pedro", "Juan", "Tomás"], "respuesta": "Pedro"},

        {"pregunta": "¿Qué sacramento une a Cristo y la Iglesia de forma indisoluble?",
         "opciones": ["Bautismo", "Matrimonio", "Orden Sagrado"], "respuesta": "Matrimonio"},

        {"pregunta": "¿Cuál es el fruto principal del Espíritu Santo?",
         "opciones": ["Sabiduría", "Felicidad", "Caridad"], "respuesta": "Caridad"},

        {"pregunta": "¿Qué evangelio comienza con 'En el principio era el Verbo'?",
         "opciones": ["Juan", "Lucas", "Marcos"], "respuesta": "Juan"},

        {"pregunta": "¿Qué rey de Israel escribió muchos salmos?",
         "opciones": ["David", "Saúl", "Salomón"], "respuesta": "David"},

        {"pregunta": "¿Cuál es el acto moral más grave según la Iglesia?",
         "opciones": ["Robo", "Pecado mortal", "Mentira"], "respuesta": "Pecado mortal"},

        {"pregunta": "¿Qué libro habla sobre el fin de los tiempos?",
         "opciones": ["Daniel", "Apocalipsis", "Romanos"], "respuesta": "Apocalipsis"},

        {"pregunta": "¿Qué virtud moral permite elegir el bien en situaciones difíciles?",
         "opciones": ["Templanza", "Prudencia", "Fortaleza"], "respuesta": "Fortaleza"},
    ]
}

# ------------------ FUNCIONES DEL JUEGO ------------------
def jugar(usuario_id, nombre, puntuacion_inicial):
    juego = tk.Toplevel()
    juego.title("Juego de Preguntas")
    juego.geometry("1280x720")
    juego.config(bg=COLOR_FONDO)

    tk.Label(juego, text=f"Bienvenido {nombre}", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 30)).pack(pady=30)
    tk.Label(juego, text=f"Puntuación actual: {puntuacion_inicial}", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 20)).pack()

    def iniciar_nivel(dificultad, vidas):
        preguntas = PREGUNTAS[dificultad][:]
        random.shuffle(preguntas)
        puntos = 0

        for preg in preguntas:
            ventana_preg = tk.Toplevel(juego)
            ventana_preg.title("Pregunta")
            ventana_preg.geometry("800x500")
            ventana_preg.config(bg=COLOR_FONDO)

            tk.Label(ventana_preg, text=preg["pregunta"], fg=COLOR_TEXTO, bg=COLOR_FONDO,
                     font=("Arial", 22)).pack(pady=20)

            def responder(opcion):
                nonlocal puntos, vidas
                if opcion == preg["respuesta"]:
                    messagebox.showinfo("Correcto", "Respuesta correcta!")
                    puntos += 1
                else:
                    messagebox.showerror("Incorrecto", "Respuesta incorrecta.")
                    vidas -= 1
                ventana_preg.destroy()

            for op in preg["opciones"]:
                tk.Button(ventana_preg, text=op, width=20, bg=COLOR_BOTON_PRINCIPAL,
                          fg="white", font=("Arial", 16), command=lambda o=op: responder(o)).pack(pady=10)

            ventana_preg.wait_window()

            if vidas <= 0:
                messagebox.showerror("Fin", "Te quedaste sin vidas")
                break

        if puntos > 0:
            actualizar_puntuacion(usuario_id, puntos)
            messagebox.showinfo("Resultado", f"Ganaste {puntos} puntos.")
        else:
            messagebox.showinfo("Resultado", "No obtuviste puntos.")

    tk.Label(juego, text="Selecciona nivel:", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 24)).pack(pady=40)

    tk.Button(juego, text="Fácil (5 vidas)", width=20, font=("Arial", 18),
              bg=COLOR_BOTON_PRINCIPAL, fg="white", command=lambda: iniciar_nivel("facil", 5)).pack(pady=10)

    tk.Button(juego, text="Medio (3 vidas)", width=20, font=("Arial", 18),
              bg=COLOR_BOTON_SECUNDARIO, fg="black", command=lambda: iniciar_nivel("medio", 3)).pack(pady=10)

    tk.Button(juego, text="Difícil (1 vida)", width=20, font=("Arial", 18),
              bg=COLOR_BOTON_PELIGRO, fg="white", command=lambda: iniciar_nivel("dificil", 1)).pack(pady=10)

    tk.Button(juego, text="Salir", width=20, font=("Arial", 16),
              bg="black", fg="white", command=juego.destroy).pack(pady=40)


# ------------------ LOGIN ------------------
def login():
    nombre = entry_nombre.get()
    contrasena = entry_contrasena.get()
    usuario_id, puntuacion = iniciar_sesion(nombre, contrasena)
    if usuario_id:
        ventana.withdraw()
        ventana_captcha(lambda: jugar(usuario_id, nombre, puntuacion))


def registro():
    nombre = entry_nombre.get()
    contrasena = entry_contrasena.get()
    registrar_usuario(nombre, contrasena)


# ------------------ PANTALLA PRINCIPAL ------------------
ventana = tk.Tk()
ventana.title("Login - ProyectoCui")
ventana.geometry("1280x720")
ventana.config(bg=COLOR_FONDO)

tk.Label(ventana, text="PROYECTO CUI", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 40)).pack(pady=50)

tk.Label(ventana, text="Nombre de usuario:", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 20)).pack(pady=10)
entry_nombre = tk.Entry(ventana, font=("Arial", 18), width=25)
entry_nombre.pack(pady=5)

tk.Label(ventana, text="Contraseña:", fg=COLOR_TEXTO, bg=COLOR_FONDO, font=("Arial", 20)).pack(pady=10)
entry_contrasena = tk.Entry(ventana, show="*", font=("Arial", 18), width=25)
entry_contrasena.pack(pady=5)

tk.Button(ventana, text="Iniciar sesión", width=20, font=("Arial", 18),
          bg=COLOR_BOTON_PRINCIPAL, fg="white", command=login).pack(pady=20)

tk.Button(ventana, text="Registrar usuario", width=20, font=("Arial", 18),
          bg=COLOR_BOTON_SECUNDARIO, fg="black", command=registro).pack(pady=10)

ventana.mainloop()
