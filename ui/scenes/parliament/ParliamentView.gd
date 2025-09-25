extends Control

# Parliamentary voting simulation scene controller
# Handles voting interface, seat visualization, and legislative processes

# UI References - MainContainer structure
@onready var session_status_label: Label = $MainContainer/HeaderContainer/SessionInfoContainer/SessionStatusLabel
@onready var government_status_label: Label = $MainContainer/HeaderContainer/SessionInfoContainer/GovernmentStatusLabel

# Left Panel - Legislation
@onready var legislation_list: VBoxContainer = $MainContainer/ContentContainer/LeftPanel/LegislationScrollContainer/LegislationList
@onready var legislation_title_label: Label = $MainContainer/ContentContainer/LeftPanel/LegislationInfoPanel/LegislationInfoContent/LegislationTitleLabel
@onready var legislation_description_label: RichTextLabel = $MainContainer/ContentContainer/LeftPanel/LegislationInfoPanel/LegislationInfoContent/LegislationDescriptionLabel
@onready var sponsor_label: Label = $MainContainer/ContentContainer/LeftPanel/LegislationInfoPanel/LegislationInfoContent/SponsorLabel

# Central Panel - Voting
@onready var seating_area: Control = $MainContainer/ContentContainer/CentralPanel/ParliamentSeatingPanel/SeatingArea
@onready var current_vote_title: Label = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/CurrentVoteTitle
@onready var vote_for_button: Button = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteButtonsContainer/VoteForButton
@onready var vote_against_button: Button = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteButtonsContainer/VoteAgainstButton
@onready var abstain_button: Button = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteButtonsContainer/AbstainButton
@onready var vote_progress_label: Label = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteResultContainer/VoteProgressLabel
@onready var for_count_label: Label = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteResultContainer/VoteCountsContainer/ForCountLabel
@onready var against_count_label: Label = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteResultContainer/VoteCountsContainer/AgainstCountLabel
@onready var abstain_count_label: Label = $MainContainer/ContentContainer/CentralPanel/VotingControlsContainer/VoteResultContainer/VoteCountsContainer/AbstainCountLabel

# Right Panel - Party Positions
@onready var party_positions_list: VBoxContainer = $MainContainer/ContentContainer/RightPanel/PartyPositionsScrollContainer/PartyPositionsList
@onready var voting_history_list: VBoxContainer = $MainContainer/ContentContainer/RightPanel/VotingHistoryContainer/HistoryScrollContainer/VotingHistoryList

# Action Buttons
@onready var back_button: Button = $MainContainer/ActionContainer/BackButton
@onready var propose_legislation_button: Button = $MainContainer/ActionContainer/ProposeLegislationButton
@onready var view_debate_button: Button = $MainContainer/ActionContainer/ViewDebateButton
@onready var help_button: Button = $MainContainer/ActionContainer/HelpButton

# Parliamentary State
var current_legislation: DataModels.Legislation
var current_vote_counts := {"for": 0, "against": 0, "abstain": 0}
var player_vote_cast := false
var voting_in_progress := false

# Scene Dependencies
var localization_manager: Node
var tooltip_manager: Node
var notification_system: Node
var navigation_controller: Node

func _ready() -> void:
	# Get singleton references (autoloads)
	localization_manager = LocalizationManager
	tooltip_manager = get_node("/root/TooltipManager") if has_node("/root/TooltipManager") else null
	notification_system = get_node("/root/NotificationSystem") if has_node("/root/NotificationSystem") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null
	
	# Initialize parliament session
	_initialize_parliament_session()
	_setup_accessibility()
	_load_proposed_legislation()
	_update_party_positions()
	_setup_tooltips()

func _initialize_parliament_session() -> void:
	"""Initialize parliamentary session state and UI"""
	# Update session status
	session_status_label.text = localization_manager.get_localized_text("parliament.session_active")
	government_status_label.text = localization_manager.get_localized_text("parliament.coalition_status")
	
	# Initialize voting interface
	current_vote_title.text = localization_manager.get_localized_text("parliament.no_active_vote")
	_disable_voting_buttons()
	
	# Clear vote counts
	_update_vote_display()

