# PHYSICS VISUAL AUDIT — FRIGOLAB
## Auditoría Técnica Exhaustiva de Separación: Física Real · Aproximación Física · Visualización

---

## 1. Resumen ejecutivo

Esta auditoría técnica ha sido realizada sobre el código fuente real existente en el repositorio de **FrigoLab** (Rama `master`, commit `8c5a48b`). El objetivo fundamental es desglosar de forma imparcial, verificable y sin ambigüedades qué partes del sistema responden a leyes físicas integradas numéricamente, cuáles se basan en aproximaciones o correlaciones simplificadas y cuáles son exclusivamente representaciones gráficas desacopladas.

### Hallazgos Principales:
1. **El principio de única fuente de verdad se cumple en la arquitectura general:** Los componentes visuales y widgets de instrumentación leen el objeto inmutable `SimulationState`, el cual es producido por `DynamicSolver.integrateStep` a un paso temporal de $dt = 0.05\ \text{s}$ ($20\ \text{Hz}$). No existen llamadas a `Random()` ni generadores estocásticos en todo el código base de simulación ni visualización.
2. **Existencia de aproximaciones lumped y parámetros fijos:** La dinámica térmica se modela mediante capacitancias concentradas constantes ($\mathcal{C}_{evap} = 450\ \text{J/K}$, $\mathcal{C}_{cond} = 700\ \text{J/K}$, $\mathcal{C}_{room} = 85.000\ \text{J/K}$). Las pérdidas de carga en tuberías utilizan un factor de fricción fijo ($f = 0.024$) sin evaluar el número de Reynolds ni regímenes de flujo.
3. **Desacoplamiento temporal efectivo:** La interfaz gráfica desacopla el refresco visual (Flutter `Ticker` a 60 FPS) del solver físico (20 Hz), interpolando el ángulo del cigüeñal y el avance de partículas sin mutar el estado físico de la planta.
4. **Discrepancias localizadas entre documentación anterior y código:**
   - La constante de tiempo del bulbo de la TXV ($\tau_{bulb}$) es de **$3.5\ \text{s}$** en el código (`dynamic_solver.dart:25`), a pesar de que el informe anterior afirmaba **$8.0\ \text{s}$**.
   - La velocidad del refrigerante en la línea de líquido calculada por el solver es de **$\sim 0.13\text{--}0.25\ \text{m/s}$**, mientras que el informe anterior citaba **$0.8\ \text{m/s}$**.
   - En el manómetro Bourdon (`bourdon_gauge_widget.dart:173`), se recalcula la temperatura de saturación $T_{sat}(P)$ invocando directamente a `R134aModel` en el método `paint()` de la UI en lugar de consumirla desde el estado.

---

## 2. Arquitectura actual

El flujo de información en FrigoLab sigue un esquema estrictamente unidireccional:

```text
[Interacción Usuario / Actuadores]
           │
           ▼
 [SimulationEngine] ──(20 Hz, dt = 0.05 s)──► [DynamicSolver]
                                                    │
                                          ┌─────────┴─────────┐
                                          ▼                   ▼
                                    [R134aModel]      [Modelos Físicos]
                                     (Antoine)        (Motor, Aire, Vacío, Tubos)
                                          │                   │
                                          └─────────┬─────────┘
                                                    ▼
                                            [SimulationState]
                                        (Estado Único Inmutable)
                                                    │
        ┌───────────────────────────────────────────┼───────────────────────────────────────────┐
        ▼                                           ▼                                           ▼
[RealisticPlantCanvas]                    [InstrumentWorkbench]                         [DynamicExplainer]
  (Ticker a 60 FPS)                          (Lectura directa)                          (Profesor Virtual)
        │                                           │                                           │
  - Componentes 2.5D                        - Manómetros Bourdon                        - Detección de
  - Partículas (v = ṁ/(ρ·A))                 - Pinza True RMS                            transitorios
  - Capas SCADA                             - Termómetro Clamp                          - Explicación causal
                                            - Vacuómetro Pirani
```

---

## 3. Física realmente calculada

Componentes y fenómenos gobernados por ecuaciones físicas deterministas sin atajos de animación:

1. **Ecuación de continuidad de fluidos en tuberías:**
   - **Archivo:** `lib/domain/models/pipe_segment_state.dart`, método `PipeSegmentState.calculate` (Línea 40).
   - **Ecuación:** $v = \frac{\dot{m}}{\rho \cdot A}$, donde $A = \frac{\pi D^2}{4}$.
   - **Comprobación:** La velocidad física calculada es estrictamente dependiente del caudal másico dinámico $\dot{m}$ y de la densidad termodinámica $\rho$ obtenida de la ecuación de estado.
2. **Conservación de la energía y Primer Principio:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 150-153).
   - **Ecuaciones:** 
     $$\dot{Q}_e = \dot{m}(h_1 - h_4)$$
     $$\dot{Q}_c = \dot{m}(h_2 - h_3)$$
     $$\dot{W}_{ind} = \dot{m}(h_2 - h_1)$$
     $$\text{COP} = \frac{\dot{Q}_e}{\dot{W}_{ind}}$$
3. **Compresión politrópica de gas real:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 102-115).
   - **Ecuaciones:**
     $$r_p = \frac{P_{cond}}{P_{evap}}$$
     $$w_{is} = \left(\frac{k}{k-1}\right) \frac{P_1}{\rho_1} \left(r_p^{\frac{k-1}{k}} - 1\right)$$
     $$h_2 = h_1 + \frac{w_{is}}{\eta_{is}}$$
     con $k = 1.13$.
4. **Relación de re-expansión en volumen nocivo (Rendimiento volumétrico):**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 100-104).
   - **Ecuación:** $\eta_v = \left[1 - c \left(r_p^{1/k} - 1\right)\right] \times 0.82$, con $c = 0.045$.
5. **Ecuaciones Diferenciales Ordinarias (EDOs) térmicas de las baterías:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 167-172).
   - **Ecuaciones:**
     $$\frac{dT_{evap}}{dt} = \frac{\dot{Q}_{evap,air} - \dot{Q}_{ref,evap}}{\mathcal{C}_{evap}}$$
     $$\frac{dT_{cond}}{dt} = \frac{\dot{Q}_{ref,cond} - \dot{Q}_{cond,air}}{\mathcal{C}_{cond}}$$
6. **Balance térmico transitorio de la cámara frigorífica:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 176-178) y `lib/domain/models/cold_room_model.dart` (Líneas 40-48).
   - **Ecuaciones:**
     $$\dot{Q}_{trans} = U \cdot A \cdot (T_{amb} - T_{room})$$
     $$\dot{Q}_{load} = \dot{Q}_{trans} + \dot{Q}_{int} + \dot{Q}_{inf}$$
     $$\frac{dT_{room}}{dt} = \frac{\dot{Q}_{load} - \dot{Q}_{evap,air}}{\mathcal{C}_{room}}$$
