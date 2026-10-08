# FRIGOLAB — INFORME DE IMPLEMENTACIÓN: SIMULADOR 3D VOLUMÉTRICO E INSTRUMENTACIÓN IN SITU
## Rediseño Profundo del Simulador Frigorífico Industrial

**Fecha:** Octubre 2026  
**Proyecto:** FrigoLab — Laboratorio Virtual de Refrigeración Industrial  
**Estado:** Implementado, validado con 67/67 tests y análisis estático limpio (0 issues)  
**Dispositivo de Referencia:** Google Pixel 7 (Android 14)  

---

## 1. RESUMEN EJECUTIVO

Se ha completado con éxito la fase de rediseño profundo del **SIMULADOR de FrigoLab**. Esta transformación sustituye la representación 2D plana y comprimida por un entorno **3D volumétrico isométrico y fotorrealista**, donde **el solver termodinámico físico congelado es la única fuente de verdad**.

### Logros Principales:
1. **Espacio Virtual Descongestionado ($1380 \times 780\text{ px}$):** Separación nítida y física de la Cámara Frigorífica, Compresor, Condensador, Calderín/Línea de Líquido y TXV.
2. **Modelos Volumétricos 3D Procedurales:** Renderizado acelerado de alta fidelidad con iluminación cenital, brillos especulares, texturas de aletas, remaches, carcasas metálicas y animación cinemática.
3. **Trazado Continuo de Tuberías:** Líneas con volumen cilíndrico, bucle antivibratorio omega en descarga, coquilla de elastómero negro (Armaflex) en aspiración y pasamuros sellados en la pared sándwich de la cámara.
4. **14 Instrumentos Físicos In Situ:** Manómetros Bourdon de aguja y escala real, termómetros de inmersión en tubería, presostato Danfoss KP15 con fuelles LP/HP, visor de líquido con burbujeo de gas flash ($SC < 2\text{ K}$), mirilla de aceite en cárter, pinza amperimétrica y vacuómetro.
5. **Control Gestual Infalible con Transformación Matricial Inversa:** Desacoplamiento matemático entre pulsación táctil (TAP) y arrastre/zoom (DRAG/PINCH). Detección exacta de instrumentos y componentes sin importar el nivel de zoom o pan.
6. **Panel Contextual de Inspección Técnica (`InstrumentInspectionPanel`):** Lectura física en tiempo real, estado del fluido, ubicación física, propósito técnico y acceso directo al Explicador Pedagógico "¿POR QUÉ?".
7. **Física Congelada al 100%:** Ni una sola ecuación, parámetro termodinámico ni constante del solver fue modificada.
8. **Compatibilidad Multiplataforma Total:** Soporte vertical para móvil y modo horizontal panorámico a pantalla completa sin `RenderFlex` overflows.

---

## 2. ARQUITECTURA DE VISUALIZACIÓN 3D

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   SOLVER FÍSICO (ESTRICTAMENTE CONGELADO)              │
│       DynamicSolver · R134aModel · Circuit · SimulationState (dt=0.05s)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Estado instantáneo (presiones, entalpías,
                                    │ temperaturas, RPM, caudales, potencias)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             REGISTRO DE INSTRUMENTOS (InstallationInstrument)          │
│   14 puntos de medición física in situ -> Mapeo directo de variables   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             GESTOR DE CÁMARA Y GESTOS (Matrix4 Transform)              │
│   Pan / Pinch-Zoom / Reset View / Inversión Matricial de Coordenadas   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             MOTOR DE RENDERIZADO VOLUMÉTRICO PROCEDURAL                │
│  ├─ ColdRoom3DRenderer      (Paneles sándwich 100mm, puerta, termostato)│
│  ├─ Evaporator3DRenderer    (Batería aleteada, doble axial, bandeja)   │
│  ├─ Compressor3DRenderer    (Bancada C, silentblocks, domo, mirilla)   │
│  ├─ Condenser3DRenderer     (Marco galva, aletas densas, ventilador)   │
│  ├─ Txv3DRenderer           (Cuerpo latón 90°, capilar, bulbo sensor)  │
│  ├─ LiquidReceiver3DRenderer(Calderín, filtro, visor líquido, m_dot)   │
│  ├─ PipeSystem3DRenderer    (Cilindros 3D, Armaflex, omega, pasamuros) │
│  └─ Instruments3DRenderer   (Manómetros Bourdon, sondas, KP15, pinza)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. TECNOLOGÍA GRÁFICA IMPLEMENTADA

