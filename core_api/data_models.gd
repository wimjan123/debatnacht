extends RefCounted
class_name DataModels

# Data Model Classes Implementation
# Core data structures for Dutch politics simulation

## Core Game Objects (defined first to avoid forward reference issues) ##

class GameState:
	extends RefCounted

	# Core game progression
	var current_day: int = 0
	var days_until_election: int = 365
	var phase: String = "campaign"  # campaign, election, results
	var is_paused: bool = false

	# Player party state
	var player_party_id: String = ""
	var campaign_funds: int = 1000000  # Starting funds in euros
	var current_polls: Dictionary = {}  # party_id -> polling_percentage
	var party_reputation: Dictionary = {}  # category -> score (-100 to 100)

	# World state - using basic types to avoid circular references
	var active_coalition_ids: Array[String] = []
	var pending_legislation_ids: Array[String] = []
	var recent_media_event_ids: Array[String] = []
	var regional_support: Dictionary = {}  # region_id -> {party_id -> support_level}

	func _init():
		# Initialize with default values
		pass

class Party:
	extends RefCounted

	# Basic identification
	var party_id: String = ""
	var display_name: String = ""
	var short_name: String = ""  # Abbreviation like "VVD", "PvdA"
	var color: Color = Color.BLUE

	# Political positioning
	var ideology_position: Vector2 = Vector2.ZERO  # x: economic left-right, y: social liberal-conservative
	var policy_priorities: Dictionary = {}  # policy_area -> importance_weight (0.0-1.0)
	var current_polls: Dictionary = {}     # region_id -> polling_percentage

	# Campaign resources and status
	var campaign_funds: int = 0
	var seat_count: int = 0  # Current seats in parliament
	var coalition_partner_ids: Array[String] = []  # party_ids as strings
	var recent_action_ids: Array[String] = []

	# AI behavior parameters (for non-player parties)
	var ai_strategy: String = "moderate"  # moderate, aggressive, defensive
	var response_predictability: float = 0.7  # How predictable AI responses are

	func _init(p_party_id: String = "", p_display_name: String = "", p_short_name: String = ""):
		party_id = p_party_id
		display_name = p_display_name
		short_name = p_short_name

class CampaignAction:
	extends RefCounted

	var action_type: String = ""  # rally, advertisement, debate, media_appearance
	var target_region: String = ""  # specific region or "national"
	var cost: int = 0
	var duration_days: int = 1
	var message_focus: String = ""  # policy area or theme
	var expected_effects: Dictionary = {}  # metric -> expected_change

	func _init(p_action_type: String = "", p_target_region: String = "", p_cost: int = 0, p_duration_days: int = 1, p_message_focus: String = "", p_expected_effects: Dictionary = {}):
		action_type = p_action_type
		target_region = p_target_region
		cost = p_cost
		duration_days = p_duration_days
		message_focus = p_message_focus
		expected_effects = p_expected_effects

class OpinionPoll:
	extends RefCounted

	var poll_date: int = 0  # days since game start
	var region: String = "national"
	var sample_size: int = 1000
	var margin_of_error: float = 3.0
	var results: Dictionary = {}  # party_id -> percentage
	var demographic_breakdown: Dictionary = {}  # age/income/education -> {party_id -> percentage}

	func _init(p_poll_date: int = 0, p_region: String = "national", p_sample_size: int = 1000, p_margin_of_error: float = 3.0, p_results: Dictionary = {}, p_demographic_breakdown: Dictionary = {}):
		poll_date = p_poll_date
		region = p_region
		sample_size = p_sample_size
		margin_of_error = p_margin_of_error
		results = p_results
		demographic_breakdown = p_demographic_breakdown

class GeographicRegion:
	extends RefCounted

	# Basic information
	var region_id: String = ""
	var display_name: String = ""
	var population: int = 0
	var electoral_seats: int = 0  # number of parliament seats this region elects

	# Demographics and characteristics
	var demographics: Dictionary = {}     # age_group/income_level/education -> percentage
	var economic_indicators: Dictionary = {}  # unemployment_rate, avg_income, etc.
	var party_support: Dictionary = {}    # party_id -> support_percentage
	var key_issues: Array[String] = []    # most important issues to voters here
	var voting_history: Dictionary = {}   # past_election_year -> {party_id -> vote_percentage}

	func _init(p_region_id: String = "", p_display_name: String = "", p_population: int = 0, p_electoral_seats: int = 0):
		region_id = p_region_id
		display_name = p_display_name
		population = p_population
		electoral_seats = p_electoral_seats

class MediaEvent:
	extends RefCounted

	var event_id: String = ""
	var title: String = ""
	var description: String = ""
	var event_type: String = ""  # scandal, policy_announcement, debate, crisis
	var affected_parties: Array[String] = []  # party_ids that this event impacts
	var response_deadline: int = 0  # days to respond (0 = immediate)

class MediaQuestion:
	extends RefCounted

	var question_text: String = ""
	var context: String = ""
	var response_option_ids: Array[String] = []  # Reference to ResponseOption by ID

class ResponseOption:
	extends RefCounted

	var option_text: String = ""
	var stance_type: String = ""  # supportive, critical, neutral, deflect
	var predicted_effects: Dictionary = {}  # audience_segment -> sentiment_change

class Coalition:
	extends RefCounted

	var coalition_id: String = ""
	var member_party_ids: Array[String] = []  # party_ids
	var formation_date: int = 0  # day formed
	var total_seats: int = 0
	var majority_status: bool = false
	var policy_agreement_ids: Array[String] = []
	var stability_score: float = 1.0  # 0.0 to 1.0, how likely to hold together
	var public_approval: float = 0.5  # 0.0 to 1.0

	func _init(p_coalition_id: String = "", p_member_party_ids: Array[String] = [], p_formation_date: int = 0):
		coalition_id = p_coalition_id
		member_party_ids = p_member_party_ids
		formation_date = p_formation_date

