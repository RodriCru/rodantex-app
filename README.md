# rodantex_app

Aplicación Flutter para iOS y Android.

## 📋 Requisitos previos

Antes de levantar el proyecto, asegúrate de tener instalado:

- **Flutter SDK** (canal stable). Instrucciones: https://docs.flutter.dev/get-started/install/macos
- **Xcode** (solo para iOS/macOS) desde la Mac App Store, con las Command Line Tools configuradas:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  ```
- **CocoaPods** (para iOS):
  ```bash
  brew install cocoapods
  ```
- **Android SDK + Command-line Tools** (para Android). Puedes instalarlo con [Android Studio](https://developer.android.com/studio) o solo las command-line tools.
- **Java 17 (JDK)** para compilar Android:
  ```bash
  brew install openjdk@17
  ```

Verifica que todo esté en orden con:

```bash
flutter doctor -v
```

> ⚠️ El aviso `[!] Xcode - Unable to get list of installed Simulator runtimes` es normal si no descargaste el simulador de iOS. **No impide compilar ni ejecutar en un iPhone físico.**

## 🚀 Levantar el proyecto

```bash
# 1. Clona el repositorio
git clone <url-del-repo>
cd rodantex_app

# 2. Instala dependencias
flutter pub get

# 3. Verifica los dispositivos conectados
flutter devices
```

### Ejecutar en un dispositivo específico

```bash
flutter run -d <id-del-dispositivo>
```

Si solo tienes un dispositivo conectado, basta con:

```bash
flutter run
```

### Hot reload

Con la app corriendo, en la terminal donde ejecutaste `flutter run`:

| Tecla | Acción |
|-------|--------|
| `r` | Hot reload (recarga los cambios sin reiniciar) |
| `R` | Hot restart (reinicia la app) |
| `q` | Salir |

## 📱 Conectar un dispositivo Android físico

1. En el teléfono, activa las **Opciones de desarrollador**:
   - Ve a **Ajustes → Acerca del teléfono** y toca 7 veces **Número de compilación**.
2. Activa la **Depuración USB** en **Ajustes → Sistema → Opciones de desarrollador**.
3. Conecta el teléfono a la Mac por USB.
4. Desbloquea el teléfono y acepta el diálogo **"¿Permitir depuración USB?"**.
5. Verifica que Flutter lo detecte:
   ```bash
   flutter devices
   ```
6. Ejecuta:
   ```bash
   flutter run -d <id-del-android>
   ```

> Si el dispositivo no aparece, prueba con otro cable USB (algunos solo cargan) o ejecuta `adb devices` para verificar la conexión.

## 🍎 Conectar un iPhone físico

1. Conecta el iPhone a la Mac por USB.
2. Desbloquéalo y toca **"Confiar"** cuando aparezca "¿Confiar en este ordenador?".
3. Activa el **Modo Desarrollador**:
   - Ve a **Ajustes → Privacidad y Seguridad → Modo Desarrollador**.
   - Actívalo y reinicia el iPhone cuando te lo pida.
   - Si no ves la opción, ejecuta `flutter run` una vez con el iPhone conectado; el modo aparecerá después.
4. Verifica que Flutter lo detecte:
   ```bash
   flutter devices
   ```
5. **Configura la firma de código** (solo la primera vez):
   ```bash
   open ios/Runner.xcworkspace
   ```
   - En Xcode, selecciona el target **Runner** → pestaña **Signing & Capabilities**.
   - En **Team**, elige tu Apple ID. Si no aparece, añádela en **Xcode → Settings → Accounts**.
   - Xcode generará el provisioning profile automáticamente.
   - Guarda (`Cmd+S`) y cierra Xcode.
6. Ejecuta:
   ```bash
   flutter run -d <id-del-iphone>
   ```

> Con una cuenta de Apple ID gratuita, la app instalada en el iPhone caduca a los 7 días y hay un límite de 3 apps simultáneas. Para desarrollo personal es suficiente.

## 🧭 Comandos útiles

| Comando | Descripción |
|---------|-------------|
| `flutter pub get` | Instala las dependencias del `pubspec.yaml` |
| `flutter run -d <id>` | Ejecuta la app en un dispositivo específico |
| `flutter devices` | Lista los dispositivos conectados |
| `flutter doctor -v` | Diagnóstico detallado del entorno |
| `flutter clean` | Limpia los archivos de build (útil cuando algo se rompe) |
| `flutter build apk` | Genera un APK de Android |
| `flutter build ios` | Genera un build de iOS (requiere firma) |

## 📂 Estructura del proyecto

```
rodantex_app/
├── lib/
│   └── main.dart          # Punto de entrada de la app
├── ios/                   # Proyecto nativo iOS (Xcode)
├── android/               # Proyecto nativo Android (Gradle)
├── pubspec.yaml           # Dependencias y configuración
└── README.md
```

## 📚 Recursos

- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [Primer app en Flutter (codelab)](https://docs.flutter.dev/get-started/codelab)
- [Recursos de aprendizaje](https://docs.flutter.dev/reference/learning-resources)
```