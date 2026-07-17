# Design System: Muhimmat Altawseel (Delivery Management System)

## 1. Visual Theme & Atmosphere
A highly functional, "Cockpit Dense" (Density 8/10) interface with "Offset Asymmetric" layouts (Variance 5/10) and fluid but snappy spring-physics motion (Motion 5/10). The atmosphere is industrial yet refined—like a modern logistics command center. It prioritizes data density, scanning speed, and operational clarity without feeling cluttered.

## 2. Color Palette & Roles
- **Canvas White** (`#F8FAFC` - Slate 50) — Primary background surface for the application.
- **Pure Surface** (`#FFFFFF`) — Card, table, and container fill.
- **Charcoal Ink** (`#0F172A` - Slate 900) — Primary text, deep depth elements.
- **Muted Steel** (`#64748B` - Slate 500) — Secondary text, descriptions, table headers, metadata.
- **Whisper Border** (`rgba(226, 232, 240, 0.6)`) — Card borders, 1px structural division lines.
- **Cobalt Slate** (`#0284C7` - Light Blue 600) — Single accent for CTAs, active states, and focus rings. (Muted saturation, professional and reliable).

## 3. Typography Rules
- **Display / Headers:** `Geist` — Track-tight, controlled scale, hierarchy established entirely through weight (Semibold/Bold) and color, not massive size.
- **Body:** `Geist` — Relaxed leading, 65ch max-width, neutral secondary color.
- **Mono (Crucial):** `Geist Mono` — Used strictly for all numerical data: salaries, order counts, dates, times, and IDs. Because this is a high-density dashboard, monospace numbers are mandatory for vertical scanning alignment.
- **Banned:** `Inter`, `Times New Roman`, `Georgia`, or any serif fonts. Serif fonts are strictly BANNED in this dashboard environment.

## 4. Component Stylings
- **Buttons:** Flat, no outer glow. Tactile -1px translate on active/press state. Cobalt Slate fill for primary actions; muted outline/ghost for secondary.
- **Cards & Containers:** Slightly rounded corners (0.75rem). Diffused whisper shadow only on floating elements (dropdowns, modals). For high-density data views, abandon cards entirely in favor of border-top dividers or negative space to separate rows.
- **Inputs & Forms:** Label strictly above the input, error text below. Focus ring in Cobalt Slate. Standardized gap spacing. No floating labels.
- **Loaders:** Skeletal shimmer matching the exact dimensions of the expected layout (e.g., table row skeletons). No circular spinners.
- **Empty States:** Composed, balanced illustrations or wireframes indicating how to populate data (e.g., "No orders yet. Sync platforms to begin."). Not just plain "No data" text.
- **Status Indicators / Badges:** Subtle background tints with high-contrast text. No heavy, oversaturated pills.

## 5. Layout Principles
- **Grid-First Architecture:** Rely on CSS Grid to structure complex dashboards. No flexbox percentage math (`calc(33% - ...)`) hacks.
- **Spatial Zones:** No overlapping elements. Every table, chart, or list occupies its own clear spatial zone. No absolute-positioned content stacking unless for tooltips/popovers.
- **Header / Hero Zones:** Centered headers are BANNED. Use left-aligned titles with inline data summaries or asymmetric split screens (e.g., Title on left, quick stats on right).
- **List / Feature Rows:** The generic "3 equal cards horizontally" is BANNED. Use 2-column zig-zag, asymmetrical 60/40 splits, or dense lists.
- **Containment:** Max-width containment for ultra-wide monitors (e.g., `1600px` centered for main dashboard views). Full-height sections must use `min-h-[100dvh]`.

## 6. Responsive Rules
- **Mobile-First Collapse:** All multi-column layouts must collapse to a single column below `768px`. No exceptions.
- **No Horizontal Scroll:** Horizontal overflow on mobile is a critical failure (except for intentionally scrollable data tables, which must have a visible scroll affordance).
- **Touch Targets:** All interactive elements on mobile must have a minimum `44px` tap target.
- **Typography Scaling:** Headlines scale via `clamp()`. Body text must never go below `1rem`/`14px`.

## 7. Motion & Interaction
- **Spring Physics:** Default motion uses spring physics (`stiffness: 100, damping: 20`) for a premium, weighty feel. No linear easing.
- **Staggered Orchestration:** Never mount dashboard lists instantly. Use cascade delays (waterfall reveals) for table rows and stat cards.
- **Performance:** Animate exclusively via `transform` and `opacity`. Never animate `top`, `left`, `width`, or `height`.
- **Micro-Interactions:** Subtle hover states on table rows (slight background tint change) to aid scanning.

## 8. Anti-Patterns (Strictly Banned)
- **NO emojis anywhere.** Use clean SVGs (e.g., Lucide icons) instead.
- **NO `Inter` font.**
- **NO pure black (`#000000`).**
- **NO neon/outer glow shadows.**
- **NO oversaturated accents.**
- **NO custom mouse cursors.**
- **NO generic names** in mockups (avoid "John Doe", "Acme"). Use realistic delivery names (e.g., "Ahmad Al-Sayed", "HungerStation").
- **NO fake round numbers.** Use realistic data (`SAR 4,250.50`, `142 Orders`).
- **NO overlapping elements** — clean spatial separation always.
- **NO AI copywriting clichés** ("Elevate", "Seamless", "Unleash"). Use direct, functional copy ("Manage Orders", "Calculate Salaries").
