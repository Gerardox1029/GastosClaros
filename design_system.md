# GastosClaros — Design System

## Identidad Visual

| Atributo     | Valor                                           |
|--------------|--------------------------------------------------|
| **Vibe**     | Simple, intuitivo, moderno                       |
| **Estilo**   | Dark mode con acentos vibrantes                  |
| **Audiencia**| Usuario individual (Ditox) — control de gastos   |

---

## 🎨 Paleta de Colores

### Colores Principales

| Nombre               | HEX       | Uso                                              |
|----------------------|-----------|--------------------------------------------------|
| **Deep Purple BG**   | `#1E1B2E` | Fondo principal de la app                        |
| **Surface Purple**   | `#2D2845` | Tarjetas, paneles, Bottom Nav                    |
| **Accent Purple**    | `#A855F7` | Botones primarios, acentos, indicadores activos  |
| **Light Purple**     | `#C084FC` | Hover states, acentos secundarios                |
| **Muted Purple**     | `#6B5B95` | Texto secundario, bordes sutiles                 |

### Colores Semánticos

| Nombre               | HEX       | Uso                                              |
|----------------------|-----------|--------------------------------------------------|
| **Success Green**    | `#22C55E` | Montos de ingreso (`+S/. XX.XX`), confirmaciones |
| **Danger Red**       | `#EF4444` | Montos de gasto (`-S/. XX.XX`), errores          |
| **Warning Amber**    | `#F59E0B` | Advertencias, estados pendientes                 |
| **White Text**       | `#F8FAFC` | Texto principal sobre fondos oscuros             |
| **Muted Text**       | `#94A3B8` | Texto secundario, placeholders                   |

### Gradientes

```dart
// Gradiente principal (fondo de splash, headers)
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1E1B2E), Color(0xFF2D2845)],
)

// Gradiente de acento (botón "+", CTAs)
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
)
```

---

## ✏️ Tipografía

| Elemento            | Font Family       | Peso       | Tamaño | Color       |
|---------------------|-------------------|------------|--------|-------------|
| Título principal    | `Poppins`         | Bold (700) | 28sp   | White Text  |
| Subtítulo splash    | `Poppins`         | Italic (400)| 14sp  | Muted Text  |
| Saldo actual        | `Space Grotesk`   | Bold (700) | 42sp   | White Text  |
| Monto ingreso       | `Space Grotesk`   | Semi (600) | 18sp   | Success Green|
| Monto gasto         | `Space Grotesk`   | Semi (600) | 18sp   | Danger Red  |
| Texto body          | `Poppins`         | Regular (400)| 14sp | White Text  |
| Texto secundario    | `Poppins`         | Regular (400)| 12sp | Muted Text  |
| Labels de formulario| `Poppins`         | Medium (500)| 13sp  | Muted Text  |
| Bottom Nav label    | `Poppins`         | Medium (500)| 11sp  | Muted Purple|

### Google Fonts a incluir:
- **Poppins** — UI general, títulos, body text.
- **Space Grotesk** — Números, montos, saldos (más legible para cifras).

---

## 🔲 Formas y Bordes

| Elemento             | Border Radius | Observaciones                                    |
|----------------------|---------------|--------------------------------------------------|
| Tarjetas             | `16px`        | Bordes suaves y redondeados                      |
| Botones primarios    | `12px`        | Redondeados pero no pill-shaped                  |
| Botón "+"            | `50%` (circle)| Circular, elevado sobre Bottom Nav               |
| Inputs de formulario | `12px`        | Consistente con botones                          |
| Modales/Pop-ups      | `24px` (top)  | Bottom sheet con esquinas superiores redondeadas |
| Botón dashed "Agregar"| `12px`       | Borde discontinuo (`dashed`) en Muted Purple     |
| Cards de captura     | `12px`        | Scroll horizontal, bordes consistentes           |

---

## ✨ Efectos Visuales

### Glassmorphism (Modales y Pop-ups)