7. **Dinámica del orificio de estrangulación de la TXV:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 126-127).
   - **Ecuación:** $\dot{m}_{txv} = C_v \cdot \left(\frac{\%_{apertura}}{100}\right) \cdot \sqrt{2 \cdot \rho_3 \cdot \Delta P_{valvula}}$.
8. **Dinámica del bulbo sensor:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Línea 131).
   - **Ecuación:** $\frac{dT_{bulb}}{dt} = \frac{T_1 - T_{bulb}}{\tau_{bulb}}$, con $\tau_{bulb} = 3.5\ \text{s}$.

---

## 4. Aproximaciones físicas

Modelos que responden a fundamentos físicos reales pero recurren a simplificaciones o coeficientes constantes:

1. **Formulación termodinámica de Antoine para R-134a:**
   - **Archivo:** `lib/simulation/thermodynamics/r134a_model.dart` (Líneas 24-55).
   - **Aproximación:** Se utiliza $\ln(P) = A - \frac{B}{T + C}$ con constantes calibradas ($A=14.365, B=2081.4, C=-33.5$).
   - **Limitación:** Es una aproximación semi-empírica válida entre $-40\ ^\circ\text{C}$ y $+70\ ^\circ\text{C}$. No implementa la ecuación fundamental explícita en energía libre de Helmholtz (NIST/REFPROP).
2. **Capacidades térmicas lumped de las baterías:**
   - **Archivo:** `lib/simulation/solver/dynamic_solver.dart` (Líneas 23-24).
   - **Aproximación:** Las baterías se consideran como masas térmicas puntuales con capacitancias constantes ($\mathcal{C}_{evap} = 450\ \text{J/K}$, $\mathcal{C}_{cond} = 700\ \text{J/K}$).
   - **Limitación:** No existe discretización espacial en 1D ni consideración de la masa de refrigerante contenida en el serpentín.
3. **Pérdida de carga en tuberías con factor de fricción constante:**
   - **Archivo:** `lib/domain/models/pipe_segment_state.dart` (Línea 44).
   - **Aproximación:** Factor de fricción fijo $f = 0.024$.
   - **Limitación:** No se calcula el número de Reynolds ($Re = \frac{\rho v D}{\mu}$) ni la rugosidad relativa ($\varepsilon/D$), ni se distingue entre régimen laminar y turbulento.
4. **Modelo de vacío con temperatura de saturación del agua fija:**
   - **Archivo:** `lib/domain/models/vacuum_model.dart` (Líneas 81-91).
   - **Aproximación:** Presión de saturación del agua constante a $2300\ \text{Pa}$ ($\approx 23\ \text{mbar}$, correspondiente a $20\ ^\circ\text{C}$ exactos) y tasa de evaporación constante de $0.008\ \text{g/s}$.
   - **Limitación:** No calcula $P_{sat,agua}(T_{amb})$ dinámicamente ni acopla la evaporación de agua con el calor absorbido por conducción de las paredes del tubo.
5. **Modelo aerotérmico de ventiladores:**
   - **Archivo:** `lib/domain/models/air_flow_model.dart` (Líneas 57-61).
   - **Aproximación:** El caudal de aire varía linealmente con la velocidad relativa del rodete, con un residual mínimo de convección natural ($5\%$ en caudal, $12\%$ en $UA$).
6. **Factor de potencia y corriente del motor eléctrico:**
   - **Archivo:** `lib/domain/models/electrical_model.dart` (Líneas 70-84).
   - **Aproximación:** Fricción mecánica modelada como $P_{fric} = 55 \cdot (\text{RPM}/\text{RPM}_{nom})^{1.4}$, y $\cos\phi$ empírico: $\cos\phi = 0.55 + 0.35 \sqrt{\text{carga}}$.

---

## 5. Elementos únicamente visuales

Elementos que no participan en el cálculo físico y son puramente gráficos:

1. **Apertura y flexión de láminas de válvulas del compresor:**
   - **Archivo:** `lib/visualization/components/compressor_visualizer.dart` (Líneas 122-144).
   - **Mecanismo:** La flexión de la lámina se determina por `isSuctionStroke = math.sin(crankAngleRad) > 0`.
   - **Clasificación:** 🔵 **VISUAL**. No procede de un balance diferencial de fuerzas de gas sobre la lámina elástica.
2. **Plumas de aire de ventiladores (ondas térmicas):**
   - **Archivo:** `lib/visualization/components/condenser_visualizer.dart` (Líneas 125-135) y `evaporator_visualizer.dart` (Líneas 107-117).
   - **Mecanismo:** Círculos y líneas trazadas mediante funciones trigonométricas con `fanAngleRad`.
   - **Clasificación:** 🔵 **VISUAL**. Representan que hay movimiento, pero las ondas no son campos de velocidad física.
3. **Desplazamiento del diafragma y aguja en el corte de la TXV:**
   - **Archivo:** `lib/visualization/components/txv_visualizer.dart` (Líneas 39, 92).
   - **Mecanismo:** `diaphragmFlex = ((valveOpeningPercent - 50.0) / 100.0) * 4.0; needleLift = ((valveOpeningPercent / 100.0) * 7.0);`.
   - **Clasificación:** 🔵 **VISUAL**. Es un escalado geométrico en píxeles del valor físico `% apertura`.
4. **Trazado de tuberías y codos en el canvas:**
   - **Archivo:** `lib/visualization/realistic_plant_canvas.dart` (Líneas 210-245).
   - **Mecanismo:** Coordenadas cartesianas 2D en pantalla.
   - **Clasificación:** 🔵 **VISUAL**.
5. **Resorte y tornillo de regulación de la TXV:**
   - **Archivo:** `lib/visualization/components/txv_visualizer.dart` (Líneas 114-125).
   - **Mecanismo:** Líneas en zigzag dibujadas mediante bucle `for`.
   - **Clasificación:** 🔵 **VISUAL**.
6. **Amortiguamiento mecánico de la aguja del manómetro:**
   - **Archivo:** `lib/presentation/widgets/instruments/bourdon_gauge_widget.dart` (Línea 48).
   - **Mecanismo:** `_displayedPressureBar += (widget.measuredPressureBar - _displayedPressureBar) * 0.35;`.
   - **Clasificación:** 🔵 **VISUAL**. Simula inercia visual de la aguja en baño de glicerina, sin afectar el valor medido en el solver.

---

## 6. Elementos mixtos

