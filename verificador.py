from flask import Flask, request, render_template_string
import requests
import os

app = Flask(__name__)


CLAVE_SECRETA = "6Lf6feUrAAAAAAq5dcqEB075PbRmuwEhQ4Y2zeL1"

@app.route('/')
def index():
    ruta_html = os.path.join(os.path.dirname(__file__), "captcha.html")
    if not os.path.exists(ruta_html):
        return "⚠️ No se encontró el archivo captcha.html."
    with open(ruta_html, "r", encoding="utf-8") as f:
        html = f.read()
    return render_template_string(html)

@app.route('/verificar', methods=['POST'])
def verificar():
    token = request.form.get('g-recaptcha-response')
    if not token:
        return "❌ No se recibió el token del reCAPTCHA."

    data = {
        'secret': CLAVE_SECRETA,
        'response': token
    }
    respuesta = requests.post('https://www.google.com/recaptcha/api/siteverify', data=data)
    resultado = respuesta.json()

    if resultado.get("success"):

        return "<h2>✅ Verificación correcta</h2><script>window.location.href='http://127.0.0.1:5000/success';</script>"
    else:
        return f"❌ Verificación fallida: {resultado}"

@app.route('/success')
def success():
    with open("captcha_result.txt", "w") as f:
        f.write("ok")
    return "<h1>✅ Verificación completada. Puedes volver al juego.</h1>"

if __name__ == "__main__":
    app.run(debug=True)
