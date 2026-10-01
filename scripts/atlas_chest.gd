extends Node
## One-shot interaction for the owner-supplied Atlas chest in Moonlit Ruins.

const LocalInput = preload("res://scripts/local_input.gd")
const OPEN_DISTANCE_SQUARED := 7.0

var room: Node3D
var chest: Node3D
var animation_player: AnimationPlayer
var prompt: Label3D
var opened := false

func setup(game_room: Node3D, chest_pivot: Node3D) -> void:
	room = game_room
	chest = chest_pivot
	animation_player = find_animation_player(chest)
	if animation_player == null:
		push_warning("Atlas chest is missing its opening animation.")
		set_process(false)
		return
	prompt = Label3D.new()
	prompt.text = "INTERACT  •  OPEN CHEST"
	prompt.pixel_size = 0.008
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.modulate = Color("efd18a")
	prompt.position = Vector3(0, 1.1, 0)
	prompt.visible = false
	chest.add_child(prompt)

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null

func _process(_delta: float) -> void:
	if opened or room == null or chest == null or animation_player == null:
		return
	var near := false
	for player in room.players:
		if player.downed or not player.controlled:
			continue
		var offset: Vector3 = player.global_position - chest.global_position
		offset.y = 0
		if offset.length_squared() > OPEN_DISTANCE_SQUARED:
			continue
		near = true
		if LocalInput.interact(player.device):
			opened = true
			prompt.hide()
			for name in animation_player.get_animation_list():
				if "OpenChest" in name:
					animation_player.play(name)
					return
			push_warning("Atlas chest animation clip was not imported.")
			return
	prompt.visible = near
