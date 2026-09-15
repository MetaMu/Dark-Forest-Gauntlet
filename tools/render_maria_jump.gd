extends SceneTree
# Ten held poses: ready, crouch, push-off, rise, apex, float, fall, land, rebound, settle.
const POSES = [
	[0,0,1.0,1.0,0.0], [0,0,1.08,.88,-.025],
	[1,30,.94,1.07,-.025], [2,88,.98,1.02,-.02],
	[2,120,1.0,1.0,0.0], [3,112,1.0,1.0,.025],
	[3,62,.98,1.03,.025], [0,0,1.12,.84,.01],
	[0,10,.97,1.04,-.01], [0,0,1.02,.98,0.0]]
func _initialize() -> void: call_deferred("run")
func smooth_pose(t: float) -> Array:
	var lift:=0.0
	var stretch:=0.0
	if t<.18:
		# Gather weight before takeoff; ease into the crouch.
		stretch=-.09*sin(t/.18*PI)
	elif t<.72:
		var flight: float=(t-.18)/.54
		lift=120.0*4.0*flight*(1.0-flight)
		stretch=.035*sin(flight*TAU)
	else:
		# Landing compression settles through a small, damped rebound.
		var settle: float=(t-.72)/.28
		stretch=-.085*sin(settle*TAU)*pow(1.0-settle,2)
	return [2,lift,1.0-stretch*.55,1.0+stretch,sin(t*TAU)*.018]
func run() -> void:
	var smooth_mode: bool="--smooth" in OS.get_cmdline_user_args()
	var count:=50 if smooth_mode else POSES.size()
	var folder:="maria-jump-50" if smooth_mode else "maria-jump-10"
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(640,640);viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var pivot:=Node2D.new();viewport.add_child(pivot)
	var sprite:=Sprite2D.new();sprite.centered=false;pivot.add_child(sprite)
	for i in count:
		var pose: Array=smooth_pose(float(i)/count) if smooth_mode else POSES[i]
		sprite.texture=load("res://assets/characters/maria/frame-%02d.png"%(pose[0]+1))
		var dims:=sprite.texture.get_size()
		sprite.position=Vector2(-dims.x*.5,-dims.y)
		pivot.position=Vector2(320,590-pose[1])
		pivot.scale=Vector2(pose[2],pose[3])*(420.0/dims.y)
		pivot.rotation=pose[4]
		await process_frame;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/%s/frame-%02d.png"%[folder,i+1])
	viewport.queue_free();await process_frame
	print("MARIA: rendered %d transparent 640 x 640 poses"%count)
	quit()
