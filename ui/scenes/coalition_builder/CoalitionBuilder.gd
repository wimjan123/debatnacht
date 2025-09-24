extends Control
class_name CoalitionBuilderScene

# Coalition builder scene with drag-and-drop coalition formation
# Interactive interface for building and validating coalition governments

@onready var available_parties_list: VBoxContainer = $MainContainer/LeftPanel/PartiesScrollContainer/AvailablePartiesList
@onready var party_name_label: Label = $MainContainer/LeftPanel/PartyInfoPanel/PartyInfoContent/PartyNameLabel
@onready var party_seats_label: Label = $MainContainer/LeftPanel/PartyInfoPanel/PartyInfoContent/PartySeatsLabel
@onready var party_ideology_label: Label = $MainContainer/LeftPanel/PartyInfoPanel/PartyInfoContent/PartyIdeologyLabel
@onready var compatibility_label: Label = $MainContainer/LeftPanel/PartyInfoPanel/PartyInfoContent/CompatibilityLabel

@onready var total_seats_label: Label = $MainContainer/CentralPanel/CoalitionStatusContainer/StatusLabelsContainer/TotalSeatsLabel
@onready var majority_status_label: Label = $MainContainer/CentralPanel/CoalitionStatusContainer/StatusLabelsContainer/MajorityStatusLabel
@onready var stability_label: Label = $MainContainer/CentralPanel/CoalitionStatusContainer/StatusLabelsContainer/StabilityLabel

@onready var coalition_drop_zone: Panel = $MainContainer/CentralPanel/CoalitionDropZone
@onready var coalition_parties_list: VBoxContainer = $MainContainer/CentralPanel/CoalitionDropZone/CoalitionPartiesList
@onready var drop_zone_label: Label = $MainContainer/CentralPanel/CoalitionDropZone/DropZoneLabel

@onready var validation_content: VBoxContainer = $MainContainer/RightPanel/ValidationResultsPanel/ValidationContent
@onready var feasibility_label: Label = $MainContainer/RightPanel/ValidationResultsPanel/ValidationContent/FeasibilityLabel
@onready var blocking_issues_list: VBoxContainer = $MainContainer/RightPanel/ValidationResultsPanel/ValidationContent/BlockingIssuesList
@onready var policy_agreements_list: VBoxContainer = $MainContainer/RightPanel/PolicyAgreementsContainer/PolicyScrollContainer/PolicyAgreementsList

@onready var validate_button: Button = $MainContainer/CentralPanel/ActionButtonsContainer/ValidateCoalitionButton
@onready var clear_button: Button = $MainContainer/CentralPanel/ActionButtonsContainer/ClearCoalitionButton
@onready var finalize_button: Button = $BottomActionsContainer/FinalizeCoalitionButton
@onready var back_button: Button = $BottomActionsContainer/BackButton

var coalition_controller: CoalitionBuilderController
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var accessibility_manager: AccessibilityManager
var navigation_controller: NavigationController

var available_parties: Array[Party] = []
var party_buttons: Array[Control] = []
var coalition_party_buttons: Array[Control] = []
var selected_party: Party = null
var current_validation: CoalitionValidation = null

var dragging: bool = false
var drag_preview: Control = null

signal coalition_formed(coalition: Coalition)
signal party_added_to_coalition(party: Party)
signal party_removed_from_coalition(party: Party)

func _ready():
	# Get managers
	tooltip_manager = get_node("/root/TooltipManager") if has_node("/root/TooltipManager") else null
	notification_system = get_node("/root/NotificationSystem") if has_node("/root/NotificationSystem") else null
	accessibility_manager = get_node("/root/AccessibilityManager") if has_node("/root/AccessibilityManager") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null

	# Initialize controller
	coalition_controller = CoalitionBuilderController.new()
	coalition_controller.coalition_updated.connect(_on_coalition_updated)
	coalition_controller.compatibility_calculated.connect(_on_compatibility_calculated)
	coalition_controller.validation_result.connect(_on_validation_result)
	coalition_controller.negotiation_progress.connect(_on_negotiation_progress)

	# Setup UI
	_update_localization()
	_setup_drop_zone()
	_setup_tooltips()

	# Initialize coalition builder
	coalition_controller.initialize_coalition_builder()

