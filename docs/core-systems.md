# Core Systems Documentation

## Architecture Overview

The Dutch Politics Simulation UI implements a clean architecture with clear separation between presentation and simulation layers. The core systems provide the foundational infrastructure for the educational political simulation.

## Event-Driven Architecture

### EventBus System (`presentation/managers/event_bus.gd`)

The EventBus serves as the central nervous system for the application, enabling loose coupling between components through a publish-subscribe pattern.

#### Key Features

- **Global Singleton**: Autoloaded for application-wide access
- **Type-Safe Events**: Organized by EventCategory enum for better debugging
- **Event History**: Maintains rolling history for debugging and replay functionality
- **Performance Monitoring**: Tracks subscriber counts and warns of potential bottlenecks

#### Event Categories

```gd
enum EventCategory {
    GAME_STATE,      # Core simulation state changes
    UI_NAVIGATION,   # Screen transitions and modal management
    USER_ACTION,     # Player input and interaction events
    SIMULATION,      # Simulation backend communications
    AUDIO,           # Sound and music management
    ACCESSIBILITY,   # A11y setting changes and requests
    DEBUG,           # Development and troubleshooting
    SYSTEM,          # Low-level system events
    INPUT,           # Input handling and validation
    GAME,            # Game-specific mechanics
    AUDIT,           # Constitutional compliance tracking
    UI               # UI component interactions
}
```

#### Core Event Constants

```gd
# Game State Events
const GAME_STATE_CHANGED = "game_state_changed"
const CAMPAIGN_ACTION_EXECUTED = "campaign_action_executed"
const ELECTION_TRIGGERED = "election_triggered"
const TIME_ADVANCED = "time_advanced"

# UI Navigation Events
const SCREEN_CHANGED = "screen_changed"
const MODAL_OPENED = "modal_opened"
const MODAL_CLOSED = "modal_closed"
const NAVIGATION_REQUESTED = "navigation_requested"

# User Interface Events
const TOOLTIP_REQUESTED = "tooltip_requested"
const NOTIFICATION_REQUESTED = "notification_requested"
const HELP_REQUESTED = "help_requested"

# Simulation Events
const MEDIA_EVENT_TRIGGERED = "media_event_triggered"
const OPINION_POLL_UPDATED = "opinion_poll_updated"
const COALITION_FORMED = "coalition_formed"

# Accessibility Events
const ACCESSIBILITY_CHANGED = "accessibility_changed"
const THEME_CHANGED = "theme_changed"
const LANGUAGE_CHANGED = "language_changed"
```

#### Usage Patterns

**Publishing Events:**
```gd
# Simple event
EventBus.publish("custom_event", {}, EventCategory.USER_ACTION)

# Using convenience methods
EventBus.publish_game_state_changed(new_state)
EventBus.publish_notification_request("Action completed", "success")
```

**Subscribing to Events:**
```gd
func _ready():
    EventBus.subscribe("game_state_changed", _on_game_state_changed)

func _on_game_state_changed(data: Dictionary):
    var new_state = data.get("new_state")
    # Handle state change...

func _exit_tree():
    EventBus.unsubscribe_all(self)  # Clean up all subscriptions
```

#### Performance & Debugging

- **Event History**: Rolling buffer of last 100 events for debugging
- **Subscription Monitoring**: Warns when events have >20 subscribers
- **Performance Metrics**: Tracks total subscribers and event frequency
- **Validation**: Built-in event data validation for development builds

## State Management

### GameStateManager (`presentation/state_managers/game_state_manager.gd`)

The GameStateManager maintains the authoritative game state and coordinates with the simulation backend.

#### Responsibilities

- **State Authority**: Single source of truth for current game state
- **Save/Load Operations**: Persistent storage with versioning and backup
- **State History**: Undo/redo functionality with action descriptions
- **Auto-Save**: Periodic saves for data protection

#### Key Features

```gd
# Game State Management
var current_game_state: DataModels.GameState
var simulation_api: SimulationAPI
var is_game_initialized: bool = false

# State History for Undo/Redo
var state_history: Array[Dictionary] = []
var max_history_entries: int = 50

# Auto-Save Configuration
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 minutes
```

#### Core Operations

