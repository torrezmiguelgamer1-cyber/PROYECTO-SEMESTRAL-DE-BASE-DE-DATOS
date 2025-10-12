import tkinter as tk
from tkinter import messagebox, simpledialog
import pyodbc
import random
import subprocess
import webbrowser
import threading
import os
import time

# ================== CONEXIÓN A BASE DE DATOS ==================
def get_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=ProyectoCui;"
        "Trusted_Connection=yes;"
    )

# ================== FUNCIONES DE USUARIO ==================
def crear_tablas():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Usuarios' AND xtype='U')
    CREATE TABLE Usuarios (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(100) UNIQUE NOT NULL,
        contraseña NVARCHAR(100) NOT NULL
    );
    """)

    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Puntajes' AND xtype='U')
    CREATE TABLE Puntajes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        usuario_id INT,
        puntuacion INT DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES Usuarios(id)
    );
    """)
    conn.commit()
    cursor.close()
    conn.close()

def registrar_usuario(nombre, contraseña):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Usuarios (nombre, contraseña) VALUES (?, ?)", (nombre, contraseña))
        conn.commit()
        cursor.close()
        conn.close()
        messagebox.showinfo("Registro", "✅ Usuario registrado correctamente.")
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo registrar el usuario: {e}")

def verificar_login(nombre, contraseña):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, contraseña FROM Usuarios WHERE nombre=?", (nombre,))
    datos = cursor.fetchone()
    cursor.close()
    conn.close()
    if datos and datos[1] == contraseña:
        return datos[0]  # retorna el ID del usuario
    return None

def obtener_puntaje(usuario_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT puntuacion FROM Puntajes WHERE usuario_id=?", (usuario_id,))
    dato = cursor.fetchone()
    if dato:
        puntaje = dato[0]
    else:
        cursor.execute("INSERT INTO Puntajes (usuario_id, puntuacion) VALUES (?, ?)", (usuario_id, 0))
        conn.commit()
        puntaje = 0
    cursor.close()
    conn.close()
    return puntaje

def actualizar_puntaje(usuario_id, puntos):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE Puntajes SET puntuacion = puntuacion + ? WHERE usuario_id=?", (puntos, usuario_id))
    conn.commit()
    cursor.close()
    conn.close()

# ================== SISTEMA DE PREGUNTAS ==================
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

# ================== CAPTCHA ==================
def iniciar_verificador():
    ruta_verificador = os.path.join(os.path.dirname(__file__), "verificador.py")
    subprocess.Popen(["python", ruta_verificador], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    messagebox.showinfo("Servidor", "Servidor de verificación iniciado.")
    webbrowser.open("http://127.0.0.1:5000/")

def verificar_captcha(callback):
    """Verifica si el captcha fue completado correctamente antes de iniciar el juego."""
    ruta_resultado = os.path.join(os.path.dirname(__file__), "captcha_result.txt")

    def esperar_resultado():
        for _ in range(20):
            if os.path.exists(ruta_resultado):
                with open(ruta_resultado, "r") as f:
                    if f.read().strip() == "ok":
                        os.remove(ruta_resultado)
                        messagebox.showinfo("Verificación", "✅ Captcha verificado correctamente.")
                        callback()  # iniciar juego
                        return
            time.sleep(1)
        messagebox.showerror("Error", "No se completó el captcha a tiempo.")

    threading.Thread(target=esperar_resultado, daemon=True).start()

# ================== SISTEMA DE JUEGO ==================
def iniciar_juego(usuario_id, nombre, nivel):
    preguntas_sel = preguntas[nivel][:]
    random.shuffle(preguntas_sel)

    ventana_juego = tk.Toplevel()
    ventana_juego.title(f"Trivia - Nivel {nivel.capitalize()}")
    ventana_juego.geometry("400x300")

    puntuacion = obtener_puntaje(usuario_id)
    lbl_puntaje = tk.Label(ventana_juego, text=f"Puntaje actual: {puntuacion}", font=("Arial", 12))
    lbl_puntaje.pack(pady=10)

    def mostrar_pregunta(i):
        if i >= len(preguntas_sel):
            messagebox.showinfo("Fin", "¡Has completado el nivel!")
            actualizar_puntaje(usuario_id, len(preguntas_sel))
            ventana_juego.destroy()
            return

        p = preguntas_sel[i]
        for widget in ventana_juego.winfo_children():
            widget.destroy()

        tk.Label(ventana_juego, text=p["pregunta"], font=("Arial", 14)).pack(pady=10)

        for op in p["opciones"]:
            tk.Button(
                ventana_juego, text=op, width=20,
                command=lambda o=op: verificar_respuesta(o, p["respuesta"], i)
            ).pack(pady=5)

    def verificar_respuesta(opcion, correcta, i):
        if opcion == correcta:
            messagebox.showinfo("Correcto", "✅ Respuesta correcta!")
            actualizar_puntaje(usuario_id, 1)
        else:
            messagebox.showerror("Incorrecto", f"❌ Incorrecto. La respuesta era {correcta}")
        mostrar_pregunta(i + 1)

    mostrar_pregunta(0)

# ================== LOGIN Y REGISTRO ==================
def ventana_login():
    root = tk.Tk()
    root.title("Inicio de sesión")
    root.geometry("350x250")

    tk.Label(root, text="Usuario:").pack(pady=5)
    entry_user = tk.Entry(root)
    entry_user.pack()

    tk.Label(root, text="Contraseña:").pack(pady=5)
    entry_pass = tk.Entry(root, show="*")
    entry_pass.pack()

    def iniciar_sesion():
        nombre = entry_user.get()
        contraseña = entry_pass.get()
        user_id = verificar_login(nombre, contraseña)
        if user_id:
            messagebox.showinfo("Bienvenido", f"¡Hola, {nombre}!")
            iniciar_verificador()
            verificar_captcha(lambda: seleccionar_nivel(user_id, nombre))
        else:
            messagebox.showerror("Error", "Usuario o contraseña incorrectos.")

    def registrarse():
        nombre = entry_user.get()
        contraseña = entry_pass.get()
        if nombre and contraseña:
            registrar_usuario(nombre, contraseña)
        else:
            messagebox.showerror("Error", "Completa ambos campos.")

    tk.Button(root, text="Iniciar sesión", command=iniciar_sesion).pack(pady=10)
    tk.Button(root, text="Registrarse", command=registrarse).pack(pady=5)
    tk.Button(root, text="Salir", command=root.destroy).pack(pady=5)

    root.mainloop()

def seleccionar_nivel(usuario_id, nombre):
    win = tk.Toplevel()
    win.title("Selecciona nivel")
    win.geometry("300x200")

    for nivel in ["facil", "medio", "dificil"]:
        tk.Button(win, text=nivel.capitalize(), width=15,
                  command=lambda n=nivel: iniciar_juego(usuario_id, nombre, n)).pack(pady=10)

# ================== INICIO ==================
if __name__ == "__main__":
    crear_tablas()
    ventana_login()



