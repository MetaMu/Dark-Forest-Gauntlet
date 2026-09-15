extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var script=load("res://scripts/realm_vfx.gd")
	print("AUDIT_SOURCE_LENGTH=",script.source_code.length())
	var has_glint_property:=false
	for property in script.get_script_property_list():
		if property.name=="glint_clock": has_glint_property=true
	print("AUDIT_GLINT_PROPERTY=",has_glint_property)
	print("AUDIT_SOURCE_HAS_SANDBOX=",script.source_code.contains("Elemental Sandbox"))
	print("AUDIT_SOURCE_HAS_GLINTS=",script.source_code.contains("glint_clock"))
	if "--pack-only" in OS.get_cmdline_user_args(): quit();return
	var parent:=Node3D.new();root.add_child(parent)
	var bolt:=Node3D.new();parent.add_child(bolt);bolt.position=Vector3(10,1,10)
	var fx=script.projectile_trail(parent,bolt,Color.GREEN)
	for i in 24:
		bolt.position.x+=.1
		await process_frame
	var visible_count:=0
	var max_distance:=0.0
	for part in fx.parts:
		if part.node.visible:
			visible_count+=1
			max_distance=maxf(max_distance,part.node.global_position.distance_to(bolt.global_position))
	print("AUDIT_TRAIL_AGE=",fx.age," PARTS=",fx.parts.size()," VISIBLE=",visible_count)
	if not fx.parts.is_empty(): print("AUDIT_GLINT_ORIGIN=",fx.parts.back().origin," DELAY=",fx.parts.back().delay," BOLT=",bolt.global_position)
	parent.queue_free();await process_frame;quit()
