# gestor_cafeteria

Cliente Flutter para gestionar los pedidos de una cafetería. Consume la API de [mini_backend](https://github.com/DMI-2026/mini_backend) y traduce cada respuesta del servidor a un tipo de error de la app (`Failure`), para distinguir «no encontrado», «conflicto», «datos inválidos», «falla del servidor» y «sin conexión».

Proyecto de la materia Desarrollo Móvil Integral (UTEZ, 10.° C, septiembre–diciembre 2026).

## Requisitos

- Flutter 3.47 (Dart 3.13) o superior.
- Node.js 22.13 o superior, para el servidor.
- Un emulador de Android, Chrome o un celular para ejecutar la app.

## Servidor (mini_backend)

El servidor es otro repositorio y no se copia dentro de este proyecto: <https://github.com/DMI-2026/mini_backend>. Esta versión del cliente se probó con el commit `94d2533` de la rama `master`.

```bash
git clone https://github.com/DMI-2026/mini_backend.git
cd mini_backend
node server.js
```

No hace falta `npm install`. El servidor escucha en el puerto 8000; para comprobarlo, abre `http://localhost:8000/health` y debe responder `{"status":"ok"}`.

## Ejecutar la app

```bash
flutter pub get
flutter run
```

La dirección del servidor se toma de `API_URL`. Si no se indica, se usa `http://10.0.2.2:8000` en el emulador de Android y `http://localhost:8000` en Chrome.

```bash
# Celular físico en la misma red que la computadora
flutter run --dart-define=API_URL=http://<IP de tu computadora>:8000

# Celular conectado por USB, sin depender de la red
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_URL=http://localhost:8000
```

## Pruebas

Las pruebas usan `MockClient` del paquete `http`, así que no necesitan el servidor ni red.

```bash
flutter test
flutter analyze
```

## Estructura

```
lib/
  core/
    failure.dart        # jerarquía sellada de errores (Failure)
    http_client.dart    # ApiClient: peticiones, timeout y mapeo de códigos HTTP a Failure
  main.dart             # pantalla de prueba que lista los pedidos
test/
  core/
    failure_test.dart       # pruebas de la jerarquía de Failure
    http_client_test.dart   # pruebas del ApiClient con MockClient
```
