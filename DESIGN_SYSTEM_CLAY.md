# Especificación de diseño — Claymorfismo Kovra

Basado en la lectura de `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/features/dashboard/screens/dashboard_screen.dart` y `lib/features/auth/screens/login_screen.dart`. La app tiene tono profesional-financiero, con un azul corporativo fuerte (`#154D86`) como identidad, gradientes en headers, tarjetas blancas con sombra plana, y radios ya redondeados (12–28px) — es decir, el terreno ya está a mitad de camino hacia clay. El público (cobradores en campo, con sol y movimiento) exige que la estética "inflada" nunca le gane a la legibilidad: por eso cada color de texto propuesto abajo fue validado contra contraste WCAG, no solo elegido "a ojo".

---

## 1. Paleta clay

### Por qué no puede ir sobre blanco puro
El efecto clay depende de que la sombra clara (luz) y la sombra oscura (sombra) sean visibles contra la superficie. Sobre `#FFFFFF` puro, la sombra clara (`#FFFFFF` u otro casi-blanco) se vuelve invisible: solo se ve la sombra oscura, y el elemento parece "con sombra caída" en vez de "inflado". Se necesita un fondo con algo de valor tonal (ni blanco ni gris neutro) contra el cual ambas sombras destaquen.

### Tokens propuestos

| Token | Hex | Uso |
|---|---|---|
| `backgroundClay` | `#E7EDF6` | Fondo global de pantalla (reemplaza `AppColors.background` actual `#F7F8FA`) |
| `surfaceClay` | `#F2F6FB` | Superficie de tarjetas/inputs en estado "raised" (default). Un paso más clara que el fondo |
| `surfaceClayPressed` | `#DCE4F0` | Relleno de tarjetas/botones en estado "pressed/inset" (más oscura que el fondo, simula hundimiento) |
| `shadowLight` | `#FFFFFF` | Sombra clara (luz), ver opacidades exactas en sección 4 |
| `shadowDark` | `#A9B7CE` | Sombra oscura (sombra), azul-grisáceo, nunca negro puro |

Se eligió una familia azul-grisácea pastel (no beige/terracota) porque el ancla de marca es un azul frío (`#154D86`); un fondo cálido generaría disonancia cromática con el primario.

### Texto: nuevos tokens necesarios

| Token | Hex | Contraste sobre `backgroundClay` | Uso |
|---|---|---|---|
| `textPrimary` (ink) | `#1B2430` | 13.3:1 | Títulos, cuerpo de texto principal |
| `textSecondary` | `#4B5768` | 6.2:1 | Captions, metadata, labels secundarios. **Reemplaza `neutralGray` para texto** (ese cae a 4.04:1, por debajo del mínimo AA 4.5:1) |
| `neutralGray` (`#64748B`) | — | 4.04:1, pero ≥3:1 | Se conserva solo para iconos, bordes, dividers y estados disabled — no para texto de tamaño normal |

### Colores semánticos: ¿funcionan tal cual como texto?

| Color | Hex | Contraste vs `backgroundClay` | Veredicto |
|---|---|---|---|
| `success` | `#16A34A` | 2.80:1 | **No apto como texto.** Solo como relleno de badge/chip o ícono |
| `danger` | `#DC2626` | 4.10:1 | Al límite. Sirve para texto grande/negrita (≥16px bold), no para caption pequeño |
| `warning` | `#F59E0B` | 1.82:1 | **No apto como texto en ningún tamaño.** Solo como relleno (con texto oscuro encima) |

**Nuevos tokens "-Strong" para texto sobre superficies claras:**

| Token | Hex | Contraste vs `backgroundClay` |
|---|---|---|
| `successStrong` | `#166534` | 6.05:1 |
| `dangerStrong` | `#B91C1C` | 5.50:1 |

**Regla de uso:** `success`/`danger`/`warning` (valores actuales) quedan reservados para **rellenos** (badges, chips, fondos de botón, barras de severidad) y **íconos**. Nunca como `color:` de un `Text` sobre `backgroundClay`/`surfaceClay`. Para texto de estado usar `successStrong`/`dangerStrong`.

La escala de severidad de mora existente (`severityMild #F6C453`, `severityHigh #F97316`, `severityLoss #1F2937`) sigue la misma regla — son colores de fill/badge, no de texto suelto, sin cambio de valor.

---

## 2. Escala de radios

| Token | Valor | Uso |
|---|---|---|
| `radiusXs` | 8px | Chips pequeños, badges compactos, checkboxes |
| `radiusSm` | 12px | Inputs de formulario, botones estándar |
| `radiusMd` | 16px | Tarjetas de contenido: cliente_card, cuota_card, tiles de lista, dashboard_stat_tile |
| `radiusLg` | 20px | Tarjetas destacadas, modales, bottom sheets, tarjeta de login |
| `radiusXl` | 28px | Headers hero con gradiente (coincide con el radio actual del header, no requiere cambio ahí) |
| `radiusPill` | 999px | Tabs tipo pill, badges de estado, avatares, FAB |

Absorbe el rango disperso de 4–28px actual en 6 pasos consistentes.

---

## 3. Escala de spacing

