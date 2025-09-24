extends Control
class_name NotificationSystem

# Notification system for non-blocking user feedback
# Provides toast notifications and modal dialogs

@onready var toast_container: VBoxContainer = $ToastContainer
@onready var modal_overlay: ColorRect = $ModalOverlay
@onready var modal_dialog: AcceptDialog = $ModalOverlay/ModalDialog
@onready var modal_title: Label = $ModalOverlay/ModalDialog/VBoxContainer/Title
@onready var modal_content: RichTextLabel = $ModalOverlay/ModalDialog/VBoxContainer/Content
@onready var modal_buttons: HBoxContainer = $ModalOverlay/ModalDialog/VBoxContainer/Buttons

var toast_scene: PackedScene
var active_toasts: Array[Control] = []
var modal_result: String = ""
var max_toasts: int = 5

signal notification_shown(message: String, type: String)
signal modal_response(button_text: String)

func _ready():
	# Setup toast container
	toast_container.alignment = BoxContainer.ALIGNMENT_END

	# Setup modal overlay
	modal_overlay.visible = false
	modal_overlay.color = Color(0, 0, 0, 0.5)
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Create toast scene template
	_create_toast_template()

func show_notification(message: String, type: String, duration: float = 3.0) -> void:
	"""Display non-blocking notification toast"""
	# Create toast notification
	var toast = _create_toast(message, type, duration)

	# Add to container and active list
	toast_container.add_child(toast)
	active_toasts.append(toast)

	# Remove old toasts if we have too many
	_cleanup_old_toasts()

	# Animate toast in
	_animate_toast_in(toast)

	# Schedule removal
	_schedule_toast_removal(toast, duration)

	notification_shown.emit(message, type)

func show_modal_dialog(title: String, content: String, buttons: Array[String]) -> String:
	"""Show modal dialog requiring user acknowledgment"""
	# Setup dialog content
	modal_title.text = title
	modal_content.text = content

	# Clear existing buttons
	for child in modal_buttons.get_children():
		child.queue_free()

	# Create buttons
	for button_text in buttons:
		var button = Button.new()
		button.text = tr(button_text) if button_text.begins_with("common.") else button_text
		button.pressed.connect(_on_modal_button_pressed.bind(button_text))
		modal_buttons.add_child(button)

		# Focus first button
		if button_text == buttons[0]:
			button.call_deferred("grab_focus")

	# Show modal
	_show_modal()

	# Wait for response
	await modal_response

	return modal_result

func hide_modal() -> void:
	"""Hide modal dialog"""
	_hide_modal()

func clear_all_notifications() -> void:
	"""Clear all active toast notifications"""
	for toast in active_toasts:
		if is_instance_valid(toast):
			_animate_toast_out(toast)
	active_toasts.clear()

func show_campaign_notification(action_result: ActionResult) -> void:
	"""Show notification for campaign action results"""
	var message = ""
	var type = "info"

	if action_result.success:
		type = "success"
		message = tr("notification.action_success") % action_result.explanation

		# Show effects breakdown
		for effect_type in action_result.effects.keys():
			var value = action_result.effects[effect_type]
			var effect_message = tr("notification.effect." + effect_type) % value
			show_notification(effect_message, "info", 4.0)
	else:
		type = "error"
		message = tr("notification.action_failed") % action_result.explanation

	show_notification(message, type, 5.0)

func show_media_response_notification(response: MediaResponse) -> void:
	"""Show notification for media event responses"""
	var message = ""
	var type = "info"

	if response.sentiment_change > 0.1:
		type = "success"
		message = tr("notification.positive_media_response")
	elif response.sentiment_change < -0.1:
		type = "warning"
		message = tr("notification.negative_media_response")
	else:
		message = tr("notification.neutral_media_response")

	message += " " + response.explanation
	show_notification(message, type, 4.0)

func show_coalition_notification(validation: CoalitionValidation) -> void:
	"""Show notification for coalition validation results"""
	var message = ""
	var type = "info"

	if validation.is_feasible:
		if validation.majority_status:
			type = "success"
			message = tr("notification.coalition_majority") % validation.total_seats
		else:
			type = "warning"
			message = tr("notification.coalition_minority") % validation.total_seats
	else:
		type = "error"
		message = tr("notification.coalition_impossible")

		# Show blocking issues
		for issue in validation.blocking_issues:
			var issue_message = tr("notification.coalition_blocked") % issue
			show_notification(issue_message, "error", 3.0)

	show_notification(message, type, 4.0)

func _create_toast_template() -> void:
	"""Create reusable toast template"""
	# This would ideally load a .tscn file, but creating programmatically for now
	toast_scene = PackedScene.new()