1. **Sistema de Partículas de Refrigerante (`refrigerant_particle_system.dart`):**
   - **Parte física:** La velocidad de avance de cada partícula se calcula estrictamente como:
     $$v = \frac{\dot{m}}{\rho \cdot A}$$
     obtenida de `pipeState.velocityMetersPerSec`. Si $\dot{m} = 0$, $v = 0$ y las partículas se detienen por completo.
   - **Parte visual:** La cantidad de partículas (18 fijas por tubería), la variación de radio por burbujas de flash gas ($r = r_0(0.8 + 0.8x)$) y el factor de escala en píxeles ($0.5 \times dt$) son decisiones de representación gráfica.
2. **Cinemática del pistón del compresor (`compressor_visualizer.dart`):**
   - **Parte física:** La velocidad angular de rotación $\omega = 2\pi \cdot (\text{RPM}/60)$ proviene de `state.dynamicRpm`, calculada por la EDO del motor eléctrico considerando par e inercia.
   - **Parte visual:** Las dimensiones geométricas de manivela ($r = 12\ \text{mm}$) y biela ($L = 36\ \text{mm}$) son constantes de dibujo para que el pistón encaje en el gráfico 2.5D.
3. **Rotación de aspas de ventiladores (`condenser_visualizer.dart`, `evaporator_visualizer.dart`):**
   - **Parte física:** La velocidad de giro se calcula a partir de `fanRpm`, la cual responde al estado del motor y al override forzado.
   - **Parte visual:** El ángulo $\theta(t)$ integrado por el ticker genera la rotación gráfica de las aspas.
4. **Interpolación de color en el cilindro de compresión:**
   - **Parte física:** Los colores extremos corresponden a las presiones/temperaturas de aspiración (azul) y descarga (rojo).
   - **Parte visual:** El gradiente vertical dentro del cilindro se interpola linealmente según la posición instantánea del pistón ($0.0$ a $1.0$).

---

## 7. Variables físicas disponibles en el Solver

Las siguientes 28 variables físicas existen en `SimulationState` (`lib/simulation/engine/simulation_state.dart`):

| Variable | Tipo | Unidad | Método / Origen en Código | Naturaleza |
| :--- | :---: | :---: | :--- | :--- |
| `timeSeconds` | `double` | $\text{s}$ | `DynamicSolver.integrateStep:329` | Física |
| `dynamicRpm` | `double` | $\text{RPM}$ | `DynamicSolver.integrateStep:57-63` | Física (EDO inercial) |
| `dynamicBulbTempK` | `double` | $\text{K}$ | `DynamicSolver.integrateStep:131` | Física (EDO 1er orden) |
| `evaporatingPressurePa` | `double` | $\text{Pa}$ | `R134aModel.saturationPressure(tEvap):90` | Física (Antoine) |
| `condensingPressurePa` | `double` | $\text{Pa}$ | `R134aModel.saturationPressure(tCond):91` | Física (Antoine) |
| `evaporatingTemperatureK` | `double` | $\text{K}$ | `DynamicSolver.integrateStep:168` | Física (EDO balance térmico) |
| `condensingTemperatureK` | `double` | $\text{K}$ | `DynamicSolver.integrateStep:172` | Física (EDO balance térmico) |
| `superheatKelvin` | `double` | $\text{K}$ | `DynamicSolver.integrateStep:183` | Física (Balance dinámico) |
| `subcoolingKelvin` | `double` | $\text{K}$ | `cond.targetSubcoolingKelvin:120` | Paramétrica |
| `massFlowKgPerSec` | `double` | $\text{kg/s}$ | `DynamicSolver.integrateStep:149` | Física (Compresor/TXV) |
| `coolingCapacityWatts` | `double` | $\text{W}$ | `DynamicSolver.integrateStep:150` | Física ($\dot{m}\Delta h$) |
| `heatingCapacityWatts` | `double` | $\text{W}$ | `DynamicSolver.integrateStep:151` | Física ($\dot{m}\Delta h$) |
| `compressorPowerWatts` | `double` | $\text{W}$ | `DynamicSolver.integrateStep:152` | Física ($\dot{m}\Delta h$) |
| `electricalPowerWatts` | `double` | $\text{W}$ | `electricalState.activePowerWatts:243` | Física ($W_{ind} + P_{fric}/\eta$) |
| `cop` | `double` | — | `DynamicSolver.integrateStep:153` | Física ($\dot{Q}_e / \dot{W}_{ind}$) |
| `state1Suction` | `ThermodynamicState` | Varios | `r134a_model.dart:97` | Estado termodinámico |
| `state2Discharge` | `ThermodynamicState` | Varios | `r134a_model.dart:117` | Estado termodinámico |
| `state3Liquid` | `ThermodynamicState` | Varios | `r134a_model.dart:123` | Estado termodinámico |
| `state4EvapInlet` | `ThermodynamicState` | Varios | `r134a_model.dart:144` | Estado termodinámico |
| `coldRoom.temperatureKelvin` | `double` | $\text{K}$ | `DynamicSolver.integrateStep:178` | Física (EDO balance recinto) |
| `electricalState.currentAmps` | `double` | $\text{A}$ | `electrical_model.dart:90-95` | Física ($P / (V\cos\phi) + I_{LRA}$) |
| `electricalState.powerFactor` | `double` | — | `electrical_model.dart:84` | Aproximada |
| `condenserAirFlow.fanRpm` | `double` | $\text{RPM}$ | `air_flow_model.dart:53` | Cinemática |
| `condenserAirFlow.massFlowKgPerSec`| `double` | $\text{kg/s}$ | `air_flow_model.dart:58` | Física ($\dot{V} \cdot \rho_{aire}$) |
| `condenserAirFlow.deltaTAirKelvin` | `double` | $\text{K}$ | `air_flow_model.dart:61` | Física ($\dot{Q}/(\dot{m} C_p)$) |
| `pipeStates[id].velocityMetersPerSec`| `double` | $\text{m/s}$ | `pipe_segment_state.dart:40` | Física ($\dot{m}/(\rho A)$) |
| `pipeStates[id].pressureDropPascals`| `double` | $\text{Pa}$ | `pipe_segment_state.dart:46` | Aproximada (Darcy-Weisbach) |
| `vacuumState.pressureMicrons` | `double` | $\mu\text{mHg}$ | `vacuum_model.dart:9, 85-99` | Aproximada (3 fases) |

---

## 8. Variables derivadas

Variables que no son de estado independiente sino combinaciones analíticas:
1. **Relación de compresión ($r_p$):** $r_p = P_{cond} / P_{evap}$.
2. **Entalpía de evaporación ($\Delta h_{evap}$):** $h_1 - h_4$.
3. **Entalpía de condensación ($\Delta h_{cond}$):** $h_2 - h_3$.
4. **Caudal másico volumétrico ($m_{dot,h}$):** $\dot{m} \times 3600\ \text{kg/h}$.
5. **Deslizamiento del motor ($s$):** $s = 1 - (\text{RPM} / \text{RPM}_{target})$.

---

## 9. Variables puramente gráficas

