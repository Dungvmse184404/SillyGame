# time_util.gd
extends Node

# Hàm delay frame
func delay_frames(frame_count: int) -> void:
	while frame_count > 0:
		await get_tree().process_frame
		#print(str(frame_count))
		frame_count -= 1

# Hàm bỏ qua x frame
# int > 0
func skip_frames(skip_frames: int, callback: Callable) -> void:
	if Engine.get_physics_frames() % skip_frames == 0:
		callback.call()


func wait_until_on_floor(obj: Node) -> void:
	if obj == null or not is_instance_valid(obj):
		return

	await delay_frames(2)
	var scene_root = obj.get_tree()
	while is_instance_valid(obj) and not obj.is_on_floor():
		await scene_root.process_frame