**Game Initialization:**
```gd
func initialize_new_game(scenario_config: Dictionary = {}):
    current_game_state = DataModels.GameState.new()
    # Apply scenario configuration...
    simulation_api.initialize_game_state(current_game_state)
    is_game_initialized = true
    _create_state_snapshot("Game Initialized")
    game_initialized.emit(current_game_state)
```

**State Updates:**
```gd
func update_game_state(new_state: DataModels.GameState, description: String = "State Updated"):
    _create_state_snapshot(description)  # For undo functionality
    current_game_state = new_state
    simulation_api.update_game_state(current_game_state)
    game_state_changed.emit(current_game_state)
```

**Save/Load with Versioning:**
```gd
func save_game(file_path: String = SAVE_FILE_PATH, create_backup: bool = true) -> bool:
    var save_data = {
        "version": save_version,
        "timestamp": Time.get_unix_time_from_system(),
        "game_state": current_game_state.serialize(),
        "state_history": _serialize_state_history(),
        "metadata": _create_save_metadata()
    }
    # Write to file with validation...
```

#### Signals

- `game_state_changed(new_state)`: Broadcast state updates
- `game_initialized(game_state)`: New game setup completion
- `save_completed(success, file_path)`: Save operation results
- `load_completed(success, game_state)`: Load operation results
- `auto_save_triggered()`: Periodic save notifications

### UIStateManager (`presentation/state_managers/ui_state_manager.gd`)

Manages UI-specific state separate from game logic, handling navigation, modals, and user interface preferences.

#### Key Responsibilities

- **Screen Navigation**: Current and previous screen tracking
- **Modal Management**: Dialog stack and overlay coordination
- **UI Preferences**: Accessibility settings, themes, layout preferences
- **Selection State**: Currently selected regions, parties, or interface elements

## Simulation Integration

### SimulationAPI Interface (`core_api/simulation_api.gd`)

Abstract interface defining the contract between the UI and simulation backends.

#### Design Philosophy

- **Contract-Driven**: Clear method signatures with documented parameters
- **Pluggable Backends**: Support for multiple simulation implementations
- **Type Safety**: Strict typing with DataModels namespace
- **Error Handling**: Explicit error states and validation

#### Core Method Groups

**Game State Management:**
```gd
func initialize_game(scenario_id: String, rng_seed: int) -> DataModels.GameState
func load_game(save_data: Dictionary) -> DataModels.GameState
func save_game(current_state: DataModels.GameState) -> Dictionary
```

**Campaign Operations:**
```gd
func execute_campaign_action(action: DataModels.CampaignAction, current_state: DataModels.GameState) -> DataModels.ActionResult
func get_available_actions(party_id: String, current_state: DataModels.GameState) -> Array[DataModels.CampaignAction]
func calculate_current_polls(current_state: DataModels.GameState) -> DataModels.OpinionPoll
```

**Geographic Data:**
```gd
func get_regional_data(filter_type: String, filter_value: String, current_state: DataModels.GameState) -> Dictionary
func get_region_tooltip_data(region_id: String, current_state: DataModels.GameState) -> DataModels.RegionTooltipData
```

**Media Events:**
```gd
func generate_media_event(event_type: String, current_state: DataModels.GameState) -> DataModels.MediaEvent
func process_media_response(response: DataModels.ResponseOption, question: DataModels.MediaQuestion, current_state: DataModels.GameState) -> DataModels.MediaResponse
```

**Coalition Building:**
```gd
func calculate_coalition_compatibility(party_a_id: String, party_b_id: String, current_state: DataModels.GameState) -> DataModels.CoalitionCompatibility
func validate_coalition(party_ids: Array[String], current_state: DataModels.GameState) -> DataModels.CoalitionValidation
```

### FakeSimulation Implementation (`stubs/fake_simulation.gd`)

Current implementation providing realistic stub data for development and testing.

#### Key Features

- **Seeded Randomization**: Deterministic results for testing
- **Realistic Data**: Authentic Dutch political party structures and demographics
- **Complete API Coverage**: Implements all SimulationAPI methods
- **Educational Focus**: Data designed for learning democratic processes

#### Data Generation Examples

