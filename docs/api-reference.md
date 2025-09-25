# API Reference

## Overview

This reference documents the key classes, interfaces, and methods in the Dutch Politics Simulation UI. The API is organized around clean architecture principles with clear separation between presentation, integration, and simulation layers.

## SimulationAPI Interface

### Core Interface (`core_api/simulation_api.gd`)

Abstract base class defining the contract between UI and simulation backends.

```gd
extends RefCounted
class_name SimulationAPI
```

#### Game State Management

##### `initialize_game(scenario_id: String, rng_seed: int) -> DataModels.GameState`
Initialize new game session with scenario and deterministic seed.

**Parameters:**
- `scenario_id`: Predefined scenario identifier ("default", "historical_2021", etc.)
- `rng_seed`: Deterministic seed for reproducible results

**Returns:** Initial game state object with parties, regions, and starting conditions

**Example:**
```gd
var game_state = simulation_api.initialize_game("default", 12345)
print("Started with ", game_state.parties.size(), " parties")
```

##### `load_game(save_data: Dictionary) -> DataModels.GameState`
Load existing game from validated save data.

**Parameters:**
- `save_data`: Dictionary containing serialized game state and metadata

**Returns:** Restored game state object

##### `save_game(current_state: DataModels.GameState) -> Dictionary`
Save current game state to serializable dictionary.

**Parameters:**
- `current_state`: Current session state to serialize

**Returns:** Dictionary with version metadata and serialized state data

#### Campaign Management

##### `execute_campaign_action(action: DataModels.CampaignAction, current_state: DataModels.GameState) -> DataModels.ActionResult`
Execute campaign action and return updated state with explanations.

**Parameters:**
- `action`: Player's chosen campaign action (rally, advertisement, etc.)
- `current_state`: Pre-action game state

**Returns:** ActionResult with success status, state changes, costs, and explanations

**Example:**
```gd
var rally = DataModels.CampaignAction.new("rally", "utrecht", 5000, 3)
var result = simulation_api.execute_campaign_action(rally, game_state)
if result.success:
    print("Rally effect: ", result.effects.get("polls", 0), "% poll change")
```

##### `get_available_actions(party_id: String, current_state: DataModels.GameState) -> Array[DataModels.CampaignAction]`
Get valid campaign actions for current game state and resources.

**Parameters:**
- `party_id`: Acting party identifier
- `current_state`: Current game context for action validation

**Returns:** Array of valid actions with costs and expected effects

##### `calculate_current_polls(current_state: DataModels.GameState) -> DataModels.OpinionPoll`
Calculate current opinion polls with margin of error and demographic breakdown.

**Parameters:**
- `current_state`: Context for poll calculation

**Returns:** OpinionPoll with party standings, methodology, and demographic data

#### Geographic Data

##### `get_regional_data(filter_type: String, filter_value: String, current_state: DataModels.GameState) -> Dictionary`
Get regional data for map visualization with various filters.

**Parameters:**
- `filter_type`: "party_support", "issue_salience", "turnout", "demographics"
- `filter_value`: Specific party/issue/demographic to highlight
- `current_state`: Context for regional calculations

**Returns:** Dictionary mapping region_id -> display_value

**Example:**
```gd
var party_support = simulation_api.get_regional_data("party_support", "player_party", game_state)
for region_id in party_support:
    print(region_id, ": ", party_support[region_id] * 100, "% support")
```

##### `get_region_tooltip_data(region_id: String, current_state: DataModels.GameState) -> DataModels.RegionTooltipData`
Get detailed tooltip information for specific region hover events.

**Parameters:**
- `region_id`: Target region identifier
- `current_state`: Current game context

**Returns:** RegionTooltipData with support levels, demographics, key issues

#### Media Events

##### `generate_media_event(event_type: String, current_state: DataModels.GameState) -> DataModels.MediaEvent`
Generate media event with questions based on current political climate.

**Parameters:**
- `event_type`: "tv_interview", "radio_interview", "debate"
- `current_state`: Context for question generation

**Returns:** MediaEvent with questions, audience info, and participation details

##### `process_media_response(response: DataModels.ResponseOption, question: DataModels.MediaQuestion, current_state: DataModels.GameState) -> DataModels.MediaResponse`
Process player response and calculate audience reaction.

**Parameters:**
- `response`: Player's chosen answer option
- `question`: Question being answered
- `current_state`: Context for reaction calculation

**Returns:** MediaResponse with sentiment change, reach multiplier, poll effects

#### Coalition Building

