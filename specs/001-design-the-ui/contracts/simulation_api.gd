# SimulationAPI Interface Contract
# Core interface for simulation data access - enables swapping between stub and agent-based models

class_name SimulationAPI
extends RefCounted

## Game State Management ##

# Initialize new game session with scenario and seed
# @param scenario_id: String - predefined scenario identifier
# @param rng_seed: int - deterministic seed for reproducible results
# @return GameState - initial game state object
func initialize_game(scenario_id: String, rng_seed: int) -> GameState:
	assert(false, "Must implement initialize_game")

# Load existing game from save data
# @param save_data: Dictionary - validated save file content
# @return GameState - restored game state
func load_game(save_data: Dictionary) -> GameState:
	assert(false, "Must implement load_game")

# Save current game state to dictionary
# @param current_state: GameState - current session state
# @return Dictionary - serializable save data with version metadata
func save_game(current_state: GameState) -> Dictionary:
	assert(false, "Must implement save_game")

## Campaign Management ##

# Execute campaign action and return updated state
# @param action: CampaignAction - player's chosen action
# @param current_state: GameState - pre-action state
# @return ActionResult - outcome with state changes and explanations
func execute_campaign_action(action: CampaignAction, current_state: GameState) -> ActionResult:
	assert(false, "Must implement execute_campaign_action")

# Get available campaign actions for current game state
# @param party_id: String - acting party identifier
# @param current_state: GameState - current game context
# @return Array[CampaignAction] - valid actions with costs and effects
func get_available_actions(party_id: String, current_state: GameState) -> Array[CampaignAction]:
	assert(false, "Must implement get_available_actions")

# Calculate current opinion polls with margin of error
# @param current_state: GameState - context for poll calculation
# @return OpinionPoll - current standings with demographic breakdown
func calculate_current_polls(current_state: GameState) -> OpinionPoll:
	assert(false, "Must implement calculate_current_polls")

## Geographic Data ##

# Get regional support breakdown for map visualization
# @param filter_type: String - "party_support", "issue_salience", "turnout", "demographics"
# @param filter_value: String - specific party/issue/demographic to highlight
# @param current_state: GameState - context for regional calculations
# @return Dictionary - region_id -> display_value mapping
func get_regional_data(filter_type: String, filter_value: String, current_state: GameState) -> Dictionary:
	assert(false, "Must implement get_regional_data")

# Get detailed tooltip information for specific region
# @param region_id: String - target region identifier
# @param current_state: GameState - current game context
# @return RegionTooltipData - support levels, issues, demographics
func get_region_tooltip_data(region_id: String, current_state: GameState) -> RegionTooltipData:
	assert(false, "Must implement get_region_tooltip_data")

## Media Events ##

# Generate media event questions based on current political climate
# @param event_type: String - "tv_interview", "radio_interview", "debate"
# @param current_state: GameState - context for question generation
# @return MediaEvent - event with questions and expected audience
func generate_media_event(event_type: String, current_state: GameState) -> MediaEvent:
	assert(false, "Must implement generate_media_event")

# Process player response and calculate audience reaction
# @param response: ResponseOption - player's chosen answer
# @param question: MediaQuestion - question being answered
# @param current_state: GameState - context for reaction calculation
# @return MediaResponse - sentiment change and explanation
func process_media_response(response: ResponseOption, question: MediaQuestion, current_state: GameState) -> MediaResponse:
	assert(false, "Must implement process_media_response")

## Coalition Building ##

# Calculate compatibility score between two parties
# @param party_a_id: String - first party identifier
# @param party_b_id: String - second party identifier
# @param current_state: GameState - context for compatibility calculation
# @return CoalitionCompatibility - score, conflicts, and explanation
func calculate_coalition_compatibility(party_a_id: String, party_b_id: String, current_state: GameState) -> CoalitionCompatibility:
	assert(false, "Must implement calculate_coalition_compatibility")

# Validate potential coalition and calculate stability
# @param party_ids: Array[String] - proposed coalition members
# @param current_state: GameState - context for validation
# @return CoalitionValidation - feasibility, seat count, stability score
func validate_coalition(party_ids: Array[String], current_state: GameState) -> CoalitionValidation:
	assert(false, "Must implement validate_coalition")

## Parliamentary Voting ##

# Generate legislation for parliamentary consideration
# @param current_state: GameState - context for bill generation
# @return Legislation - bill with predicted party positions
func generate_legislation(current_state: GameState) -> Legislation:
	assert(false, "Must implement generate_legislation")

# Calculate voting outcome based on party whips and member positions
# @param legislation: Legislation - bill being voted on
# @param current_state: GameState - parliament composition context
# @return VotingResult - final tally with explanations for each party's vote
func calculate_voting_outcome(legislation: Legislation, current_state: GameState) -> VotingResult:
	assert(false, "Must implement calculate_voting_outcome")

## Election Simulation ##

# Run final election using D'Hondt method
# @param current_state: GameState - pre-election state with final polls
# @return Election - results with seat distribution and regional breakdown
func simulate_election(current_state: GameState) -> Election:
	assert(false, "Must implement simulate_election")

# Generate post-election analysis explaining results
# @param election: Election - completed election results
# @param campaign_history: Array[CampaignAction] - player's campaign actions
# @return ElectionAnalysis - "why you won/lost" breakdown with contributing factors
func analyze_election_outcome(election: Election, campaign_history: Array[CampaignAction]) -> ElectionAnalysis:
	assert(false, "Must implement analyze_election_outcome")

## Explanation System ##

# Generate tooltip explanation for any displayed metric
# @param metric_type: String - type of value being explained
# @param metric_value: Variant - current value
# @param context: Dictionary - relevant context for explanation
# @return TooltipData - explanation text with contributing factors
func explain_metric(metric_type: String, metric_value: Variant, context: Dictionary) -> TooltipData:
	assert(false, "Must implement explain_metric")

# Get detailed "why?" panel content for complex calculations
# @param calculation_type: String - what calculation to explain
# @param inputs: Dictionary - values that went into calculation
# @param result: Variant - calculation result
# @return ExplanationPanel - detailed breakdown with mathematical reasoning
func get_detailed_explanation(calculation_type: String, inputs: Dictionary, result: Variant) -> ExplanationPanel:
	assert(false, "Must implement get_detailed_explanation")