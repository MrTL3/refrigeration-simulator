# FRIGOLAB — INFORME DE REDISEÑO INTEGRAL DEL SIMULADOR
## INSTALACIÓN FRIGORÍFICA INTERACTIVA · VISTA VERTICAL + HORIZONTAL PANORÁMICA · CONTROL EN TIEMPO REAL

---

## 1. RESUMEN EJECUTIVO Y OBJETIVOS ALCANZADOS

En cumplimiento estricto del plan de evolución del simulador frigorífico industrial **FrigoLab**, se ha culminado el rediseño integral de la experiencia visual e interactiva del simulador. 

El objetivo primordial ha sido transformar la aplicación en una herramienta donde el usuario experimente la sensación de estar físicamente frente a una instalación frigorífica real, eliminando la impresión de una maqueta estática o una animación decorativa desacoplada.

### Principios Fundamentales Cumplidos:
1. **EL SOLVER FÍSICO ES LA ÚNICA FUENTE DE VERDAD:**
   - La física existente ha permanecido **100% CONGELADA**: no se han modificado ecuaciones diferenciales, balances de materia o energía, modelo termodinámico de R-134a, constantes termodinámicas ni el paso temporal $dt = 0.05\text{ s}$.
   - Toda animación (rotación de compresor, giro de ventiladores, flujo bifásico, agujas de manómetros, burbujas en el visor de líquido) está conectada de manera unívoca a las variables reales del estado termodinámico `SimulationState`.
2. **DISTINCIÓN RIGUROSA ENTRE CONTROL Y MEDICIÓN:**
   - Se ha clasificado taxativamente en toda la interfaz lo que constituye una consigna o perturbación introducida por el operador (`CONTROL (Actuador)`) frente a lo que resulta del balance termodinámico calculado (`MEDICIÓN (Calculado por el solver)`).
3. **DOBLE EXPERIENCIA OPERATIVA (VERTICAL Y HORIZONTAL):**
   - **Vista Vertical Móvil:** Diseñada para supervisar la instalación y operar los mandos con comodidad a una mano en smartphones (Pixel 7 y similares).
   - **Vista Horizontal Panorámica / Pantalla Completa:** Modo inmersivo en el que la planta completa es la protagonista indiscutible, con bloqueo apaisado (`SystemChrome.setPreferredOrientations`), encuadre automático que erradica la necesidad de hacer paneo forzado para ver componentes, barra SCADA superior translúcida y HUD de telemetría inferior.
4. **PANEL DESPLEGABLE DE PARÁMETROS:**
   - Disponible en vertical como hoja modal (`bottom sheet`) y en horizontal como barra lateral flotante (`slide-over drawer` de 340 px) que **NO eclipsa la máquina**, permitiendo manipular variables en vivo mientras se observa la respuesta dinámica del ciclo.
5. **INSTRUMENTACIÓN FÍSICA IN SITU:**
   - Manómetros Bourdon con escalas marcadas, aguja móvil calculada analíticamente y temperatura de saturación $T_{sat}$ inscrita en la esfera.
   - Píldoras de medición térmica en tuberías ($T_{dis}$, $T_{liq}$, $T_{o}$, $T_{asp}$, $T_{c\acute{a}m}$, $T_{amb}$).
   - Indicadores directos de Recalentamiento ($SH$) y Subenfriamiento ($SC$).
6. **MÁXIMA CALIDAD DE CÓDIGO Y COMPATIBILIDAD:**
   - **61/61 tests superados** exitosamente en `flutter test`.
   - **0 advertencias ni errores** en `flutter analyze`.
   - **0 desbordamientos `RenderFlex overflowed`** en pantallas móviles y panorámicas.

---

## 2. ARQUITECTURA DE PANTALLAS Y EXPERIENCIA DE USUARIO

```
                        ┌──────────────────────────────────────────────┐
                        │              SIMULATOR SCREEN                │
                        │           (Modo Vertical Estándar)           │
                        └──────────────────────┬───────────────────────┘
                                               │
             ┌─────────────────────────────────┴─────────────────────────────────┐
             ▼                                                                   ▼
┌─────────────────────────┐                                         ┌─────────────────────────┐
│     PUESTO DE MANDO     │                                         │      BOTÓN INMERSIVO    │
│  (Mandos Rápidos Strip) │                                         │ [⛶ PANTALLA COMPLETA]   │
└────────────┬────────────┘                                         └────────────┬────────────┘
             │ [⚙ PARÁMETROS]                                                    │
             ▼                                                                   ▼
┌─────────────────────────┐                                         ┌─────────────────────────┐
│  SIMULATION PARAMETERS  │                                         │   FULLSCREEN SIMULATOR  │
│          PANEL          │                                         │          SCREEN         │
│  (Modal Bottom Sheet)   │                                         │  (Landscape Inmersivo)  │
└─────────────────────────┘                                         └────────────┬────────────┘
                                                                                 │ [⚙ PARÁMETROS]
                                                                                 ▼
                                                                    ┌─────────────────────────┐
                                                                    │   SLIDE-OVER DRAWER     │
                                                                    │    (Barra Lateral 340px │
                                                                    │   + Máquina Visible)    │
                                                                    └─────────────────────────┘
```

