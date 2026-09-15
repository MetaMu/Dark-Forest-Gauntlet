extends "res://scripts/clearing.gd"

# Isolated art trial. Collision, movement and encounter rules remain inherited.
const SHEET = preload("res://assets/characters/gnomes/v1/gnome_universal_apose_sheet.png")
const SPRITE_HEIGHT := 2.2
var gnome: Sprite3D

func _ready() -> void:
	super._ready()
	var player = players[0]
	for child in player.visual.get_children():
		child.hide()
	gnome = Sprite3D.new()
	gnome.name = "UniversalGnomeTrial"
	gnome.texture = SHEET
	gnome.hframes = 4
	gnome.frame = 3
	gnome.pixel_size = SPRITE_HEIGHT / 416.0
	gnome.offset = Vector2(0, 208)
	gnome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gnome.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	gnome.shaded = false
	gnome.no_depth_test = false
	# Parent outside the rotating placeholder visual; retain downed scaling below.
	player.add_child(gnome)
	for child in player.get_children():
		if child is Label3D:
			child.position.y = 3.6
	var help := Label.new()
	help.text = "UNIVERSAL SPRITE TRIAL  •  1 Front  2 Side  3 Back  4 Three-quarter  •  WASD to move"
	help.position = Vector2(24, 120)
	help.add_theme_font_size_override("font_size", 16)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	overlay.add_child(help)

func _process(delta: float) -> void:
	super._process(delta)
	if gnome != null:
		gnome.scale.y = players[0].visual.scale.y

func _input(event: InputEvent) -> void:
	super._input(event)
	if gnome != null and event is InputEventKey and event.pressed:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			gnome.frame = event.physical_keycode - KEY_1
