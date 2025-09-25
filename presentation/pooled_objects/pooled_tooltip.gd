extends Control

# Pooled tooltip object for efficient tooltip rendering
# Reusable tooltip component that can be recycled by the object pool

var is_pooled: bool = false
var tooltip_data: DataModels.TooltipData

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var value_label: Label = $VBoxContainer/ValueLabel
@onready var explanation_label: Label = $VBoxContainer/ExplanationLabel

func _ready():
	set_visible(false)

func setup_tooltip(data: DataModels.TooltipData) -> void:
	"""Configure tooltip with provided data"""
	tooltip_data = data

	if title_label:
		title_label.text = data.title
	if value_label:
		value_label.text = data.current_value
	if explanation_label:
		explanation_label.text = data.explanation

func show_tooltip():
	"""Show the tooltip"""
	set_visible(true)

func hide_tooltip():
	"""Hide the tooltip"""
	set_visible(false)

func reset_for_pool():
	"""Reset tooltip state for return to pool"""
	tooltip_data = null
	set_visible(false)
	if title_label:
		title_label.text = ""
	if value_label:
		value_label.text = ""
	if explanation_label:
		explanation_label.text = ""