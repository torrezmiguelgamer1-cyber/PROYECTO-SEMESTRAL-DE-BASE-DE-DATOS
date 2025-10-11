import tkinter as tk
from tkinter import messagebox, simpledialog
import random
import pyodbc

# ================== CONEXIÓN A BASE DE DATOS ==================
def get_connection():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"  # cambia a localhost\\SQLEXPRESS si usas SQL Express
        "DATABASE=TriviaGame;"
        "Trusted_Connection=yes;"
    )
    return conn

def usuario_existe(nombre):
    """Verifica si el usuario ya está registrado"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM Usuarios WHERE nombre = ?", (nombre,))
        count = cursor.fetchone()[0]
        conn.close()
        return count > 0
    except Exception as e:
        print("❌ Error al verificar usuario:", e)
        return False

def registrar_usuario(nombre, contrasena):
    """Registra un nuevo usuario si no existe"""
    if usuario_existe(nombre):
        messagebox.showwarning("Registro", "⚠️ Este usuario ya está registrado. Inicia sesión.")
        return False

    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Usuarios (nombre, contrasena) VALUES (?, ?)", (nombre, contrasena))
        conn.commit()
        conn.close()
        print(f"✅ Usuario '{nombre}' registrado correctamente")
        messagebox.showinfo("Registro", "Usuario registrado correctamente ✅")
        return True
    except Exception as e:
        print("❌ Error al registrar usuario:", e)
        messagebox.showerror("Error", "No se pudo registrar el usuario")
        return False

def verificar_login(nombre, contrasena):
    """Verifica si usuario y contraseña son correctos"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Usuarios WHERE nombre = ? AND contrasena = ?", (nombre, contrasena))
        user = cursor.fetchone()
        conn.close()
        return user is not None
    except Exception as e:
        print("❌ Error al verificar login:", e)
        return False

# ================== DATOS DE PREGUNTAS ==================
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

# ================== CLASE JUGADOR ==================
class Jugador:
    def __init__(self, nombre, vidas):
        self.nombre = nombre
        self.vidas = vidas
        self.puntuacion = 0

    def sumar_punto(self):
        self.puntuacion += 1

    def perder_vida(self):
        self.vidas -= 1