func _create_toast(message: String, type: String, duration: float) -> Control:
	"""Create individual toast notification"""
	var toast = Panel.new()
	toast.custom_minimum_size = Vector2(300, 60)

	# Style based on type
	var style_box = StyleBoxFlat.new()
	match type:
		"success":
			style_box.bg_color = Color.GREEN
		"warning":
			style_box.bg_color = Color.ORANGE
		"error":
			style_box.bg_color = Color.RED
		"info":
			style_box.bg_color = Color.BLUE
		_:
			style_box.bg_color = Color.GRAY

	style_box.bg_color.a = 0.9
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8

	toast.add_theme_stylebox_override("panel", style_box)

	# Add content
	var hbox = HBoxContainer.new()
	toast.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)

	# Icon
	var icon = Label.new()
	match type:
		"success":
			icon.text = "✓"
		"warning":
			icon.text = "⚠"
		"error":
			icon.text = "✗"
		"info":
			icon.text = "ℹ"
		_:
			icon.text = "•"

	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(icon)

	# Message
	var label = RichTextLabel.new()
	label.text = message
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_color_override("default_color", Color.WHITE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.flat = true
	close_btn.pressed.connect(_remove_toast.bind(toast))
	hbox.add_child(close_btn)

	# Store metadata
	toast.set_meta("type", type)
	toast.set_meta("duration", duration)
	toast.set_meta("creation_time", Time.get_ticks_msec())

	return toast

func _animate_toast_in(toast: Control) -> void:
	"""Animate toast sliding in from right"""
	var start_pos = toast.position
	toast.position.x = get_viewport().get_visible_rect().size.x

	var tween = create_tween()
	tween.tween_property(toast, "position:x", start_pos.x, 0.3)
	tween.tween_property(toast, "modulate:a", 1.0, 0.3)

func _animate_toast_out(toast: Control) -> void:
	"""Animate toast sliding out to right"""
	var tween = create_tween()
	tween.tween_property(toast, "position:x", get_viewport().get_visible_rect().size.x, 0.3)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_remove_toast.bind(toast))

func _schedule_toast_removal(toast: Control, duration: float) -> void:
	"""Schedule automatic toast removal"""
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(toast) and toast in active_toasts:
		_animate_toast_out(toast)

func _remove_toast(toast: Control) -> void:
	"""Remove toast from display and active list"""
	if toast in active_toasts:
		active_toasts.erase(toast)

	if is_instance_valid(toast):
		toast.queue_free()

func _cleanup_old_toasts() -> void:
	"""Remove oldest toasts if we exceed the limit"""
	while active_toasts.size() > max_toasts:
		var oldest_toast = active_toasts[0]
		_animate_toast_out(oldest_toast)

func _show_modal() -> void:
	"""Show modal overlay and dialog"""
	modal_overlay.visible = true
	modal_dialog.popup_centered()

	# Animate overlay fade-in
	modal_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(modal_overlay, "modulate:a", 1.0, 0.2)

func _hide_modal() -> void:
	"""Hide modal overlay and dialog"""
	modal_dialog.hide()

	# Animate overlay fade-out
	var tween = create_tween()
	tween.tween_property(modal_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): modal_overlay.visible = false)

func _on_modal_button_pressed(button_text: String) -> void:
	"""Handle modal button press"""
	modal_result = button_text
	_hide_modal()
	modal_response.emit(button_text)

# Constitutional compliance helpers

func show_explanation_request(explanation_available: bool) -> void:
	"""Show notification that detailed explanations are available"""
	if explanation_available:
		var message = tr("notification.explanation_available")
		show_notification(message, "info", 4.0)

func show_transparency_notice(metric_name: String) -> void:
	"""Show transparency notice for constitutional compliance"""
	var message = tr("notification.transparency_notice") % metric_name
	show_notification(message, "info", 3.0)

func show_accessibility_update(feature: String, enabled: bool) -> void:
	"""Show notification for accessibility feature changes"""
	var message_key = "notification.accessibility_enabled" if enabled else "notification.accessibility_disabled"
	var message = tr(message_key) % tr("accessibility.feature." + feature)
	show_notification(message, "success", 3.0)

func show_language_change(new_language: String) -> void:
	"""Show notification for language switch"""
	var language_name = tr("language.name." + new_language)
	var message = tr("notification.language_changed") % language_name
	show_notification(message, "success", 2.0)

# Campaign-specific notifications

func show_poll_change(old_value: float, new_value: float) -> void:
	"""Show notification for significant poll changes"""
	var change = new_value - old_value
	var message = ""
	var type = "info"

	if abs(change) > 1.0:  # Significant change
		if change > 0:
			type = "success"
			message = tr("notification.poll_increase") % change
		else:
			type = "warning"
			message = tr("notification.poll_decrease") % abs(change)

		show_notification(message, type, 4.0)

func show_funds_low_warning(current_funds: int, threshold: int = 25000) -> void:
	"""Show warning when campaign funds are running low"""
	if current_funds <= threshold:
		var message = tr("notification.funds_low") % current_funds
		show_notification(message, "warning", 5.0)

func show_election_approaching(days_left: int) -> void:
	"""Show notification when election is approaching"""
	if days_left <= 7:
		var message = tr("notification.election_approaching") % days_left
		show_notification(message, "warning", 5.0)
	elif days_left == 30:
		var message = tr("notification.election_month")
		show_notification(message, "info", 4.0)