Variables existentes exclusivamente para el dibujado en pantalla (no presentes en el solver):
1. `_crankAngleRad`: Ángulo de rotación del cigüeñal ($\text{rad}$).
2. `_condFanAngleRad`: Ángulo de rotación del ventilador del condensador ($\text{rad}$).
3. `_evapFanAngleRad`: Ángulo de rotación del ventilador del evaporador ($\text{rad}$).
4. `FlowParticle.progress`: Posición paramétrica normalizada de la partícula ($0.0\text{--}1.0$).
5. `FlowParticle.lateralOffset`: Desplazamiento transversal dentro del tubo ($\pm 2.5\ \text{px}$).
6. `needleLift`: Alzada gráfica de la aguja de la TXV en píxeles ($1.0\text{--}7.0\ \text{px}$).
7. `diaphragmFlex`: Deformación gráfica de la curva de Bézier del diafragma ($\pm 2.0\ \text{px}$).
8. `_displayedPressureBar`: Posición amortiguada de la aguja del manómetro en pantalla.

---

## 10. Instrumentación

Auditoría detallada de los 5 instrumentos virtuales SCADA:

### 10.1. Manómetros Bourdon (`bourdon_gauge_widget.dart`)
- **Variable que lee:** `measuredPressureBar` proveniente de `state.evaporatingPressurePa / 1e5` (LP) y `state.condensingPressurePa / 1e5` (HP).
- **Punto de conexión:** Conectados respectivamente a la cámara de aspiración y a la cámara de descarga.
- **Dinámica propia:** Sí, filtro pasa-bajos de primer orden: $\Delta P_{disp} = 0.35 \cdot (P_{real} - P_{disp})$ ejecutado en cada frame de la UI para simular el amortiguamiento de la aguja en glicerina.
- **Tolerancia/error:** Ninguno modelado.
- **Valores inventados:** Ninguno.
- **Nota técnica (Física en la UI):** En la línea 173 recalcula la temperatura de saturación $T_{sat}$ para la etiqueta central invocando `refrigerant.saturationTemperature(pressureBar * 1e5)`.

### 10.2. Termómetro digital de pinza (`digital_thermometer_clamp_widget.dart`)
- **Variable que lee:** Temperatura termodinámica $T$ de `state.state1Suction`, `state.state2Discharge`, `state.state3Liquid`, `state.state4EvapInlet` o `state.coldRoom`.
- **Punto de conexión:** Selector de 6 posiciones físicas de prueba en la tubería y recintos.
- **Dinámica propia:** Ninguna; lectura instantánea directa del solver.
- **Cálculo de $SH$ y $SC$:** Muestra $SH = T_1 - T_{sat}(P_e)$ y $SC = T_{sat}(P_c) - T_3$ exactamente como calcula el solver.
- **Valores inventados:** Ninguno.

### 10.3. Pinza amperimétrica True RMS (`clamp_meter_widget.dart`)
- **Variable que lee:** `state.electricalState.currentAmps`, `activePowerWatts` y `powerFactor`.
- **Punto de conexión:** Motor eléctrico del compresor.
- **Dinámica propia:** Responde al modelo electromecánico de `electrical_model.dart`, mostrando el pico de arranque LRA ($20\text{--}24\ \text{A}$) y la estabilización en régimen continuo ($3.8\text{--}4.5\ \text{A}$).
- **Valores inventados:** Ninguno.

### 10.4. Caudalímetro másico Coriolis (`mass_flow_meter_widget.dart`)
- **Variable que lee:** `state.massFlowKgPerSec`.
- **Transformación:** Conversión directa a $\text{kg/h}$ ($\times 3600$) y $\text{g/s}$ ($\times 1000$).
- **Valores inventados:** Ninguno.

### 10.5. Vacuómetro Pirani de micras (`vacuum_gauge_widget.dart`)
- **Variable que lee:** `state.vacuumState.pressureMicrons`.
- **Punto de conexión:** Puerto de servicio del circuito.
- **Comportamiento:** Responde a la integración del modelo de 3 etapas de `vacuum_model.dart`.
- **Valores inventados:** Ninguno.

---

## 11. Partículas y flujo visual

Analizado en `lib/visualization/flow/refrigerant_particle_system.dart`:

| Parámetro | Naturaleza | Fuente en Código |
| :--- | :---: | :--- |
| **Velocidad de avance** | 🟢 **FÍSICA** | $v = \dot{m}/(\rho A)$, tomado de `PipeSegmentState.velocityMetersPerSec`. |
| **Sentido de circulación** | 🟢 **FÍSICA** | Definido por la topología cerrada del ciclo (1 $\to$ 2 $\to$ 3 $\to$ 4 $\to$ 1). |
| **Número de partículas** | 🔵 **VISUAL** | 18 partículas fijas por tubería (Línea 40). |
| **Avance en pantalla** | 🔵 **VISUAL** | `dProgress = (vPhysical / lengthM) * dtRenderSeconds * 0.5;` (Factor 0.5 de escala visual). |
| **Tamaño de partícula** | 🔵 **VISUAL** | $2.5\ \text{px}$ base; en bifásico escala con el título de vapor: $r = r_0 (0.8 + 0.8x)$ (Línea 147). |
| **Color del fluido** | 🟠 **MIXTO** | Determinado por `pipeState.phaseState`: rojo (descarga), rojo oscuro (líquido), cian (bifásico), azul (aspiración). |
| **Estela de vapor** | 🔵 **VISUAL** | Línea semitransparente orientada hacia atrás si $v > 0.05\ \text{m/s}$ y el fluido es gaseoso (Línea 154). |

---

## 12. Compresor

- **Física calculada:**
  - Desplazamiento volumétrico: $V_{desp} = \text{displacementCm3} \times 10^{-6}$.
  - Caudal másico: $\dot{m} = V_{desp} \times \left(\frac{\text{RPM}}{60}\right) \times \rho_1 \times \eta_v$.
  - Trabajo de compresión: Formulación politrópica con $k = 1.13$.
  - Rendimiento volumétrico $\eta_v$ dependiente de la relación de compresión $P_c/P_e$.
- **Aproximaciones:**
  - Volumen nocivo fijo al $4.5\%$ ($c = 0.045$).
  - Rendimiento isentrópico constante del compresor ($\eta_{is} = 0.75$).
  - Inercia del rotor modelada con constante de tiempo de primer orden ($\tau_{motor} = 0.8\ \text{s}$ en aceleración, $0.5\ \text{s}$ en frenado).
- **Elementos visuales:**
  - Cinemática de biela-manivela exacta mediante fórmula trigonométrica de corredera.
  - Válvulas de láminas abren según el signo de la velocidad del pistón, no por cálculo diferencial de presiones en cámara.

---

## 13. Condensador