# ================== JUEGO ==================
class Juego:
    def __init__(self, root):
        self.root = root
        self.root.title("Trivia Game con Login")
        self.root.geometry("420x320")
        self.main_menu()

    # --- Menú principal ---
    def main_menu(self):
        self.clear_window()
        tk.Label(self.root, text="🎮 Juego de Preguntas", font=("Arial", 16)).pack(pady=20)
        tk.Button(self.root, text="Iniciar Sesión", width=20, command=self.login_menu).pack(pady=5)
        tk.Button(self.root, text="Registrar Usuario", width=20, command=self.registro_menu).pack(pady=5)
        tk.Button(self.root, text="Salir", width=20, command=self.root.destroy).pack(pady=20)

    # --- Menú de login ---
    def login_menu(self):
        self.clear_window()
        tk.Label(self.root, text="🔑 Iniciar Sesión", font=("Arial", 14)).pack(pady=10)

        tk.Label(self.root, text="Usuario:").pack()
        self.entry_user = tk.Entry(self.root)
        self.entry_user.pack()

        tk.Label(self.root, text="Contraseña:").pack()
        self.entry_pass = tk.Entry(self.root, show="*")
        self.entry_pass.pack()

        tk.Button(self.root, text="Ingresar", command=self.login).pack(pady=10)
        tk.Button(self.root, text="Volver", command=self.main_menu).pack()

    def login(self):
        nombre = self.entry_user.get().strip()
        contrasena = self.entry_pass.get().strip()
        if verificar_login(nombre, contrasena):
            messagebox.showinfo("Bienvenido", f"✅ Bienvenido {nombre}")
            self.usuario_actual = nombre
            self.seleccionar_dificultad(1)  # Inicia con 1 jugador
        else:
            messagebox.showerror("Error", "❌ Usuario o contraseña incorrectos")

    # --- Menú de registro ---
    def registro_menu(self):
        self.clear_window()
        tk.Label(self.root, text="📝 Registrar Usuario", font=("Arial", 14)).pack(pady=10)

        tk.Label(self.root, text="Nombre de usuario:").pack()
        self.reg_user = tk.Entry(self.root)
        self.reg_user.pack()

        tk.Label(self.root, text="Contraseña:").pack()
        self.reg_pass = tk.Entry(self.root, show="*")
        self.reg_pass.pack()

        tk.Button(self.root, text="Registrar", command=self.registrar).pack(pady=10)
        tk.Button(self.root, text="Volver", command=self.main_menu).pack()

    def registrar(self):
        nombre = self.reg_user.get().strip()
        contrasena = self.reg_pass.get().strip()
        if not nombre or not contrasena:
            messagebox.showwarning("Advertencia", "Completa todos los campos")
            return
        if registrar_usuario(nombre, contrasena):
            self.main_menu()

    # --- Selección de dificultad ---
    def seleccionar_dificultad(self, jugadores):
        self.clear_window()
        tk.Label(self.root, text="Selecciona dificultad:", font=("Arial", 14)).pack(pady=15)
        tk.Button(self.root, text="Fácil", command=lambda: self.iniciar_juego("facil", jugadores, 5)).pack(pady=5)
        tk.Button(self.root, text="Medio", command=lambda: self.iniciar_juego("medio", jugadores, 3)).pack(pady=5)
        tk.Button(self.root, text="Difícil", command=lambda: self.iniciar_juego("dificil", jugadores, 1)).pack(pady=5)
        tk.Button(self.root, text="Volver", command=self.main_menu).pack(pady=20)

    # --- Iniciar juego ---
    def iniciar_juego(self, dificultad, jugadores, vidas):
        self.dificultad = dificultad
        self.vidas_iniciales = vidas
        self.preguntas_sel = preguntas[dificultad][:]
        random.shuffle(self.preguntas_sel)
        self.j1 = Jugador(self.usuario_actual, vidas)
        self.turno = 0
        self.mostrar_pregunta()

    # --- Mostrar pregunta ---
    def mostrar_pregunta(self):
        if not self.preguntas_sel:
            return self.mostrar_resultados()

        self.clear_window()
        preg = self.preguntas_sel.pop(0)
        tk.Label(self.root, text=f"Turno de {self.j1.nombre}", font=("Arial", 13)).pack(pady=10)
        tk.Label(self.root, text=preg["pregunta"], font=("Arial", 12)).pack(pady=10)
        for op in preg["opciones"]:
            tk.Button(self.root, text=op, width=15, command=lambda o=op, p=preg: self.verificar_respuesta(o, p)).pack(pady=4)

    def verificar_respuesta(self, opcion, preg):
        if opcion == preg["respuesta"]:
            messagebox.showinfo("Resultado", "✅ Correcto!")
            self.j1.sumar_punto()
        else:
            messagebox.showwarning("Resultado", f"❌ Incorrecto! La respuesta era {preg['respuesta']}")
            self.j1.perder_vida()
        self.turno += 1
        self.mostrar_pregunta()

    # --- Mostrar resultados ---
    def mostrar_resultados(self):
        self.clear_window()
        tk.Label(self.root, text="🏆 Resultados finales", font=("Arial", 15)).pack(pady=10)
        tk.Label(self.root, text=f"{self.j1.nombre}: {self.j1.puntuacion} puntos, {self.j1.vidas} vidas").pack(pady=5)
        tk.Button(self.root, text="Volver al menú", command=self.main_menu).pack(pady=20)

    def clear_window(self):
        for widget in self.root.winfo_children():
            widget.destroy()

# ================== EJECUCIÓN PRINCIPAL ==================
if __name__ == "__main__":
    root = tk.Tk()
    app = Juego(root)
    root.mainloop()