En lugar de depender de motores 3D pesados con texturas rasterizadas que sobrecargan la memoria y batería móvil, se implementó una arquitectura basada en **CustomPainter de alto rendimiento vectorial**:
- **Shaders y Gradientes Matemáticos:** Gradientes lineales y radiales para iluminación especular metálica (cromo pulido, acero esmaltado, latón y cobre).
- **Sombras Arrojadas Suaves:** Proyecciones de suelo mediante elipses de oclusión ambiental.
- **Tasa de Refresco de 60-120 fps:** Sincronizado mediante `TickerProvider` sin recrear objetos pesados en memoria.
- **Cero Dependencias Externas Inestables:** Puramente nativo Flutter sobre el motor Skia/Impeller.

---

## 4. ORDENAMIENTO ESPACIAL Y SEPARACIÓN FÍSICA

El canvas virtual de $1380 \times 780\text{ px}$ resuelve el amontonamiento de la versión previa:
| Zona | Rango Coordenadas $X$ | Componentes Principales |
|---|---|---|
| **Zona Fría (Cámara)** | $X = 50 \dots 470$, $Y = 70 \dots 670$ | Cámara Frigorífica, evaporador cúbico comercial, termostato dintel puerta |
| **Zona Expansión** | $X = 510 \dots 590$, $Y = 320 \dots 450$ | Válvula TXV en 90°, capilar en espiral hacia bulbo de aspiración exterior |
| **Zona Central (Compresión)** | $X = 620 \dots 840$, $Y = 460 \dots 690$ | Bancada estructural, silentblocks, compresor hermético, mirilla de aceite, caja bornes |
| **Zona Condensación** | $X = 960 \dots 1280$, $Y = 80 \dots 380$ | Condensador de tiro forzado, motoventilador axial con rejilla, vectores de calor |
| **Zona Líquido y Filtrado** | $X = 1100 \dots 1240$, $Y = 410 \dots 640$ | Calderín vertical, filtro deshidratador, visor de líquido, caudalímetro másico |

---

## 5. DETALLE DE MODELOS 3D VOLUMÉTRICOS

### 5.1. Cámara Frigorífica (`ColdRoom3DRenderer`)
- Paneles sándwich de poliuretano de 100 mm con junta machihembrada y remaches estructurales.
- Suelo reforzado antideslizante con rampa de acceso.
- Puerta frigorífica semiabierta en perspectiva con bisagras de acero inoxidable y maneta de apertura de seguridad con golpe de escape interior.
- Termostato digital en el dintel con display de 7 segmentos LED verde que muestra la temperatura real de la cámara ($T_{c\acute{a}m}$).
- Brillo frío volumétrico interior (luz LED frigorífica).

### 5.2. Evaporador Comercial (`Evaporator3DRenderer`)
- Carcasa suspendida de chapa prepintada blanca con cantoneras de protección.
- Batería de intercambio con tubos de cobre y aletas de aluminio de paso ancho (evita bloqueo por escarcha).
- Dos toberas venturi con motoventiladores axiales de 4 palas rotando a la velocidad física calculada (`evaporatorAirFlow.fanRpm`).
- Bandeja colectora de condensados con pendiente hacia desagüe con sifón en P.
- Vectores dinámicos de absorción de calor $\dot{Q}_e$ proyectados en color cian frío.

