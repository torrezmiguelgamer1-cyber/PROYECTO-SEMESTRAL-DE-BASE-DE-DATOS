import tkinter as tk
from tkinter import messagebox
import random
import pyodbc

# ================== CONEXIÓN A SQL SERVER ==================
def get_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=TriviaGame;"
        "Trusted_Connection=yes;"
    )

# ================== FUNCIONES DE BASE DE DATOS ==================
def registrar_usuario(nombre, contrasena):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Verificar si ya existe
        cursor.execute("SELECT * FROM Usuarios WHERE nombre=?", (nombre,))
        if cursor.fetchone():
            messagebox.showerror("Error", "El usuario ya existe.")
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
        messagebox.showerror("Error", f"No se pudo registrar: {e}")
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
        messagebox.showerror("Error", f"No se pudo iniciar sesión: {e}")
        return None, 0

def actualizar_puntuacion(usuario_id, puntos):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Puntuaciones SET puntuacion = puntuacion + ? WHERE usuario_id=?", (puntos, usuario_id))
        conn.commit()
        conn.close()
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo actualizar la puntuación: {e}")

# ================== PREGUNTAS ==================
preguntas = [
    {"pregunta": "Capital de Francia?", "opciones": ["París", "Madrid", "Roma"], "respuesta": "París"},
    {"pregunta": "5 + 3 = ?", "opciones": ["6", "8", "9"], "respuesta": "8"},
    {"pregunta": "¿Quién pintó la Mona Lisa?", "opciones": ["Picasso", "Da Vinci", "Van Gogh"], "respuesta": "Da Vinci"},
    {"pregunta": "Raíz cuadrada de 81?", "opciones": ["7", "8", "9"], "respuesta": "9"},
]

# ================== VENTANA DE LOGIN ==================
def ventana_login():
    def login():
        nombre = entry_nombre.get()
        contrasena = entry_contra.get()
        usuario_id, puntuacion = iniciar_sesion(nombre, contrasena)
        if usuario_id:
            root.destroy()
            ventana_juego(nombre, usuario_id, puntuacion)

    def registrar():
        nombre = entry_nombre.get()
        contrasena = entry_contra.get()
        if registrar_usuario(nombre, contrasena):
            messagebox.showinfo("Listo", "Ya puedes iniciar sesión.")

    root = tk.Tk()
    root.title("Login Trivia")

    tk.Label(root, text="Nombre de usuario:").pack(pady=5)
    entry_nombre = tk.Entry(root)
    entry_nombre.pack()

    tk.Label(root, text="Contraseña:").pack(pady=5)
    entry_contra = tk.Entry(root, show="*")
    entry_contra.pack()

    tk.Button(root, text="Iniciar sesión", command=login).pack(pady=10)
    tk.Button(root, text="Registrarse", command=registrar).pack(pady=5)

    root.mainloop()

# ================== VENTANA DEL JUEGO ==================
def ventana_juego(nombre, usuario_id, puntuacion_actual):
    ventana = tk.Tk()
    ventana.title("Trivia Game")

    tk.Label(ventana, text=f"Bienvenido {nombre}", font=("Arial", 14)).pack()
    label_puntuacion = tk.Label(ventana, text=f"Puntuación actual: {puntuacion_actual}")
    label_puntuacion.pack()

    preguntas_juego = random.sample(preguntas, len(preguntas))
    puntaje_sesion = 0
    indice = [0]  # lista mutable para usar dentro de función

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
            label_puntuacion.config(text=f"Puntuación actual: {puntuacion_actual + puntaje_sesion}")
        else:
            messagebox.showerror("Incorrecto", f"❌ La respuesta correcta era: {pregunta_actual['respuesta']}")
        indice[0] += 1
        siguiente_pregunta()

    label_pregunta = tk.Label(ventana, text="", font=("Arial", 12))
    label_pregunta.pack(pady=10)

    botones_opciones = [tk.Button(ventana, text="", width=20) for _ in range(3)]
    for b in botones_opciones:
        b.pack(pady=3)

    siguiente_pregunta()
    ventana.mainloop()

# ================== INICIO ==================
if __name__ == "__main__":
    ventana_login()