- **Física calculada:**
  - Calor cedido: $\dot{Q}_c = \dot{m}(h_2 - h_3)$.
  - Temperatura de saturación $T_c$: EDO basada en balance de energía: $\frac{dT_c}{dt} = \frac{\dot{Q}_c - \dot{Q}_{air}}{\mathcal{C}_{cond}}$.
  - Presión de condensación: $P_{cond} = P_{sat}(T_c)$.
- **Aproximaciones:**
  - Capacidad calorífica $\mathcal{C}_{cond} = 700\ \text{J/K}$.
  - Modulación de conductancia térmica por ventilador: $UA_{eff} = UA \times (0.12 + 0.88 \cdot \text{fanFraction})$.
  - Subenfriamiento fijo como parámetro de consigna del condensador ($\Delta T_{sub} = 3\text{--}5\ \text{K}$).
- **Elementos visuales:**
  - Serpentín con 4 tubos y coloración estática por pasos (vapor $\to$ bifásico $\to$ líquido).
  - Rotación de aspas ligada a `fanRpm`.
  - Ondas de aire caliente calculadas por funciones modulares de ángulo.

---

## 14. Evaporador y Cámara

- **Física calculada:**
  - Potencia frigorífica: $\dot{Q}_e = \dot{m}(h_1 - h_4)$.
  - Temperatura de evaporación $T_e$: EDO $\frac{dT_e}{dt} = \frac{\dot{Q}_{air} - \dot{Q}_e}{\mathcal{C}_{evap}}$.
  - Temperatura de la cámara $T_{room}$: EDO $\frac{dT_{room}}{dt} = \frac{\dot{Q}_{load} - \dot{Q}_{air}}{\mathcal{C}_{room}}$.
  - Transmisión por paredes: $\dot{Q}_{trans} = U \cdot A \cdot (T_{amb} - T_{room})$.
- **Aproximaciones:**
  - Cámara de capacidad lumped ($\mathcal{C}_{room} = 85.000\ \text{J/K}$).
  - Cargas internas ($150\ \text{W}$) e infiltraciones ($100\ \text{W}$) constantes.
  - El enfriamiento del recinto **procede 100% de la ecuación diferencial**, no de ninguna animación.
- **Elementos visuales:**
  - Batería de evaporador con tubo bifásico cian y vapor azul.
  - Rotación de ventilador cúbico.
  - Corriente de aire frío dibujada como trazos verticales descendentes en el interior de la cámara.

---

## 15. Válvula de Expansión Termostática (TXV)

- **Física calculada:**
  - Caudal por orificio: $\dot{m} \propto A_{eff} \sqrt{2\rho\Delta P}$.
  - Retardo térmico del bulbo: EDO de primer orden con $\tau_{bulb} = 3.5\ \text{s}$.
  - Expansión isoentálpica: $h_4 = h_3$.
- **Aproximaciones:**
  - Modulación de apertura en modo automático: proporcional al error de recalentamiento con factor $0.8 \cdot dt$, sin modelado de histéresis ni fricción en el vástago.
- **Elementos visuales:**
  - Desplazamiento visual de aguja cónica y flexión del diafragma linealmente escalados con `% apertura`.
  - Tubo capilar y bulbo dibujados como primitivas vectoriales fijas con etiqueta de temperatura.

---

## 16. Tuberías

- **Física calculada:**
  - Conservación de masa: $\dot{m}_{tubo} = \dot{m}_{circuito}$.
  - Densidad del fluido: tomada de la ecuación de estado de cada nodo termodinámico.
  - Velocidad real: $v = \dot{m} / (\rho A)$.
- **Aproximaciones:**
  - Factor de fricción constante $f = 0.024$.
  - Caída de presión $\Delta P$ calculada pero no restada de las presiones de los nodos del solver (no afecta al ciclo termodinámico).
- **Elementos visuales:**
  - Rutas poligonales 2D trazadas entre los componentes en la pantalla.

---

## 17. Motor eléctrico

- **Física calculada:**
  - Potencia en eje: $P_{shaft} = W_{ind} + P_{fric}(\text{RPM})$.
  - Potencia eléctrica activa: $P_{elec} = P_{shaft} / \eta_{motor}$.
  - Corriente eficaz: $I = \frac{P_{elec}}{V \cdot \cos\phi} + I_{LRA} \cdot s \cdot 0.75$.
- **Aproximaciones:**
  - Curva de $\cos\phi$ y pérdidas mecánicas mediante correlaciones empíricas.
  - Modelo monofásico a $230\ \text{V}$ constante, sin fluctuaciones de red.
- **Elementos visuales:**
  - Coloración de haces de cobre del estator en el compresor (marrón claro si hay corriente, oscuro en parada).

---

## 18. Vacío

- **Física calculada:**
  - Velocidad de evacuación volumétrica exponencial: $P(t) = P_0 e^{-S/V \cdot t}$.
  - Balance de masa de humedad residual líquida en el circuito: $m_{agua}(t) = \max(0, m_0 - \dot{m}_{evap} \cdot t)$.
- **Aproximaciones:**
  - Presión de ebullición de humedad fijada en $2300\ \text{Pa}$ ($23\ \text{mbar}$, equivalente a $20\ ^\circ\text{C}$ fijos).
  - Tasa de evaporación constante de $0.008\ \text{g/s}$.
  - Límite mecánico inferior de la bomba fijado en $2.5\ \text{Pa}$ ($\approx 18\ \mu\text{mHg}$).
- **Elementos visuales:**
  - Visualización del display LCD del vacuómetro y colores de estado (rojo $\to$ cian $\to$ naranja $\to$ verde).

---

## 19. Diagrama P-h

- **Física calculada:**
  - Puntos del ciclo $1, 2, 3, 4$: Leídos directamente de `SimulationState` calculados por el solver.
  - Campana de saturación: Generada mediante barrido de 60 puntos de $T_{min} = -40\ ^\circ\text{C}$ a $T_{max} = T_{crit} - 1.5\ ^\circ\text{C}$ aplicando $P = P_{sat}(T)$, $h_f = h_f(P)$ y $h_g = h_g(P)$.
  - Isolíneas de calidad $x$: Calculadas estrictamente con $h = h_f + x(h_g - h_f)$.
- **Aproximaciones:**
  - Las isotermas en la zona de líquido subenfriado y vapor sobrecalentado se grafican con tramos de interpolación fija (`hfKj - 15.0, pSatBar * 2.2` y `hgKj + 45.0, pSatBar * 0.45`).
- **Elementos visuales:**
  - Ejes semilogarítmicos, rejilla y escalado en píxeles del widget Flutter.

---

## 20. Diagrama T-s

- **Física calculada:**
  - Curvas de líquido y vapor saturado generadas a partir de $s_f(P)$ y $s_g(P)$ en `r134a_model.dart`.
  - Isolíneas de título $x$: $s = s_f + x(s_g - s_f)$.
  - Puntos del ciclo en coordenadas $(s, T)$.
