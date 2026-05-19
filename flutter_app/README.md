# Flutter app

## Estado
Compila y consume el backend real. Ahora muestra ejercicios, detalle y sesiones guardadas.

## Ejecutar en esta Raspberry

```bash
cd flutter_app
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter pub get
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Para Android Emulator:

```bash
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Flujo mínimo ya implementado

1. Abrir un ejercicio.
2. Pulsar `Guardar sesión real`.
3. Volver a la home.
4. Ver la sesión en `Sesiones guardadas`.