func receive_transition_data(data: Dictionary):
	"""Receive transition data from navigation"""
	if data.has("available_parties"):
		var parties_data = data.available_parties
		if parties_data is Array:
			available_parties = parties_data
			_populate_available_parties()

	if data.has("election_result"):
		var election = data.election_result
		coalition_controller.initialize_coalition_builder(election)

func _populate_available_parties():
	"""Populate available parties list"""
	# Clear existing buttons
	for button in party_buttons:
		button.queue_free()
	party_buttons.clear()

	# Get parties from controller if not provided
	if available_parties.is_empty():
		available_parties = coalition_controller.available_parties

	# Create party buttons
	for party in available_parties:
		_create_party_button(party)

func _create_party_button(party: Party):
	"""Create draggable button for party"""
	var party_button = Panel.new()
	party_button.custom_minimum_size = Vector2(200, 80)
	party_button.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox = VBoxContainer.new()
	party_button.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)

	var name_label = Label.new()
	name_label.text = party.party_name
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	var seats_label = Label.new()
	var party_seats = coalition_controller._get_party_seats(party)
	seats_label.text = tr("coalition.seats_count") % party_seats
	vbox.add_child(seats_label)

	var ideology_label = Label.new()
	ideology_label.text = _format_ideology(party.ideology_position)
	ideology_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(ideology_label)

	# Style based on party characteristics
	_style_party_button(party_button, party)

	# Set up drag and drop
	party_button.set_meta("party", party)
	party_button.gui_input.connect(_on_party_button_input.bind(party_button))
	party_button.mouse_entered.connect(_on_party_button_hovered.bind(party))

	# Add tooltip
	if tooltip_manager:
		var tooltip_data = _create_party_tooltip(party)
		tooltip_manager.register_tooltip_target(party_button, tooltip_data)

	available_parties_list.add_child(party_button)
	party_buttons.append(party_button)

func _style_party_button(button: Panel, party: Party):
	"""Style party button based on characteristics"""
	var style_box = StyleBoxFlat.new()

	# Color based on ideology
	var economic_pos = party.ideology_position.economic
	var social_pos = party.ideology_position.social

	if economic_pos > 0.5:
		style_box.bg_color = Color(0.8, 0.9, 1.0)  # Light blue for conservative
	elif economic_pos < -0.5:
		style_box.bg_color = Color(1.0, 0.8, 0.8)  # Light red for progressive
	else:
		style_box.bg_color = Color(0.9, 0.9, 0.9)  # Gray for centrist

	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8

	button.add_theme_stylebox_override("panel", style_box)

func _format_ideology(ideology: Dictionary) -> String:
	"""Format ideology position for display"""
	var economic = ideology.get("economic", 0.0)
	var social = ideology.get("social", 0.0)

	var econ_text = ""
	if economic > 0.5:
		econ_text = tr("coalition.ideology.conservative")
	elif economic < -0.5:
		econ_text = tr("coalition.ideology.progressive")
	else:
		econ_text = tr("coalition.ideology.centrist")

	var social_text = ""
	if social > 0.5:
		social_text = tr("coalition.ideology.traditional")
	elif social < -0.5:
		social_text = tr("coalition.ideology.liberal")
	else:
		social_text = tr("coalition.ideology.moderate")

	return econ_text + " / " + social_text

func _create_party_tooltip(party: Party) -> TooltipData:
	"""Create tooltip data for party"""
	if not tooltip_manager:
		return null

	var tooltip = TooltipData.new()
	tooltip.title = party.party_name
	tooltip.explanation = tr("coalition.party_tooltip.explanation") % party.party_name

	var seats = coalition_controller._get_party_seats(party)
	tooltip.contributing_factors = [
		tr("coalition.party_tooltip.seats") % seats,
		tr("coalition.party_tooltip.ideology") % _format_ideology(party.ideology_position),
		tr("coalition.party_tooltip.positions") % party.policy_positions.size()
	]

	return tooltip