- **Aproximaciones:**
  - Modelo de entropía basado en integración de calores específicos constantes promedio.
- **Elementos visuales:**
  - Renderizado vectorial de líneas en canvas.

---

## 21. Fallos

Análisis de los fallos implementados en el simulador:

1. **Fallo de ventilador del condensador (DEMO 4 / `toggleCondenserFan`):**
   - **Variable que modifica:** `condenserFanSpeedOverride = 0.0`.
   - **Mecanismo:** En `dynamic_solver.dart:157`, el coeficiente global $UA$ se multiplica por $0.12$.
   - **Respuesta física:** El balance $\frac{dT_c}{dt} = \frac{\dot{Q}_c - \dot{Q}_{air}}{\mathcal{C}_{cond}}$ produce un incremento continuo de $T_{cond}$, lo que eleva $P_{cond} = P_{sat}(T_c)$.
   - **Clasificación:** 🟢 **FALLO FÍSICO MODELADO**. No hay valores de presión inyectados a mano.
2. **Ensuciamiento del condensador (`setCondenserFouling`):**
   - **Variable que modifica:** `foulingFactor` ($0.0\text{--}1.0$).
   - **Mecanismo:** Reduce la conductancia térmica nominal $UA$ multiplicando por $(1 - \text{fouling})$.
   - **Clasificación:** 🟢 **FALLO FÍSICO MODELADO**.
3. **Estrangulamiento de la TXV (`setValveOpening`):**
   - **Variable que modifica:** `openingPercent` ($5\%\text{--}100\%$).
   - **Mecanismo:** Reduce $A_{eff}$, disminuye $\dot{m}_{txv}$, desalimenta el evaporador y eleva el sobrecalentamiento.
   - **Clasificación:** 🟢 **FALLO FÍSICO MODELADO**.
4. **Carga térmica excesiva (`setInternalHeatLoad`):**
   - **Variable que modifica:** `internalHeatLoadWatts` en `ColdRoomModel`.
   - **Mecanismo:** Incrementa la entrada de calor a la EDO del recinto.
   - **Clasificación:** 🟢 **FALLO FÍSICO MODELADO**.

---

## 22. Cadena causal de fenómenos

| Fenómeno | Entrada física | Ecuación / Cálculo en Solver | Salida física real | Representación visual |
| :--- | :--- | :--- | :--- | :--- |
| **Arranque del motor** | `isRunning = true` | $\frac{d\text{RPM}}{dt} = \frac{\text{RPM}_{nom} - \text{RPM}}{\tau_m}$ | $\text{RPM} \uparrow$, $I_{LRA} \uparrow$ por deslizamiento | Pistón acelera, pinza marca 22 A |
| **Fallo ventilador condensador** | `fanOverride = 0` | $UA_{eff} = 0.12 \cdot UA \implies \dot{Q}_{air} \downarrow$ | $\frac{dT_c}{dt} > 0 \implies P_{cond} \uparrow$ | Aspas quietas, aguja HP sube a 15 bar |
| **Estrangulamiento TXV** | `apertura = 10%` | $\dot{m}_{txv} = C_v A \sqrt{2\rho\Delta P} \implies \dot{m} \downarrow$ | $P_{evap} \downarrow$, $SH \uparrow$ | Aguja TXV baja, manómetro LP cae |
| **Ola de calor exterior** | $T_{amb} = 38\ ^\circ\text{C}$ | $\dot{Q}_{cond} = UA(T_c - T_{amb}) \implies T_c \uparrow$ | $P_{cond} \uparrow$, $W_{comp} \uparrow$, $\text{COP} \downarrow$ | Termómetro ambiente, subida de alta |
| **Pull-down cámara** | $\dot{Q}_e > \dot{Q}_{load}$ | $\frac{dT_{room}}{dt} = \frac{\dot{Q}_{load} - \dot{Q}_e}{\mathcal{C}_{room}} < 0$ | $T_{room} \downarrow$ asintóticamente | Borde azul en cámara, etiqueta desciende |
| **Parada de instalación** | `isRunning = false` | $\frac{d\text{RPM}}{dt} = -\frac{\text{RPM}}{0.5}$, $\Delta P \to 0$ | $\text{RPM} \to 0$, $v_{tubos} \to 0$, ecualización | Pistón frena, partículas se detienen |

---

## 23. Física duplicada o potencialmente duplicada

Se detectó una instancia de cálculo físico dentro de la capa de presentación:
- **Archivo:** `lib/presentation/widgets/instruments/bourdon_gauge_widget.dart`
- **Línea:** 173
- **Código:** `tSatC = refrigerant.saturationTemperature(pressureBar * 1e5) - 273.15;`
- **Diagnóstico:** POSIBLE DUPLICACIÓN DE FÍSICA. El widget recalcula la temperatura de saturación a partir de la presión medida en lugar de leer el valor de temperatura de saturación ya disponible en `SimulationState` (`state.evaporatingTemperatureK` o `state.condensingTemperatureK`).
- **Impacto:** Menor, ya que utiliza el mismo modelo `R134aModel`, pero incumple el principio estricto de consumir únicamente datos precalculados.

---

## 24. Valores hardcoded encontrados

Lista exhaustiva de constantes fijas utilizadas en el cálculo o representación:

| Archivo | Línea | Variable / Valor | Uso | Clasificación |
| :--- | :---: | :--- | :--- | :--- |
| `dynamic_solver.dart` | 23 | `_cEvap = 450.0` | Capacitancia térmica evaporador (J/K) | Constante lumped |
| `dynamic_solver.dart` | 24 | `_cCond = 700.0` | Capacitancia térmica condensador (J/K) | Constante lumped |
| `dynamic_solver.dart` | 25 | `_tauBulb = 3.5` | Constante de tiempo bulbo TXV (s) | Parámetro físico calibrado |
| `dynamic_solver.dart` | 26 | `_tauMotor = 0.8` | Inercia de aceleración motor (s) | Parámetro físico calibrado |
| `dynamic_solver.dart` | 27 | `_cvTxv = 5.5e-7` | Coeficiente orificio TXV ($\text{m}^2$) | Parámetro físico calibrado |
| `dynamic_solver.dart` | 100 | `clearanceRatio = 0.045` | Fracción volumen nocivo (4.5%) | Parámetro físico geométrico |
| `dynamic_solver.dart` | 101 | `adiabaticK = 1.13` | Coeficiente politrópico R-134a | Parámetro termodinámico |
| `dynamic_solver.dart` | 157 | `0.12` | Residual convección natural condensador | Coeficiente empírico |
| `dynamic_solver.dart` | 160 | `0.10` | Residual convección natural evaporador | Coeficiente empírico |
| `pipe_segment_state.dart` | 44 | `frictionFactor = 0.024` | Factor fricción Darcy-Weisbach | Parámetro fijo |
| `vacuum_model.dart` | 81 | `pWaterSat = 2300.0` | Presión saturación agua a 20 °C (Pa) | Constante fija de temperatura |
| `vacuum_model.dart` | 89 | `evaporationRate = 0.008` | Tasa evaporación agua residual (g/s) | Parámetro empírico |
| `vacuum_model.dart` | 94 | `pPumpLimit = 2.5` | Límite físico bomba paletas (Pa) | Límite mecánico de equipo |
| `electrical_model.dart` | 62 | `nominalVoltage = 230.0` | Tensión de alimentación de red (V) | Constante eléctrica |
| `electrical_model.dart` | 80 | `nominalMotorPower = 950.0`| Potencia nominal diseño motor (W) | Constante de componente |
| `diagram_data_generator.dart`| 96, 101 | `hfKj - 15.0`, `hgKj + 45.0` | Extrapolación de isotermas P-h | Constante gráfica de dibujo |
| `refrigerant_particle_system.dart`| 40 | `18` | Partículas por tramo de tubería | Constante gráfica de renderizado |
| `refrigerant_particle_system.dart`| 68 | `0.5` | Factor de escala visual de velocidad | Constante gráfica de renderizado |

