import tkinter as tk
from tkinter import messagebox
import pyodbc
import subprocess
import webbrowser
import threading
import time
import os
import random

# ------------------ CONEXIÓN A SQL SERVER ------------------
def get_connection():
    try:
        conn = pyodbc.connect(
            "Driver={ODBC Driver 17 for SQL Server};"
            "Server=LOCALHOST;"  # 🔹 Cambia esto según tu entorno
            "Database=ProyectoCui;"
            "Trusted_Connection=yes;"
        )
        return conn
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo conectar a la base de datos:\n{e}")
        return None


# ------------------ FUNCIONES DE USUARIO ------------------
def registrar_usuario(nombre, contrasena):
    """Registra un nuevo usuario con su contraseña."""
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
        messagebox.showerror("Error", f"No se pudo registrar el usuario:\n{e}")
        return False


def iniciar_sesion(nombre, contrasena):
    """Verifica usuario y contraseña, devuelve (usuario_id, puntuacion)."""
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
    """Suma puntos al usuario en la base de datos."""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Puntuaciones SET puntuacion = puntuacion + ? WHERE usuario_id=?", (puntos, usuario_id))
        conn.commit()
        conn.close()
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo actualizar la puntuación:\n{e}")


# ------------------ CAPTCHA ------------------
def eliminar_archivo_seguro(ruta_resultado):
    """Elimina el archivo captcha_result.txt sin causar errores si está en uso."""
    for _ in range(5):
        try:
            if os.path.exists(ruta_resultado):
                os.remove(ruta_resultado)
            break
        except PermissionError:
            time.sleep(0.5)
    else:
        print(f"No se pudo eliminar {ruta_resultado}, aún está en uso.")