**Dutch Political Parties:**
```gd
var party_data = [
    {"id": "player_party", "name": "Your Party", "ideology": Vector2(0.0, 0.0), "seats": 25},
    {"id": "center_party", "name": "Center Party", "ideology": Vector2(0.1, 0.0), "seats": 35},
    {"id": "left_party", "name": "Social Democrats", "ideology": Vector2(-0.6, 0.3), "seats": 28},
    {"id": "right_party", "name": "Conservative Party", "ideology": Vector2(0.7, -0.2), "seats": 22},
    {"id": "green_party", "name": "Green Party", "ideology": Vector2(-0.3, 0.8), "seats": 15}
]
```

**Dutch Provinces:**
```gd
var province_names = [
    "Noord-Holland", "Zuid-Holland", "Utrecht", "Noord-Brabant",
    "Gelderland", "Overijssel", "Limburg", "Groningen",
    "Friesland", "Drenthe", "Flevoland", "Zeeland"
]
```

## Data Models System

### DataModels Namespace (`core_api/data_models.gd`)

Comprehensive type system defining all game entities and their relationships.

#### Core Game Objects

**GameState:**
```gd
class GameState:
    var current_day: int = 0
    var days_until_election: int = 365
    var phase: String = "campaign"  # campaign, election, results
    var player_party_id: String = ""
    var campaign_funds: int = 1000000
    var current_polls: Dictionary = {}
    var party_reputation: Dictionary = {}
```

**Party:**
```gd
class Party:
    var party_id: String = ""
    var display_name: String = ""
    var short_name: String = ""  # "VVD", "PvdA"
    var color: Color = Color.BLUE
    var ideology_position: Vector2 = Vector2.ZERO  # economic/social axes
    var policy_priorities: Dictionary = {}
    var current_polls: Dictionary = {}
    var campaign_funds: int = 0
    var seat_count: int = 0
```

#### Result Types

**ActionResult:**
```gd
class ActionResult:
    var success: bool = false
    var new_state: GameState = null
    var effects: Dictionary = {}  # metric_name -> change_amount
    var explanation: String = ""  # human-readable outcome
    var cost_paid: int = 0
```

**MediaResponse:**
```gd
class MediaResponse:
    var sentiment_change: float = 0.0     # -1.0 to 1.0
    var reach_multiplier: float = 1.0     # audience reach adjustment
    var poll_effects: Dictionary = {}     # party_id -> poll change
    var explanation: String = ""
```

## Supporting Systems

### Object Pool (`presentation/managers/object_pool.gd`)

Memory-efficient object management for frequently created/destroyed UI elements.

- **Tooltip Pool**: Reusable tooltip instances
- **Notification Pool**: Message display objects
- **Effect Pool**: Visual feedback elements

### Performance Monitor (`presentation/managers/performance_monitor.gd`)

Real-time performance tracking for constitutional compliance (60 FPS requirement).

- **FPS Monitoring**: Continuous frame rate tracking
- **Memory Usage**: Heap and object count monitoring
- **Response Time**: UI interaction latency measurement

### Accessibility Manager (`presentation/managers/accessibility_manager.gd`)

WCAG 2.1 AA compliance management.

- **Screen Reader Support**: Aria labels and navigation hints
- **Keyboard Navigation**: Full functionality without mouse
- **Visual Accessibility**: High contrast themes, text scaling
- **Focus Management**: Logical tab order and focus indicators

### Localization Manager (`presentation/managers/localization_manager.gd`)

Multi-language support with cultural adaptation.

- **Dynamic Language Switching**: Runtime locale changes
- **Text Scaling**: 75%-200% size support
- **Cultural Formatting**: Dutch/English date and number formats
- **Translation Validation**: Missing key detection and fallback

### Input Handler (`presentation/managers/input_handler.gd`)

Centralized input processing with accessibility support.

- **Action Mapping**: Configurable key bindings
- **Accessibility Shortcuts**: Screen reader and navigation aids
- **Multi-Modal Input**: Mouse, keyboard, and assistive device support
- **Input Validation**: Constitutional compliance checks

---

*For API details and method signatures, see [API Reference](api-reference.md)*
*For component integration patterns, see [Integration Guide](integration-guide.md)*