##### `calculate_coalition_compatibility(party_a_id: String, party_b_id: String, current_state: DataModels.GameState) -> DataModels.CoalitionCompatibility`
Calculate compatibility score and policy alignment between two parties.

**Parameters:**
- `party_a_id`: First party identifier
- `party_b_id`: Second party identifier
- `current_state`: Context for compatibility calculation

**Returns:** CoalitionCompatibility with score, conflicts, shared policies

##### `validate_coalition(party_ids: Array[String], current_state: DataModels.GameState) -> DataModels.CoalitionValidation`
Validate potential coalition feasibility and calculate stability.

**Parameters:**
- `party_ids`: Array of proposed coalition member party IDs
- `current_state`: Context for validation

**Returns:** CoalitionValidation with feasibility, seat count, stability score

#### Parliamentary Operations

##### `generate_legislation(current_state: DataModels.GameState) -> DataModels.Legislation`
Generate legislation for parliamentary consideration based on current climate.

**Parameters:**
- `current_state`: Context for bill generation

**Returns:** Legislation with predicted party positions and public opinion

##### `calculate_voting_outcome(legislation: DataModels.Legislation, current_state: DataModels.GameState) -> DataModels.VotingResult`
Calculate voting outcome based on party whips and member positions.

**Parameters:**
- `legislation`: Bill being voted on
- `current_state`: Parliament composition context

**Returns:** VotingResult with final tally and explanations

#### Election System

##### `simulate_election(current_state: DataModels.GameState) -> DataModels.Election`
Run final election using D'Hondt proportional representation method.

**Parameters:**
- `current_state`: Pre-election state with final polls

**Returns:** Election with results, seat distribution, regional breakdown

##### `analyze_election_outcome(election: DataModels.Election, campaign_history: Array[DataModels.CampaignAction]) -> DataModels.ElectionAnalysis`
Generate post-election analysis explaining results and campaign effectiveness.

**Parameters:**
- `election`: Completed election results
- `campaign_history`: Player's campaign actions for analysis

**Returns:** ElectionAnalysis with "why you won/lost" breakdown

#### Explanation System

##### `explain_metric(metric_type: String, metric_value: Variant, context: Dictionary) -> DataModels.TooltipData`
Generate tooltip explanation for displayed metrics.

**Parameters:**
- `metric_type`: Type of value being explained
- `metric_value`: Current value to explain
- `context`: Relevant context for explanation

**Returns:** TooltipData with explanation text and contributing factors

##### `get_detailed_explanation(calculation_type: String, inputs: Dictionary, result: Variant) -> DataModels.ExplanationPanel`
Get detailed "why?" panel content for complex calculations.

**Parameters:**
- `calculation_type`: What calculation to explain
- `inputs`: Values that went into calculation
- `result`: Calculation result

**Returns:** ExplanationPanel with step-by-step breakdown

## DataModels Namespace

### Core Classes (`core_api/data_models.gd`)

#### GameState
Central game state container with all simulation data.

```gd
class GameState:
    var current_day: int = 0
    var days_until_election: int = 365
    var phase: String = "campaign"  # campaign, election, results
    var is_paused: bool = false

    var player_party_id: String = ""
    var campaign_funds: int = 1000000
    var current_polls: Dictionary = {}  # party_id -> polling_percentage
    var party_reputation: Dictionary = {}  # category -> score (-100 to 100)

    var active_coalition_ids: Array[String] = []
    var pending_legislation_ids: Array[String] = []
    var recent_media_event_ids: Array[String] = []
    var regional_support: Dictionary = {}  # region_id -> {party_id -> support_level}
```

#### Party
Political party data with positioning and resources.

```gd
class Party:
    var party_id: String = ""
    var display_name: String = ""
    var short_name: String = ""  # "VVD", "PvdA", etc.
    var color: Color = Color.BLUE

    var ideology_position: Vector2 = Vector2.ZERO  # x: economic, y: social
    var policy_priorities: Dictionary = {}  # policy_area -> importance (0.0-1.0)
    var current_polls: Dictionary = {}     # region_id -> polling_percentage

    var campaign_funds: int = 0
    var seat_count: int = 0
    var coalition_partner_ids: Array[String] = []
    var recent_action_ids: Array[String] = []

    var ai_strategy: String = "moderate"  # AI behavior for non-player parties
    var response_predictability: float = 0.7
```

#### CampaignAction
Player campaign activities with costs and effects.