---

## 25. Análisis de los 47 tests

Auditoría de cobertura y alcance real de las suites de prueba:

### 1. `units_test.dart` (8 tests)
- **Qué prueba:** Factores de conversión matemática entre bar, Pa, PSI, Celsius, Kelvin, Fahrenheit, kW y kg/h.
- **Qué NO prueba:** No prueba ninguna ecuación termodinámica ni dinámica de simulación.
- **Tipo:** Prueba unitaria puramente algebraica.

### 2. `lessons_and_workshop_test.dart` (8 tests)
- **Qué prueba:** Disponibilidad de las 11 lecciones del syllabus, lógica de progreso, validación topológica de conexiones en el taller (rechazo de conexiones inválidas, cortocircuitos o sentido termodinámico inverso) y servicio de preguntas del profesor virtual.
- **Qué NO prueba:** No prueba ecuaciones diferenciales ni precisión termodinámica.
- **Tipo:** Prueba funcional de lógica de negocio y grafos de conexión.

### 3. `r134a_test.dart` (7 tests)
- **Qué prueba:** Puntos de saturación clave ($0\ ^\circ\text{C} \approx 2.9\ \text{bar}$, $-10\ ^\circ\text{C} \approx 2.0\ \text{bar}$, $+45\ ^\circ\text{C} \approx 11.6\ \text{bar}$), reversibilidad analítica $T_{sat}(P_{sat}(T)) = T$, calor latente positivo y cálculo de estados bifásicos.
- **Qué NO prueba:** No valida el modelo frente a bases de datos de alta precisión de REFPROP en toda la superficie de estado ni estados supercríticos.
- **Tipo:** Prueba unitaria termodinámica de coherencia interna.

### 4. `topology_and_solver_test.dart` (4 tests)
- **Qué prueba:** Verificación de circuito cerrado básico, detección de circuitos incompletos, cumplimiento del Primer Principio en el solver estático ($\dot{Q}_c \approx \dot{Q}_e + \dot{W}_{comp}$) e igualación de presiones en parada.
- **Qué NO prueba:** No prueba transitorios temporales de aceleración ni EDOs.
- **Tipo:** Prueba de balance energético en estado estacionario.

### 5. `dynamic_solver_test.dart` (4 tests)
- **Qué prueba:** Transitorio de arranque con divergencia de presiones, curva de pull-down de la cámara frigorífica, ciclo de marcha/paro por termostato con histéresis y estabilidad numérica ante perturbaciones sin NaN ni infinitos.
- **Qué NO prueba:** No valida la convergencia matemática del integrador frente a métodos analíticos formales (Runge-Kutta 4).
- **Tipo:** Prueba de integración de ecuaciones diferenciales (ODE).

### 6. `transient_experiments_test.dart` (4 tests)
- **Qué prueba:** Sensibilidad del modelo dinámico ante cambios de RPM, temperatura exterior y estrangulamiento de la TXV, además del ciclo de vida del experimento pedagógico.
- **Qué NO prueba:** No valida la magnitud cuantitativa experimental frente a un banco de ensayos físico de laboratorio.
- **Tipo:** Prueba de comportamiento cualitativo-físico.

### 7. `ph_and_ts_diagram_test.dart` (5 tests)
- **Qué prueba:** Que las campanas de saturación P-h y T-s son cerradas y suaves, que las curvas de título $x$ se mantienen dentro de la campana, que las isotermas son horizontales en la región bifásica y que los 4 puntos del ciclo se extraen correctamente.
- **Qué NO prueba:** No valida la fidelidad gráfica de renderizado en píxeles.
- **Tipo:** Prueba geométrica y matemática de datos para diagramas.

### 8. `physical_visualizer_consistency_test.dart` (6 tests)
- **Test 1 (No-invención):** Comprueba que los visualizadores toman sus variables directamente de `SimulationState`. *No prueba la exactitud anatómica del dibujo 2.5D.*
- **Test 2 (Continuidad de fluidos):** Comprueba que $v = \dot{m}/(\rho A)$ coincide analíticamente y que $v_{gas} > v_{liq}$. *No prueba perfiles parabólicos de velocidad ni efectos de turbulencia.*
- **Test 3 (Estado de parada):** Comprueba que al detener el motor tras el período de inercia, las velocidades decaen a $0.0\ \text{m/s}$. *No prueba migraciones lentas de masa durante días de parada.*
- **Test 4 (Modelo eléctrico):** Comprueba $P = V \cdot I \cdot \cos\phi$ y la sobrecorriente por deslizamiento ($slip$). *No prueba caídas de tensión por impedancia de línea ni armónicos.*
- **Test 5 (Fallo ventilador condensador):** Comprueba que parar el ventilador reduce el flujo de aire y eleva $P_{cond}$ y $T_{cond}$. *No prueba el disparo de protecciones térmicas internas en bobinado.*
- **Test 6 (Modelo de vacío):** Comprueba las fases de evacuación, meseta de ebullición del agua y alto vacío profundo. *No prueba fugas capilares microscópicas de helio.*

### 9. `widget_test.dart` (1 test)
- **Qué prueba:** Smoke test de inicio y renderizado de la UI de FrigoLab.

---

## 26. Comparación con el informe anterior

