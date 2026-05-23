---
name: Digital Intelligence
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#b9cac4'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#83948f'
  outline-variant: '#3a4a46'
  surface-tint: '#00dfc1'
  primary: '#d7fff3'
  on-primary: '#00382f'
  primary-container: '#00f5d4'
  on-primary-container: '#006c5c'
  inverse-primary: '#006b5b'
  secondary: '#a3c9ff'
  on-secondary: '#00315d'
  secondary-container: '#1493ff'
  on-secondary-container: '#002a51'
  tertiary: '#fff5ed'
  on-tertiary: '#452b00'
  tertiary-container: '#ffd39b'
  on-tertiary-container: '#845500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#26fedc'
  primary-fixed-dim: '#00dfc1'
  on-primary-fixed: '#00201a'
  on-primary-fixed-variant: '#005144'
  secondary-fixed: '#d3e3ff'
  secondary-fixed-dim: '#a3c9ff'
  on-secondary-fixed: '#001c39'
  on-secondary-fixed-variant: '#004883'
  tertiary-fixed: '#ffddb4'
  tertiary-fixed-dim: '#ffb955'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#633f00'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Sora
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Sora
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Sora
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  numeral-xl:
    fontFamily: Sora
    fontSize: 40px
    fontWeight: '600'
    lineHeight: '1.0'
    letterSpacing: -0.04em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 32px
---

## Brand & Style

The design system is engineered for a premium fintech experience that balances high-velocity digital intelligence with institutional-grade trustworthiness. It rejects the "soft wellness" aesthetic of modern consumer banking in favor of a sophisticated, immersive environment that feels like a high-end financial command center.

The visual language is a fusion of **Minimalism** and **Glassmorphism**. It utilizes deep, atmospheric depth, precision-engineered typography, and translucent surfaces to create a sense of infinite digital space. The interface should feel like an intelligent layer of data floating over a solid, secure foundation. Every interaction should evoke a feeling of "controlled power"—fast, responsive, and definitive.

## Colors

The palette is centered on a high-energy **Teal-to-Cyan gradient** that represents liquid capital and digital flow. While the primary mode is dark to emphasize premium immersion, the system maintains high contrast ratios for critical data visualization.

- **Primary:** A vibrant Teal (#00F5D4) used for primary actions and "active" states.
- **Secondary/Supporting:** Electric Blue, Vivid Orange, Cyber Pink, and Deep Purple are used to categorize different asset classes or financial streams.
- **Surface Strategy:** We avoid flat white or flat black. Instead, we use "Deep Slate" and "Midnight Navy" for backgrounds, creating a canvas for glassmorphic elements.
- **Gradients:** Use linear 135-degree gradients for primary buttons and progress indicators, blending Teal-Green into a deeper Cyan.

## Typography

Typography in this design system is treated as data architecture. We use **Sora** for its geometric, tech-forward personality in headlines and numerical displays. **Inter** provides a highly legible, neutral foundation for functional UI text and secondary data.

A heavy emphasis is placed on **Numeral Displays**. Financial figures should be rendered in Sora with tighter letter-spacing to feel impactful and precise. Large balances use the `display-lg` or `numeral-xl` roles to dominate the visual hierarchy. For data labels, use `label-caps` to provide clear, categorized structures without cluttering the interface.

## Layout & Spacing

The design system utilizes a **12-column fluid grid** for desktop and a **4-column grid** for mobile. The layout philosophy is built on "Floating Content"—elements should feel unconfined by rigid page borders, often bleeding off the edge or overlapping in Z-space.

- **Margins:** Generous outer margins (40px on desktop) create a "letterbox" effect that feels cinematic.
- **Gutters:** Large 24px gutters ensure that complex financial data has room to breathe.
- **Rhythm:** All spacing is based on an 8px scale. Use `stack-lg` for separating major content sections and `stack-sm` for grouping related data points (e.g., a label and its value).

## Elevation & Depth

This design system eschews traditional "drop shadows" in favor of **Atmospheric Depth**. 

1.  **Glassmorphic Surfaces:** UI containers use a semi-transparent background (e.g., `rgba(255, 255, 255, 0.05)`) with a high background blur (20px to 40px). 
2.  **Rim Lighting:** Every card or floating element must have a 1px "inner stroke" or "border." This border should be a subtle gradient (top-left to bottom-right) that simulates a light source hitting the edge of a glass pane.
3.  **Directional Glows:** Instead of black shadows, use "Shadow Glows" that inherit the color of the primary element (e.g., a Teal button casts a soft Teal shadow).
4.  **Z-Axis Stacking:** The background layer is deep and dark, the mid-layer contains glassmorphic cards, and the top layer is reserved for floating controls and tooltips.

## Shapes

The shape language is defined by **High-Radius Geometry**. Standard UI components like buttons and inputs use a 0.5rem (8px) radius, but the primary containers and cards use a much more aggressive **1.5rem (24px)** radius to feel modern and "friendly yet technical."

Floating controls and action buttons should occasionally utilize "Pill" shapes to distinguish them from data-heavy containers. Avoid sharp 90-degree angles entirely, as they conflict with the "liquid" nature of the teal-to-cyan primary theme.

## Components

- **Glass Cards:** The primary container. Must feature background blur, a 1px translucent border, and high corner radius. No solid fills.
- **Action Buttons:** High-contrast Teal gradients with white or deep-navy text. Hover states should increase the "inner glow" rather than changing the base color.
- **Floating Controls:** Navigation and key actions should appear to float above the content layer, often using a "Pill" shape and a slightly higher opacity glass effect.
- **Input Fields:** Minimalist. Only a bottom border or a very subtle glass inset. Labels should be small and uppercase (`label-caps`).
- **Data Visualizations:** Charts should use the multi-color palette (Blue, Orange, Pink) with glowing lines. Avoid thick, heavy axes; use "Ghost Grids" (very low opacity dotted lines).
- **Minimal Iconography:** Use thin-stroke (1.5px) SVG icons. Avoid filled icons unless they represent an active state. Icons should be abstract and technical, never illustrative or "bubbly."