func _setup_drop_zone():
	"""Setup coalition drop zone"""
	coalition_drop_zone.mouse_entered.connect(_on_drop_zone_entered)
	coalition_drop_zone.mouse_exited.connect(_on_drop_zone_exited)

func _setup_tooltips():
	"""Setup explanatory tooltips"""
	if not tooltip_manager:
		return

	# Coalition validation tooltip
	var validation_tooltip = TooltipData.new()
	validation_tooltip.title = tr("coalition.validation_tooltip.title")
	validation_tooltip.explanation = tr("coalition.validation_tooltip.explanation")
	validation_tooltip.contributing_factors = [
		tr("coalition.validation_tooltip.majority"),
		tr("coalition.validation_tooltip.compatibility"),
		tr("coalition.validation_tooltip.stability")
	]
	tooltip_manager.register_tooltip_target(validation_content.get_parent(), validation_tooltip)

func _update_localization():
	"""Update all text with current localization"""
	# Left panel
	$MainContainer/LeftPanel/AvailablePartiesTitle.text = tr("coalition.available_parties")
	$MainContainer/LeftPanel/PartyInfoPanel/PartyInfoContent/PartyInfoTitle.text = tr("coalition.party_info")

	# Central panel
	$MainContainer/CentralPanel/CoalitionBuilderTitle.text = tr("coalition.builder_title")
	drop_zone_label.text = tr("coalition.drop_parties_here")
	validate_button.text = tr("coalition.validate")
	clear_button.text = tr("coalition.clear")

	# Right panel
	$MainContainer/RightPanel/ValidationResultsTitle.text = tr("coalition.validation_results")
	$MainContainer/RightPanel/PolicyAgreementsContainer/PolicyAgreementsTitle.text = tr("coalition.policy_agreements")

	# Bottom actions
	back_button.text = tr("common.back")
	$BottomActionsContainer/SimulateNegotiationsButton.text = tr("coalition.simulate_negotiations")
	finalize_button.text = tr("coalition.finalize")
	$BottomActionsContainer/HelpButton.text = tr("common.help")

# Drag and drop handling