```dart
// Fondo difuminado detrás del modal
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
  child: Container(
    decoration: BoxDecoration(
      color: Color(0xFF2D2845).withOpacity(0.85),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      border: Border.all(
        color: Color(0xFFA855F7).withOpacity(0.15),
        width: 1,
      ),
    ),
  ),
)
```

### Elevación y Sombras

```dart
// Sombra del botón "+" central
BoxShadow(
  color: Color(0xFFA855F7).withOpacity(0.4),
  blurRadius: 20,
  spreadRadius: 2,
  offset: Offset(0, 4),
)

// Sombra sutil para tarjetas
BoxShadow(
  color: Colors.black.withOpacity(0.2),
  blurRadius: 10,
  offset: Offset(0, 4),
)
```

---

## 🎬 Animaciones

### Transiciones de Pantalla

| Transición                    | Tipo             | Duración   | Curva            |
|-------------------------------|------------------|------------|------------------|
| Splash → Dashboard            | FadeTransition   | 1500ms     | `Curves.easeOut` |
| Abrir modal (bottom sheet)    | SlideTransition  | 350ms      | `Curves.easeOutCubic` |
| Cerrar modal                  | SlideTransition  | 250ms      | `Curves.easeIn`  |

### Micro-Animaciones

| Elemento                      | Animación        | Duración   | Detalle                         |
|-------------------------------|------------------|------------|---------------------------------|
| Items de lista                | Staggered Fade   | 200ms each | Aparecen secuencialmente        |
| Botón "+" presionado          | Scale bounce     | 150ms      | `1.0 → 0.9 → 1.0`            |
| Saldo actual (cambio)        | CountUp animation| 800ms      | Anima numéricamente al nuevo valor |
| Progress bar (IA)             | Animated width   | Continuo   | Barra progresiva 0-100%        |
| Spinner de carga              | Rotate + Fade    | Continuo   | `CircularProgressIndicator` con color Accent Purple |

### Loading Spinner Global

```dart
// Spinner dinámico para todos los estados de carga
Center(
  child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
    strokeWidth: 3.0,
  ),
)
```

---

## 📐 Espaciado y Layout

| Token           | Valor  | Uso                                    |
|-----------------|--------|----------------------------------------|
| `spacing-xs`    | `4px`  | Gaps mínimos entre iconos y texto      |
| `spacing-sm`    | `8px`  | Padding interno de chips, tags         |
| `spacing-md`    | `16px` | Padding estándar de tarjetas y secciones|
| `spacing-lg`    | `24px` | Separación entre secciones principales |
| `spacing-xl`    | `32px` | Margen superior/inferior de pantalla   |
| `spacing-2xl`   | `48px` | Separación de bloques mayores          |

---

## 📱 Bottom Navigation Bar

```
┌────────────────────────────────────────────────────┐
│                                                    │
│   🏠 Saldo        ➕ (elevated)       📊 Gastos   │
│                                                    │
└────────────────────────────────────────────────────┘
```

- **Fondo:** `Surface Purple (#2D2845)` con borde superior sutil.
- **Botón central "+":** Circular, gradiente Accent Purple, elevado `-20px` sobre la barra, con sombra glow.
- **Items activos:** Accent Purple icon + label.
- **Items inactivos:** Muted Purple icon + label.

---

## 🔤 Formato de Moneda y Fecha

| Dato              | Formato                          | Ejemplo                    |
|-------------------|----------------------------------|----------------------------|
| Moneda (ingreso)  | `+S/. {monto}`                   | `+S/. 12.50`              |
| Moneda (gasto)    | `-S/. {monto}`                   | `-S/. 45.00`              |
| Saldo principal   | `S/. {monto}`                    | `S/. 1,250.50`            |
| Fecha corta       | `dd/MM/yyyy`                     | `15/10/2026`              |
| Fecha con hora    | `dd/MM/yyyy HH:mm`              | `15/10/2026 14:30`        |
| Zona horaria      | UTC-5 (Perú)                     | —                          |
