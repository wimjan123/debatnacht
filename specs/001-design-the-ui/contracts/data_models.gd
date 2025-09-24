# Data Model Classes Contract
# Type definitions for all data structures used in simulation

## Result Types ##

class_name ActionResult
extends RefCounted

var success: bool
var new_state: GameState
var effects: Dictionary  # metric_name -> change_amount
var explanation: String  # human-readable description of what happened
var cost_paid: int      # campaign funds spent

class_name MediaResponse
extends RefCounted

var sentiment_change: float     # -1.0 to 1.0 audience reaction
var reach_multiplier: float     # audience reach adjustment
var poll_effects: Dictionary    # party_id -> poll change
var explanation: String         # why this response had these effects

class_name CoalitionCompatibility
extends RefCounted

var compatibility_score: float  # 0.0 to 1.0 compatibility rating
var policy_conflicts: Array[String]  # areas of disagreement
var shared_positions: Array[String]  # areas of agreement
var explanation: String         # reasoning for score

class_name CoalitionValidation
extends RefCounted

var is_feasible: bool          # whether coalition can form
var total_seats: int           # combined seat count
var majority_status: bool      # >= 76 seats
var stability_score: float     # 0.0 to 1.0 predicted stability
var blocking_issues: Array[String]  # red line conflicts

class_name VotingResult
extends RefCounted

var votes_for: int
var votes_against: int
var abstentions: int
var party_votes: Dictionary     # party_id -> vote_choice
var vote_explanations: Dictionary  # party_id -> reasoning
var legislation_passed: bool

class_name ElectionAnalysis
extends RefCounted

var seat_changes: Dictionary    # party_id -> seat_difference
var key_factors: Array[String]  # major influences on outcome
var regional_swings: Dictionary # region_id -> swing_amount
var campaign_effectiveness: Dictionary  # action_type -> impact_rating
var what_if_scenarios: Array[String]    # alternative outcomes

class_name RegionTooltipData
extends RefCounted

var region_name: String
var party_support: Dictionary   # party_id -> support_percentage
var key_issues: Array[String]   # top local concerns
var demographic_info: Dictionary # age/income/education breakdown
var turnout_prediction: float   # expected voter participation

class_name TooltipData
extends RefCounted

var title: String              # metric name
var current_value: String      # formatted current value
var explanation: String        # simple explanation
var contributing_factors: Array[String]  # what influences this metric
var trend_direction: String    # "increasing", "decreasing", "stable"

class_name ExplanationPanel
extends RefCounted

var calculation_name: String
var step_by_step: Array[String]    # mathematical breakdown
var input_values: Dictionary       # variable_name -> value
var assumptions: Array[String]     # modeling assumptions made
var confidence_level: String       # "high", "medium", "low"

## Core Game Classes ##

class_name GameState
extends RefCounted

var current_date: String
var game_phase: String          # "campaign", "election", "coalition", "parliament"
var active_scenario: String
var player_party_id: String
var rng_seed: int
var save_version: String
var total_play_time: int
var parties: Array[Party]
var current_polls: OpinionPoll
var regions: Array[GeographicRegion]
var active_coalitions: Array[Coalition]
var pending_legislation: Array[Legislation]

class_name Party
extends RefCounted

var id: String
var display_name: String
var ideology_position: Vector2   # economic_axis, social_axis (-1 to 1)
var current_polls: float        # 0-100 percentage
var projected_seats: int        # 0-150 seats
var campaign_funds: int         # euros available
var red_lines: Array[String]    # non-negotiable policies
var ministry_preferences: Array[String]  # desired cabinet positions
var compatibility_scores: Dictionary     # party_id -> compatibility

class_name CampaignAction
extends RefCounted

var action_type: String         # "rally", "advertisement", "interview", etc.
var cost: int                  # campaign funds required
var duration_hours: int        # time investment
var target_region: String      # optional regional targeting
var expected_effects: Dictionary  # metric -> expected_change
var description: String        # localized action description

class_name OpinionPoll
extends RefCounted

var poll_date: String
var party_standings: Dictionary    # party_id -> percentage
var margin_of_error: float        # polling uncertainty
var sample_size: int              # survey respondents
var demographic_breakdown: Dictionary  # demographic -> party_preferences
var issue_salience: Dictionary    # policy_topic -> importance_rating
var volatility_index: float      # likelihood of vote switching

class_name GeographicRegion
extends RefCounted

var region_id: String
var display_name: String
var region_type: String         # "province", "municipality", "constituency"
var population: int             # eligible voters
var turnout_rate: float         # historical participation
var party_support: Dictionary   # party_id -> support_percentage
var key_issues: Array[String]   # top local concerns
var demographic_profile: Dictionary  # age/income/education stats

class_name MediaEvent
extends RefCounted

var event_type: String          # "tv_interview", "debate", etc.
var event_title: String
var audience_reach: int         # estimated viewers
var questions: Array[MediaQuestion]
var participant_parties: Array[String]  # involved parties
var base_sentiment: float       # starting audience attitude

class_name MediaQuestion
extends RefCounted

var question_text: String
var response_options: Array[ResponseOption]
var topic_category: String      # policy area
var difficulty_level: int       # 1-5 impact potential
var time_limit: int            # seconds for response

class_name ResponseOption
extends RefCounted

var option_text: String
var tone: String               # "aggressive", "diplomatic", etc.
var stance_position: Vector2   # ideology positioning
var audience_appeal: Dictionary  # demographic -> appeal_rating
var risk_level: float         # chance of backfire

class_name Coalition
extends RefCounted

var member_parties: Array[String]  # party IDs
var total_seats: int
var majority_status: bool         # >= 76 seats
var policy_agreements: Array[PolicyAgreement]
var ministry_allocations: Dictionary  # ministry -> party_id
var stability_score: float       # survival likelihood
var formation_date: String

class_name PolicyAgreement
extends RefCounted

var policy_topic: String
var agreed_position: String      # compromise stance
var supporting_parties: Array[String]
var implementation_priority: int  # 1-10 urgency
var public_support: float       # polling on this policy

class_name Legislation
extends RefCounted

var bill_title: String
var policy_area: String
var proposing_party: String
var committee_stage: String     # current legislative stage
var party_positions: Dictionary  # party_id -> position
var predicted_vote: VotingResult # expected outcome
var public_opinion: float       # polling support

class_name Election
extends RefCounted

var election_date: String
var final_results: Dictionary    # party_id -> vote_percentage
var seat_distribution: Dictionary  # party_id -> seats_won
var turnout_rate: float
var regional_breakdown: Dictionary  # region_id -> results
var calculation_method: String   # "D'Hondt"
var coalition_possibilities: Array[Array[String]]  # viable combinations