func _setup_accessibility() -> void:
	"""Configure accessibility features for parliament interface"""
	# Keyboard navigation for voting buttons
	vote_for_button.focus_neighbor_right = vote_against_button.get_path()
	vote_against_button.focus_neighbor_left = vote_for_button.get_path()
	vote_against_button.focus_neighbor_right = abstain_button.get_path()
	abstain_button.focus_neighbor_left = vote_against_button.get_path()
	
	# Screen reader descriptions (skip theme loading if files don't exist)
	var accessibility_focus = load("res://ui/themes/accessibility_focus.tres")
	if accessibility_focus:
		vote_for_button.add_theme_stylebox_override("focus", accessibility_focus)
		vote_against_button.add_theme_stylebox_override("focus", accessibility_focus)
		abstain_button.add_theme_stylebox_override("focus", accessibility_focus)

func _load_proposed_legislation() -> void:
	"""Load and display current legislative proposals"""
	# Clear existing legislation list
	for child in legislation_list.get_children():
		child.queue_free()
	
	# Load legislation from simulation API (stub implementation)
	var proposed_bills = _get_proposed_legislation()
	
	for bill in proposed_bills:
		var legislation_item := Button.new()
		legislation_item.text = bill.title
		legislation_item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		legislation_item.pressed.connect(_on_legislation_selected.bind(bill))
		legislation_list.add_child(legislation_item)
	
	# Select first legislation if available
	if proposed_bills.size() > 0:
		_on_legislation_selected(proposed_bills[0])

func _get_proposed_legislation() -> Array[DataModels.Legislation]:
	"""Retrieve proposed legislation from simulation API"""
	var bills: Array[DataModels.Legislation] = []
	
	# Stub implementation - would connect to FakeSimulation
	var healthcare_bill := DataModels.Legislation.new()
	healthcare_bill.title = "Healthcare Reform Act 2024"
	healthcare_bill.description = "Comprehensive healthcare system modernization"
	healthcare_bill.sponsor_party = "VVD"
	healthcare_bill.status = DataModels.LegislationStatus.IN_DEBATE
	bills.append(healthcare_bill)
	
	var climate_bill := DataModels.Legislation.new()
	climate_bill.title = "Climate Action Framework"
	climate_bill.description = "National climate change mitigation strategy"
	climate_bill.sponsor_party = "D66"
	climate_bill.status = DataModels.LegislationStatus.IN_COMMITTEE
	bills.append(climate_bill)
	
	return bills

func _on_legislation_selected(legislation: DataModels.Legislation) -> void:
	"""Handle selection of legislation for review and voting"""
	current_legislation = legislation
	
	# Update legislation info panel
	legislation_title_label.text = legislation.title
	legislation_description_label.text = legislation.description
	sponsor_label.text = localization_manager.get_localized_text("parliament.sponsored_by") + ": " + legislation.sponsor_party
	
	# Check if voting is available
	if legislation.status == DataModels.LegislationStatus.IN_VOTE:
		_start_voting_session(legislation)
	else:
		current_vote_title.text = localization_manager.get_localized_text("parliament.not_ready_for_vote")
		_disable_voting_buttons()

func _start_voting_session(legislation: DataModels.Legislation) -> void:
	"""Begin voting session for selected legislation"""
	voting_in_progress = true
	player_vote_cast = false
	
	current_vote_title.text = localization_manager.get_localized_text("parliament.voting_on") + ": " + legislation.title
	_enable_voting_buttons()
	
	# Initialize vote counts
	current_vote_counts = {"for": 0, "against": 0, "abstain": 0}
	_update_vote_display()
	
	# Start AI party voting simulation
	_simulate_party_votes()

func _enable_voting_buttons() -> void:
	"""Enable voting buttons for player interaction"""
	vote_for_button.disabled = false
	vote_against_button.disabled = false
	abstain_button.disabled = false

