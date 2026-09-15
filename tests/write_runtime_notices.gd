extends SceneTree
func _initialize() -> void:
	var license:=FileAccess.open("res://builds/Forest-Playtest/GODOT-LICENSE.txt",FileAccess.WRITE)
	license.store_string(Engine.get_license_text())
	var notice:=FileAccess.open("res://builds/Forest-Playtest/GODOT-THIRD-PARTY-NOTICES.json",FileAccess.WRITE)
	notice.store_string(JSON.stringify({"components":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"\t"))
	quit()
