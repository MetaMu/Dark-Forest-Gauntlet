extends PanelContainer
const Controls=preload("res://scripts/local_input.gd")
const LABELS=["Left","Right","Up","Down","Attack","Power","Revive","Switch gnome"]
var waiting_device:=0
var waiting_action:=""
var hint: Label
var buttons: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left=-375;offset_right=375;offset_top=-240;offset_bottom=240
	var style:=StyleBoxFlat.new();style.bg_color=Color("101a20");style.border_color=Color("b09a63")
	style.set_border_width_all(2);style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=18;style.content_margin_bottom=18
	add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",12);add_child(stack)
	var title:=Label.new();title.text="KEYBOARD CONTROLS";title.add_theme_font_size_override("font_size",24);stack.add_child(title)
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
