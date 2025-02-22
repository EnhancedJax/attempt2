extends NinePatchRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func update(value: int, max_value: int):
	$Value.text = "%s/%s" % [value, max_value]
	$ProgressBar.max_value = max_value
	$ProgressBar.value = value
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
