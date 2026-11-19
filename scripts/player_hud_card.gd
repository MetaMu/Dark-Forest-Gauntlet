extends Control
const UI=preload("res://scripts/gnomish_ui.gd")
const FRAME=preload("res://assets/ui/gnomish/player-hud-frame.png")
var name_label: Label
var power_label: Label
var health_text: Label
var bar: TextureProgressBar
var cooldown_bar: TextureProgressBar
var realm:=0
var player_number:=1
var tint:=Color.WHITE
var recharge:=1.0
var downed:=false

static func gloss(width: int, height: int) -> GradientTexture2D:
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.25,.48,.52,1])
	gradient.colors=PackedColorArray([Color(.45,.45,.45),Color(.95,.95,.95),Color.WHITE,Color(.66,.66,.66),Color(.40,.40,.40)])
	var tex:=GradientTexture2D.new();tex.gradient=gradient;tex.width=width;tex.height=height
	tex.fill_from=Vector2(.5,0);tex.fill_to=Vector2(.5,1)
	return tex

func text_at(point: Vector2, dimensions: Vector2, size_px: int) -> Label:
	var text:=Label.new();text.position=point;text.size=dimensions
	text.add_theme_font_override("font",UI.body());text.add_theme_font_size_override("font_size",size_px)
	text.add_theme_color_override("font_color",Color("f7e8bd"))
	text.add_theme_color_override("font_shadow_color",Color("120d08"));text.add_theme_constant_override("shadow_offset_y",1)
	text.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(text)
	return text

func _ready() -> void:
	custom_minimum_size=Vector2(300,100);mouse_filter=Control.MOUSE_FILTER_IGNORE
	name_label=text_at(Vector2(81,25),Vector2(190,18),13)
	bar=TextureProgressBar.new();bar.position=Vector2(81,45);bar.size=Vector2(186,10)
	bar.texture_progress=gloss(186,10);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bar)
	health_text=text_at(Vector2(81,42),Vector2(186,15),10);health_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cooldown_bar=TextureProgressBar.new();cooldown_bar.position=Vector2(82,58);cooldown_bar.size=Vector2(184,2)
	cooldown_bar.texture_progress=gloss(184,2);cooldown_bar.tint_progress=Color("dcc489")
	cooldown_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(cooldown_bar)
	power_label=text_at(Vector2(81,61),Vector2(190,17),11)

func update_emblem(class_id: int, number: int, color: Color, ready: float, is_downed: bool) -> void:
	realm=class_id;player_number=number;tint=color;recharge=ready;downed=is_downed
	bar.tint_progress=Color("e85b4d") if bar.value<25 else color
	cooldown_bar.value=ready*100
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(FRAME,Rect2(0,0,300,100),false)
	var center:=Vector2(42,45)
	draw_circle(center,20,Color(.02,.025,.015,.5))
	draw_arc(center,21,-PI/2,-PI/2+TAU*maxf(.001,recharge),40,Color(tint,.8),1.5,true)
	var color:=Color("ac8c79") if downed else tint.lightened(.15)
	match realm:
		0:
			draw_colored_polygon(PackedVector2Array([center+Vector2(0,-15),center+Vector2(4,-3),center+Vector2(9,-8),center+Vector2(12,6),center+Vector2(5,13),center+Vector2(-6,13),center+Vector2(-12,5),center+Vector2(-9,-5),center+Vector2(-4,0)]),color)
		1:
			draw_colored_polygon(PackedVector2Array([center+Vector2(-11,12),center+Vector2(-10,-3),center+Vector2(12,-14),center+Vector2(10,3)]),color)
			draw_line(center+Vector2(-10,12),center+Vector2(9,-10),Color("f1e3aa"),1.5,true)
		2:
			draw_rect(Rect2(center+Vector2(-3,0),Vector2(6,13)),color)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-14,1),center+Vector2(-10,-8),center+Vector2(0,-13),center+Vector2(10,-8),center+Vector2(14,1)]),color)
			for p in [Vector2(-7,-3),Vector2(3,-6),Vector2(7,-1)]: draw_circle(center+p,1.5,Color("fff0d0"))
		3:
			var points:=PackedVector2Array()
			for i in 16:
				var a:=float(i)*TAU/16-PI/2;points.append(center+Vector2(cos(a),sin(a))*(14 if i%2==0 else 5))
			draw_colored_polygon(points,color)
	draw_string(UI.body(),Vector2(27,79),"P%d" % player_number,HORIZONTAL_ALIGNMENT_CENTER,30,12,Color("f4dfac"))
