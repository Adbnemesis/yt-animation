class_name PhoneNotification
extends CanvasLayer

# Smartphone Notification Popup Component for "Stuck in the Elevator"

signal notification_shown()
signal notification_hidden()

@onready var panel: PanelContainer = get_node_or_null("Panel")
@onready var sfx_buzz: AudioStreamPlayer = get_node_or_null("BuzzAudio")

func _ready() -> void:
	if panel:
		panel.modulate.a = 0.0
		panel.position.y = -120.0

func show_notification(message: String = "Your elevator ride has been rated ⭐⭐⭐⭐⭐.") -> void:
	if sfx_buzz:
		sfx_buzz.play()

	var msg_label = panel.find_child("MessageLabel") as Label
	if msg_label:
		msg_label.text = message

	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(panel, "position:y", 30.0, 0.45)
	tw.tween_property(panel, "modulate:a", 1.0, 0.30)
	tw.chain().tween_callback(func():
		notification_shown.emit()
	)

func hide_notification() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(true)
	tw.tween_property(panel, "position:y", -120.0, 0.35)
	tw.tween_property(panel, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(func():
		notification_hidden.emit()
	)
