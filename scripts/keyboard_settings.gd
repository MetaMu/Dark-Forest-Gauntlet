extends PanelContainer
const UI=preload("res://scripts/gnomish_ui.gd")
const Controls=preload("res://scripts/local_input.gd")
const LABELS=["Left","Right","Up","Down","Attack","Power","Revive","Switch gnome"]
var waiting_device:=0
var waiting_action:=""
var hint: Label
var buttons: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left=-405;offset_right=405;offset_top=-295;offset_bottom=295
	theme=UI.theme()
	add_theme_stylebox_override("panel",UI.scroll())
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",8);add_child(stack)
	var title:=Label.new();title.text="KEYBOARD CONTROLS";UI.heading(title,26);stack.add_child(title)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",20);stack.add_child(columns)
	for team in 2:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(column)
		var heading:=Label.new();heading.text="PLAYER %d" % [team+1];column.add_child(heading)
		for i in 8:
			var option:=Button.new();option.custom_minimum_size=Vector2(320,34)
			option.pressed.connect(func():
				waiting_device=-1-team;waiting_action=Controls.ACTIONS[i]
				hint.text="Press a new key for P%d %s. Escape cancels." % [team+1,LABELS[i]])
			column.add_child(option);buttons.append(option)
	hint=Label.new();hint.text="Click a binding, then press a key. Changes save automatically.";hint.add_theme_font_size_override("font_size",13);stack.add_child(hint)
	var back:=Button.new();back.text="BACK [Esc]";back.custom_minimum_size.y=38
	back.pressed.connect(func(): waiting_device=0;hide())
	stack.add_child(back);refresh()

func refresh() -> void:
	for team in 2:
		for i in 8: buttons[team*8+i].text="%s: %s" % [LABELS[i],Controls.key_label(-1-team,Controls.ACTIONS[i])]

func capture_key(event: InputEventKey) -> void:
	if event.physical_keycode==KEY_ESCAPE:
		if waiting_device!=0:
			waiting_device=0;hint.text="Binding cancelled."
		else: hide()
	elif waiting_device!=0:
		if Controls.rebind(waiting_device,waiting_action,event.physical_keycode):
			waiting_device=0;hint.text="Saved. Both players' bindings stay separate.";refresh()
		else: hint.text="That key is already assigned or reserved. Try another key, or Esc."
