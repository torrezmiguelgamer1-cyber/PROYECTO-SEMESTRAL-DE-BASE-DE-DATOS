import tkinter as tk
from tkinter import messagebox
import webbrowser
import subprocess
import threading
import os
import time

def iniciar_verificador():
    """Inicia el servidor Flask (verificador.py) en segundo plano."""
    ruta_verificador = os.path.join(os.path.dirname(__file__), "verificador.py")
    subprocess.Popen(["python", ruta_verificador], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    messagebox.showinfo("Servidor", "Servidor de verificación iniciado.")

def abrir_captcha():
    """Abre la página del captcha en el navegador."""
    webbrowser.open("http://127.0.0.1:5000/")

def verificar_captcha():
    """Verifica si el captcha fue completado correctamente."""
    ruta_resultado = os.path.join(os.path.dirname(__file__), "captcha_result.txt")

    for i in range(15):  
        if os.path.exists(ruta_resultado):
            with open(ruta_resultado, "r") as f:
                if f.read().strip() == "ok":
                    messagebox.showinfo("Verificación", " Captcha verificado correctamente.")
                    os.remove(ruta_resultado)
                    abrir_juego()
                    return
        time.sleep(1)

    messagebox.showerror("Error", " No se completó el captcha a tiempo.")

def abrir_juego():
    """Muestra la ventana principal del juego."""
    nueva = tk.Toplevel()
    nueva.title(" Juego principal")
    nueva.geometry("400x300")
    tk.Label(nueva, text="¡Bienvenido al juego!", font=("Arial", 16)).pack(pady=40)
    tk.Button(nueva, text="Salir", command=nueva.destroy).pack(pady=10)



ventana = tk.Tk()
ventana.title("Verificación reCAPTCHA")
ventana.geometry("400x250")
ventana.config(bg="#000000")

tk.Label(ventana, text="Verifica que eres humano antes de jugar", bg="#F2F2F2").pack(pady=20)

tk.Button(ventana, text="Iniciar verificador", command=iniciar_verificador).pack(pady=10)
tk.Button(ventana, text="Abrir reCAPTCHA", command=abrir_captcha).pack(pady=10)
tk.Button(ventana, text="Verificar", command=verificar_captcha).pack(pady=10)

ventana.mainloop()
