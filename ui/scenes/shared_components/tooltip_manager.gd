extends Control
class_name TooltipManager

# TooltipManager component with explanation panels for constitutional transparency
# Provides explanatory tooltips on all metrics as required by constitution

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_title: Label = $TooltipPanel/VBoxContainer/Title
@onready var tooltip_content: RichTextLabel = $TooltipPanel/VBoxContainer/Content
@onready var tooltip_factors: RichTextLabel = $TooltipPanel/VBoxContainer/Factors
@onready var explanation_panel: Panel = $ExplanationPanel
@onready var explanation_title: Label = $ExplanationPanel/VBoxContainer/Title
@onready var explanation_steps: RichTextLabel = $ExplanationPanel/VBoxContainer/Steps
@onready var explanation_assumptions: RichTextLabel = $ExplanationPanel/VBoxContainer/Assumptions
@onready var close_button: Button = $ExplanationPanel/VBoxContainer/CloseButton

var current_target: Control = null
var tooltip_timer: Timer
var show_delay: float = 0.5
var hide_delay: float = 0.1

signal tooltip_shown(target: Control)
signal tooltip_hidden()
signal explanation_shown(calculation: String)
signal explanation_closed()

func _ready():
	# Setup tooltip panel
	tooltip_panel.visible = false
	tooltip_panel.modulate.a = 0.0
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Setup explanation panel
	explanation_panel.visible = false
	explanation_panel.modulate.a = 0.0
	close_button.pressed.connect(_on_close_explanation)

	# Setup timer
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = show_delay
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_show_tooltip_delayed)
	add_child(tooltip_timer)

func show_tooltip(target_element: Control, tooltip_data: TooltipData) -> void:
	"""Show explanatory tooltip for any UI element"""
	if target_element == null or tooltip_data == null:
		return

	current_target = target_element

	# Update tooltip content
	tooltip_title.text = tooltip_data.title
	tooltip_content.text = tooltip_data.explanation

	# Format contributing factors
	if tooltip_data.contributing_factors.size() > 0:
		var factors_text = "[b]Contributing factors:[/b]\n"
		for factor in tooltip_data.contributing_factors:
			factors_text += "• " + factor + "\n"
		tooltip_factors.text = factors_text
	else:
		tooltip_factors.text = ""

	# Show trend indicator
	var trend_icon = ""
	match tooltip_data.trend_direction:
		"increasing":
			trend_icon = " ↗"
		"decreasing":
			trend_icon = " ↘"
		"stable":
			trend_icon = " →"

	tooltip_title.text += trend_icon

	# Position tooltip near target
	_position_tooltip(target_element)

	# Show tooltip with fade-in
	_fade_in_tooltip()

	tooltip_shown.emit(target_element)

func show_explanation_panel(explanation: ExplanationPanel) -> void:
	"""Show detailed 'why?' panel for complex calculations"""
	if explanation == null:
		return

	# Hide tooltip first
	hide_all_tooltips()

	# Update explanation content
	explanation_title.text = explanation.calculation_name

	# Format step-by-step breakdown
	var steps_text = "[b]Calculation steps:[/b]\n"
	for i in range(explanation.step_by_step.size()):
		steps_text += "%d. %s\n" % [i + 1, explanation.step_by_step[i]]
	explanation_steps.text = steps_text

	# Format assumptions
	if explanation.assumptions.size() > 0:
		var assumptions_text = "[b]Assumptions:[/b]\n"
		for assumption in explanation.assumptions:
			assumptions_text += "• " + assumption + "\n"
		assumptions_text += "\n[b]Confidence level:[/b] " + explanation.confidence_level
		explanation_assumptions.text = assumptions_text

	# Position and show explanation panel
	_position_explanation_panel()
	_fade_in_explanation_panel()

	explanation_shown.emit(explanation.calculation_name)

func hide_all_tooltips() -> void:
	"""Hide all tooltips and explanation panels"""
	_fade_out_tooltip()
	_fade_out_explanation_panel()
	current_target = null
	tooltip_hidden.emit()

func register_tooltip_target(target: Control, tooltip_data: TooltipData) -> void:
	"""Register a control to show tooltips on hover"""
	if target == null:
		return

	# Connect mouse events
	if not target.mouse_entered.is_connected(_on_target_mouse_entered):
		target.mouse_entered.connect(_on_target_mouse_entered.bind(target, tooltip_data))
	if not target.mouse_exited.is_connected(_on_target_mouse_exited):
		target.mouse_exited.connect(_on_target_mouse_exited)

	# Connect focus events for keyboard navigation
	if not target.focus_entered.is_connected(_on_target_focus_entered):
		target.focus_entered.connect(_on_target_focus_entered.bind(target, tooltip_data))
	if not target.focus_exited.is_connected(_on_target_focus_exited):
		target.focus_exited.connect(_on_target_focus_exited)

func _on_target_mouse_entered(target: Control, tooltip_data: TooltipData) -> void:
	tooltip_timer.start()
	current_target = target

func _on_target_mouse_exited() -> void:
	tooltip_timer.stop()
	_fade_out_tooltip()

func _on_target_focus_entered(target: Control, tooltip_data: TooltipData) -> void:
	# Show tooltip immediately for keyboard users
	show_tooltip(target, tooltip_data)