### 2.1 Vista Vertical (Modo Estándar de Supervisión)
- **Barra de Estado del Sistema:**
  - Led de funcionamiento (Verde en marcha, Rojo detenido).
  - Refrigerante cargado (`R-134a`).
  - Validación topológica del lazo (`Circuito Cerrado Válido`).
  - Accesos rápidos integrados `[ ⚙ PARÁMETROS ]` y `[ ⛶ PANTALLA COMPLETA ]`.
- **Selector de Modo de Visualización:**
  - `Instalación` (representación realista de taller).
  - `P&ID Técnico` (diagrama de flujo de instrumentación).
  - `Instrumentos` (mesa de pruebas SCADA).
  - `Diagrama P-h` (presión-entalpía con campana de vapor).
  - `Diagrama T-s` (temperatura-entropía).
- **Lienzo Central Interactivo (480 px):**
  - Muestra la planta con encuadre óptimo.
  - Filtros visuales SCADA: Flujo, Calor, Presión, Temperatura, Motor e Instrumentos.
  - Botón de inyección de avería directa: `PARAR VENT. COND.`.
- **Nuevo Puesto de Mando Rápido (`_buildMachineQuickControlStrip`):**
  - Situado estratégicamente inmediatamente bajo el lienzo de la máquina para interacción sin fricción.
  - Botones de ejecución: Marcha, Pausa, Paso discreto $dt=0.05\text{ s}$, Reinicio.
  - Ajuste rápido de velocidad de compresión (RPM $\pm 200$).
  - Selector de modo TXV (Manual vs Auto).
  - Conmutador directo de ventilador de condensador.
  - Botones destacados de apertura de parámetros y pantalla completa.
- **Control Termostático y Gráfica Transitoria:**
  - Termostato con consigna y diferencial.
  - Curvas temporales vivas de presiones y temperaturas.

### 2.2 Vista Horizontal Panorámica (`FullscreenSimulatorScreen`)
- **Bloqueo Inmersivo:**
  - Invoca `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])` y `SystemUiMode.immersiveSticky`.
  - Al cerrar, restaura de inmediato las orientaciones estándar del sistema sin efectos secundarios.
- **Encuadre Automático de la Planta:**
  - El lienzo de `InstallationPlantView` monitoriza las restricciones espaciales (`constraints.biggest`). Al pasar a apaisado ($W \approx 900\text{ px}, H \approx 412\text{ px}$), la matriz de transformación calcula la escala óptima `fitScale = min(w / 1000, h / 600)` y centra el circuito.
  - Todos los componentes (evaporador a la izquierda, cámara frigorífica, línea de aspiración, compresor en bancada, línea de descarga, condensador a la derecha, recipiente de líquido y válvula de expansión) quedan perfectamente visibles y encuadrados sin cortes laterales ni necesidad de scroll forzado.
- **Barra SCADA Superior Translúcida:**
  - Botón de escape rápido `[ ✕ SALIR ]`.
  - Indicador interactivo de estado de máquina (`[ EN MARCHA / DETENIDO ]`).
  - Conmutador instantáneo entre las 5 perspectivas (`Instalación`, `P&ID`, `Instrumentos`, `P-h`, `T-s`).
  - Botón de despliegue del panel de parámetros `[ ⚙ PARÁMETROS ]`.
- **HUD Inferior de Telemetría Dinámica:**
  - Muestra en una sola línea translúcida de lectura rápida los parámetros críticos calculados:
    $$P_o\text{ (bar)} \quad\vert\quad P_k\text{ (bar)} \quad\vert\quad T_{c\acute{a}m}\text{ (\textdegree C)} \quad\vert\quad SH\text{ (K)} \quad\vert\quad SC\text{ (K)} \quad\vert\quad \dot{Q}_e\text{ (kW)} \quad\vert\quad W_{comp}\text{ (kW)} \quad\vert\quad COP \quad\vert\quad \dot{m}\text{ (g/s)} \quad\vert\quad RPM$$