Grid de 4, confirmado sin cambios: `4 / 8 / 12 / 16 / 20 / 24 / 32`

Se agrega un paso opcional: `spaceXxl = 40px` — separación entre secciones grandes.

---

## 4. Sombra clay (`BoxShadow` para Flutter)

### Estado "raised" (default — tarjetas, botones no presionados, header)

```dart
boxShadow: [
  BoxShadow(
    color: AppColors.shadowDark.withOpacity(0.35), // #A9B7CE
    offset: const Offset(6, 6),
    blurRadius: 16,
  ),
  BoxShadow(
    color: AppColors.shadowLight.withOpacity(0.85), // #FFFFFF
    offset: const Offset(-6, -6),
    blurRadius: 16,
  ),
]
```

La sombra oscura va abajo-derecha (luz simulada viniendo de arriba-izquierda), la clara arriba-izquierda — no invertir. Sobre `surfaceClay`, ambas sombras deben dibujarse en el `Container` padre, nunca directamente sobre `backgroundClay` global.

### Estado "pressed / inset" (botones activos, tab seleccionado, input con foco)

Flutter no soporta `inset` nativo en `BoxShadow`. Alternativa visualmente equivalente y simple:

```dart
boxShadow: [
  BoxShadow(
    color: AppColors.shadowDark.withOpacity(0.20),
    offset: const Offset(1, 1),
    blurRadius: 3,
  ),
],
// + color de fondo cambia de surfaceClay a surfaceClayPressed (#DCE4F0)
// + opcionalmente, escala del widget a 0.97 con AnimatedScale (150ms) al presionar
```

Consistente con el patrón que ya usa `_PillTabs` en el dashboard actual (tab seleccionado = fill sólido). Efecto inset "perfecto" vía `CustomPainter` queda como mejora futura opcional, no bloquea el rollout inicial.

---

## 5. Tipografía

### Fuente

Recomendación: **Manrope** vía `google_fonts` (agregar dependencia nueva a `pubspec.yaml`). Terminaciones redondeadas acordes al lenguaje clay, buena legibilidad en tamaños chicos, rango completo de pesos (200–800), buen soporte numérico (clave para una app que muestra montos constantemente).

Alternativa aceptable si se quiere evitar dependencia nueva: fuente de sistema (Roboto/San Francisco).

Para montos: activar `FontFeature.tabularFigures()` para alinear cifras en columna.

### Escala de pesos por rol

| Rol | Tamaño | Peso | Color por defecto |
|---|---|---|---|
| Título (H1) | 22–24px | 800 (ExtraBold) | `textOnPrimary` sobre header con gradiente, `textPrimary` sobre superficies claras |
| Subtítulo (H2) | 18–20px | 700 (Bold) | `textPrimary` |
| Subtítulo menor | 15–16px | 600 (SemiBold) | `textPrimary` |
| Cuerpo | 14–15px | 500 (datos importantes) / 400 (párrafos largos) | `textPrimary` |
| Caption | 12–13px | 500 (Medium) — nunca menos | `textSecondary` |

Regla dura: no usar pesos 300/400 en tamaños menores a 13px — con sol directo el texto liviano se "lava" visualmente.

---

## 6. Accesibilidad y legibilidad (uso en campo, con sol)

1. `textPrimary` (`#1B2430`) sobre `backgroundClay`: 13.3:1 — excelente, sobre AAA.
2. `textSecondary` (`#4B5768`) sobre `backgroundClay`: 6.2:1 — pasa AA cómodamente.
3. Colores semánticos como texto directo fallan o están al límite (ver sección 1) — usar `successStrong`/`dangerStrong` para texto de estado.
4. Regla de fills: badge/chip/botón con `success`/`danger`/`warning`/`severity*` de fondo debe llevar texto de color adecuado al brillo del fondo — no asumir blanco automáticamente (ej. sobre `warning` `#F59E0B`, usar `textPrimary`, no blanco).
5. El efecto clay no debe volverse "neumorfismo puro" (que sacrifica contraste por estética): se mitiga con (a) salto de tono real entre `backgroundClay` y `surfaceClay`, (b) sombra oscura con opacidad 0.35 (más marcada que neumorfismo típico ~0.1-0.15) para que se note con sol directo, (c) texto siempre en `textPrimary`/`textSecondary` de alto contraste, nunca dependiendo de la sombra para "leer" el elemento.
6. Tamaño mínimo de caption: 12px. Targets táctiles: mínimo 48px de alto (ya cumplido por `ElevatedButton` actual, mantener en botones clay nuevos).

---

## Resumen de tokens nuevos/modificados para `app_colors.dart`

```
backgroundClay        #E7EDF6   (reemplaza background)
surfaceClay            #F2F6FB
surfaceClayPressed     #DCE4F0
shadowLight             #FFFFFF
shadowDark              #A9B7CE
textPrimary              #1B2430
textSecondary           #4B5768
successStrong            #166534
dangerStrong              #B91C1C
```

`AppColors.primary` (`#154D86`), `accent`, y los semánticos base (`success`/`danger`/`warning`) se mantienen sin cambio de valor — solo cambia su regla de uso (fill/ícono, no texto suelto).
