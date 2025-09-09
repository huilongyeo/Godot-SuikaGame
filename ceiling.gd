extends StaticBody2D

signal fruit_hit_wall

# Called when the node enters the scene tree for the first time.
func _ready():
	$Area2D.connect("area_entered", Callable(self, "_on_area_entered"))


func _on_area_entered(area):
	var fruit = area.get_parent()
	if fruit.has_method("get_level"):
		# 檢查是否掉落中的水果
		if fruit.can_trigger_ceiling:
			fruit_hit_wall.emit()