extends Control
## Fifty generated, articulated poses with the approved stop-motion timing.
signal replay_requested
signal quit_requested
const LOOP_SECONDS := 3.12
const FRAME_COUNT := 50
const ATLAS=preload("res://assets/characters/maria/dynamic-50/maria-celebration-atlas.png")
var elapsed := 0.0
var replay: Button
var exit_button: Button
var manual_time := -1.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	process_mode=Node.PROCESS_MODE_ALWAYS
	replay=Button.new();replay.text="PLAY AGAIN";replay.pressed.connect(func(): replay_requested.emit())
	exit_button=Button.new();exit_button.text="QUIT GAME";exit_button.pressed.connect(func(): quit_requested.emit())
	for b in [replay,exit_button]:
		add_child(b)
		b.add_theme_font_size_override("font_size",16)
		var style:=StyleBoxFlat.new();style.bg_color=Color("3c5147");style.border_color=Color("b38c45");style.set_border_width_all(2);style.set_corner_radius_all(7)
		b.add_theme_stylebox_override("normal",style)
		var hover:=style.duplicate();hover.bg_color=Color("5b7054");b.add_theme_stylebox_override("hover",hover)

func open() -> void:
	elapsed=0.0;show();replay.grab_focus()

static func pose_at(seconds: float) -> Dictionary:
	var time:=fposmod(seconds,LOOP_SECONDS)
	var frame:=0 if time<.12 else mini(49,1+int(floor((time-.12)/.06)))
	var lift:=0.0
	if frame>=8 and frame<=33:
		var flight:=float(frame-8)/25.0
		lift=105.0*4.0*flight*(1.0-flight)
	return {"frame":frame,"jump":lift}

func _process(delta: float) -> void:
	if not visible: return
	elapsed+=delta
	var factor:=minf(size.x/1280.0,size.y/720.0)
	var origin:=(size-Vector2(1280,720)*factor)*.5
	replay.position=origin+Vector2(436,566)*factor;replay.size=Vector2(196,44)*factor
	exit_button.position=origin+Vector2(648,566)*factor;exit_button.size=Vector2(196,44)*factor
	queue_redraw()

func words(text: String, y: float, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,Vector2(280,y),text,HORIZONTAL_ALIGNMENT_CENTER,720,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,.04,.045,1.0))
	var factor:=minf(size.x/1280.0,size.y/720.0)
	draw_set_transform((size-Vector2(1280,720)*factor)*.5,0,Vector2.ONE*factor)
	var t:=manual_time if manual_time>=0.0 else elapsed
	var unfold:=smoothstep(0.0,.65,t)
	var paper:=Rect2(260,350-280*unfold,760,560*unfold)
	draw_style_box(parchment(),paper)
	for y in [paper.position.y,paper.end.y]:
		draw_style_box(roller(),Rect2(240,y-13,800,26))
		for x in [240,1040]:
			draw_circle(Vector2(x,y),17,Color("75552f"));draw_circle(Vector2(x,y),10,Color("dcb871"))
	if unfold<.99: return
	draw_rect(Rect2(282,94,716,512),Color("b99b65"),false,1.0)
	words("THE GNOME PEAR CLUB",127,15,Color("7d6744"))
	words("THE CISTERN IS SAVED!",169,34,Color("354a40"))
	words("Both realms restored. A golden victory for your party.",202,17,Color("695738"))
	# All particles are periodic, with zero alpha at each wrap.
	for i in 38:
		var p:=fposmod(t/LOOP_SECONDS+float(i)/38.0,1.0)
		var x:=330.0+fposmod(float(i)*97.0,620.0)+sin(p*TAU+i)*16.0
		var y:=230.0+p*265.0
		var color:=Color(["ba8447","8d70ab","c69557","7f9c75"][i%4]);color.a=sin(p*PI)*.8
		draw_set_transform((size-Vector2(1280,720)*factor)*.5+Vector2(x,y)*factor,p*TAU+i,Vector2.ONE*factor)
		draw_rect(Rect2(-3,-5,6,10),color)
	draw_set_transform((size-Vector2(1280,720)*factor)*.5,0,Vector2.ONE*factor)
	var pose:=pose_at(maxf(0,t-1.15))
	var emerge:=smoothstep(.65,1.15,t)
	var jump: float=pose.jump
	draw_set_transform((size-Vector2(1280,720)*factor)*.5+Vector2(640,498)*factor,0,Vector2(1,.18)*factor)
	draw_circle(Vector2.ZERO,58.0-jump*.18,Color(0.25,.21,.14,.19))
	draw_set_transform((size-Vector2(1280,720)*factor)*.5,0,Vector2.ONE*factor)
	var frame: int=pose.frame
	# Jump height and articulation are already authored into each atlas cell.
	# No extra bobbing, squash/stretch or body-pose interpolation.
	var region:=Rect2((frame%10)*320,(frame/10)*320,320,320)
	draw_texture_rect_region(ATLAS,Rect2(470,190,340,340),region,Color(1,1,1,emerge))
	words("MARIA CHEERS FOR YOU!",532,22,Color("684663"))
	words("A little joy. A big adventure. Thank you for playing.",554,14,Color("786347"))

func parchment() -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color("eee0b9");s.border_color=Color("be9959");s.set_border_width_all(3);s.set_corner_radius_all(8);s.shadow_color=Color(0,0,0,.4);s.shadow_size=20
	return s

func roller() -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color("d0ad6d");s.border_color=Color("9f7941");s.set_border_width_all(2);s.set_corner_radius_all(12)
	return s
