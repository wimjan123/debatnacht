extends Control
class_name ElectionResultsScene

# Election results scene controller
# Handles results display, analysis, and post-election actions

# UI References - MainContainer structure
@onready var results_title: Label = $MainContainer/HeaderContainer/ResultsTitle
@onready var election_date_label: Label = $MainContainer/HeaderContainer/ElectionInfoContainer/ElectionDateLabel
@onready var turnout_label: Label = $MainContainer/HeaderContainer/ElectionInfoContainer/TurnoutLabel
@onready var valid_votes_label: Label = $MainContainer/HeaderContainer/ElectionInfoContainer/ValidVotesLabel

# Left Panel - Player and All Results
@onready var party_name_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/PartyNameLabel
@onready var votes_received_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/VotesContainer/VotesReceivedLabel
@onready var vote_percentage_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/VotesContainer/VotePercentageLabel
@onready var seats_won_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/SeatsContainer/SeatsWonLabel
@onready var seats_change_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/SeatsContainer/SeatsChangeLabel
@onready var government_status_label: Label = $MainContainer/ContentContainer/LeftPanel/PlayerResultsPanel/PlayerResultsContent/GovernmentStatusLabel
@onready var all_results_list: VBoxContainer = $MainContainer/ContentContainer/LeftPanel/ResultsScrollContainer/AllResultsList

# Central Panel - Seats Visualization
@onready var seats_visualization: Control = $MainContainer/ContentContainer/CentralPanel/ParliamentSeatsPanel/SeatsVisualization
@onready var majority_status_label: Label = $MainContainer/ContentContainer/CentralPanel/ParliamentStatsContainer/MajorityStatusLabel
@onready var coalition_required_label: Label = $MainContainer/ContentContainer/CentralPanel/ParliamentStatsContainer/CoalitionRequiredLabel

# Right Panel - Analysis
@onready var trends_content: RichTextLabel = $MainContainer/ContentContainer/RightPanel/AnalysisScrollContainer/AnalysisContent/TrendsContent
@onready var regional_content: RichTextLabel = $MainContainer/ContentContainer/RightPanel/AnalysisScrollContainer/AnalysisContent/RegionalContent
@onready var next_steps_content: RichTextLabel = $MainContainer/ContentContainer/RightPanel/AnalysisScrollContainer/AnalysisContent/NextStepsContent

# Action Buttons
@onready var back_button: Button = $MainContainer/ActionContainer/BackButton
@onready var export_results_button: Button = $MainContainer/ActionContainer/ExportResultsButton
@onready var coalition_builder_button: Button = $MainContainer/ActionContainer/CoalitionBuilderButton
@onready var new_election_button: Button = $MainContainer/ActionContainer/NewElectionButton
@onready var help_button: Button = $MainContainer/ActionContainer/HelpButton

# Election Results State
var election_results: ElectionResults
var player_party_results: PartyResults
var all_party_results: Array[PartyResults] = []
var total_valid_votes: int = 0
var total_seats: int = 150  # Dutch parliament seats

# Scene Dependencies
var localization_manager: LocalizationManager
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var navigation_controller: NavigationController

func _ready() -> void:
	# Get singleton references
	localization_manager = LocalizationManager.get_instance()
	tooltip_manager = TooltipManager.get_instance()
	notification_system = NotificationSystem.get_instance()
	navigation_controller = NavigationController.get_instance()
	
	# Initialize election results display
	_load_election_results()
	_display_election_info()
	_display_player_results()
	_display_all_results()
	_create_seats_visualization()
	_generate_analysis()
	_setup_tooltips()

func _load_election_results() -> void:
	"""Load election results from game state"""
	# Stub implementation - would load from simulation API
	election_results = _generate_sample_results()
	player_party_results = _get_player_party_results()
	all_party_results = _get_all_party_results()

func _generate_sample_results() -> ElectionResults:
	"""Generate sample election results for demonstration"""
	var results := ElectionResults.new()
	results.election_date = "2024-09-24"
	results.turnout_percentage = 78.3
	results.total_eligible_voters = 13200000
	results.total_valid_votes = int(results.total_eligible_voters * results.turnout_percentage / 100.0)
	return results

