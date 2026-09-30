class_name CurrencyDisplay
extends PanelContainer

var amount_label: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel(Color("FFF1BE"), 15))
	amount_label = UiKit.label("● 0", 16, true)
	add_child(amount_label)

func set_amount(value: int) -> void:
	if amount_label:
		amount_label.text = "● %d" % value