def iniciar_verificador():
    """Inicia el servidor Flask (verificador.py) en segundo plano."""
    ruta_verificador = os.path.join(os.path.dirname(__file__), "verificador.py")
    subprocess.Popen(["python", ruta_verificador], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    messagebox.showinfo("Servidor", "Servidor de verificación iniciado.")


def abrir_captcha():
    """Abre la página del captcha en el navegador."""
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
                        messagebox.showinfo("Verificación", "✅ Captcha verificado correctamente.")
                        callback()
                        return
            time.sleep(1)
        messagebox.showerror("Error", "❌ No se completó el captcha a tiempo.")

    threading.Thread(target=esperar_resultado, daemon=True).start()


def ventana_captcha(callback):
    """Muestra la ventana con las opciones del captcha."""
    cap = tk.Toplevel()
    cap.title("Verificación reCAPTCHA")
    cap.geometry("400x250")
    cap.config(bg="#000000")

    tk.Label(cap, text="Verifica que eres humano antes de jugar", bg="#F2F2F2").pack(pady=20)
    tk.Button(cap, text="Iniciar verificador", command=iniciar_verificador).pack(pady=10)
    tk.Button(cap, text="Abrir reCAPTCHA", command=abrir_captcha).pack(pady=10)
    tk.Button(cap, text="Verificar", command=lambda: verificar_captcha(lambda: [cap.destroy(), callback()])).pack(pady=10)


# ------------------ PREGUNTAS ------------------
PREGUNTAS = {
    "facil": [
        {"pregunta": "Capital de Francia?", "opciones": ["Paris", "Madrid", "Roma"], "respuesta": "Paris"},
        {"pregunta": "5 + 3 = ?", "opciones": ["6", "8", "9"], "respuesta": "8"},
        {"pregunta": "Color del cielo despejado?", "opciones": ["Azul", "Verde", "Rojo"], "respuesta": "Azul"},
    ],
    "medio": [
        {"pregunta": "¿Quién pintó la Mona Lisa?", "opciones": ["Picasso", "Da Vinci", "Van Gogh"], "respuesta": "Da Vinci"},
        {"pregunta": "Raíz cuadrada de 81?", "opciones": ["7", "8", "9"], "respuesta": "9"},
        {"pregunta": "¿Cuál es el río más largo del mundo?", "opciones": ["Nilo", "Amazonas", "Yangtsé"], "respuesta": "Amazonas"},
    ],
    "dificil": [
        {"pregunta": "Año de la caída de Constantinopla?", "opciones": ["1453", "1492", "1415"], "respuesta": "1453"},
        {"pregunta": "¿Quién formuló la teoría de la relatividad?", "opciones": ["Newton", "Einstein", "Galileo"], "respuesta": "Einstein"},
        {"pregunta": "¿Cuál es el elemento químico con símbolo Au?", "opciones": ["Plata", "Oro", "Aluminio"], "respuesta": "Oro"},
    ]
}


# ------------------ FUNCIONES DEL JUEGO ------------------
def jugar(usuario_id, nombre, puntuacion_inicial):
    """Muestra la ventana del juego con niveles y preguntas aleatorias."""
    juego = tk.Toplevel()
    juego.title("Juego de Preguntas")
    juego.geometry("500x400")

    tk.Label(juego, text=f"Bienvenido {nombre}", font=("Arial", 16)).pack(pady=10)
    tk.Label(juego, text=f"Puntuación actual: {puntuacion_inicial}", font=("Arial", 12)).pack()

    def iniciar_nivel(dificultad, vidas):
        preguntas = PREGUNTAS[dificultad][:]
        random.shuffle(preguntas)
        puntos = 0

        for preg in preguntas:
            ventana_preg = tk.Toplevel(juego)
            ventana_preg.title("Pregunta")
            tk.Label(ventana_preg, text=preg["pregunta"], font=("Arial", 12)).pack(pady=10)

            def responder(opcion):
                nonlocal puntos, vidas
                if opcion == preg["respuesta"]:
                    messagebox.showinfo("Correcto", "✅ Respuesta correcta!")
                    puntos += 1
                else:
                    messagebox.showerror("Incorrecto", "❌ Respuesta incorrecta.")
                    vidas -= 1
                ventana_preg.destroy()

            for op in preg["opciones"]:
                tk.Button(ventana_preg, text=op, command=lambda o=op: responder(o)).pack(pady=5)
            ventana_preg.wait_window()

            if vidas <= 0:
                messagebox.showerror("Fin", "Te quedaste sin vidas 😢")
                break

        if puntos > 0:
            actualizar_puntuacion(usuario_id, puntos)
            messagebox.showinfo("Resultado", f"Ganaste {puntos} puntos.")
        else:
            messagebox.showinfo("Resultado", "No obtuviste puntos esta vez.")

    # Menú de niveles
    tk.Label(juego, text="Selecciona nivel:", font=("Arial", 13)).pack(pady=15)
    tk.Button(juego, text="Fácil (5 vidas)", command=lambda: iniciar_nivel("facil", 5)).pack(pady=5)
    tk.Button(juego, text="Medio (3 vidas)", command=lambda: iniciar_nivel("medio", 3)).pack(pady=5)
    tk.Button(juego, text="Difícil (1 vida)", command=lambda: iniciar_nivel("dificil", 1)).pack(pady=5)
    tk.Button(juego, text="Salir", command=juego.destroy).pack(pady=10)


# ------------------ INTERFAZ PRINCIPAL ------------------
def login():
    nombre = entry_nombre.get()
    contrasena = entry_contrasena.get()
    usuario_id, puntuacion = iniciar_sesion(nombre, contrasena)
    if usuario_id:
        ventana_captcha(lambda: jugar(usuario_id, nombre, puntuacion))


def registro():
    nombre = entry_nombre.get()
    contrasena = entry_contrasena.get()
    registrar_usuario(nombre, contrasena)


# ------------------ PANTALLA PRINCIPAL ------------------
ventana = tk.Tk()
ventana.title("Login - ProyectoCui")
ventana.geometry("400x300")

tk.Label(ventana, text="Nombre de usuario:").pack(pady=5)
entry_nombre = tk.Entry(ventana)
entry_nombre.pack(pady=5)

tk.Label(ventana, text="Contraseña:").pack(pady=5)
entry_contrasena = tk.Entry(ventana, show="*")
entry_contrasena.pack(pady=5)

tk.Button(ventana, text="Iniciar sesión", command=login).pack(pady=10)
tk.Button(ventana, text="Registrar usuario", command=registro).pack(pady=5)

ventana.mainloop()