```gd
class CampaignAction:
    var action_type: String = ""  # rally, advertisement, debate, media_appearance
    var target_region: String = ""  # specific region or "national"
    var cost: int = 0
    var duration_days: int = 1
    var message_focus: String = ""  # policy area or theme
    var expected_effects: Dictionary = {}  # metric -> expected_change
```

#### OpinionPoll
Polling data with methodology and demographic breakdowns.

```gd
class OpinionPoll:
    var poll_date: int = 0  # days since game start
    var region: String = "national"
    var sample_size: int = 1000
    var margin_of_error: float = 3.0
    var results: Dictionary = {}  # party_id -> percentage
    var demographic_breakdown: Dictionary = {}  # demographic -> {party_id -> percentage}
```

#### GeographicRegion
Dutch provinces and municipalities with voter profiles.

```gd
class GeographicRegion:
    var region_id: String = ""
    var display_name: String = ""
    var population: int = 0
    var electoral_seats: int = 0

    var demographics: Dictionary = {}     # age_group/income/education -> percentage
    var economic_indicators: Dictionary = {}  # unemployment, income, etc.
    var party_support: Dictionary = {}    # party_id -> support_percentage
    var key_issues: Array[String] = []    # most important issues to voters
    var voting_history: Dictionary = {}   # past_election -> {party_id -> percentage}
```

#### MediaEvent
Media interactions with questions and audience data.

```gd
class MediaEvent:
    var event_id: String = ""
    var title: String = ""
    var description: String = ""
    var event_type: String = ""  # scandal, policy_announcement, debate, crisis
    var affected_parties: Array[String] = []
    var response_deadline: int = 0  # days to respond
```

#### Coalition
Multi-party governing arrangements.

```gd
class Coalition:
    var coalition_id: String = ""
    var member_party_ids: Array[String] = []
    var formation_date: int = 0
    var total_seats: int = 0
    var majority_status: bool = false
    var policy_agreement_ids: Array[String] = []
    var stability_score: float = 1.0  # 0.0-1.0
    var public_approval: float = 0.5
```

#### Legislation
Parliamentary bills with voting data.

```gd
class Legislation:
    var bill_id: String = ""
    var title: String = ""
    var description: String = ""
    var policy_area: String = ""
    var sponsor_party: String = ""
    var proposed_by: String = ""
    var status: LegislationStatus = LegislationStatus.PROPOSED
    var support_level: Dictionary = {}  # party_id -> "support"/"oppose"/"neutral"
    var public_opinion: float = 0.5
```

### Result Types

#### ActionResult
Campaign action outcome with state changes and explanations.

```gd
class ActionResult:
    var success: bool = false
    var new_state: GameState = null
    var effects: Dictionary = {}  # metric_name -> change_amount
    var explanation: String = ""  # human-readable outcome
    var cost_paid: int = 0
```

#### MediaResponse
Media event response outcome with audience reaction.

```gd
class MediaResponse:
    var sentiment_change: float = 0.0     # -1.0 to 1.0
    var reach_multiplier: float = 1.0     # audience reach adjustment
    var poll_effects: Dictionary = {}     # party_id -> poll change
    var explanation: String = ""          # what happened
```

#### CoalitionCompatibility
Party compatibility analysis for coalition formation.

```gd
class CoalitionCompatibility:
    var party_a: String = ""
    var party_b: String = ""
    var compatibility_score: float = 0.0  # 0.0-1.0
    var shared_policies: Array[String] = []
    var conflicting_policies: Array[String] = []
    var explanation: String = ""
```

#### VotingResult
Parliamentary voting outcome with party positions.

```gd
class VotingResult:
    var bill_id: String = ""
    var passed: bool = false
    var votes_for: int = 0
    var votes_against: int = 0
    var abstentions: int = 0
    var party_votes: Dictionary = {}  # party_id -> "for"/"against"/"abstain"
```

### UI State Types

#### UIState
User interface state separate from game logic.

```gd
class UIState:
    var current_screen: String = "main_menu"
    var previous_screens: Array[String] = []
    var modal_dialogs: Array[String] = []
    var selected_region: String = ""
    var tooltip_target: Control = null
```

#### NotificationMessage
System notification data.

```gd
class NotificationMessage:
    var message_id: String = ""
    var title: String = ""
    var content: String = ""
    var urgency: String = "normal"  # low, normal, high, critical
    var category: String = "general"  # general, campaign, media, coalition
    var timestamp: float = 0.0
    var auto_dismiss: bool = true
    var dismiss_time: float = 5.0
```

## EventBus System

### Event Management (`presentation/managers/event_bus.gd`)

Global event system for decoupled component communication.