### 5.3. Compresor Hermético (`Compressor3DRenderer`)
- Bancada de perfiles de acero normalizado fijada al suelo mediante 4 amortiguadores de caucho (*silentblocks*).
- Cuerpo cilíndrico ovoide con cúpula superior convexa, cordón perimetral de soldadura de estanqueidad y acabado esmaltado azul industrial brillante con destellos especulares.
- Caja de conexiones eléctricas IP55 con triángulo de aviso de peligro eléctrico.
- Válvulas de servicio Rotalock de 3 vías con tomas de manómetro independientes.
- Mirilla de nivel de aceite en el tercio inferior del cárter mostrando fluido lubricante ámbar.
- Micro-vibración cinemática dependiente de las RPM del cigüeñal.

### 5.4. Condensador de Tiro Forzado (`Condenser3DRenderer`)
- Estructura galvanizada con patas de anclaje exterior.
- Paquete aleteado de aluminio de alta densidad atravesado por circuitos de horquillas de cobre.
- Tobera aerodinámica con rejilla de protección electrocincada y ventilador axial de 5 palas rotando proporcionalmente a `condenserAirFlow.fanRpm`.
- Indicador visual de alerta de "VENTILADOR PARADO" si se simula avería del motor de condensación.
- Vectores térmicos ascendentes de disipación de calor $\dot{Q}_c$ en color naranja cálido.

### 5.5. Válvula de Expansión Termostática (`Txv3DRenderer`)
- Cuerpo forjado en latón dorado en ángulo de 90° con tuerca inferior de ajuste de recalentamiento estático.
- Cabezal termostático superior en acero inoxidable que aloja la membrana elástica de accionamiento.
- Tubo capilar de cobre en espiral elástica que conecta la parte superior de la membrana con el bulbo palpador.
- Bulbo palpador cilíndrico fijado a la tubería de aspiración mediante abrazadera metálica.

### 5.6. Calderín, Filtro y Visor (`LiquidReceiver3DRenderer`)
- Calderín cilíndrico vertical con fondos toriesféricos convexos y columna de nivel.
- Filtro deshidratador molecular hermético con flecha grabada de dirección de flujo.
- Visor de líquido con mirilla transparente y corona indicadora de humedad química (verde = seco, amarillo = húmedo).
- Formación dinámica de burbujas de vapor flash cuando el subenfriamiento cae por debajo de $2\text{ K}$ ($SC < 2\text{ K}$).
- Caudalímetro másico digital con display de lectura continua en g/s y kg/h.

---

## 6. RED DE INSTRUMENTACIÓN IN SITU (14 PUNTOS)

| Tag | Tipo | Ubicación Física Real | Variable Termodinámica Mapeada |
|---|---|---|---|
| **PI-01** | Manómetro Bourdon Baja | Válvula de servicio de aspiración | Presión de evaporación $P_o$ y $T_{sat}(P_o)$ |
| **PI-02** | Manómetro Bourdon Alta | Toma de descarga de culata | Presión de condensación $P_k$ y $T_{sat}(P_k)$ |
| **TI-01** | Termómetro de Contacto | Tubería de descarga de cobre | Temperatura de descarga $T_{dis}$ |
| **TI-02** | Termómetro de Contacto | Tubería de líquido (salida filtro) | Temperatura de líquido $T_{liq}$ y cálculo de Subcooling $SC$ |
| **TI-03** | Termómetro de Inmersión | Distribuidor venturi entrada evaporador | Temperatura mezcla $T_o$ y título $x$ |
| **TI-04** | Termómetro de Contacto | Bulbo sensor de aspiración | Temperatura de aspiración $T_{asp}$ y cálculo de Superheat $SH$ |
| **TT-01** | Sonda Ambiente Digital | Dintel puerta / ambiente cámara | Temperatura de aire de cámara $T_{c\acute{a}m}$ |
| **TT-02** | Sonda Ambiente Digital | Aire exterior batería condensador | Temperatura ambiente exterior $T_{amb}$ |
| **PS-01** | Presostato Dual KP15 | Bancada central tomas capilares HP/LP | Disparo de seguridad LP ($<0.5\text{ bar}$) o HP ($>18\text{ bar}$) |
| **FI-01** | Caudalímetro Másico | Línea de líquido antes de TXV | Caudal másico instantáneo $\dot{m}$ (g/s y kg/h) |
| **SG-01** | Visor de Líquido | Antes de válvula de expansión | Presencia de vapor flash por bajo subenfriamiento |
| **LG-01** | Mirilla de Aceite | Cárter inferior del compresor | Nivel de aceite POE y espumación |
| **EM-01** | Pinza Amperimétrica | Bornes motor compresor | Intensidad de línea ($A$), potencia ($kW$), $\cos \varphi$ |
| **VI-01** | Vacuómetro Electrónico | Toma Schräder de aspiración | Presión de vacío (mbar / $\mu\text{mHg}$) en procesos de evacuación |

