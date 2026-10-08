# FrigoLab — Simulador Físico de Refrigeración Industrial

[![Deploy FrigoLab Web to GitHub Pages](https://github.com/MrTL3/refrigeration-simulator/actions/workflows/deploy.yml/badge.svg)](https://github.com/MrTL3/refrigeration-simulator/actions/workflows/deploy.yml)
[![Flutter 3.x](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Plataforma-Android%20%7C%20Web-00C49F)](#)
[![Tests](https://img.shields.io/badge/Tests-75%2F75%20Passing-brightgreen)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**FrigoLab** es una plataforma avanzada e interactiva de simulación física y pedagógica de instalaciones frigoríficas por compresión de vapor (R-134a), diseñada para ejecutarse de manera fluida y simultánea en dispositivos móviles **Android** y entornos de escritorio **Web (HTML5 / CanvasKit)**.

El solver termodinámico en tiempo real es la **única fuente de verdad** del sistema: todas las lecturas de los instrumentos, el comportamiento de los actuadores, los diagramas de ciclo termodinámico (P-h y T-s) y las animaciones de flujo derivan directamente de ecuaciones diferenciales ordinarias resueltas cada $dt = 0.05\text{ s}$.

---

## 🚀 Despliegue en GitHub Pages

La versión Web de FrigoLab se compila y publica de forma automatizada mediante **GitHub Actions** en cada `push` a las ramas `main` o `master`:

- **URL de Producción Web:** [https://MrTL3.github.io/refrigeration-simulator/](https://MrTL3.github.io/refrigeration-simulator/)
- **Repositorio Oficial:** [https://github.com/MrTL3/refrigeration-simulator](https://github.com/MrTL3/refrigeration-simulator)

---

## 🌟 Características Principales

### 1. Física Termodinámica Determinista
- **Refrigerante:** R-134a con propiedades termodinámicas completas (ecuaciones de saturación Antoine/Lee-Kesler, cálculo de calidad de vapor $x$, entalpías $h$ y entropías $s$).
- **Solver Dinámico:** Integración temporal continua con paso temporal fijo $dt = 0.05\text{ s}$ respetando el Primer Principio ($\dot{Q}_c \approx \dot{Q}_e + \dot{W}_{comp}$).
- **Dinámica de Componentes:**
  - Compresor alternativo con mapa de rendimiento volumétrico e isentrópico función de la relación de compresión.
  - Condensador con balance térmico frente a temperatura exterior y cálculo de subenfriamiento ($SC$).
  - Válvula de expansión termostática (TXV) con regulación automática por recalentamiento ($SH$) o control manual de apertura (5% - 100%).
  - Evaporador con carga térmica y balance dinámico en cámara frigorífica.
  - Calderín de líquido y filtro deshidratador.

### 2. Experiencia de Escritorio Web (Desktop Web Experience)
- **Zoom Suave con Rueda de Ratón:** Anclado con precisión matemática al punto focal bajo el cursor (`PointerScrollEvent` con transformación de matriz inversa).
- **Desplazamiento / Panning:** Arrastre continuo del lienzo haciendo clic y sosteniendo en cualquier zona vacía.
- **Drag & Drop de Componentes:** Posicionamiento libre de compresor, condensador, TXV, evaporador y calderín en coordenadas de mundo virtual ($1380 \times 780$).
- **Enrutamiento Dinámico de Tuberías:** Las líneas de refrigerante de alta presión, líquido, inyección y aspiración recalculan sus trayectorias Bézier y ortogonales en tiempo real según la posición de los componentes.
- **Sincronización de Instrumentación:** Los manómetros, termómetros y visores acompañan automáticamente los desplazamientos de sus respectivos equipos.
- **Botonera de Presets de Escala:** Botones de acceso directo para `50%`, `100%`, `200%`, `400%`, `Centrar vista` y `Restablecer posiciones`.
- **Cursores Contextuales Dinámicos:** Transición fluida de punteros (`grab`, `grabbing`, `move`, `click`).

### 3. Panel Lateral de Inspección y Telemetría Desktop ($\ge 1024\text{ px}$)
- Disposición en pantalla dividida en pantallas de escritorio sin obstruir ni tapar la planta frigorífica.
- Telemetría analítica en tiempo real de manómetros Bourdon, termómetros bimetálicos, visores y presostatos.
- Inspección profunda de componentes con estados termodinámicos de entrada y salida ($P$, $T$, fase fluida).
- Actuadores interactivos en tiempo real (control de RPM de compresor y apertura de TXV).
- Módulo didáctico causal "¿Por qué ocurre esto?" integrado con explicaciones físicas contextuales.

### 4. Soporte Nativo Android
- Interfaz táctil ergonómica con soporte de orientación vertical y horizontal panorámica.
- Paneles modales inferiores contextuales.
- Gestión de orientación e inmersión sticky protegida por la capa de abstracción `PlatformService`.

---

## 🏗️ Arquitectura del Software

```
frigolab/
├── .github/workflows/
│   └── deploy.yml                       # CI/CD automatizado para GitHub Pages
├── web/
│   ├── index.html                       # HTML5 con preloader SCADA y metaetiquetas
│   ├── manifest.json                    # Manifiesto PWA para navegador
│   └── favicon.png                      # Favicon FrigoLab
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── platform_service.dart    # Aislamiento multiplataforma (Web vs Android)
│   │   └── units/                       # Unidades de presión y temperatura
│   ├── domain/
│   │   ├── components/                  # Modelos de componentes frigoríficos
│   │   └── models/                      # Topología de circuitos y estado
│   ├── education/                       # Motor pedagógico y explicador causal
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── simulator_screen.dart    # Pantalla principal con LayoutBuilder responsivo
│   │   │   └── fullscreen_simulator.dart# Vista horizontal inmersiva
│   │   └── widgets/
│   │       └── desktop_inspector_panel.dart # Panel lateral para Desktop Web
│   ├── simulation/
│   │   ├── engine/                      # DynamicSolver y SimulationEngine (Física Congelada)
│   │   └── thermodynamics/              # Modelo termodinámico de R-134a
│   └── visualization/
│       ├── installation_plant_view.dart # Planta interactiva (Zoom, Pan, Drag&Drop)
│       ├── models/
│       │   └── installation_instrument.dart # Puntos de instrumentación física
│       └── painters/                    # Renderizadores de tuberías, componentes y flujo
└── test/                                # 75 tests unitarios, de widgets e integración
```

---

## 🛠️ Guía de Ejecución y Desarrollo

### Requisitos Previos
- **Flutter SDK:** $\ge 3.22.0$ (Canal `stable`)
- **Dart SDK:** $\ge 3.4.0$
- **Google Chrome / Edge** (para desarrollo Web)
- **Android SDK & NDK** (para compilación Android)

### Instalación de Dependencias
```bash
flutter pub get
```

### Análisis Estático de Código
```bash
flutter analyze
```

### Ejecución de Pruebas Unitarias y de Widgets
```bash
flutter test
```
*Total: 75/75 tests passing (determinismo, invarianza física, Undo/Redo, P-h, T-s, interacción web y responsividad).*

---

### Ejecución en Desarrollo

#### 🌐 Versión Web
```bash
flutter run -d chrome
```

#### 📱 Versión Android
```bash
flutter run -d <device_id>
```

---

### Compilación para Producción

#### 📦 Compilar para GitHub Pages (Web)
```bash
flutter build web --release --base-href /refrigeration-simulator/
```
*Los artefactos optimizados se generan en el directorio `build/web/`.*

#### 📱 Compilar APK de Android
```bash
# APK Release
flutter build apk --release

# APK Debug para pruebas
flutter build apk --debug
```
*El binario generado se ubicará en `build/app/outputs/flutter-apk/`.*

---

## ⚙️ Configuración del Flujo CI/CD en GitHub

Para que la publicación en GitHub Pages funcione en el repositorio [MrTL3/refrigeration-simulator](https://github.com/MrTL3/refrigeration-simulator):

1. En GitHub, navega a **Settings > Pages**.
2. En la sección **Build and deployment > Source**, selecciona **GitHub Actions**.
3. Realiza un `git push origin master` o `main`.
4. El workflow `.github/workflows/deploy.yml` ejecutará automáticamente el análisis estático, la suite completa de 75 tests, compilará la versión web con `--base-href /refrigeration-simulator/` y desplegará la web en GitHub Pages.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más información.