#### Core Methods

##### `subscribe(event_name: String, callback: Callable) -> void`
Subscribe to an event with callback function.

**Parameters:**
- `event_name`: Event identifier string
- `callback`: Function to call when event is published

**Example:**
```gd
EventBus.subscribe("game_state_changed", _on_game_state_changed)
```

##### `unsubscribe(event_name: String, callback: Callable) -> void`
Unsubscribe from an event.

##### `publish(event_name: String, data: Dictionary = {}, category: EventCategory = EventCategory.DEBUG) -> void`
Publish an event with optional data payload.

**Parameters:**
- `event_name`: Event identifier
- `data`: Optional data dictionary
- `category`: Event category for organization and debugging

##### `unsubscribe_all(subscriber: Object) -> void`
Unsubscribe an object from all events (useful for cleanup).

#### Convenience Methods

```gd
# Game state events
EventBus.publish_game_state_changed(new_state)
EventBus.publish_campaign_action(action, result)

# UI events
EventBus.publish_screen_changed(old_screen, new_screen)
EventBus.publish_notification_request(message, type)
EventBus.publish_tooltip_request(target, content)

# Simulation events
EventBus.publish_media_event(event)
EventBus.publish_accessibility_change(setting, value)
```

#### Debugging & Performance

##### `get_recent_events(count: int = 10, category: EventCategory = EventCategory.DEBUG) -> Array[Dictionary]`
Get recent events for debugging, optionally filtered by category.

##### `get_event_statistics() -> Dictionary`
Get comprehensive event system statistics.

##### `print_active_subscriptions() -> void`
Debug print of all active event subscriptions.

## GameStateManager

### State Management (`presentation/state_managers/game_state_manager.gd`)

Singleton managing authoritative game state with persistence and history.

#### Core Operations

##### `initialize_new_game(scenario_config: Dictionary = {}) -> void`
Initialize new game with optional scenario configuration.

##### `get_current_state() -> DataModels.GameState`
Get current authoritative game state.

##### `update_game_state(new_state: DataModels.GameState, description: String = "State Updated") -> void`
Update game state with change tracking for undo/redo.

##### `apply_campaign_action(action: DataModels.CampaignAction) -> bool`
Apply campaign action through simulation and update state.

##### `advance_time(days: int) -> void`
Advance game time and process time-based events.

#### Save/Load System

##### `save_game(file_path: String = SAVE_FILE_PATH, create_backup: bool = true) -> bool`
Save current game state with versioning and backup.

##### `load_game(file_path: String = SAVE_FILE_PATH) -> bool`
Load game state from file with version validation.

##### `get_save_file_info(file_path: String) -> Dictionary`
Get save file metadata without full loading.

#### History & Undo

##### `can_undo() -> bool`
Check if undo operation is available.

##### `undo_last_action() -> bool`
Undo the last state change.

##### `get_state_history() -> Array[String]`
Get list of state change descriptions for UI display.

## Usage Examples

### Basic Game Flow

```gd
# Initialize game
GameStateManager.initialize_new_game({
    "scenario": "default",
    "difficulty": "medium"
})

# Subscribe to state changes
EventBus.subscribe("game_state_changed", _on_state_changed)

# Execute campaign action
var rally = DataModels.CampaignAction.new("rally", "utrecht", 5000, 3)
var success = GameStateManager.apply_campaign_action(rally)

# Process media event
var event = simulation_api.generate_media_event("tv_interview", current_state)
# ... handle user response selection
var response_result = simulation_api.process_media_response(selected_response, question, current_state)

# Build coalition
var party_ids = ["player_party", "center_party", "green_party"]
var validation = simulation_api.validate_coalition(party_ids, current_state)
if validation.is_feasible:
    print("Coalition viable with ", validation.total_seats, " seats")
```

### Event System Integration

```gd
class Dashboard extends Control:
    func _ready():
        EventBus.subscribe("game_state_changed", _update_display)
        EventBus.subscribe("campaign_action_executed", _show_action_result)

    func _update_display(data: Dictionary):
        var new_state = data.get("new_state") as DataModels.GameState
        poll_label.text = "%.1f%%" % new_state.current_polls.get("player_party", 0.0)
        funds_label.text = "€%s" % String.num(new_state.campaign_funds, 0)

    func _exit_tree():
        EventBus.unsubscribe_all(self)
```

---

*For integration patterns and architectural guidance, see [Integration Guide](integration-guide.md)*
*For development setup and best practices, see [Developer Guide](developer-guide.md)*