func _disable_voting_buttons() -> void:
	"""Disable voting buttons when no vote is active"""
	vote_for_button.disabled = true
	vote_against_button.disabled = true
	abstain_button.disabled = true

func _simulate_party_votes() -> void:
	"""Simulate other parties' voting behavior based on ideology"""
	if not current_legislation:
		return
	
	# Simulate votes based on party positions and legislation type
	var parties = _get_parliamentary_parties()
	
	for party in parties:
		var vote_position = _calculate_party_vote_position(party, current_legislation)
		current_vote_counts[vote_position] += party.seats
	
	_update_vote_display()

func _calculate_party_vote_position(party: DataModels.Party, legislation: DataModels.Legislation) -> String:
	"""Calculate how a party would vote based on ideology and legislation content"""
	# Simplified ideology-based voting logic
	var party_position = party.ideology_position
	var legislation_type = legislation.policy_category
	
	# Conservative parties more likely to vote against progressive legislation
	if party_position.x < -0.3 and legislation_type == "progressive":
		return "against" if randf() < 0.7 else "abstain"
	# Progressive parties more likely to support progressive legislation
	elif party_position.x > 0.3 and legislation_type == "progressive":
		return "for" if randf() < 0.8 else "abstain"
	# Centrist parties vary based on specific policies
	else:
		var support_probability = 0.4 + randf() * 0.4
		if randf() < support_probability:
			return "for"
		elif randf() < 0.3:
			return "abstain"
		else:
			return "against"

func _get_parliamentary_parties() -> Array[DataModels.Party]:
	"""Get parties currently in parliament with seat counts"""
	var parties: Array[DataModels.Party] = []
	
	# Stub implementation - would connect to game state
	var vvd := DataModels.Party.new()
	vvd.name = "VVD"
	vvd.seats = 34
	vvd.ideology_position = Vector2(0.6, -0.2)
	parties.append(vvd)
	
	var pvda := DataModels.Party.new()
	pvda.name = "PvdA"
	pvda.seats = 9
	pvda.ideology_position = Vector2(-0.5, 0.3)
	parties.append(pvda)
	
	return parties

func _update_vote_display() -> void:
	"""Update vote count display"""
	for_count_label.text = localization_manager.get_localized_text("parliament.for_votes") + ": " + str(current_vote_counts["for"])
	against_count_label.text = localization_manager.get_localized_text("parliament.against_votes") + ": " + str(current_vote_counts["against"])
	abstain_count_label.text = localization_manager.get_localized_text("parliament.abstain_votes") + ": " + str(current_vote_counts["abstain"])
	
	# Update progress indicator
	var total_votes = current_vote_counts["for"] + current_vote_counts["against"] + current_vote_counts["abstain"]
	var total_seats = 150  # Dutch parliament seats
	vote_progress_label.text = localization_manager.get_localized_text("parliament.votes_cast") + ": " + str(total_votes) + "/" + str(total_seats)

func _update_party_positions() -> void:
	"""Update party position display for current legislation"""
	# Clear existing positions
	for child in party_positions_list.get_children():
		child.queue_free()
	
	var parties = _get_parliamentary_parties()
	for party in parties:
		var position_item := Label.new()
		var stance = _get_party_stance_text(party, current_legislation)
		position_item.text = party.name + ": " + stance
		party_positions_list.add_child(position_item)

func _get_party_stance_text(party: DataModels.Party, legislation: DataModels.Legislation) -> String:
	"""Get descriptive text for party's stance on legislation"""
	if not legislation:
		return localization_manager.get_localized_text("parliament.no_position")
	
	# Simplified stance based on ideology
	var position = party.ideology_position.x
	if position < -0.3:
		return localization_manager.get_localized_text("parliament.likely_oppose")
	elif position > 0.3:
		return localization_manager.get_localized_text("parliament.likely_support")
	else:
		return localization_manager.get_localized_text("parliament.undecided")