func _get_player_party_results() -> PartyResults:
	"""Get results for player's party"""
	var results := PartyResults.new()
	results.party_name = "New Democratic Party"
	results.votes_received = 1240000
	results.vote_percentage = 12.4
	results.seats_won = 19
	results.seats_change = +7  # Gained 7 seats
	results.is_in_government = false
	return results

func _get_all_party_results() -> Array[PartyResults]:
	"""Get results for all parties"""
	var results: Array[PartyResults] = []
	
	# Major Dutch parties with sample results
	var parties_data = [
		{"name": "VVD", "votes": 2100000, "seats": 34, "change": -4},
		{"name": "PVV", "votes": 1800000, "seats": 37, "change": +20},
		{"name": "New Democratic Party", "votes": 1240000, "seats": 19, "change": +7},  # Player
		{"name": "CDA", "votes": 920000, "seats": 15, "change": -4},
		{"name": "D66", "votes": 810000, "seats": 12, "change": -12},
		{"name": "GL-PvdA", "votes": 1650000, "seats": 25, "change": +8},
		{"name": "SP", "votes": 480000, "seats": 8, "change": +3}
	]
	
	for party_data in parties_data:
		var party_result := PartyResults.new()
		party_result.party_name = party_data.name
		party_result.votes_received = party_data.votes
		party_result.vote_percentage = float(party_data.votes) / total_valid_votes * 100.0
		party_result.seats_won = party_data.seats
		party_result.seats_change = party_data.change
		party_result.is_in_government = _determine_government_status(party_result)
		results.append(party_result)
	
	# Sort by seats won (descending)
	results.sort_custom(func(a, b): return a.seats_won > b.seats_won)
	return results

func _determine_government_status(party_result: PartyResults) -> bool:
	"""Determine if party is likely to be in government"""
	# Simplified logic - parties with >15 seats might form government
	return party_result.seats_won >= 15

func _display_election_info() -> void:
	"""Display general election information"""
	results_title.text = localization_manager.get_text("results.election_results_2024")
	election_date_label.text = localization_manager.get_text("results.date") + ": " + election_results.election_date
	turnout_label.text = localization_manager.get_text("results.turnout") + ": " + str(election_results.turnout_percentage) + "%"
	valid_votes_label.text = localization_manager.get_text("results.total_votes") + ": " + _format_number(election_results.total_valid_votes)

func _display_player_results() -> void:
	"""Display results for player's party"""
	party_name_label.text = player_party_results.party_name
	votes_received_label.text = localization_manager.get_text("results.votes") + ": " + _format_number(player_party_results.votes_received)
	vote_percentage_label.text = str(player_party_results.vote_percentage).pad_decimals(1) + "%"
	seats_won_label.text = str(player_party_results.seats_won) + " " + localization_manager.get_text("results.seats")
	
	# Format seats change with + or - indicator
	var change_text: String
	var change_color: Color
	if player_party_results.seats_change > 0:
		change_text = "+" + str(player_party_results.seats_change)
		change_color = Color.GREEN
	elif player_party_results.seats_change < 0:
		change_text = str(player_party_results.seats_change)
		change_color = Color.RED
	else:
		change_text = "0"
		change_color = Color.GRAY
	
	seats_change_label.text = "(" + change_text + ")"
	seats_change_label.add_theme_color_override("font_color", change_color)
	
	# Government status
	var status_text: String
	if player_party_results.seats_won >= 76:  # Absolute majority
		status_text = localization_manager.get_text("results.majority_government")
	elif player_party_results.is_in_government:
		status_text = localization_manager.get_text("results.coalition_partner")
	else:
		status_text = localization_manager.get_text("results.opposition")
	
	government_status_label.text = status_text

func _display_all_results() -> void:
	"""Display results for all parties"""
	# Clear existing results
	for child in all_results_list.get_children():
		child.queue_free()
	
	for party_result in all_party_results:
		var result_item = _create_party_result_item(party_result)
		all_results_list.add_child(result_item)