- **Panel Lateral Desplegable (Slide-over Drawer):**
  - Al pulsar `[ ⚙ PARÁMETROS ]`, se despliega un panel lateral de $340\text{ px}$ desde el borde derecho.
  - **La instalación sigue siendo visible en más del 65% de la pantalla.** El usuario puede variar los potenciómetros del compresor o la TXV y ver simultáneamente cómo cambia el giro del motor, la aguja del manómetro y la tasa de evaporación en tiempo real.

---

## 3. DISEÑO DEL PANEL DE PARÁMETROS (`SimulationParametersPanel`)

El nuevo componente [`SimulationParametersPanel`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/presentation/widgets/simulation_parameters_panel.dart) está estructurado en dos pestañas principales:

### Pestaña 1: ACTUADORES (CONTROL)
Dedicada exclusivamente a magnitudes que el técnico o frigorista puede manipular físicamente:
1. **Compresor Hermético:**
   - Deslizador de velocidad de giro: $500\text{ RPM}$ a $4500\text{ RPM}$ (con indicación de valor nominal $2900\text{ RPM}$ e industrial $1450\text{ RPM}$).
   - Lecturas asociadas calculadas por el modelo eléctrico: Frecuencia de red equivalente ($\text{Hz}$), Potencia eléctrica activa ($W$) y Corriente de consumo absorbida ($A$).
2. **Válvula de Expansión Termostática (TXV):**
   - Conmutador selector de modo: `AUTOMÁTICA` (modulación termostática de aguja para mantener $SH = 7\text{ K}$) vs `MANUAL` (fijación manual de apertura).
   - Deslizador de apertura de orificio de paso: $5\%$ a $100\%$.
   - Lecturas asociadas: Recalentamiento resultante ($SH$), Presión de bulbo ($P_{bulbo}$) y Caudal másico instantáneo ($\dot{m}$).
3. **Cámara Frigorífica y Termostato:**
   - Interruptor de habilitación del lazo de regulación termostático.
   - Deslizador de consigna de corte: $-25\text{ \textdegree C}$ a $+15\text{ \textdegree C}$.
   - Deslizador de carga térmica interna de género/apertura de puerta: $0\text{ W}$ a $5000\text{ W}$.
   - Lecturas asociadas: Temperatura de cámara ($T_{c\acute{a}m}$), Capacidad frigorífica útil ($\dot{Q}_e$) y $COP$.
4. **Condensador y Entorno Exterior:**
   - Interruptor de funcionamiento del ventilador del condensador (permite simular fallo de motor de ventilador o suciedad severa en batería).
   - Deslizador de temperatura ambiente del aire exterior: $+10\text{ \textdegree C}$ a $+45\text{ \textdegree C}$ (simulación de condiciones estacionales invierno/verano).
   - Lecturas asociadas: Presión de condensación ($P_k$), Temperatura de condensación ($T_k$) y Subenfriamiento ($SC$).
5. **Acciones de Simulación y Restauración:**
   - Botón `[ ARRANCAR / PAUSAR ]`.
   - Botón `[ PASO dt (0.05 s) ]` para análisis paso a paso en régimen transitorio.
   - Botón `[ REINICIAR ]` para restablecer el ciclo frigorífico al punto de trabajo estándar.

### Pestaña 2: MEDICIONES EN VIVO
Reúne en una cuadrícula SCADA de 14 tarjetas todos los sensores virtuales calculados por el solver físico:
- $P_{baja} (P_o)$ en bar.
- $P_{alta} (P_k)$ en bar.
- $T_{evap} (T_o)$ en \textdegree C (temperatura de saturación en evaporador).
- $T_{cond} (T_k)$ en \textdegree C (temperatura de saturación en condensador).
- $T_{descarga}$ en \textdegree C (salida de culata del compresor).
- $T_{l\acute{i}quido}$ en \textdegree C (salida del condensador hacia filtro).
- $T_{aspiraci\acute{o}n}$ en \textdegree C (entrada al compresor).
- $Recalentamiento\ (SH)$ en K (con alarma visual en rojo si $SH < 4\text{ K}$, riesgo de golpe de líquido).
- $Subenfriamiento\ (SC)$ en K (garantía de líquido 100% en entrada a TXV).
- $T_{c\acute{a}mara}$ en \textdegree C.
- $Caudal\ m\acute{a}sico\ (\dot{m})$ en g/s.
- $Potencia\ Fr\acute{i}o\ (\dot{Q}_e)$ en kW.
- $Calor\ Disipado\ (\dot{Q}_c)$ en kW.
- $Consumo\ (W_{comp})$ en kW.
- $Eficiencia\ (COP)$ adimensional.

---