func _setup_tooltips() -> void:
	"""Setup educational tooltips for parliamentary process"""
	if tooltip_manager:
		tooltip_manager.call("add_tooltip", vote_for_button, "tooltip.vote_for_explanation")
		tooltip_manager.call("add_tooltip", vote_against_button, "tooltip.vote_against_explanation")
		tooltip_manager.call("add_tooltip", abstain_button, "tooltip.abstain_explanation")
		tooltip_manager.call("add_tooltip", seating_area, "tooltip.parliament_seating_explanation")

# Signal Handlers
func _on_vote_for_pressed() -> void:
	"""Handle player voting FOR current legislation"""
	if not voting_in_progress or player_vote_cast:
		return
	
	_cast_player_vote("for")
	if notification_system:
		notification_system.call("show_notification", "notification.vote_cast_for")

func _on_vote_against_pressed() -> void:
	"""Handle player voting AGAINST current legislation"""
	if not voting_in_progress or player_vote_cast:
		return
	
	_cast_player_vote("against")
	if notification_system:
		notification_system.call("show_notification", "notification.vote_cast_against")

func _on_abstain_pressed() -> void:
	"""Handle player ABSTAINING from current vote"""
	if not voting_in_progress or player_vote_cast:
		return
	
	_cast_player_vote("abstain")
	if notification_system:
		notification_system.call("show_notification", "notification.vote_cast_abstain")

func _cast_player_vote(vote_type: String) -> void:
	"""Process player's vote and update display"""
	player_vote_cast = true
	current_vote_counts[vote_type] += 1  # Player's party seats
	
	_update_vote_display()
	_disable_voting_buttons()
	
	# Check if vote is complete and determine outcome
	_check_vote_completion()

func _check_vote_completion() -> void:
	"""Check if voting is complete and process results"""
	var total_votes = current_vote_counts["for"] + current_vote_counts["against"] + current_vote_counts["abstain"]
	var total_seats = 150
	
	if total_votes >= total_seats:
		_process_vote_results()

func _process_vote_results() -> void:
	"""Process completed vote and show results"""
	voting_in_progress = false
	
	var for_votes = current_vote_counts["for"]
	var against_votes = current_vote_counts["against"]
	
	# Determine outcome (simple majority)
	var passed = for_votes > against_votes
	
	var result_message: String
	if passed:
		result_message = localization_manager.get_localized_text("parliament.bill_passed")
	else:
		result_message = localization_manager.get_localized_text("parliament.bill_failed")
	
	if notification_system:
		notification_system.call("show_notification", result_message + ": " + current_legislation.title)
	
	# Update legislation status
	current_legislation.status = DataModels.LegislationStatus.PASSED if passed else DataModels.LegislationStatus.FAILED
	
	# Add to voting history
	_add_to_voting_history(current_legislation, passed)

func _add_to_voting_history(legislation: DataModels.Legislation, passed: bool) -> void:
	"""Add completed vote to voting history display"""
	var history_item := Label.new()
	var status_text = localization_manager.get_localized_text("parliament.passed" if passed else "parliament.failed")
	history_item.text = legislation.title + " - " + status_text
	voting_history_list.add_child(history_item)

func _on_back_button_pressed() -> void:
	"""Handle back button navigation"""
	if navigation_controller:
		navigation_controller.call("navigate_to_previous_scene")

func _on_propose_legislation_pressed() -> void:
	"""Handle propose legislation button"""
	# Would open legislation proposal interface
	if notification_system:
		notification_system.call("show_notification", "notification.feature_coming_soon")

func _on_view_debate_pressed() -> void:
	"""Handle view debate button"""
	# Would open debate visualization
	if notification_system:
		notification_system.call("show_notification", "notification.feature_coming_soon")

func _on_help_button_pressed() -> void:
	"""Handle help button"""
	# Would show parliamentary process help
	if notification_system:
		notification_system.call("show_notification", "notification.help_coming_soon")
