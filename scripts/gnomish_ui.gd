extends RefCounted
const HEADING=preload("res://assets/fonts/GnomishElder-Regular.ttf")
const PAPER=preload("res://assets/ui/gnomish/parchment-scroll.png")
const SEAL=preload("res://assets/ui/gnomish/elder-seal.svg")
const INK=Color("34291d")
const GOLD=Color("cfad69")
static var body_font: SystemFont
static var paper_texture: ImageTexture

static func body() -> SystemFont:
	if body_font==null:
		body_font=SystemFont.new();body_font.font_names=PackedStringArray(["Georgia","Palatino Linotype","serif"])
	return body_font

static func scroll() -> StyleBoxTexture:
	if paper_texture==null:
		var img:=PAPER.get_image();img.resize(480,640,Image.INTERPOLATE_LANCZOS)
		paper_texture=ImageTexture.create_from_image(img)
	var s:=StyleBoxTexture.new();s.texture=paper_texture
	for edge in [SIDE_LEFT,SIDE_RIGHT]:
		s.set_texture_margin(edge,64);s.set_expand_margin(edge,8);s.set_content_margin(edge,52)
	for edge in [SIDE_TOP,SIDE_BOTTOM]:
		s.set_texture_margin(edge,90);s.set_expand_margin(edge,10);s.set_content_margin(edge,80 if edge==SIDE_TOP else 56)
	return s

static func glass() -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color(.035,.065,.052,.68)
	s.border_color=Color(.64,.52,.29,.55);s.border_width_top=1;s.border_width_bottom=1
	s.corner_radius_top_left=14;s.corner_radius_bottom_right=14
	s.content_margin_left=16;s.content_margin_right=16;s.content_margin_top=10;s.content_margin_bottom=10
	return s

static func button_style(state: String="normal") -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=Color("263e32") if state=="normal" else Color("38563c")
	if state=="pressed": s.bg_color=Color("172d25")
	if state=="selected": s.bg_color=Color("55502f")
	s.border_color=GOLD if state!="normal" else Color("847348")
	s.set_border_width_all(1);s.border_width_bottom=3
	s.corner_radius_top_left=10;s.corner_radius_bottom_right=10
	s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=7;s.content_margin_bottom=7
	return s

static func theme() -> Theme:
	var t:=Theme.new();t.default_font=body();t.default_font_size=16
	t.set_color("font_color","Label",INK)
	for state in ["normal","hover","pressed","disabled"]: t.set_stylebox(state,"Button",button_style(state))
	var focus:=StyleBoxFlat.new();focus.bg_color=Color(0,0,0,0);focus.border_color=Color("ffe3a0")
	focus.set_border_width_all(2);focus.set_expand_margin_all(3)
	t.set_stylebox("focus","Button",focus)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: t.set_color(key,"Button",Color("f5e7bf"))
	t.set_color("font_disabled_color","Button",Color("a3997d"))
	var rail:=StyleBoxFlat.new();rail.bg_color=Color("6c6043");rail.content_margin_top=3;rail.content_margin_bottom=3
	t.set_stylebox("slider","HSlider",rail)
	var fill:=StyleBoxFlat.new();fill.bg_color=Color("718250");fill.content_margin_top=3;fill.content_margin_bottom=3
	t.set_stylebox("grabber_area","HSlider",fill);t.set_stylebox("grabber_area_highlight","HSlider",fill)
	return t

static func heading(node: Label, size: int=24) -> void:
	node.add_theme_font_override("font",HEADING);node.add_theme_font_size_override("font_size",size)
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
