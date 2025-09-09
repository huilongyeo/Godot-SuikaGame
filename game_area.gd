extends Node2D

@onready var spawner = $Spawner
@onready var fruits = $Fruits
@onready var hud = $HUD
var fruit_scene = preload("res://fruit.tscn")

# 水果等級資料
const MIN_LEVEL = 1
const MAX_LEVEL = 4

var pending_fruit = null
var current_max_level = MIN_LEVEL # 記錄目前場上最大水果等級
var game_over = false

# 自動或手動呼叫產生水果
func _ready():
	add_to_group("game_area")
	$Ceiling.connect("fruit_hit_wall", Callable(self, "_on_fruit_hit_wall"))
	$HUD.connect("start_game", Callable(self, "_on_start_game"))

func _on_start_game():
	# 這裡可以加上遊戲初始化、分數歸零等
	clear_all_fruits()
	hud.reset_score()
	# 其它初始化邏輯
	game_over = false
	current_max_level = MIN_LEVEL
	spawn_pending_fruit()

# 產生隨機等級水果
func spawn_pending_fruit() -> void:
	if pending_fruit != null and pending_fruit.is_inside_tree():
		pending_fruit.queue_free()
	var fruit = fruit_scene.instantiate()
	# 取得滑鼠在 Fruits 本地座標系的位置
	var mouse_global = get_global_mouse_position()
	var mouse_local = fruits.to_local(mouse_global)
	var rand_level= randi_range(MIN_LEVEL, current_max_level)
	var fruit_radius = fruit.FRUIT_DATA[rand_level]["radius"] # 使用隨機等級的半徑
	var min_x = fruit_radius
	var max_x = 480 - fruit_radius
	var clamped_x = clamp(mouse_local.x, min_x, max_x)
	# 生成在滑鼠下方
	fruit.position = Vector2(clamped_x, spawner.position.y)
	fruits.add_child(fruit)
	fruit.setup(rand_level, true)
	pending_fruit = fruit

func _process(_delta):
	if pending_fruit and pending_fruit.waiting_for_drop:
		var mouse_global = get_global_mouse_position()
		var mouse_local = fruits.to_local(mouse_global)
		var fruit_radius = pending_fruit.FRUIT_DATA[pending_fruit.level]["radius"]
		var min_x = fruit_radius
		var max_x = 480 - fruit_radius # 480是GameArea寬度
		var clamped_x = clamp(mouse_local.x, min_x, max_x)
		# 設定完整的 position（x,y都設）
		pending_fruit.position = Vector2(clamped_x, pending_fruit.position.y)

# 範例：每當玩家點擊時產生一顆隨機水果
func _unhandled_input(event):
	if event.is_action_pressed("drop_fruit") and not game_over:
		if pending_fruit and pending_fruit.waiting_for_drop:
			# 掉落水果，加分（水果等級）
			hud.update_score(pending_fruit.level)
			pending_fruit.drop()
			pending_fruit = null
			await get_tree().create_timer(0.5).timeout
			spawn_pending_fruit()

func spawn_higher_fruit(pos: Vector2, new_level: int):
	var fruit = fruit_scene.instantiate()
	fruit.position = fruits.to_local(pos) # 確保座標系正確
	fruits.add_child(fruit)
	fruit.setup(new_level, false)
	# 合成新水果，加分（新水果等級）
	hud.update_score(new_level)
	# 合成後若有更高等級，更新目前最大等級
	if new_level > current_max_level and new_level < MAX_LEVEL:
		current_max_level = new_level

func _on_fruit_hit_wall():
	# 顯示訊息、停止遊戲
	$HUD.game_over()
	game_over = true
	
func clear_all_fruits():
	for fruit in $Fruits.get_children():
		fruit.queue_free()
