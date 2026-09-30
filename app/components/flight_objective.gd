class_name FlightObjective
extends PanelContainer

var objective_label: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel(Color("FFF1BE"), 14, UiKit.GOLD, 2))
	objective_label = UiKit.label("", 14, true)
	add_child(objective_label)

func set_objective(text_value: String, active: bool = true) -> void:
	visible = active and not text_value.is_empty()
	if objective_label:
		objective_label.text = text_value