func _on_party_button_input(event: InputEvent, party_button: Control):
	"""Handle party button input for drag and drop"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_start_drag(party_button)
			else:
				_end_drag(party_button)

	elif event is InputEventMouseMotion and dragging:
		_update_drag(event)

func _start_drag(party_button: Control):
	"""Start dragging party button"""
	dragging = true
	selected_party = party_button.get_meta("party")

	# Create drag preview
	drag_preview = party_button.duplicate()
	drag_preview.modulate.a = 0.7
	drag_preview.z_index = 100
	get_viewport().add_child(drag_preview)

	# Update drag preview position
	drag_preview.global_position = get_global_mouse_position() - party_button.size / 2

func _update_drag(event: InputEventMouseMotion):
	"""Update drag preview position"""
	if drag_preview:
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2

func _end_drag(party_button: Control):
	"""End dragging and handle drop"""
	if not dragging:
		return

	dragging = false

	# Check if dropped on coalition zone
	var mouse_pos = get_global_mouse_position()
	var drop_zone_rect = coalition_drop_zone.get_global_rect()

	if drop_zone_rect.has_point(mouse_pos):
		_add_party_to_coalition(selected_party)

	# Clean up drag preview
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

	selected_party = null

func _on_drop_zone_entered():
	"""Handle mouse entering drop zone"""
	if dragging:
		coalition_drop_zone.modulate = Color(1.2, 1.2, 1.2)

func _on_drop_zone_exited():
	"""Handle mouse leaving drop zone"""
	coalition_drop_zone.modulate = Color.WHITE

func _add_party_to_coalition(party: Party):
	"""Add party to coalition"""
	var success = coalition_controller.add_party_to_coalition(party)

	if success:
		party_added_to_coalition.emit(party)

		if notification_system:
			notification_system.show_notification(
				tr("coalition.party_added") % party.party_name,
				"success",
				2.0
			)
	else:
		if notification_system:
			notification_system.show_notification(
				tr("coalition.party_add_failed") % party.party_name,
				"error",
				3.0
			)

func _remove_party_from_coalition(party: Party):
	"""Remove party from coalition"""
	var success = coalition_controller.remove_party_from_coalition(party)

	if success:
		party_removed_from_coalition.emit(party)

		if notification_system:
			notification_system.show_notification(
				tr("coalition.party_removed") % party.party_name,
				"info",
				2.0
			)

# Party selection and info display

func _on_party_button_hovered(party: Party):
	"""Handle party button hover"""
	_update_party_info_display(party)

func _update_party_info_display(party: Party):
	"""Update party information panel"""
	party_name_label.text = party.party_name

	var seats = coalition_controller._get_party_seats(party)
	party_seats_label.text = tr("coalition.seats_display") % seats

	party_ideology_label.text = tr("coalition.ideology_display") % _format_ideology(party.ideology_position)

	# Calculate compatibility with current coalition
	if coalition_controller.proposed_coalition.member_parties.size() > 1:
		var avg_compatibility = 0.0
		var comparison_count = 0

		for member in coalition_controller.proposed_coalition.member_parties:
			if member != party:
				var compatibility = coalition_controller.calculate_party_compatibility(party, member)
				avg_compatibility += compatibility
				comparison_count += 1

		if comparison_count > 0:
			avg_compatibility /= comparison_count
			compatibility_label.text = tr("coalition.compatibility_display") % (avg_compatibility * 100.0)

			if avg_compatibility > 0.7:
				compatibility_label.add_theme_color_override("font_color", Color.GREEN)
			elif avg_compatibility > 0.4:
				compatibility_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				compatibility_label.add_theme_color_override("font_color", Color.RED)
	else:
		compatibility_label.text = tr("coalition.no_compatibility_data")

# Coalition updates and validation

func _on_coalition_updated(coalition: Coalition):
	"""Handle coalition update from controller"""
	_update_coalition_display(coalition)
	_update_coalition_status(coalition)

func _update_coalition_display(coalition: Coalition):
	"""Update coalition parties display"""
	# Clear existing coalition party displays
	for button in coalition_party_buttons:
		button.queue_free()
	coalition_party_buttons.clear()

	# Hide/show drop zone label
	drop_zone_label.visible = coalition.member_parties.size() <= 1

	# Create displays for coalition parties
	for party in coalition.member_parties:
		_create_coalition_party_display(party)

func _create_coalition_party_display(party: Party):
	"""Create display for party in coalition"""
	var party_display = Panel.new()
	party_display.custom_minimum_size = Vector2(180, 60)

	var hbox = HBoxContainer.new()
	party_display.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = party.party_name
	info_vbox.add_child(name_label)

	var seats_label = Label.new()
	var seats = coalition_controller._get_party_seats(party)
	seats_label.text = tr("coalition.seats_short") % seats
	info_vbox.add_child(seats_label)

	# Remove button (except for player party)
	var game_state = coalition_controller.game_state
	if game_state and party != game_state.player_party:
		var remove_button = Button.new()
		remove_button.text = "×"
		remove_button.custom_minimum_size = Vector2(30, 30)
		remove_button.pressed.connect(_remove_party_from_coalition.bind(party))
		hbox.add_child(remove_button)

	# Style coalition party
	_style_coalition_party_display(party_display, party)

	coalition_parties_list.add_child(party_display)
	coalition_party_buttons.append(party_display)

func _style_coalition_party_display(display: Panel, party: Party):
	"""Style coalition party display"""
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.9, 1.0, 0.9)  # Light green for coalition members
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6

	display.add_theme_stylebox_override("panel", style_box)

func _update_coalition_status(coalition: Coalition):
	"""Update coalition status display"""
	var total_seats = coalition_controller._calculate_total_seats()
	total_seats_label.text = tr("coalition.total_seats_display") % total_seats

	var majority_needed = 76
	if total_seats >= majority_needed:
		majority_status_label.text = tr("coalition.has_majority")
		majority_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		var needed = majority_needed - total_seats
		majority_status_label.text = tr("coalition.needs_majority") % needed
		majority_status_label.add_theme_color_override("font_color", Color.RED)

	# Update stability prediction
	if coalition.member_parties.size() > 1:
		var stability = coalition_controller._predict_coalition_stability()
		stability_label.text = tr("coalition.stability_display") % tr("coalition.stability." + stability)

		match stability:
			"high":
				stability_label.add_theme_color_override("font_color", Color.GREEN)
			"medium":
				stability_label.add_theme_color_override("font_color", Color.YELLOW)
			"low":
				stability_label.add_theme_color_override("font_color", Color.RED)

# Validation and policy agreements

func _on_validation_result(validation: CoalitionValidation):
	"""Handle validation result from controller"""
	current_validation = validation
	_update_validation_display(validation)

func _update_validation_display(validation: CoalitionValidation):
	"""Update validation results display"""
	# Feasibility
	if validation.is_feasible:
		feasibility_label.text = tr("coalition.feasible")
		feasibility_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		feasibility_label.text = tr("coalition.not_feasible")
		feasibility_label.add_theme_color_override("font_color", Color.RED)

	# Clear existing blocking issues
	for child in blocking_issues_list.get_children():
		if child != blocking_issues_list.get_child(0):  # Keep title
			child.queue_free()

	# Show blocking issues
	for issue in validation.blocking_issues:
		var issue_label = Label.new()
		issue_label.text = "• " + tr("coalition.blocking." + issue)
		issue_label.add_theme_color_override("font_color", Color.RED)
		blocking_issues_list.add_child(issue_label)

	# Update policy agreements
	_update_policy_agreements_display(validation.coalition.policy_agreements)

	# Enable/disable finalize button
	finalize_button.disabled = not validation.is_feasible

func _update_policy_agreements_display(agreements: Array[PolicyAgreement]):
	"""Update policy agreements display"""
	# Clear existing agreements
	for child in policy_agreements_list.get_children():
		child.queue_free()

	# Show policy agreements
	for agreement in agreements:
		_create_policy_agreement_display(agreement)

func _create_policy_agreement_display(agreement: PolicyAgreement):
	"""Create display for policy agreement"""
	var agreement_panel = Panel.new()
	agreement_panel.custom_minimum_size = Vector2(0, 80)

	var vbox = VBoxContainer.new()
	agreement_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)

	var title_label = Label.new()
	title_label.text = tr("policy." + agreement.policy_area)
	title_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title_label)

	var stability_label = Label.new()
	stability_label.text = tr("coalition.agreement_stability") % tr("coalition.stability." + agreement.stability)

	match agreement.stability:
		"high":
			stability_label.add_theme_color_override("font_color", Color.GREEN)
		"medium":
			stability_label.add_theme_color_override("font_color", Color.YELLOW)
		"low":
			stability_label.add_theme_color_override("font_color", Color.RED)

	vbox.add_child(stability_label)

	# Style agreement panel
	var style_box = StyleBoxFlat.new()
	match agreement.stability:
		"high":
			style_box.bg_color = Color(0.9, 1.0, 0.9)
		"medium":
			style_box.bg_color = Color(1.0, 1.0, 0.9)
		"low":
			style_box.bg_color = Color(1.0, 0.9, 0.9)

	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4

	agreement_panel.add_theme_stylebox_override("panel", style_box)
	policy_agreements_list.add_child(agreement_panel)

# Event handlers

func _on_compatibility_calculated(party1: Party, party2: Party, compatibility: float):
	"""Handle compatibility calculation result"""
	# This could update displays showing party relationships
	pass

func _on_negotiation_progress(party_id: String, progress: Dictionary):
	"""Handle negotiation progress update"""
	# This could show negotiation status in UI
	pass

# Button handlers

func _on_validate_coalition_pressed():
	"""Handle validate coalition button press"""
	var validation = coalition_controller.validate_coalition()

	if notification_system:
		var message = ""
		if validation.is_feasible:
			message = tr("coalition.validation_success")
		else:
			message = tr("coalition.validation_failed")

		notification_system.show_coalition_notification(validation)

func _on_clear_coalition_pressed():
	"""Handle clear coalition button press"""
	# Show confirmation dialog
	if notification_system:
		var result = await notification_system.show_modal_dialog(
			tr("coalition.clear_title"),
			tr("coalition.clear_confirmation"),
			["common.confirm", "common.cancel"]
		)

		if result == "common.confirm":
			# Reset coalition to just player party
			coalition_controller.proposed_coalition.member_parties = [coalition_controller.game_state.player_party]
			coalition_controller.coalition_updated.emit(coalition_controller.proposed_coalition)

func _on_simulate_negotiations_pressed():
	"""Handle simulate negotiations button press"""
	var negotiations = coalition_controller.simulate_coalition_negotiations()
	_show_negotiations_results(negotiations)

func _show_negotiations_results(negotiations: Dictionary):
	"""Show negotiation simulation results"""
	var results_text = tr("coalition.negotiation_results") + "\n\n"

	for party_id in negotiations.keys():
		var negotiation = negotiations[party_id]
		var party = negotiation.party
		results_text += party.party_name + ":\n"
		results_text += tr("coalition.likelihood") % (negotiation.likelihood * 100.0) + "\n"
		results_text += tr("coalition.timeline") % negotiation.timeline + "\n\n"

	if notification_system:
		notification_system.show_modal_dialog(
			tr("coalition.negotiation_title"),
			results_text,
			["common.ok"]
		)

func _on_finalize_coalition_pressed():
	"""Handle finalize coalition button press"""
	if not current_validation or not current_validation.is_feasible:
		return

	# Show final confirmation
	if notification_system:
		var confirmation_text = tr("coalition.finalize_confirmation") + "\n\n"
		confirmation_text += tr("coalition.final_total_seats") % current_validation.total_seats + "\n"
		confirmation_text += tr("coalition.final_stability") % current_validation.stability_prediction

		var result = await notification_system.show_modal_dialog(
			tr("coalition.finalize_title"),
			confirmation_text,
			["coalition.proceed", "common.cancel"]
		)

		if result == "coalition.proceed":
			var finalized_coalition = coalition_controller.finalize_coalition()
			coalition_formed.emit(finalized_coalition)

			notification_system.show_notification(
				tr("coalition.formation_success"),
				"success",
				4.0
			)

			# Navigate to next phase
			await get_tree().create_timer(2.0).timeout
			if navigation_controller:
				navigation_controller.navigate_to_screen("parliament")

func _on_back_button_pressed():
	"""Handle back button press"""
	if navigation_controller:
		navigation_controller.navigate_back()

func _on_help_button_pressed():
	"""Handle help button press"""
	_show_help_dialog()

func _show_help_dialog():
	"""Show coalition builder help"""
	var help_content = tr("coalition.help.overview") + "\n\n"
	help_content += tr("coalition.help.drag_drop") + "\n"
	help_content += tr("coalition.help.majority") + "\n"
	help_content += tr("coalition.help.compatibility") + "\n"
	help_content += tr("coalition.help.validation") + "\n"
	help_content += tr("coalition.help.negotiations")

	if notification_system:
		notification_system.show_modal_dialog(
			tr("coalition.help.title"),
			help_content,
			["common.ok"]
		)

# Input handling

func _input(event):
	"""Handle input for keyboard navigation and help"""
	if event.is_action_pressed("show_help"):
		_show_help_dialog()
		get_viewport().set_input_as_handled()

# Constitutional compliance

func _notification(what):
	"""Handle system notifications"""
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_localization()

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return coalition_controller.get_transparency_data() if coalition_controller else {}

func validate_democratic_legitimacy() -> Dictionary:
	"""Validate democratic legitimacy of coalition process"""
	return coalition_controller.validate_democratic_legitimacy() if coalition_controller else {}