class PolicyAgreement:
	extends RefCounted

	var policy_area: String = ""
	var agreed_position: String = ""
	var compromise_level: float = 0.5  # how much each party compromised
	var implementation_priority: int = 1  # 1-10, higher = more important

class Legislation:
	extends RefCounted

	var bill_id: String = ""
	var title: String = ""
	var policy_area: String = ""
	var proposed_by: String = ""  # party_id
	var status: String = "proposed"  # proposed, committee, voting, passed, rejected
	var support_level: Dictionary = {}  # party_id -> support_stance ("support", "oppose", "neutral")
	var public_opinion: float = 0.5  # 0.0 to 1.0

	func _init(p_bill_id: String = "", p_title: String = "", p_policy_area: String = "", p_proposed_by: String = ""):
		bill_id = p_bill_id
		title = p_title
		policy_area = p_policy_area
		proposed_by = p_proposed_by

class Election:
	extends RefCounted

	var election_date: int = 0
	var election_type: String = "general"  # general, local, european
	var final_results: Dictionary = {}  # party_id -> {votes, seats, percentage}
	var turnout_rate: float = 0.0

## Result Types (defined after core types) ##

class ActionResult:
	extends RefCounted

	var success: bool = false
	var new_state: GameState = null
	var effects: Dictionary = {}  # metric_name -> change_amount
	var explanation: String = ""  # human-readable description of what happened
	var cost_paid: int = 0      # campaign funds spent

	func _init(p_success: bool = false, p_new_state: GameState = null, p_effects: Dictionary = {}, p_explanation: String = "", p_cost_paid: int = 0):
		success = p_success
		new_state = p_new_state
		effects = p_effects
		explanation = p_explanation
		cost_paid = p_cost_paid

class MediaResponse:
	extends RefCounted

	var sentiment_change: float = 0.0     # -1.0 to 1.0 audience reaction
	var reach_multiplier: float = 1.0     # audience reach adjustment
	var poll_effects: Dictionary = {}    # party_id -> poll change
	var explanation: String = ""         # What happened in this response

	func _init(p_sentiment_change: float = 0.0, p_reach_multiplier: float = 1.0, p_poll_effects: Dictionary = {}, p_explanation: String = ""):
		sentiment_change = p_sentiment_change
		reach_multiplier = p_reach_multiplier
		poll_effects = p_poll_effects
		explanation = p_explanation

class CoalitionCompatibility:
	extends RefCounted

	var party_a: String = ""
	var party_b: String = ""
	var compatibility_score: float = 0.0  # 0.0 to 1.0
	var shared_policies: Array[String] = []
	var conflicting_policies: Array[String] = []
	var explanation: String = ""

	func _init(p_party_a: String = "", p_party_b: String = "", p_compatibility_score: float = 0.0, p_shared_policies: Array[String] = [], p_conflicting_policies: Array[String] = [], p_explanation: String = ""):
		party_a = p_party_a
		party_b = p_party_b
		compatibility_score = p_compatibility_score
		shared_policies = p_shared_policies
		conflicting_policies = p_conflicting_policies
		explanation = p_explanation

class CoalitionValidation:
	extends RefCounted

	var is_valid: bool = false
	var total_seats: int = 0
	var has_majority: bool = false
	var stability_prediction: float = 0.0  # 0.0 to 1.0
	var potential_issues: Array[String] = []

	func _init(p_is_valid: bool = false, p_total_seats: int = 0, p_has_majority: bool = false, p_stability_prediction: float = 0.0, p_potential_issues: Array[String] = []):
		is_valid = p_is_valid
		total_seats = p_total_seats
		has_majority = p_has_majority
		stability_prediction = p_stability_prediction
		potential_issues = p_potential_issues

class VotingResult:
	extends RefCounted

	var bill_id: String = ""
	var passed: bool = false
	var votes_for: int = 0
	var votes_against: int = 0
	var abstentions: int = 0
	var party_votes: Dictionary = {}  # party_id -> vote ("for", "against", "abstain")

	func _init(p_bill_id: String = "", p_passed: bool = false, p_votes_for: int = 0, p_votes_against: int = 0, p_abstentions: int = 0, p_party_votes: Dictionary = {}):
		bill_id = p_bill_id
		passed = p_passed
		votes_for = p_votes_for
		votes_against = p_votes_against
		abstentions = p_abstentions
		party_votes = p_party_votes

class ElectionAnalysis:
	extends RefCounted

	var winner: String = ""
	var coalition_needed: bool = false
	var turnout_rate: float = 0.0

class RegionTooltipData:
	extends RefCounted

	var region_name: String = ""
	var population: int = 0

class TooltipData:
	extends RefCounted

	var title: String = ""
	var content: String = ""
	var explanation: String = ""

class ExplanationPanel:
	extends RefCounted

	var title: String = ""
	var sections: Array[Dictionary] = []

## UI and System Types ##

class UIState:
	extends RefCounted

	var current_screen: String = "main_menu"
	var previous_screens: Array[String] = []
	var modal_dialogs: Array[String] = []
	var selected_region: String = ""
	var tooltip_target: Control = null

class NotificationMessage:
	extends RefCounted

	var message_id: String = ""
	var title: String = ""
	var content: String = ""
	var urgency: String = "normal"  # low, normal, high, critical
	var category: String = "general"  # general, campaign, media, coalition
	var timestamp: float = 0.0
	var auto_dismiss: bool = true
	var dismiss_time: float = 5.0  # seconds