| Parámetro afirmado en informe | Valor en Informe | Valor real en Código | Estado de Verificación |
| :--- | :---: | :---: | :---: |
| Frecuencia del solver físico | $20\ \text{Hz}$ ($dt = 0.05\ \text{s}$) | $0.05\ \text{s}$ (`dynamic_solver.dart:18`) | 🟢 **CONFIRMADO POR CÓDIGO** |
| Tasa de refresco visual | $60\ \text{FPS}$ | Flutter `Ticker` (`realistic_plant_canvas.dart:58`) | 🟢 **CONFIRMADO POR CÓDIGO** |
| Modelo termodinámico | R-134a | Antoine + Clausius-Clapeyron (`r134a_model.dart`) | 🟡 **CONFIRMADO PERO APROXIMADO** |
| Velocidades nominales motor | $1450\ /\ 2900\ \text{RPM}$ | Rango de operación en código (`dynamic_solver.dart:60`) | 🟢 **CONFIRMADO POR CÓDIGO** |
| Corriente de arranque (LRA) | $20\text{--}24\ \text{A}$ | Pico de inrush calculado ($21.6\ \text{A}$) | 🟢 **CONFIRMADO POR CÓDIGO** |
| Corriente nominal en marcha | $3.8\text{--}4.5\ \text{A}$ | Corriente régimen permanente calculada | 🟢 **CONFIRMADO POR CÓDIGO** |
| Presión alta nominal R-134a | $11.6\ \text{bar}$ | $P_{sat}(45\ ^\circ\text{C}) = 11.60\ \text{bar}$ | 🟢 **CONFIRMADO POR CÓDIGO** |
| Presión baja nominal R-134a | $2.4\ \text{bar}$ | $P_{sat}(-5\ ^\circ\text{C}) = 2.43\ \text{bar}$ | 🟢 **CONFIRMADO POR CÓDIGO** |
| Velocidad vapor descarga | $\sim 12\ \text{m/s}$ | $v = \dot{m}/(\rho A) \approx 4\text{--}12\ \text{m/s}$ según RPM | 🟢 **CONFIRMADO POR CÓDIGO** |
| Velocidad líquido subenfriado| $0.8\ \text{m/s}$ | $v = \dot{m}/(\rho A) \approx 0.13\text{--}0.25\ \text{m/s}$ | 🟡 **CONTRADICHO EN VALOR NUMÉRICO** |
| Presión con ventilador parado | $> 15.5\ \text{bar}$ | Alcanza $> 15.5\ \text{bar}$ tras asfixia térmica | 🟢 **CONFIRMADO POR CÓDIGO** |
| Temperatura saturación fallo | $> +55\ ^\circ\text{C}$ | Corresponde a $P_{sat} > 15.0\ \text{bar}$ | 🟢 **CONFIRMADO POR CÓDIGO** |
| Aumento de corriente en fallo| $> 25\%$ | Aumento por ratio de compresión | 🟢 **CONFIRMADO POR CÓDIGO** |
| Constante de tiempo bulbo TXV| $\tau = 8.0\ \text{s}$ | `_tauBulb = 3.5` (`dynamic_solver.dart:25`) | 🔴 **CONTRADICHO POR CÓDIGO** |
| Residual ventilador parado | $12\%$ $UA$ | $0.12 + 0.88 \cdot \text{fanFraction}$ (`dynamic_solver.dart:157`) | 🟢 **CONFIRMADO POR CÓDIGO** |

---

## 27. Limitaciones físicas reales

1. **Ausencia de cálculo dinámico de pérdidas de carga acopladas:** La pérdida de carga en tuberías $\Delta P$ se calcula de manera aislada en `PipeSegmentState`, pero no retroalimenta las presiones nodales del ciclo en `DynamicSolver`. Los nodos del ciclo se consideran isobáricos entre componentes ($P_1 = P_{evap}, P_2 = P_3 = P_{cond}, P_4 = P_{evap}$).
2. **Capacitancia térmica concentrada (Lumped):** No existe distribución espacial de temperatura a lo largo del serpentín de las baterías; toda la batería tiene una temperatura uniforme de saturación.
3. **Ausencia de dinámica de desrecalentamiento en condensador:** No se computa la zona de vapor sobrecalentado de los primeros tubos de forma desacoplada de la condensación bifásica.
4. **Circuito de lubricación ausente:** No se modela el arrastre de aceite en el refrigerante, la caída de presión en sifones ni la solubilidad del aceite en el cárter.
5. **Comportamiento subcrítico exclusivo:** Las ecuaciones no son válidas por encima de la presión crítica de $4.059\ \text{MPa}$ ($40.59\ \text{bar}$).

---

## 28. Limitaciones visuales

1. **Perspectiva isométrica 2.5D plana:** La representación visual se dibuja mediante un `CustomPainter` vectorial 2D en coordenadas de pantalla, sin mallas poligonales 3D ni cálculo de iluminación espacial.
2. **Partículas como esferas fijas:** El flujo no resuelve ecuaciones de Navier-Stokes para el fluido; se limita a mover 18 marcadores paramétricos a lo largo de polilíneas.
3. **Deformación cinemática sin elasticidad de materiales:** Las válvulas de láminas y diafragmas se mueven por funciones geométricas fijas sin considerar resonancias, fatiga de material ni flexión elástica.

---

## 29. Riesgos técnicos

1. **Estabilidad temporal ante pasos de integración grandes:** El solver utiliza integración Euler explícita con $dt = 0.05\ \text{s}$. Si se aumenta el paso temporal a $dt > 0.2\ \text{s}$ (por ejemplo en modos de aceleración x10 mal controlados), las EDOs térmicas de las baterías pueden sufrir inestabilidades numéricas u oscilaciones parásitas.
2. **Duplicación de lógica termodinámica en widgets:** La llamada a `R134aModel.saturationTemperature` dentro del `CustomPainter` del manómetro Bourdon introduce un acoplamiento indebido entre la vista y el modelo de refrigerante.
3. **Falta de retroalimentación de $\Delta P$ de tuberías:** Si en el futuro se añade tubería muy larga o de diámetro pequeño, el alumno esperaría ver una caída de presión en la aspiración del compresor que actualmente el solver no refleja en los manómetros.

---

## 30. Conclusión

FrigoLab cuenta con un **núcleo de simulación físico-dinámico genuino y determinista** en el que todas las magnitudes principales (presiones de saturación, entalpías, balances de energía, trabajo de compresión, abatimiento de temperatura del recinto, inercia del motor y velocidad de flujo en tuberías) proceden de cálculos matemáticos reales y no de secuencias estocásticas ni animaciones arbitrarias.

No obstante, **el sistema no debe presentarse como un software de cálculo ejecutivo o dimensionamiento industrial**, sino como un **laboratorio virtual de simulación pedagógica**. Sus aproximaciones (capacitancias concentradas lumped, ecuaciones de Antoine, factor de fricción constante e hipótesis isobáricas entre nodos) son plenamente adecuadas para la formación técnica y comprensión cualitativa y cuantitativa de los ciclos frigoríficos, pero presentan límites matemáticos claros documentados rigurosamente en este informe.