---

## 7. CONTROL GESTUAL ROBUSTO: TAP VS PAN/ZOOM

El problema de las pulsaciones fantasma o del desalineamiento de coordenadas al hacer zoom fue resuelto implementando un detector desacoplado:
1. **Detección de Intención:** En `onScaleStart`, se registra el punto focal `_startFocalPoint` y la matriz de partida `_startMatrix`.
2. **Umbral de Arrastre:** En `onScaleUpdate`, si la distancia euclídea acumulada supera los $4\text{ px}$ o el factor de escala difiere en más del 2%, se activa la bandera `_pointerMoved = true` y se aplica la transformación afín a la cámara.
3. **Pulsación Pura (TAP):** En `onScaleEnd`, si `_pointerMoved == false`, el gesto se clasifica como una pulsación pura.
4. **Transformación Matricial Inversa:** Se invierte la matriz de cámara:
   $$\mathbf{M}^{-1} = \text{Matrix4.tryInvert}(\mathbf{M})$$
   $$\mathbf{p}_{mundo} = \mathbf{M}^{-1} \cdot \mathbf{p}_{pantalla}$$
5. **Hit-Testing Jerárquico:** Se evalúa primero la colisión radial con cada uno de los 14 instrumentos ($\text{radio} \le 28\text{ px}$). Si ningún instrumento fue pulsado, se evalúan los bounding boxes de los 4 componentes mayores.
6. **Controles Flotantes:** Botones `[ + ZOOM ]`, `[ - ZOOM ]` y `[ ⟲ CENTRAR INSTALACIÓN ]` para restablecer inmediatamente la perspectiva inicial.

---

## 8. RESULTADOS DE VERIFICACIÓN Y PRUEBAS

- **Análisis Estático de Dart:**
  `flutter analyze` $\rightarrow$ **0 issues found!**
- **Batería de Pruebas Automatizadas:**
  `flutter test` $\rightarrow$ **67 / 67 tests superados (100% éxito)**
  - Tests de termodinámica R-134a.
  - Tests del solver y balance de energía del Primer Principio ($Q_c \approx Q_e + W$).
  - Tests del modelo eléctrico y cinemático.
  - Tests de diagramas P-h y T-s.
  - Tests de gestión de estado, Undo/Redo y Determinismo estricto.
  - Tests de instrumentación 3D, mapeo de lecturas y transformación matricial inversa.
  - Smoke tests de interfaz y ausencia de desbordamientos `RenderFlex`.

---

## 9. CONCLUSIÓN Y ESTADO FINAL

FrigoLab cuenta ahora con una **experiencia de simulación de alta gama para refrigeración industrial**. Combina la precisión físico-matemática rigurosa con una interfaz visual inmersiva, clara y pedagógica. El alumno puede tocar cualquier tubería o instrumento para ver qué está sucediendo físicamente dentro de la máquina en tiempo real.
