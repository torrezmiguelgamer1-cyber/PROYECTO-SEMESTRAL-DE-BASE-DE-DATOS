CREATE DATABASE TriviaGame;
GO
USE TriviaGame;
GO
CREATE TABLE Usuarios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL,
    fecha_registro DATETIME DEFAULT GETDATE()
);
CREATE TABLE Partidas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT FOREIGN KEY REFERENCES Usuarios(id),
    fecha DATETIME DEFAULT GETDATE(),
    dificultad NVARCHAR(20),
    modo NVARCHAR(20)
);
CREATE TABLE Puntajes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    partida_id INT FOREIGN KEY REFERENCES Partidas(id),
    puntaje INT NOT NULL,
    vidas_restantes INT
);