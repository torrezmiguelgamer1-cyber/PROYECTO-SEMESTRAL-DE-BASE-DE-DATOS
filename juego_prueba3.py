import tkinter as tk
from tkinter import messagebox, simpledialog
import random
import pyodbc

# ================== CONEXIÓN A BASE DE DATOS ==================
def get_connection():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"  # Cambia si usas SQLEXPRESS → localhost\\SQLEXPRESS
        "DATABASE=TriviaGame;"
        "Trusted_Connection=yes;"
    )
    return conn

def guardar_usuario(nombre):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Usuarios (nombre) VALUES (?)", (nombre,))
        conn.commit()
        cursor.close()
        conn.close()
        print(f"✅ Usuario '{nombre}' guardado correctamente en SQL Server")
    except Exception as e:
        print("❌ Error al guardar usuario:", e)

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
        self.root.title("CABROS PREGUNTANDO")
        self.root.geometry("800x500")
        self.root.configure(bg="gray60")
        self.main_menu()

    # --- Menú principal ---
    def main_menu(self):
        self.clear_window()
        tk.Label(self.root, text="🎮 QUE TAN CJDO ERES???", font=("Arial", 16), bg="gray60").pack(pady=20)
        tk.Button(self.root, text="Un Jugador", command=lambda: self.seleccionar_dificultad(1), fg="yellow", bg="black").pack(pady=10)
        
        tk.Button(self.root, text="Dos Jugadores", command=lambda: self.seleccionar_dificultad(2),fg="yellow", bg="black").pack(pady=5)
        tk.Button(self.root, text="Salir", command=self.root.destroy,fg="yellow", bg="black").pack(pady=20)

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
        self.jugadores = jugadores

        # Pedir nombres
        nombre1 = simpledialog.askstring("Jugador 1", "Nombre del Jugador 1:")
        if not nombre1:
            return self.main_menu()

        self.j1 = Jugador(nombre1, vidas)
        guardar_usuario(nombre1)

        if jugadores == 2:
            nombre2 = simpledialog.askstring("Jugador 2", "Nombre del Jugador 2:")
            if not nombre2:
                return self.main_menu()
            self.j2 = Jugador(nombre2, vidas)
            guardar_usuario(nombre2)
        else:
            self.j2 = None

        self.turno = 0
        self.mostrar_pregunta()

    # --- Mostrar pregunta actual ---
    def mostrar_pregunta(self):
        if not self.preguntas_sel:
            return self.mostrar_resultados()

        self.clear_window()
        preg = self.preguntas_sel.pop(0)

        jugador_actual = self.j1 if (self.turno % 2 == 0 or self.j2 is None) else self.j2
        self.jugador_actual = jugador_actual

        tk.Label(self.root, text=f"Turno de {jugador_actual.nombre}", font=("Arial", 13)).pack(pady=10)
        tk.Label(self.root, text=preg["pregunta"], font=("Arial", 12)).pack(pady=10)

        for op in preg["opciones"]:
            tk.Button(self.root, text=op, width=15, command=lambda o=op, p=preg: self.verificar_respuesta(o, p)).pack(pady=4)

    # --- Verificar respuesta ---
    def verificar_respuesta(self, opcion, preg):
        if opcion == preg["respuesta"]:
            messagebox.showinfo("Resultado", "✅ Correcto!")
            self.jugador_actual.sumar_punto()
        else:
            messagebox.showwarning("Resultado", f"❌ Incorrecto! La respuesta era {preg['respuesta']}")
            self.jugador_actual.perder_vida()

        self.turno += 1
        self.mostrar_pregunta()

    # --- Mostrar resultados ---
    def mostrar_resultados(self):
        self.clear_window()
        tk.Label(self.root, text="🏆 Resultados finales", font=("Arial", 15)).pack(pady=10)
        tk.Label(self.root, text=f"{self.j1.nombre}: {self.j1.puntuacion} puntos, {self.j1.vidas} vidas").pack(pady=5)
        if self.j2:
            tk.Label(self.root, text=f"{self.j2.nombre}: {self.j2.puntuacion} puntos, {self.j2.vidas} vidas").pack(pady=5)
        tk.Button(self.root, text="Volver al menú", command=self.main_menu).pack(pady=20)

    # --- Limpiar ventana ---
    def clear_window(self):
        for widget in self.root.winfo_children():
            widget.destroy()


# ================== EJECUCIÓN PRINCIPAL ==================
if __name__ == "__main__":
    root = tk.Tk()
    app = Juego(root)
    root.mainloop()