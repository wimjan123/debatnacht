extends RefCounted
class_name DataModels

# Data Model Classes Implementation
# Core data structures for Dutch politics simulation

## Result Types ##

class_name ActionResult
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

class_name MediaResponse
extends RefCounted

var sentiment_change: float = 0.0     # -1.0 to 1.0 audience reaction
var reach_multiplier: float = 1.0     # audience reach adjustment
var poll_effects: Dictionary = {}    # party_id -> poll change
var explanation: String = ""         # why this response had these effects

func _init(p_sentiment: float = 0.0, p_reach: float = 1.0, p_effects: Dictionary = {}, p_explanation: String = ""):
	sentiment_change = p_sentiment
	reach_multiplier = p_reach
	poll_effects = p_effects
	explanation = p_explanation

class_name CoalitionCompatibility
extends RefCounted

var compatibility_score: float = 0.0  # 0.0 to 1.0 compatibility rating
var policy_conflicts: Array[String] = []  # areas of disagreement
var shared_positions: Array[String] = []  # areas of agreement
var explanation: String = ""         # reasoning for score

func _init(p_score: float = 0.0, p_conflicts: Array[String] = [], p_shared: Array[String] = [], p_explanation: String = ""):
	compatibility_score = p_score
	policy_conflicts = p_conflicts
	shared_positions = p_shared
	explanation = p_explanation

class_name CoalitionValidation
extends RefCounted

var is_feasible: bool = false          # whether coalition can form
var total_seats: int = 0           # combined seat count
var majority_status: bool = false      # >= 76 seats
var stability_score: float = 0.0     # 0.0 to 1.0 predicted stability
var blocking_issues: Array[String] = []  # red line conflicts

func _init(p_feasible: bool = false, p_seats: int = 0, p_majority: bool = false, p_stability: float = 0.0, p_blocking: Array[String] = []):
	is_feasible = p_feasible
	total_seats = p_seats
	majority_status = p_majority
	stability_score = p_stability
	blocking_issues = p_blocking

class_name VotingResult
extends RefCounted

var votes_for: int = 0
var votes_against: int = 0
var abstentions: int = 0
var party_votes: Dictionary = {}     # party_id -> vote_choice
var vote_explanations: Dictionary = {}  # party_id -> reasoning
var legislation_passed: bool = false

func _init(p_for: int = 0, p_against: int = 0, p_abstain: int = 0, p_party_votes: Dictionary = {}, p_explanations: Dictionary = {}, p_passed: bool = false):
	votes_for = p_for
	votes_against = p_against
	abstentions = p_abstain
	party_votes = p_party_votes
	vote_explanations = p_explanations
	legislation_passed = p_passed

class_name ElectionAnalysis
extends RefCounted

var seat_changes: Dictionary = {}    # party_id -> seat_difference
var key_factors: Array[String] = []  # major influences on outcome
var regional_swings: Dictionary = {} # region_id -> swing_amount
var campaign_effectiveness: Dictionary = {}  # action_type -> impact_rating
var what_if_scenarios: Array[String] = []    # alternative outcomes

class_name RegionTooltipData
extends RefCounted

var region_name: String = ""
var party_support: Dictionary = {}   # party_id -> support_percentage
var key_issues: Array[String] = []   # top local concerns
var demographic_info: Dictionary = {} # age/income/education breakdown
var turnout_prediction: float = 0.0   # expected voter participation

class_name TooltipData
extends RefCounted

var title: String = ""              # metric name
var current_value: String = ""      # formatted current value
var explanation: String = ""        # simple explanation
var contributing_factors: Array[String] = []  # what influences this metric
var trend_direction: String = ""    # "increasing", "decreasing", "stable"

class_name ExplanationPanel
extends RefCounted

var calculation_name: String = ""
var step_by_step: Array[String] = []    # mathematical breakdown
var input_values: Dictionary = {}       # variable_name -> value
var assumptions: Array[String] = []     # modeling assumptions made
var confidence_level: String = ""       # "high", "medium", "low"

## Core Game Classes ##

class_name GameState
extends RefCounted

var current_date: String = ""
var game_phase: String = "campaign"          # "campaign", "election", "coalition", "parliament"
var active_scenario: String = ""
var player_party_id: String = ""
var rng_seed: int = 12345
var save_version: String = "1.0.0"
var total_play_time: int = 0
var parties: Array[Party] = []
var current_polls: OpinionPoll = null
var regions: Array[GeographicRegion] = []
var active_coalitions: Array[Coalition] = []
var pending_legislation: Array[Legislation] = []

func _init():
	current_date = Time.get_date_string_from_system()
	current_polls = OpinionPoll.new()

class_name Party
extends RefCounted

var id: String = ""
var display_name: String = ""
var ideology_position: Vector2 = Vector2.ZERO   # economic_axis, social_axis (-1 to 1)
var current_polls: float = 0.0        # 0-100 percentage
var projected_seats: int = 0        # 0-150 seats
var campaign_funds: int = 100000         # euros available
var red_lines: Array[String] = []    # non-negotiable policies
var ministry_preferences: Array[String] = []  # desired cabinet positions
var compatibility_scores: Dictionary = {}     # party_id -> compatibility

func _init(p_id: String = "", p_name: String = "", p_ideology: Vector2 = Vector2.ZERO):
	id = p_id
	display_name = p_name
	ideology_position = p_ideology

