class_name CropData
extends Resource

## Define una especie de cultivo / planta (tiempos, fases, drops)

@export var id: String = ""
@export var crop_name: String = ""

## Tiempo en segundos que tarda en avanzar cada etapa de crecimiento
@export var seconds_per_stage: float = 12.0

## Texturas para cada etapa: [0]=Brote, [1]=Creciendo, [2]=Maduro (lista para cosechar)
@export var growth_stage_textures: Array[Texture2D] = []

## Color representativo mientras no haya imágenes dibujadas
@export var placeholder_color: Color = Color(0.3, 0.85, 0.4)

## Item que produce al cosechar
@export var harvest_item: ItemData
@export var min_harvest_count: int = 1
@export var max_harvest_count: int = 3

## Item de semilla necesario para plantarlo
@export var seed_item: ItemData
@export var extra_seed_chance: float = 0.5

## ¿Es una planta silvestre de caverna que vuelve a brotar sola?
## (Las plantas fuera de un bancal siempre rebrotan al instante; esto lo fuerza también en bancales)
@export var is_perennial_wild: bool = false
