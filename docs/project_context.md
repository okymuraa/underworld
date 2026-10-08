# Contexto del Proyecto: Juego Inspirado en Slugterra

Este documento recopila la información de diseño, mecánicas y contexto general para el desarrollo del juego, sirviendo como punto de referencia persistente.

---

## 📖 Concepto General
El juego está fuertemente inspirado en la franquicia **Slugterra** (Bajo Terra). 
La premisa principal gira en torno a:
- **Combate y exploración subterránea**: El mundo se sitúa bajo la tierra, compuesto por un sistema interconectado de cavernas.
- **Las 99 Cavernas**: Hay 99 cavernas principales que representan las zonas o niveles del juego.
- **Mecánica de Babosas (Slugs)**: Criaturas mágicas que son utilizadas como munición en lanzadoras (blasters). Al ser disparadas y alcanzar cierta velocidad (generalmente 100 mph), se transforman temporalmente en poderosas versiones de combate con habilidades elementales o físicas únicas.

---

## 🎮 Perspectiva y Estilo Visual
- **Perspectiva**: Vista Isométrica 2D / Cenital (Top-down Isometric), facilitando la gestión del terreno y la estética del mundo subterráneo.
- **Dimensión**: **2D**. Todos los elementos del mundo y del terreno se gestionan en 2D (sprites y mapas de azulejos isométricos) para simplificar el desarrollo y evitar la complejidad del modelado y terreno en 3D.

---

## 🛠️ Tecnologías y Herramientas
- **Motor de Videojuegos**: Godot Engine 4 (Godot 4.x)
- **Terreno y Mapas**: Nodos `TileMapLayer` 2D en cuadrícula isométrica.
- **Físicas**: Físicas 2D nativas de Godot Engine (`CharacterBody2D`, `Area2D`, etc.).