func validate() -> bool:
	if ideology_position.x < -1.0 or ideology_position.x > 1.0:
		return false
	if ideology_position.y < -1.0 or ideology_position.y > 1.0:
		return false
	if current_polls < 0.0 or current_polls > 100.0:
		return false
	if projected_seats < 0 or projected_seats > 150:
		return false
	return true

class_name CampaignAction
extends RefCounted

var action_type: String = ""         # "rally", "advertisement", "interview", etc.
var cost: int = 0                  # campaign funds required
var duration_hours: int = 0        # time investment
var target_region: String = ""      # optional regional targeting
var expected_effects: Dictionary = {}  # metric -> expected_change
var description: String = ""        # localized action description

func _init(p_type: String = "", p_cost: int = 0, p_duration: int = 0, p_description: String = ""):
	action_type = p_type
	cost = p_cost
	duration_hours = p_duration
	description = p_description

class_name OpinionPoll
extends RefCounted

var poll_date: String = ""
var party_standings: Dictionary = {}    # party_id -> percentage
var margin_of_error: float = 3.0        # polling uncertainty
var sample_size: int = 1000              # survey respondents
var demographic_breakdown: Dictionary = {}  # demographic -> party_preferences
var issue_salience: Dictionary = {}    # policy_topic -> importance_rating
var volatility_index: float = 0.5      # likelihood of vote switching

func _init():
	poll_date = Time.get_date_string_from_system()

class_name GeographicRegion
extends RefCounted

var region_id: String = ""
var display_name: String = ""
var region_type: String = "province"         # "province", "municipality", "constituency"
var population: int = 0             # eligible voters
var turnout_rate: float = 0.75         # historical participation
var party_support: Dictionary = {}   # party_id -> support_percentage
var key_issues: Array[String] = []   # top local concerns
var demographic_profile: Dictionary = {}  # age/income/education stats

func _init(p_id: String = "", p_name: String = "", p_type: String = "province"):
	region_id = p_id
	display_name = p_name
	region_type = p_type

class_name MediaEvent
extends RefCounted

var event_type: String = ""          # "tv_interview", "debate", etc.
var event_title: String = ""
var audience_reach: int = 0         # estimated viewers
var questions: Array[MediaQuestion] = []
var participant_parties: Array[String] = []  # involved parties
var base_sentiment: float = 0.0       # starting audience attitude

class_name MediaQuestion
extends RefCounted

var question_text: String = ""
var response_options: Array[ResponseOption] = []
var topic_category: String = ""      # policy area
var difficulty_level: int = 1       # 1-5 impact potential
var time_limit: int = 30            # seconds for response

class_name ResponseOption
extends RefCounted

var option_text: String = ""
var tone: String = ""               # "aggressive", "diplomatic", etc.
var stance_position: Vector2 = Vector2.ZERO   # ideology positioning
var audience_appeal: Dictionary = {}  # demographic -> appeal_rating
var risk_level: float = 0.0         # chance of backfire

class_name Coalition
extends RefCounted

var member_parties: Array[String] = []  # party IDs
var total_seats: int = 0
var majority_status: bool = false         # >= 76 seats
var policy_agreements: Array[PolicyAgreement] = []
var ministry_allocations: Dictionary = {}  # ministry -> party_id
var stability_score: float = 0.0       # survival likelihood
var formation_date: String = ""

func _init():
	formation_date = Time.get_date_string_from_system()

func calculate_majority_status():
	majority_status = total_seats >= 76

class_name PolicyAgreement
extends RefCounted

var policy_topic: String = ""
var agreed_position: String = ""      # compromise stance
var supporting_parties: Array[String] = []
var implementation_priority: int = 5  # 1-10 urgency
var public_support: float = 0.5       # polling on this policy

class_name Legislation
extends RefCounted

var bill_title: String = ""
var policy_area: String = ""
var proposing_party: String = ""
var committee_stage: String = "proposed"     # current legislative stage
var party_positions: Dictionary = {}  # party_id -> position
var predicted_vote: VotingResult = null # expected outcome
var public_opinion: float = 0.5       # polling support

func _init():
	predicted_vote = VotingResult.new()

class_name Election
extends RefCounted

var election_date: String = ""
var final_results: Dictionary = {}    # party_id -> vote_percentage
var seat_distribution: Dictionary = {}  # party_id -> seats_won
var turnout_rate: float = 0.0
var regional_breakdown: Dictionary = {}  # region_id -> results
var calculation_method: String = "D'Hondt"   # "D'Hondt"
var coalition_possibilities: Array = []  # viable combinations

class_name UIState
extends RefCounted

var active_screen: String = "menu" # menu, dashboard, map, media, coalition, parliament, social, results, settings
var language_setting: String = "en" # english, dutch
var accessibility_mode: String = "default" # default, high_contrast, large_text
var tooltip_preferences: Dictionary = {} # which tooltips to show
var map_filter_state: Dictionary = {} # current map view settings
var notification_queue: Array = [] # pending UI notifications

class_name NotificationMessage
extends RefCounted

var message_text: String = "" # localized notification content
var message_type: String = "info" # info, warning, success, error
var display_duration: float = 3.0 # seconds to show notification
var action_required: bool = false # whether user must acknowledge
var related_screen: String = "" # which screen this notification relates to