extends RigidBody2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var waiting_for_drop := false
var level: int = 1
var ignore_ceiling_time := 0.5
var can_trigger_ceiling := false

# 水果等級對應素材與半徑
const FRUIT_DATA = {
	1: { "image": "res://assets/Level1.png", "radius": 25 },
	2: { "image": "res://assets/Level2.png", "radius": 35 },
	3: { "image": "res://assets/Level3.png", "radius": 42 },
	4: { "image": "res://assets/Level4.png", "radius": 50 },
}

const MAX_LEVEL = 4

# 用來防止重複合成
var is_processing := false

# 主程序會呼叫這個方法，指定水果等級
func setup(new_level: int, wait_for_drop := false) -> void:
	level = new_level
	print("setup level:", level)
	if sprite == null:
		push_error("Sprite2D 節點不存在！請檢查 Fruit.tscn 結構。")
		return
	var data = FRUIT_DATA.get(level)
	if data == null:
		push_error("未知的水果等級：" + str(level))
		return
	var tex = load(data["image"])
	sprite.texture = tex

	if collision_shape != null:
		var shape = CircleShape2D.new()
		shape.radius = data["radius"]
		collision_shape.shape = shape

		var img_size = tex.get_size()
		var orig_radius = img_size.x / 2.0
		var scale_factor = data["radius"] / orig_radius
		sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		push_error("CollisionShape2D 不存在，請檢查場景設計。")

	# 初始化 Area2D 的碰撞範圍
	if has_node("Area2D/AreaShape"):
		var area_shape = $Area2D/AreaShape
		if area_shape != null:
			var area_circle = CircleShape2D.new()
			area_circle.radius = data["radius"]
			area_shape.shape = area_circle
		else:
			push_error("Area2D 的 CollisionShape2D 不存在，請檢查場景設計。")
	else:
		push_error("Area2D/AreaShape 路徑不存在，請檢查場景設計。")

	waiting_for_drop = wait_for_drop
	if waiting_for_drop:
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		freeze = true
	else:
		freeze = false

# 讓水果在等待掉落時，能被外部設定x坐標
func set_x(x:float):
	if waiting_for_drop:
		position.x = x

# 讓外部觸發下落
func drop():
	waiting_for_drop = false
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	can_trigger_ceiling = false
	start_ceiling_timer()

func start_ceiling_timer():
	await get_tree().create_timer(ignore_ceiling_time).timeout
	can_trigger_ceiling = true


func _ready():
	$Area2D.connect("area_entered", Callable(self, "_on_area_entered"))
	print("[DEBUG] Fruit ready, level:", level)

func _on_area_entered(area):
	# 防止重複觸發
	if is_processing:
		return

	var other_fruit = area.get_parent()
	if other_fruit != self and other_fruit.has_method("get_level"):
		var other_level = other_fruit.get_level()
		# 1. 階級必須相同且都不是最大階級
		if (other_level == level) and (level < MAX_LEVEL):
			# 2. 兩個水果消失
			is_processing = true
			other_fruit.is_processing = true # 防止對方也執行
			var collision_pos = (self.global_position + other_fruit.global_position) / 2.0
			other_fruit.queue_free()
			self.queue_free()
			# 3. 在中心位置生成新水果（高一級）
			get_tree().call_group("game_area", "spawn_higher_fruit", collision_pos, level + 1)

func get_level():
	return level