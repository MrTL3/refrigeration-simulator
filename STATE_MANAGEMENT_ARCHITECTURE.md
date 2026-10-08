# ARQUITECTURA DE GESTIÓN DE ESTADO, HISTORIAL Y REVERSIBILIDAD EN FRIGOLAB
## Consolidación Arquitectónica · Desacoplamiento Físico/Visual · Snapshots Inmutables

---

## 1. Qué es Estado Físico

El **Estado Físico** en FrigoLab es la representación cuantitativa y determinista de las leyes de conservación (masa, energía, cantidad de movimiento) y ecuaciones de estado termodinámico calculadas por el motor de simulación.

Está encapsulado en la clase inmutable [`SimulationState`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/simulation/engine/simulation_state.dart#L18) y sus componentes del dominio físico:
- **Variables nodales y de campo:** Presión de evaporación ($P_0$), presión de condensación ($P_k$), temperatura de evaporación ($T_{evap}$), temperatura de condensación ($T_{cond}$), recalentamiento útil (Superheat, $\Delta T_{sh}$), subenfriamiento de líquido (Subcooling, $\Delta T_{sc}$), caudal másico en circulación ($\dot{m}$), potencia frigorífica ($\dot{Q}_e$), calor de condensación ($\dot{Q}_c$), trabajo de compresión ($W_{ind}$), potencia eléctrica activa ($P_{elec}$) y COP.
- **Cinemática y actuadores reales:** Frecuencia de giro del compresor (RPM), temperatura del bulbo sensor de la TXV ($T_{bulb}$), apertura de estrangulamiento de la TXV ($openingPercent$), modo de control automático/manual, factor de suciedad del condensador ($foulingFactor$) y estado operativo de ventiladores.
- **Acoplamiento con recintos:** Temperatura instantánea de la cámara frigorífica ($T_{room}$), consigna del termostato, histéresis y estado on/off del relé de frío.
- **Tuberías y vacío:** Velocidad media del refrigerante ($v$), pérdida de carga Darcy-Weisbach ($\Delta P$), presión de vacío en micras de Hg ($P_{vac}$) y masa de humedad remanente.

**Regla de Congelación:** Ninguna ecuación de `DynamicSolver` ni `R134aModel` ha sido alterada en esta fase.

---

## 2. Qué es Estado de Montaje

El **Estado de Montaje** pertenece al entorno de **Taller (Workshop)** y describe la topología de interconexión física entre los equipos antes o durante la puesta en marcha:
- Está representado en la clase [`WorkshopState`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/workshop_state.dart#L6).
- **Componentes y puertos interconectados:** Conjunto de tuberías trazadas por el alumno (`WorkshopPipeConnection`), uniendo puertos de salida con puertos de entrada (ej. `comp_out -> cond_in`, `cond_out -> exp_in`, `exp_out -> evap_in`, `evap_out -> comp_in`).
- **Etapa procedimental de puesta en servicio:** Paso actual dentro del enum `CommissioningStep` (1. Montaje de tuberías $\to$ 2. Prueba de estanqueidad con N₂ $\to$ 3. Vacío y deshidratación $\to$ 4. Carga pesada de R-134a $\to$ 5. Puesta en marcha).
- **Certificaciones de prueba:** Flags booleanos de estanqueidad verificada (`leakTestPassed`), vacío profundo alcanzado (`vacuumCompleted`, $< 500\ \mu\text{m}$) y masa pesada cargada (`chargedMassGrams = 250\ \text{g}`).

Este estado es puramente topológico y procedimental; no participa en el cálculo termodinámico continuo hasta que el circuito está cerrado y se autoriza el arranque.

---

## 3. Qué es Estado de Interacción

El **Estado de Interacción** registra las acciones intencionales, discretas y reversibles ejecutadas por el usuario:
- Arrancar la máquina (`engine.start()`) o detenerla (`engine.pause()`).
- Modificar las RPM del compresor, consigna de temperatura del termostato o apertura manual de la TXV mediante sliders o botones.
- Conectar o desconectar una tubería en el taller frigorífico.
- Pulsar los pulsadores de presurización con nitrógeno, encendido de bomba de vacío o inyección de carga de gas.
- Inyectar una perturbación guiada de laboratorio (ej. bloqueo de flujo de aire en condensador o aumento de carga térmica en cámara).

Cada acción discreta del usuario recibe una etiqueta descriptiva legible y una categoría (`UserActionCategory.simulation`, `workshop`, `experiment`, `thermostat`, etc.) antes de registrarse en el historial.

---

## 4. Qué es Estado Visual

El **Estado Visual** comprende los artefactos y efectos gráficos transitorios que facilitan la comprensión intuitiva al usuario pero **NO constituyen magnitudes físicas persistentes**:
- Posiciones espaciales $x, y$ de las burbujas o partículas de refrigerante en el canvas.
- Ángulo instantáneo de rotación gráfica de las aspas del ventilador o del cigüeñal 2.5D.
- Filtro de amortiguamiento de la aguja analógica de los manómetros Bourdon (`_displayedPressureBar += (\dots) \times 0.35`).
- Pestaña seleccionada en el banco de instrumentos o índice de navegación de pantallas.
- Estados de animación de `AnimationController` o `Ticker`.

**Principio de Restauración:** El estado visual **nunca se almacena en los snapshots**. Tras cualquier restauración de estado, la capa visual se reconstruye y proyecta reactivamente desde el estado físico restaurado.

---

## 5. Cómo funciona Snapshot

El sistema de instantáneas está formalizado en [`AppSnapshot`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/app_snapshot.dart#L19):
1. **Inmutabilidad y Aislamiento:** Un `AppSnapshot` solo almacena estructuras de datos inmutables (`SimulationState`, `WorkshopState`, `EducationalExperiment`).
2. **Desacoplamiento Estricto:** Está garantizado al 100% que ningún snapshot guarda punteros a `BuildContext`, `Widget`, `Element`, `TickerProvider`, `Timer`, `StreamSubscription` ni callbacks dinámicos.
3. **Punto de Retorno Previo:** Cada vez que el motor o el taller va a ejecutar una acción de usuario, [`SessionCoordinator`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/session_coordinator.dart#L14) captura un snapshot del estado inmediatamente anterior y lo traslada a la cima de la pila de deshacer.

---

## 6. Cómo funciona Undo (Deshacer)

1. El usuario pulsa `↶ DESHACER` en la barra de control superior ([`SessionControlBar`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/presentation/widgets/control_bar/session_control_bar.dart#L7)).
2. [`HistoryManager.undo()`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/history_manager.dart#L44) comprueba que `canUndo == true`.
3. El estado actual se clona y se deposita en la pila de rehacer (`_redoStack`).
4. Se extrae el último snapshot de la pila de deshacer (`_undoStack.removeLast()`).
5. Se aplican los estados al motor y al taller:
   - `_workshopState` adopta el montaje previo.
   - `engine.restoreState(snapshot.simulationState)` asienta los balances físicos instantáneos en $dt = 0.0\ \text{s}$.
6. Si el estado restaurado tenía `isRunning: true`, el bucle de integración física de 20 Hz continúa calculando inmediatamente desde ese instante. Si estaba parado, permanece en pausa.

---

## 7. Cómo funciona Redo (Rehacer)

1. El usuario pulsa `↷ REHACER`.
2. [`HistoryManager.redo()`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/history_manager.dart#L54) comprueba que `canRedo == true`.
3. El estado actual se traslada a `_undoStack`.
4. Se extrae el último snapshot de `_redoStack`.
5. Se restaura dicho snapshot con `_applySnapshot(targetSnapshot)`.
6. **Regla de Ramificación Limpia (Sección 17):** Si el usuario ejecuta cualquier acción nueva tras haber hecho uno o más `Undo`, `_redoStack.clear()` se ejecuta de forma inmediata e incondicional.

---

## 8. Cómo funciona Reset Practice (Reiniciar Práctica)

- **Objetivo:** Permitir al alumno repetir una práctica de montaje o ensayo guiado que salió mal sin destruir su instalación principal.
- **Acción:**
  - Restablece el taller a [`WorkshopState.initial()`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/state/workshop_state.dart#L32) (etapa 1 de montaje sin tuberías).
  - Si hay un experimento pedagógico activo (`engine.activeExperiment != null`), reinicia los parámetros a la línea base y fase inicial de estabilización.
  - **No altera** parámetros de la máquina que no formaban parte de la práctica ni borra el historial previo.

---

## 9. Cómo funciona Reset Installation (Reiniciar Instalación)

- **Objetivo:** Devolver la máquina física a las condiciones nominales de fábrica.
- **Requisito de Seguridad:** Solicita confirmación explícita mediante un cuadro de diálogo modal antes de ejecutarse:
  > *"¿Reiniciar la instalación? Se perderán los cambios realizados en el circuito, tuberías y actuadores desde el último estado guardado."*
- **Acción:**
  1. Detiene la simulación física continua (`engine.pause()`).
  2. Recarga el circuito canónico [`BasicCyclePreset.create()`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/domain/models/basic_cycle_preset.dart#L12).
  3. Elimina averías inyectadas (suciedad en condensador $0.0$, ventiladores 100% operativos).
  4. Restablece actuadores nominales (2900 RPM, TXV 45% automática).
  5. Asienta las presiones igualadas a temperatura ambiente.

---

## 10. Cómo funciona Reset All (Reiniciar Todo)

- **Objetivo:** Devolver FrigoLab al estado inicial global completo como recién instalada la aplicación.
- **Requisito de Seguridad:** Solicita confirmación mediante un diálogo crítico de advertencia:
  > *"¿Reiniciar FrigoLab? La instalación, prácticas, montajes y configuración volverán a su estado inicial y el historial de acciones se vaciará. El progreso educativo permanente no se eliminará."*
- **Acción:**
  1. Ejecuta `resetInstallation()`.
  2. Vacía íntegramente las pilas de Undo y Redo (`historyManager.clearHistory()`).
  3. **REGLA ABSOLUTA:** **NO borra** [`ProgressTracker`](file:///C:/Users/JFS24/.gemini/antigravity/scratch/frigolab/lib/education/lessons/progress_tracker.dart#L4). Las lecciones completadas, los conceptos dominados y el expediente del alumno quedan preservados intactos.

---

## 11. Qué Estados NO se Guardan

Para evitar fugas de memoria, sobrecarga computacional y estados incoherentes, quedan terminantemente excluidos de los snapshots:
1. **Pasos numéricos de simulación a 20 Hz:** Integraciones físicas periódicas de $dt = 0.05\ \text{s}$ no generan snapshots de undo.
2. **Punteros a widgets o árboles de elementos:** Cero referencias a `BuildContext`, `State<Widget>` o widgets de Flutter.
3. **Controladores de hardware o renderizado:** `AnimationController`, `Ticker`, `Paint`, `Path`.
4. **Timers vivos o sockets:** Punteros a `Timer.periodic`.
5. **Posiciones efímeras de partículas:** La posición de cada gota o burbuja en la tubería se regenera dinámicamente según la velocidad $v$ del estado restaurado.

---

## 12. Cómo se Garantiza la Consistencia Física

1. **Determinismo Numérico Estricto:** La prueba de regresión formal demuestra que $A \to X \to B \to \text{UNDO} \implies A' == A$, verificando igualdad matemática de presiones, temperaturas, entalpías y masas.
2. **Conservación de la Energía (Primer Principio):** Tras cualquier secuencia de Undo, Redo o Reset, el solver físico continúa satisfaciendo el balance energético $\dot{Q}_c \approx \dot{Q}_e + W_{comp}$.
3. **Paso de Integración Constante:** El paso temporal $\Delta t = 0.05\ \text{s}$ (20 Hz) permanece inalterado.
4. **Cero Aleatoriedad:** La base de código contiene **0 generadores aleatorios (`Random`)**; todas las transiciones y variables son rigurosamente deterministas.
