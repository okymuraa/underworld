class_name ItemData
extends Resource

## Identificador único interno (ej: "wood", "stone", "axe")
@export var id: String = ""

## Nombre visible para el jugador (ej: "Madera", "Piedra", "Hacha de Piedra")
@export var name: String = ""

## Descripción breve del item
@export_multiline var description: String = ""

## Textura/Sprite del icono del item (opcional, si es null se usa figura representativa)
@export var icon: Texture2D = null

## Color de la figura representativa en caso de que aún no agregues la imagen
@export var placeholder_color: Color = Color(0.75, 0.55, 0.35)

## Símbolo o letra representativa corta (ej: "M" para Madera, "P" para Piedra, "H" para Hacha)
@export var placeholder_symbol: String = "?"

## Cantidad máxima por slot
@export var max_stack: int = 99

## Tipo de item
@export_enum("material", "tool", "seed", "furniture", "consumable") var item_type: String = "material"

## Si es herramienta, qué tipo y potencia tiene:
@export_enum("none", "axe", "pickaxe", "hoe") var tool_type: String = "none"
@export var tool_power: int = 1