func _create_party_result_item(party_result: PartyResults) -> Control:
	"""Create visual item for party results"""
	var item_container := HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 30)
	
	# Party name
	var name_label := Label.new()
	name_label.text = party_result.party_name
	name_label.custom_minimum_size = Vector2(120, 0)
	item_container.add_child(name_label)
	
	# Seats won
	var seats_label := Label.new()
	seats_label.text = str(party_result.seats_won)
	seats_label.custom_minimum_size = Vector2(40, 0)
	seats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_container.add_child(seats_label)
	
	# Vote percentage
	var percentage_label := Label.new()
	percentage_label.text = str(party_result.vote_percentage).pad_decimals(1) + "%"
	percentage_label.custom_minimum_size = Vector2(60, 0)
	percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_container.add_child(percentage_label)
	
	# Seats change
	var change_label := Label.new()
	var change_text = str(party_result.seats_change) if party_result.seats_change <= 0 else "+" + str(party_result.seats_change)
	change_label.text = "(" + change_text + ")"
	change_label.custom_minimum_size = Vector2(50, 0)
	change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Color code the change
	if party_result.seats_change > 0:
		change_label.add_theme_color_override("font_color", Color.GREEN)
	elif party_result.seats_change < 0:
		change_label.add_theme_color_override("font_color", Color.RED)
	else:
		change_label.add_theme_color_override("font_color", Color.GRAY)
	
	item_container.add_child(change_label)
	return item_container

func _create_seats_visualization() -> void:
	"""Create visual representation of parliament seats"""
	# Clear existing visualization
	for child in seats_visualization.get_children():
		child.queue_free()
	
	# Create semicircular parliament layout
	var seat_size = 8
	var rows = 6
	var seats_per_row = [20, 22, 24, 26, 28, 30]  # Increasing seats per row
	var current_seat_index = 0
	
	for row in range(rows):
		for seat in range(seats_per_row[row]):
			if current_seat_index >= total_seats:
				break
			
			# Calculate position in semicircle
			var angle = PI * float(seat) / float(seats_per_row[row] - 1)
			var radius = 80 + row * 15
			var x = seats_visualization.size.x / 2 + cos(angle) * radius
			var y = seats_visualization.size.y - 20 - sin(angle) * radius
			
			# Create seat indicator
			var seat_indicator := ColorRect.new()
			seat_indicator.size = Vector2(seat_size, seat_size)
			seat_indicator.position = Vector2(x - seat_size/2, y - seat_size/2)
			
			# Assign party color based on seat allocation
			var party_color = _get_seat_party_color(current_seat_index)
			seat_indicator.color = party_color
			
			seats_visualization.add_child(seat_indicator)
			current_seat_index += 1
	
	# Update majority status
	var largest_party_seats = all_party_results[0].seats_won if all_party_results.size() > 0 else 0
	if largest_party_seats >= 76:
		majority_status_label.text = localization_manager.get_text("results.majority_achieved")
		coalition_required_label.text = ""
	else:
		majority_status_label.text = localization_manager.get_text("results.no_majority")
		coalition_required_label.text = localization_manager.get_text("results.coalition_needed")

func _get_seat_party_color(seat_index: int) -> Color:
	"""Get party color for specific seat based on allocation"""
	var current_count = 0
	
	for party_result in all_party_results:
		if seat_index < current_count + party_result.seats_won:
			return _get_party_color(party_result.party_name)
		current_count += party_result.seats_won
	
	return Color.GRAY

func _get_party_color(party_name: String) -> Color:
	"""Get representative color for political party"""
	match party_name:
		"VVD":
			return Color.ROYAL_BLUE
		"PVV":
			return Color.DARK_BLUE
		"New Democratic Party":
			return Color.PURPLE
		"CDA":
			return Color.ORANGE
		"D66":
			return Color.CYAN
		"GL-PvdA":
			return Color.GREEN
		"SP":
			return Color.RED
		_:
			return Color.GRAY

func _generate_analysis() -> void:
	"""Generate post-election analysis content"""
	# Key trends analysis
	var trends_text = _generate_trends_analysis()
	trends_content.text = trends_text
	
	# Regional breakdown
	var regional_text = _generate_regional_analysis()
	regional_content.text = regional_text
	
	# Next steps
	var next_steps_text = _generate_next_steps_analysis()
	next_steps_content.text = next_steps_text

