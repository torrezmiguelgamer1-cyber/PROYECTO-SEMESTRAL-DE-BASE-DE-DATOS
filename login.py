import tkinter as tk
from tkinter import messagebox
import random
import pyodbc

# ================== CONEXIÓN A SQL SERVER ==================
def get_connection():
    """Crea una conexión a la base de datos ProyectoCui"""
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"        # Cambia si tu instancia es distinta, por ejemplo: localhost\\SQLEXPRESS
        "DATABASE=ProyectoCui;"
        "Trusted_Connection=yes;"
    )

# ================== FUNCIONES DE BASE DE DATOS ==================
def registrar_usuario(nombre, contrasena):
    """Registra un nuevo usuario con su contraseña."""
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Verificar si el usuario ya existe
        cursor.execute("SELECT * FROM Usuarios WHERE nombre=?", (nombre,))
        if cursor.fetchone():
            messagebox.showerror("Error", "El usuario ya existe.")
            conn.close()
            return False

        # Insertar nuevo usuario
        cursor.execute("INSERT INTO Usuarios (nombre, contrasena) VALUES (?, ?)", (nombre, contrasena))
        conn.commit()

        # Obtener su ID para crear su puntuación inicial
        cursor.execute("SELECT id FROM Usuarios WHERE nombre=?", (nombre,))
        usuario_id = cursor.fetchone()[0]

        # Crear registro de puntuación inicial
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

# ================== PREGUNTAS ==================
preguntas = [
    {"pregunta": "Capital de Francia?", "opciones": ["París", "Madrid", "Roma"], "respuesta": "París"},
    {"pregunta": "5 + 3 = ?", "opciones": ["6", "8", "9"], "respuesta": "8"},
    {"pregunta": "¿Quién pintó la Mona Lisa?", "opciones": ["Picasso", "Da Vinci", "Van Gogh"], "respuesta": "Da Vinci"},
    {"pregunta": "Raíz cuadrada de 81?", "opciones": ["7", "8", "9"], "respuesta": "9"},
    {"pregunta": "¿Quién formuló la teoría de la relatividad?", "opciones": ["Newton", "Einstein", "Galileo"], "respuesta": "Einstein"},
]

# ================== INTERFAZ DE LOGIN ==================
def ventana_login():
    def login():
        nombre = entry_nombre.get()
        contrasena = entry_contra.get()
        if not nombre or not contrasena:
            messagebox.showwarning("Atención", "Completa todos los campos.")
            return

        usuario_id, puntuacion = iniciar_sesion(nombre, contrasena)
        if usuario_id:
            root.destroy()
            ventana_juego(nombre, usuario_id, puntuacion)

    def registrar():
        nombre = entry_nombre.get()
        contrasena = entry_contra.get()
        if not nombre or not contrasena:
            messagebox.showwarning("Atención", "Completa todos los campos.")
            return

        if registrar_usuario(nombre, contrasena):
            messagebox.showinfo("Listo", "Usuario registrado. Ya puedes iniciar sesión.")

    root = tk.Tk()
    root.title("Login ProyectoCui - Trivia")
    root.geometry("320x240")

    tk.Label(root, text="Bienvenido a ProyectoCui", font=("Arial", 14, "bold")).pack(pady=10)
    tk.Label(root, text="Nombre de usuario:").pack()
    entry_nombre = tk.Entry(root)
    entry_nombre.pack(pady=5)

    tk.Label(root, text="Contraseña:").pack()
    entry_contra = tk.Entry(root, show="*")
    entry_contra.pack(pady=5)

    tk.Button(root, text="Iniciar sesión", width=15, command=login).pack(pady=10)
    tk.Button(root, text="Registrarse", width=15, command=registrar).pack(pady=5)

    root.mainloop()

# ================== INTERFAZ DEL JUEGO ==================
def ventana_juego(nombre, usuario_id, puntuacion_actual):
    ventana = tk.Tk()
    ventana.title("Trivia - ProyectoCui")
    ventana.geometry("400x350")

    tk.Label(ventana, text=f"Bienvenido {nombre}", font=("Arial", 14)).pack()
    label_puntuacion = tk.Label(ventana, text=f"Puntuación total: {puntuacion_actual}", font=("Arial", 11))
    label_puntuacion.pack(pady=5)

    preguntas_juego = random.sample(preguntas, len(preguntas))
    puntaje_sesion = 0
    indice = [0]

    def siguiente_pregunta():
        if indice[0] >= len(preguntas_juego):
            messagebox.showinfo("Fin", f"Juego terminado. Ganaste {puntaje_sesion} puntos.")
            actualizar_puntuacion(usuario_id, puntaje_sesion)
            ventana.destroy()
            return

        pregunta_actual = preguntas_juego[indice[0]]
        label_pregunta.config(text=pregunta_actual["pregunta"])

        for i, op in enumerate(pregunta_actual["opciones"]):
            botones_opciones[i].config(text=op, command=lambda resp=op: responder(resp))

    def responder(respuesta):
        nonlocal puntaje_sesion
        pregunta_actual = preguntas_juego[indice[0]]
        if respuesta == pregunta_actual["respuesta"]:
            messagebox.showinfo("Correcto", "✅ ¡Respuesta correcta!")
            puntaje_sesion += 1
            label_puntuacion.config(text=f"Puntuación total: {puntuacion_actual + puntaje_sesion}")
        else:
            messagebox.showerror("Incorrecto", f"❌ La respuesta correcta era: {pregunta_actual['respuesta']}")
        indice[0] += 1
        siguiente_pregunta()

    label_pregunta = tk.Label(ventana, text="", font=("Arial", 12), wraplength=350)
    label_pregunta.pack(pady=20)

    botones_opciones = [tk.Button(ventana, text="", width=25, height=1) for _ in range(3)]
    for b in botones_opciones:
        b.pack(pady=3)

    siguiente_pregunta()
    ventana.mainloop()

# ================== EJECUCIÓN PRINCIPAL ==================
if __name__ == "__main__":
    ventana_login()