func _on_target_focus_exited() -> void:
	hide_all_tooltips()

func _show_tooltip_delayed() -> void:
	if current_target != null:
		# Get tooltip data for current target
		var tooltip_data = _get_tooltip_data_for_target(current_target)
		if tooltip_data != null:
			show_tooltip(current_target, tooltip_data)

func _get_tooltip_data_for_target(target: Control) -> TooltipData:
	# This would normally be stored when registering the target
	# For now, create default tooltip data
	var data = TooltipData.new()
	data.title = target.name
	data.explanation = "Information about " + target.name
	data.contributing_factors = []
	data.trend_direction = "stable"
	return data

func _position_tooltip(target: Control) -> void:
	if target == null:
		return

	# Get target's global position and size
	var target_rect = target.get_global_rect()
	var tooltip_size = tooltip_panel.get_combined_minimum_size()

	# Calculate position (below target, centered)
	var pos = Vector2()
	pos.x = target_rect.position.x + (target_rect.size.x - tooltip_size.x) / 2
	pos.y = target_rect.position.y + target_rect.size.y + 10

	# Ensure tooltip stays on screen
	var viewport_size = get_viewport().get_visible_rect().size
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = viewport_size.x - tooltip_size.x - 10
	if pos.x < 10:
		pos.x = 10
	if pos.y + tooltip_size.y > viewport_size.y:
		# Show above target instead
		pos.y = target_rect.position.y - tooltip_size.y - 10

	tooltip_panel.position = pos

func _position_explanation_panel() -> void:
	# Center explanation panel on screen
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = explanation_panel.get_combined_minimum_size()

	explanation_panel.position = Vector2(
		(viewport_size.x - panel_size.x) / 2,
		(viewport_size.y - panel_size.y) / 2
	)

func _fade_in_tooltip() -> void:
	tooltip_panel.visible = true
	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.2)

func _fade_out_tooltip() -> void:
	if tooltip_panel.visible:
		var tween = create_tween()
		tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func(): tooltip_panel.visible = false)

func _fade_in_explanation_panel() -> void:
	explanation_panel.visible = true
	var tween = create_tween()
	tween.tween_property(explanation_panel, "modulate:a", 1.0, 0.3)

func _fade_out_explanation_panel() -> void:
	if explanation_panel.visible:
		var tween = create_tween()
		tween.tween_property(explanation_panel, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): explanation_panel.visible = false)

func _on_close_explanation() -> void:
	_fade_out_explanation_panel()
	explanation_closed.emit()

# Constitutional compliance helpers

func create_metric_tooltip(metric_type: String, value: Variant, context: Dictionary = {}) -> TooltipData:
	"""Create tooltip data for constitutional transparency requirement"""
	var data = TooltipData.new()

	match metric_type:
		"poll_percentage":
			data.title = tr("tooltip.poll_percentage.title")
			data.current_value = "%.1f%%" % value
			data.explanation = tr("tooltip.poll_percentage.explanation")
			data.contributing_factors = [
				tr("tooltip.poll_percentage.factor1"),
				tr("tooltip.poll_percentage.factor2"),
				tr("tooltip.poll_percentage.factor3")
			]
		"projected_seats":
			data.title = tr("tooltip.projected_seats.title")
			data.current_value = "%d " + tr("common.seats") % value
			data.explanation = tr("tooltip.projected_seats.explanation")
			data.contributing_factors = [
				tr("tooltip.projected_seats.factor1"),
				tr("tooltip.projected_seats.factor2")
			]
		"campaign_funds":
			data.title = tr("tooltip.campaign_funds.title")
			data.current_value = "€%s" % String.num(value, 0)
			data.explanation = tr("tooltip.campaign_funds.explanation")
			data.contributing_factors = [
				tr("tooltip.campaign_funds.factor1"),
				tr("tooltip.campaign_funds.factor2")
			]
		_:
			data.title = metric_type.capitalize()
			data.explanation = tr("tooltip.generic.explanation")

	return data

func create_calculation_explanation(calc_type: String, inputs: Dictionary, result: Variant) -> ExplanationPanel:
	"""Create detailed explanation panel for complex calculations"""
	var panel = ExplanationPanel.new()
	panel.calculation_name = calc_type.capitalize()
	panel.input_values = inputs

	match calc_type:
		"seat_projection":
			panel.step_by_step = [
				"Current polling: %.1f%%" % inputs.get("poll_percentage", 0),
				"Apply D'Hondt divisor method",
				"Account for regional variations",
				"Final seat projection: %d" % result
			]
			panel.assumptions = [
				"Current polling trends continue",
				"Turnout similar to previous elections",
				"D'Hondt calculation method used"
			]
			panel.confidence_level = "medium"
		"coalition_compatibility":
			panel.step_by_step = [
				"Analyze ideological positions",
				"Compare policy stances",
				"Historical coalition patterns",
				"Compatibility score: %.2f" % result
			]
			panel.assumptions = [
				"Party positions remain stable",
				"No major policy shifts",
				"Normal coalition dynamics"
			]
			panel.confidence_level = "high"
		_:
			panel.step_by_step = ["Calculation not yet implemented"]
			panel.assumptions = ["Standard assumptions apply"]
			panel.confidence_level = "unknown"

	return panel