func _generate_trends_analysis() -> String:
	"""Generate key trends analysis"""
	var analysis = "[b]Key Election Trends:[/b]\n\n"
	
	# Identify biggest winners and losers
	var biggest_winner: PartyResults
	var biggest_loser: PartyResults
	var max_gain = -999
	var max_loss = 999
	
	for party in all_party_results:
		if party.seats_change > max_gain:
			max_gain = party.seats_change
			biggest_winner = party
		if party.seats_change < max_loss:
			max_loss = party.seats_change
			biggest_loser = party
	
	if biggest_winner:
		analysis += "• Biggest winner: " + biggest_winner.party_name + " (+" + str(max_gain) + " seats)\n"
	
	if biggest_loser:
		analysis += "• Biggest decline: " + biggest_loser.party_name + " (" + str(max_loss) + " seats)\n"
	
	analysis += "• Voter turnout: " + str(election_results.turnout_percentage) + "% - "
	if election_results.turnout_percentage > 75:
		analysis += "High democratic engagement\n"
	else:
		analysis += "Moderate democratic engagement\n"
	
	return analysis

func _generate_regional_analysis() -> String:
	"""Generate regional breakdown analysis"""
	var analysis = "[b]Regional Patterns:[/b]\n\n"
	analysis += "• Urban areas showed strong support for progressive parties\n"
	analysis += "• Rural regions favored traditional conservative parties\n"
	analysis += "• Your party performed particularly well in suburban districts\n"
	analysis += "• Swing regions will be crucial for future electoral strategy\n"
	return analysis

func _generate_next_steps_analysis() -> String:
	"""Generate next steps analysis"""
	var analysis = "[b]What Happens Next:[/b]\n\n"
	
	var largest_party_seats = all_party_results[0].seats_won if all_party_results.size() > 0 else 0
	
	if largest_party_seats >= 76:
		analysis += "• Majority government formation begins\n"
		analysis += "• New cabinet formation within 100 days\n"
	else:
		analysis += "• Coalition negotiations will begin immediately\n"
		analysis += "• Parties must find common ground on key policies\n"
		analysis += "• Formation process may take several months\n"
	
	if player_party_results.seats_won >= 15:
		analysis += "• Your party is in a strong position for coalition talks\n"
	else:
		analysis += "• Focus on opposition role and policy influence\n"
	
	return analysis

func _format_number(number: int) -> String:
	"""Format large numbers with proper separators"""
	var number_str = str(number)
	var formatted = ""
	
	for i in range(number_str.length()):
		if i > 0 and (number_str.length() - i) % 3 == 0:
			formatted += "."
		formatted += number_str[i]
	
	return formatted

func _setup_tooltips() -> void:
	"""Setup educational tooltips for election results"""
	tooltip_manager.add_tooltip(seats_visualization, "tooltip.parliament_seats_explanation")
	tooltip_manager.add_tooltip(coalition_builder_button, "tooltip.coalition_builder_explanation")
	tooltip_manager.add_tooltip(export_results_button, "tooltip.export_results_explanation")

# Signal Handlers
func _on_back_button_pressed() -> void:
	"""Handle back button navigation"""
	navigation_controller.navigate_to_previous_scene()

func _on_export_results_pressed() -> void:
	"""Handle export results button"""
	# Would export election results to various formats
	notification_system.show_notification("results.export_started")

func _on_coalition_builder_pressed() -> void:
	"""Handle coalition builder button"""
	# Navigate to coalition builder with current results
	navigation_controller.navigate_to_scene("CoalitionBuilder")

func _on_new_election_pressed() -> void:
	"""Handle new election button"""
	# Would start new election scenario
	notification_system.show_notification("results.new_election_confirm")

func _on_help_button_pressed() -> void:
	"""Handle help button"""
	# Would show election results help
	notification_system.show_notification("notification.help_coming_soon")

# Helper classes for election results data
class_name ElectionResults
class ElectionResults:
	var election_date: String
	var turnout_percentage: float
	var total_eligible_voters: int
	var total_valid_votes: int

class PartyResults:
	var party_name: String
	var votes_received: int
	var vote_percentage: float
	var seats_won: int
	var seats_change: int
	var is_in_government: bool
