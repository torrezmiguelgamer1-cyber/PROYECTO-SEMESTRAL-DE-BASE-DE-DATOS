#include <iostream>
#include <fstream>
#include <vector>
#include <windows.h>
#include <conio.h>
#include <string>
#include <thread>
#include <chrono>

using namespace std;

class Jugador {
private:
    string nombre;
    int puntuacion;

public:
    Jugador(string _nombre) {
        nombre = _nombre;
        puntuacion = 0;
    }

    void incrementarPuntuacion() {
        puntuacion++;
    }

    int getPuntuacion() const {
        return puntuacion;
    }

    string getNombre() const {
        return nombre;
    }

    void guardarInfo() const {
        ofstream archivo("jugadores.txt", ios::app);
        if (archivo.is_open()) {
            archivo << "Nombre: " << nombre << " - Puntuacion: " << puntuacion << endl;
            archivo.close();
        }
    }
};

void setColor(int color);
void menuPrincipal();
void jugar(int dificultad, int jugadores);
void cargarPreguntasDesdeArchivo(const string& archivo, vector<string>& preguntas, vector<string>& respuestas, vector<string>& correctas);
void verificarRespuesta(Jugador& jugador, string respuestaUsuario, string respuestaCorrecta, int& vidas);
string esperarRespuestaConTemporizador(int segundos, bool& tiempoAgotado);
void mostrarResultadoFinal(Jugador jugador);
int seleccionarDificultad();

int main() {
    menuPrincipal();
    return 0;
}

void menuPrincipal() {
    int opcion;
    do {
        setColor(3);
        cout << "====== MENU PRINCIPAL ======" << endl;
        cout << "1. Modo Un Jugador" << endl;
        cout << "2. Modo Dos Jugadores" << endl;
        cout << "3. Salir" << endl;
        cout << "Selecciona una opcion: ";
        cin >> opcion;

        switch (opcion) {
        case 1:
            jugar(seleccionarDificultad(), 1);
            break;
        case 2:
            jugar(seleccionarDificultad(), 2);
            break;
        case 3:
            cout << "Gracias por jugar!" << endl;
            break;
        default:
            cout << "Opcion invalida.\n";
        }
    } while (opcion != 3);
}

int seleccionarDificultad() {
    int opcion;
    setColor(3);
    cout << "\nSelecciona el nivel de dificultad:\n";
    cout << "1. FACIL (LAICOS)\n";
    cout << "2. MEDIO (SACERDOTE)\n";
    cout << "3. DIFICIL (CARDENAL)\n";
    cout << "Opcion: ";
    cin >> opcion;
    system("cls");
    if (opcion >= 1 && opcion <= 3)
        return opcion;
    else {
        setColor(4);
        cout << "Opcion invalida. Se seleccionara dificultad media por defecto.\n";
        return 2;
    }
}

void jugar(int dificultad, int jugadores) {
    cin.ignore();
    string nombre1, nombre2;
    int vidas1, vidas2;
    string archivoPreguntas;

    switch (dificultad) {
    case 1:
        archivoPreguntas = "preguntas_facil.txt";
        vidas1 = vidas2 = 5;
        break;
    case 2:
        archivoPreguntas = "preguntas_medio.txt";
        vidas1 = vidas2 = 3;
        break;
    case 3:
        archivoPreguntas = "preguntas_dificil.txt";
        vidas1 = vidas2 = 1;
        break;
    default:
        archivoPreguntas = "preguntas_medio.txt";
        vidas1 = vidas2 = 3;
        break;
    }

    cout << "Nombre del jugador 1: ";
    getline(cin, nombre1);
    Jugador jugador1(nombre1);

    Jugador jugador2("IA");
    if (jugadores == 2) {
        cout << "Nombre del jugador 2: ";
        getline(cin, nombre2);
        jugador2 = Jugador(nombre2);
    }

    vector<string> preguntas, respuestas, correctas;
    cargarPreguntasDesdeArchivo(archivoPreguntas, preguntas, respuestas, correctas);
    int totalPreguntas = preguntas.size();

    for (int i = 0; i < totalPreguntas && (vidas1 > 0 || vidas2 > 0); i++) {
        if (vidas1 > 0) {
            setColor(6);
            cout << "\nTurno de " << jugador1.getNombre() << ":\n";
            cout << preguntas[i] << endl << respuestas[i] << endl;
            cout << "Tu respuesta es: ";
            string r;
            cin >> r;
            verificarRespuesta(jugador1, r, correctas[i], vidas1);
        }

        if (jugadores == 2 && vidas2 > 0) {
            setColor(5);
            cout << "\nTurno de " << jugador2.getNombre() << ":\n";
            cout << preguntas[i] << endl << respuestas[i] << endl;
            cout << "Tu respuesta es: ";
            string r;
            cin >> r;
            verificarRespuesta(jugador2, r, correctas[i], vidas2);
        }
    }

    mostrarResultadoFinal(jugador1);
    if (jugadores == 2)
        mostrarResultadoFinal(jugador2);

    jugador1.guardarInfo();
    if (jugadores == 2)
        jugador2.guardarInfo();

    system("pause");
    system("cls");
}

void cargarPreguntasDesdeArchivo(const string& archivo, vector<string>& preguntas, vector<string>& respuestas, vector<string>& correctas) {
    ifstream file(archivo);
    string line;
    int count = 0;

    while (getline(file, line)) {
        if (count % 3 == 0) preguntas.push_back(line);
        else if (count % 3 == 1) respuestas.push_back(line);
        else correctas.push_back(line);
        count++;
    }
    file.close();
}

void verificarRespuesta(Jugador& jugador, string respuestaUsuario, string respuestaCorrecta, int& vidas) {
    if (respuestaUsuario == respuestaCorrecta) {
        setColor(2);
        cout << "Correcto!\n";
        jugador.incrementarPuntuacion();
    } else {
        setColor(4);
        vidas--;
        cout << "Incorrecto. Te quedan " << vidas << " vidas.\n";
    }
}

void mostrarResultadoFinal(Jugador jugador) {
    setColor(3);
    cout << "\n--- Resultado de " << jugador.getNombre() << " ---\n";
    cout << "Puntuacion final: " << jugador.getPuntuacion() << endl;
}

void setColor(int color) {
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);
}