## 4. INSTRUMENTACIÓN FÍSICA IN SITU EN EL LIENZO

En [`InstallationPlantView`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/visualization/installation_plant_view.dart), se ha dotado a la planta de instrumentación física tangible en los puntos exactos de la instalación:

1. **Manómetros de Esfera Bourdon Integrados:**
   - **Manómetro de Baja Presión ($P_o$):** Situado sobre la línea de aspiración del compresor. Esfera azul SCADA con escala de $0$ a $10\text{ bar}$, marcas de división graduadas, aguja indicadora roja que gira proporcionalmente a la presión calculada por el solver ($p / p_{max} \cdot 270^\circ$) e inscripción del valor de presión y su temperatura de saturación correspondiente:
     $$\text{Ejemplo: } P_o: 2.01\text{ bar} \quad (T_{sat}: -10.0\text{ \textdegree C})$$
   - **Manómetro de Alta Presión ($P_k$):** Situado sobre la línea de descarga del compresor. Esfera roja SCADA con escala de $0$ a $30\text{ bar}$, aguja móvil calculada e inscripción de presión y temperatura de condensación:
     $$\text{Ejemplo: } P_k: 11.60\text{ bar} \quad (T_{sat}: 45.0\text{ \textdegree C})$$
2. **Píldoras de Medición Térmica de Contacto:**
   - Situadas sobre las tuberías correspondientes:
     - Sonda de descarga culata: $T_{dis}$.
     - Sonda de línea de líquido: $T_{liq}$.
     - Sonda de aspiración compresor: $T_{asp}$.
     - Sonda de bulbo evaporador: $T_o$.
     - Termómetro ambiental de cámara: $T_{c\acute{a}m}$.
     - Termómetro ambiente sala de máquinas: $T_{amb}$.
3. **Indicadores de Diagnóstico Termodinámico In Situ:**
   - Píldora de $SH$ (Superheat) junto al bulbo de la TXV. Se ilumina en verde cuando está en rango óptimo ($5 - 10\text{ K}$) y en rojo intermitente cuando $SH < 4\text{ K}$ (alerta al alumno de posible llegada de gotas de refrigerante líquido al pistón).
   - Píldora de $SC$ (Subcooling) en la salida del condensador. Confirma si el refrigerante ha condensado totalmente.

---

## 5. VERIFICACIÓN Y CONTROL DE CALIDAD

### 5.1 Suite Completa de Tests Automatizados
Se han ejecutado los 61 tests unitarios, de integración, termodinámicos y de widgets que componen la batería de pruebas de FrigoLab:
```
00:00 +0: Ciclos termodinámicos y R-134a
00:01 +20: Consistencia física y SCADA
00:01 +40: Balances de materia y energía (Primer Principio)
00:01 +56: Gestión de estado, Snapshots, Determinismo y Undo/Redo
00:02 +57: UI smoke test
00:02 +58: InstallationPlantView y selector de modos sin overflow
00:02 +59: SimulationParametersPanel renderiza actuadores y mediciones
00:02 +60: FullscreenSimulatorScreen inicializa HUD y barra SCADA
00:03 +61: All tests passed!
```
**Resultado:** **61/61 tests superados exitosamente (100% pass rate).**

### 5.2 Análisis Estático de Código (`flutter analyze`)
```
Analyzing frigolab...
No issues found! (ran in 2.0s)
```
**Resultado:** **0 errores, 0 advertencias, 0 lints.**

### 5.3 Verificación de Ausencia de Overflows (`RenderFlex`)
- Todas las estructuras de tarjetas y encabezados emplean `Wrap`, `Flexible`, `Expanded` o `SingleChildScrollView` donde los anchos varían.
- El panel de parámetros utiliza `Expanded(child: SingleChildScrollView(...))` con altura controlada tanto en modo modal como en barra lateral, garantizando que nunca se produzcan desbordamientos en resoluciones reducidas o pantallas panorámicas estrechas.

---

## 6. CONCLUSIÓN Y ESTADO DEL SIMULADOR

Con este rediseño, **FrigoLab** da el salto definitivo a un simulador frigorífico industrial inmersivo y riguroso. El alumno o técnico frigorista puede ahora:
- Observar el ciclo frigorífico completo en vista apaisada o vertical.
- Manipular actuadores reales (RPM, orificio TXV, carga térmica, temperatura ambiente exterior) mientras observa la instalación en movimiento.
- Leer manómetros con aguja y temperaturas de saturación reales.
- Diagnosticar el comportamiento del sistema mediante telemetría instantánea y diagramas técnicos coordinados.
- Todo ello sustentado sobre la verdad irremplazable del solver físico integrado.
