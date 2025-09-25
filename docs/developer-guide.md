# Developer Guide

## Getting Started

### Prerequisites

- **Godot 4.5+**: Download from [godotengine.org](https://godotengine.org/download)
- **Git**: For version control and contribution workflow
- **Text Editor**: VSCode with Godot Language Server extension recommended
- **Screen Reader** (optional): For accessibility testing (NVDA, JAWS, or VoiceOver)

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd debatnacht

# Open in Godot
godot project.godot

# Alternative: Import project through Godot Project Manager
# File > Import > Select project.godot
```

### Project Structure Overview

```
debatnacht/
├── core_api/              # Simulation interface and data models
│   ├── simulation_api.gd  # Abstract simulation interface
│   └── data_models.gd     # Type system and data structures
├── presentation/          # UI and presentation logic
│   ├── controllers/       # UI logic controllers
│   ├── managers/         # Autoloaded system managers
│   ├── state_managers/   # Game and UI state management
│   ├── pooled_objects/   # Object pooling for performance
│   └── integration/      # Simulation-UI integration layer
├── ui/                   # Godot scenes and UI assets
│   ├── scenes/          # Game screens (.tscn files)
│   ├── themes/         # Visual themes and accessibility
│   └── fonts/          # Typography assets
├── stubs/               # Development simulation implementation
│   ├── fake_simulation.gd # Current simulation backend
│   └── sample_data/      # Test scenarios and mock data
├── tests/               # Comprehensive test suite
│   ├── unit/           # Unit tests for individual components
│   ├── integration/    # Integration and workflow tests
│   ├── performance/    # Performance and compliance tests
│   └── accessibility/  # WCAG 2.1 AA compliance tests
├── config/             # Configuration files
│   └── localization/   # Translation files (.csv format)
├── docs/               # Documentation (this guide)
└── scripts/            # Build and deployment scripts
```

## Development Workflow

### 1. Branch Strategy

```bash
# Feature development
git checkout -b feature/your-feature-name
git commit -m "feat: add coalition building drag-and-drop"
git push origin feature/your-feature-name

# Bug fixes
git checkout -b bugfix/issue-description
git commit -m "fix: resolve poll calculation edge case"
git push origin bugfix/issue-description

# Documentation
git checkout -b docs/update-api-reference
git commit -m "docs: update SimulationAPI method signatures"
git push origin docs/update-api-reference
```

### 2. Code Quality Standards

#### GDScript Style Guide

Follow Godot's official style conventions:

```gd
# Class structure
extends Control
class_name DashboardView

# Constants in UPPER_CASE
const MAX_CAMPAIGN_FUNDS = 2000000
const DEFAULT_POLL_PERCENTAGE = 15.0

# Private variables with leading underscore
var _current_state: DataModels.GameState
var _tooltip_manager: TooltipManager

# Public interface clearly documented
## Initialize dashboard with initial game state
## @param initial_state: Starting game state data
## @param simulation_api: API for simulation communication
func initialize(initial_state: DataModels.GameState, simulation_api: SimulationAPI) -> void:
    _current_state = initial_state
    _setup_ui_components()
    _subscribe_to_events()

# Type hints for all parameters and returns
func _calculate_poll_change(base_percentage: float, action_effect: float) -> float:
    return clamp(base_percentage + action_effect, 0.0, 100.0)

# Clear error handling
func _handle_campaign_action(action: DataModels.CampaignAction) -> bool:
    if action == null:
        push_error("Dashboard: Cannot execute null campaign action")
        return false

    if not _validate_action_preconditions(action):
        push_warning("Dashboard: Action preconditions not met")
        return false

    return true
```

#### File Organization

```gd
# File header with purpose and dependencies
extends Control
class_name CoalitionBuilderView
## Coalition formation interface with drag-and-drop party cards
## Requires: EventBus, GameStateManager, SimulationAPI

# Constants first
const MIN_COALITION_SEATS = 76
const TOTAL_PARLIAMENT_SEATS = 150

# Exports for designer configuration
@export var card_spacing: float = 10.0
@export var animation_duration: float = 0.3

# Public properties
var selected_parties: Array[String] = []
var current_compatibility: Dictionary = {}

# Private implementation
var _drag_preview: Control
var _compatibility_timer: Timer

# Initialization
func _ready() -> void:
    _setup_ui_components()
    _connect_signals()
    _subscribe_to_events()

# Public interface
func add_party_to_coalition(party_id: String) -> bool:
    # Implementation

# Signal handlers (grouped)
func _on_party_card_drag_started(party_id: String) -> void:
    # Implementation

func _on_compatibility_timer_timeout() -> void:
    # Implementation

# Private helpers (grouped by functionality)
func _setup_ui_components() -> void:
    # Implementation

func _validate_coalition_requirements(party_ids: Array[String]) -> bool:
    # Implementation

# Cleanup
func _exit_tree() -> void:
    EventBus.unsubscribe_all(self)
    if _compatibility_timer:
        _compatibility_timer.queue_free()
```

### 3. Testing Requirements

#### Unit Tests

All core logic must have unit tests:

```gd
# tests/unit/test_coalition_validation.gd
extends "res://addons/gut/test.gd"

var simulation_api: FakeSimulation

func before_each():
    simulation_api = FakeSimulation.new()

func test_valid_coalition_calculation():
    # Arrange
    var party_ids = ["center_party", "left_party", "green_party"]
    var game_state = _create_test_game_state()

    # Act
    var validation = simulation_api.validate_coalition(party_ids, game_state)

    # Assert
    assert_true(validation.is_feasible, "Coalition should be feasible")
    assert_ge(validation.total_seats, 76, "Should have majority")

func test_insufficient_seats_coalition():
    # Test coalition without majority
    var party_ids = ["small_party_1", "small_party_2"]
    var game_state = _create_test_game_state()

    var validation = simulation_api.validate_coalition(party_ids, game_state)

    assert_false(validation.majority_status, "Should not have majority")
    assert_lt(validation.total_seats, 76, "Should have insufficient seats")

func _create_test_game_state() -> DataModels.GameState:
    # Create consistent test state
    var state = DataModels.GameState.new()
    state.parties = _create_test_parties()
    return state
```

#### Integration Tests

Test component interactions:

```gd
# tests/integration/test_coalition_builder_workflow.gd
extends "res://addons/gut/test.gd"

var coalition_builder: CoalitionBuilderView
var mock_simulation: MockSimulationAPI

func before_each():
    mock_simulation = MockSimulationAPI.new()
    GameStateManager.simulation_api = mock_simulation

    coalition_builder = preload("res://ui/scenes/coalition_builder/CoalitionBuilder.tscn").instantiate()
    add_child_autofree(coalition_builder)

func test_full_coalition_formation_workflow():
    # Test complete user workflow
    # 1. Drag party cards together
    # 2. Validate compatibility
    # 3. Confirm coalition
    # 4. Update game state

    # Simulate UI interactions
    coalition_builder._on_party_card_selected("center_party")
    coalition_builder._on_party_card_selected("green_party")

    # Verify validation triggered
    assert_true(mock_simulation.validate_coalition_called)
    assert_eq(mock_simulation.last_validation_parties.size(), 2)

    # Simulate confirmation
    coalition_builder._on_confirm_coalition_pressed()

    # Verify state update
    var current_state = GameStateManager.get_current_state()
    assert_gt(current_state.active_coalition_ids.size(), 0)
```

#### Accessibility Tests

Ensure WCAG 2.1 AA compliance:

```gd
# tests/accessibility/test_coalition_builder_accessibility.gd
extends "res://addons/gut/test.gd"

func test_keyboard_navigation():
    var scene = preload("res://ui/scenes/coalition_builder/CoalitionBuilder.tscn").instantiate()
    add_child_autofree(scene)

    # Test tab order
    var focusable_nodes = _get_focusable_nodes(scene)
    assert_gt(focusable_nodes.size(), 0, "Should have focusable elements")

    # Test each node has accessible name
    for node in focusable_nodes:
        assert_true(node.has_meta("accessible_name") or node.get("text", "") != "",
                   "Node should have accessible name: " + str(node))

func test_color_contrast():
    # Test high contrast theme
    AccessibilityManager.set_high_contrast_enabled(true)

    var scene = preload("res://ui/scenes/coalition_builder/CoalitionBuilder.tscn").instantiate()
    add_child_autofree(scene)

    # Verify contrast ratios meet WCAG standards
    _verify_contrast_ratios(scene)

func _get_focusable_nodes(node: Node) -> Array:
    var focusable = []
    if node is Control and node.focus_mode != Control.FOCUS_NONE:
        focusable.append(node)

    for child in node.get_children():
        focusable.append_array(_get_focusable_nodes(child))

    return focusable
```

### 4. Performance Standards

#### Constitutional Compliance Requirements

The project must maintain constitutional compliance through technical excellence:

```gd
# Performance monitoring integration
func _ready():
    PerformanceMonitor.set_fps_target(60)  # Constitutional requirement
    PerformanceMonitor.set_response_time_target(100)  # Sub-100ms interactions

    # Monitor critical paths
    PerformanceMonitor.start_monitoring("campaign_action_execution")
    PerformanceMonitor.start_monitoring("coalition_validation")
    PerformanceMonitor.start_monitoring("map_rendering")

func _execute_campaign_action(action: DataModels.CampaignAction):
    var timer = PerformanceMonitor.start_timer("campaign_action_execution")

    # Execute action...
    var result = simulation_api.execute_campaign_action(action, current_state)

    PerformanceMonitor.end_timer("campaign_action_execution", timer)

    # Verify constitutional compliance
    if PerformanceMonitor.get_last_frame_time() > 16.67:  # >60 FPS violation
        PerformanceMonitor.report_compliance_violation("FPS below constitutional requirement")
```

#### Memory Management

```gd
# Object pooling for frequent allocations
func _show_tooltip(content: String):
    var tooltip = ObjectPool.get_pooled_tooltip()
    tooltip.setup(content)
    tooltip.show()

    # Auto-return when done
    tooltip.finished.connect(ObjectPool.return_pooled_tooltip.bind(tooltip))

# Resource cleanup
func _exit_tree():
    # Clean up subscriptions
    EventBus.unsubscribe_all(self)

    # Free pooled objects
    ObjectPool.cleanup_unused_objects()

    # Clear caches
    _region_data_cache.clear()
    _tooltip_content_cache.clear()
```

## Architecture Patterns

### 1. Event-Driven Architecture

Use EventBus for loose coupling:

```gd
# Publishing events
class CampaignController extends RefCounted:
    func execute_rally(region_id: String, budget: int):
        var action = DataModels.CampaignAction.new("rally", region_id, budget, 3)
        var result = GameStateManager.apply_campaign_action(action)

        # Publish result for all interested components
        EventBus.publish("campaign_action_executed", {
            "action": action,
            "result": result,
            "success": result.success if result else false
        })

# Subscribing to events
class Dashboard extends Control:
    func _ready():
        EventBus.subscribe("campaign_action_executed", _on_campaign_action_executed)
        EventBus.subscribe("game_state_changed", _on_game_state_changed)

    func _on_campaign_action_executed(data: Dictionary):
        var action = data.get("action") as DataModels.CampaignAction
        var success = data.get("success", false)

        if success:
            _show_success_feedback(action)
        else:
            _show_error_feedback(action)

    func _exit_tree():
        EventBus.unsubscribe_all(self)  # Critical for memory management
```

### 2. State Management Pattern

Centralized state with reactive updates:

```gd
# GameStateManager as single source of truth
func get_current_polls() -> Dictionary:
    # CORRECT: Always use authoritative source
    return GameStateManager.get_current_state().current_polls

# UI components react to state changes
func _on_game_state_changed(data: Dictionary):
    var new_state = data.get("new_state") as DataModels.GameState

    # Update UI to reflect new state
    _update_poll_display(new_state.current_polls)
    _update_funds_display(new_state.campaign_funds)
    _update_time_display(new_state.current_day, new_state.days_until_election)
```

### 3. Clean Architecture Boundaries

Respect dependency directions:

```gd
# CORRECT: UI depends on controllers, controllers depend on managers
class DashboardView extends Control:
    var controller: DashboardController

    func _ready():
        controller = DashboardController.new()
        controller.initialize(GameStateManager, EventBus)

# INCORRECT: Don't let simulation layer depend on UI
# Never do this in SimulationAPI implementations:
# func execute_action(action):
#     SomeUIComponent.show_message("Action executed")  # WRONG!
```

### 4. Accessibility Integration

Make accessibility a first-class concern:

```gd
func _setup_accessibility():
    # Screen reader labels
    poll_percentage_label.set("accessible_name", "Current polling percentage")
    funds_label.set("accessible_name", "Available campaign funds")

    # Keyboard navigation
    rally_button.focus_neighbor_right = rally_button.get_path_to(ad_button)
    rally_button.focus_neighbor_down = rally_button.get_path_to(next_row_first_button)

    # Color independence
    success_indicator.text = "✓ Success"  # Don't rely only on green color
    error_indicator.text = "✗ Error"     # Don't rely only on red color

func _on_accessibility_settings_changed(setting: String, value):
    match setting:
        "text_scale":
            _apply_text_scaling(value)
        "high_contrast":
            _apply_high_contrast_theme(value)
        "screen_reader_enabled":
            _enable_screen_reader_support(value)
```

## Common Development Tasks

### 1. Adding New UI Screens

```bash
# Create new scene structure
mkdir ui/scenes/your_feature
cd ui/scenes/your_feature

# Files to create:
# YourFeature.tscn     - Main scene file
# YourFeature.gd       - Scene script (UI logic only)
```

```gd
# YourFeature.gd - Scene script template
extends Control
class_name YourFeatureView

var controller: YourFeatureController

func _ready():
    controller = YourFeatureController.new()
    _setup_ui_components()
    _connect_signals()
    _subscribe_to_events()

func _setup_ui_components():
    # Initialize UI elements
    pass

func _connect_signals():
    # Connect UI signals to handlers
    pass

func _subscribe_to_events():
    # Subscribe to EventBus events
    EventBus.subscribe("relevant_event", _on_relevant_event)

func _on_relevant_event(data: Dictionary):
    # Handle event
    pass

func _exit_tree():
    EventBus.unsubscribe_all(self)
```

```gd
# presentation/controllers/your_feature_controller.gd
extends RefCounted
class_name YourFeatureController

func initialize():
    # Setup controller logic
    pass

func handle_user_action(action_data: Dictionary):
    # Process user interaction
    # Call simulation API if needed
    # Update game state
    # Publish events for UI updates
    pass
```

### 2. Adding New SimulationAPI Methods

```gd
# 1. Add method signature to core_api/simulation_api.gd
func your_new_method(param1: String, param2: int) -> DataModels.YourResultType:
    assert(false, "Must implement your_new_method")
    return null

# 2. Implement in stubs/fake_simulation.gd
func your_new_method(param1: String, param2: int) -> DataModels.YourResultType:
    var result = DataModels.YourResultType.new()
    result.calculated_value = param2 * rng.randf_range(0.8, 1.2)
    result.explanation = "Simulated calculation for %s" % param1
    return result

# 3. Add corresponding data model if needed in core_api/data_models.gd
class YourResultType:
    extends RefCounted
    var calculated_value: float = 0.0
    var explanation: String = ""

# 4. Write unit test in tests/unit/
func test_your_new_method():
    var simulation = FakeSimulation.new()
    var result = simulation.your_new_method("test_param", 100)

    assert_not_null(result)
    assert_gt(result.calculated_value, 0.0)
    assert_ne(result.explanation, "")
```

### 3. Adding Localization Support

```csv
# config/localization/strings_en.csv
KEY,EN,CONTEXT
ui.dashboard.poll_percentage,Poll: {poll}%,Polling percentage display
ui.dashboard.campaign_funds,Funds: €{funds},Campaign budget display
ui.coalition.seats_needed,Need {seats} for majority,Coalition requirement explanation

# config/localization/strings_nl.csv
KEY,NL,CONTEXT
ui.dashboard.poll_percentage,Peiling: {poll}%,Polling percentage display
ui.dashboard.campaign_funds,Budget: €{funds},Campaign budget display
ui.coalition.seats_needed,{seats} zetels nodig voor meerderheid,Coalition requirement explanation
```

```gd
# Using localization in code
func _update_poll_display(poll_percentage: float):
    var formatted_text = tr("ui.dashboard.poll_percentage").format({
        "poll": "%.1f" % poll_percentage
    })
    poll_label.text = formatted_text

# Accessibility label in multiple languages
func _setup_accessibility_labels():
    poll_label.set("accessible_name", tr("ui.dashboard.poll_percentage.accessible"))
```

### 4. Adding Themes and Accessibility

```gd
# ui/themes/accessibility_themes/high_contrast_theme.tres
# Create high contrast theme resource with WCAG AA compliant colors

# Applying themes programmatically
func _apply_accessibility_theme(theme_name: String):
    var theme_path = "res://ui/themes/accessibility_themes/%s.tres" % theme_name
    if ResourceLoader.exists(theme_path):
        var accessibility_theme = load(theme_path)
        theme = accessibility_theme

# Color-blind friendly palette
const COLORBLIND_FRIENDLY_PALETTE = {
    "primary": Color("#1f77b4"),    # Blue
    "secondary": Color("#ff7f0e"),  # Orange
    "success": Color("#2ca02c"),    # Green
    "warning": Color("#d62728"),    # Red
    "info": Color("#9467bd"),       # Purple
    "neutral": Color("#7f7f7f")     # Gray
}
```

## Debugging and Development Tools

### 1. EventBus Debug Tools

```gd
# Debug current event subscriptions
func _input(event):
    if event.is_action_pressed("debug_events"):
        EventBus.print_active_subscriptions()
        EventBus.print_recent_events(10)

# Monitor specific events
func _ready():
    EventBus.subscribe("debug_all_events", _debug_event_handler)

func _debug_event_handler(data: Dictionary):
    print("Event Debug: ", data)
```

### 2. Performance Profiling

```gd
# Profile specific operations
func _execute_expensive_operation():
    var start_time = Time.get_ticks_usec()

    # Your operation here...

    var end_time = Time.get_ticks_usec()
    var duration_ms = (end_time - start_time) / 1000.0

    if duration_ms > 16.67:  # >60 FPS threshold
        print("Performance Warning: Operation took %.2fms" % duration_ms)

# Built-in profiler integration
func _ready():
    if OS.is_debug_build():
        PerformanceMonitor.start_profiling()
```

### 3. Accessibility Testing

```gd
# Test screen reader compatibility
func _test_screen_reader_support():
    # Check all interactive elements have accessible names
    for child in get_all_children():
        if child is Control and child.focus_mode != Control.FOCUS_NONE:
            var accessible_name = child.get("accessible_name", "")
            if accessible_name.is_empty():
                push_warning("Missing accessible name: %s" % child.name)

# Keyboard navigation testing
func _test_keyboard_navigation():
    # Verify focus chain completeness
    var focusable_controls = _get_focusable_controls()
    for control in focusable_controls:
        if not _has_valid_focus_neighbors(control):
            push_warning("Incomplete focus navigation: %s" % control.name)
```

## Deployment and Build

### 1. Build Configuration

```gd
# Build script configuration
# scripts/build.sh
#!/bin/bash

# Set build parameters
GODOT_VERSION="4.5"
BUILD_NAME="debatnacht"
EXPORT_PRESETS=("Windows Desktop" "macOS" "Linux/X11")

# Constitutional compliance checks
echo "Running constitutional compliance validation..."
godot --headless --script tests/constitutional_compliance.gd

if [ $? -ne 0 ]; then
    echo "Constitutional compliance check failed!"
    exit 1
fi

# Performance validation
echo "Running performance validation..."
godot --headless --script tests/performance/performance_validation.gd

# Accessibility validation
echo "Running accessibility validation..."
godot --headless --script tests/accessibility/accessibility_audit.gd

# Build exports
for preset in "${EXPORT_PRESETS[@]}"; do
    echo "Building for: $preset"
    godot --headless --export-release "$preset" "builds/${BUILD_NAME}_${preset}.zip"
done
```

### 2. CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: Constitutional Compliance CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.5

      - name: Constitutional Compliance Tests
        run: |
          godot --headless --script tests/constitutional_compliance.gd

      - name: Performance Tests
        run: |
          godot --headless --script tests/performance/test_performance_validation.gd

      - name: Accessibility Tests
        run: |
          godot --headless --script tests/accessibility/test_accessibility_audit.gd

      - name: Unit Tests
        run: |
          godot --headless --script tests/run_all_tests.gd
```

## Contributing Guidelines

### 1. Pull Request Process

1. **Fork and Branch**: Create feature branch from main
2. **Constitutional Compliance**: Ensure all changes meet constitutional requirements
3. **Testing**: Add/update tests for new functionality
4. **Documentation**: Update relevant documentation
5. **Accessibility**: Verify WCAG 2.1 AA compliance
6. **Performance**: Validate 60 FPS and <100ms response time requirements
7. **Review**: Submit PR with detailed description

### 2. Code Review Checklist

**Constitutional Compliance:**
- [ ] Maintains political neutrality
- [ ] Provides transparent calculations
- [ ] Includes educational explanations
- [ ] Meets accessibility standards

**Technical Quality:**
- [ ] Follows GDScript style guide
- [ ] Includes comprehensive tests
- [ ] Proper error handling
- [ ] Performance requirements met
- [ ] Memory management correct

**Architecture:**
- [ ] Respects clean architecture boundaries
- [ ] Uses EventBus appropriately
- [ ] Proper separation of concerns
- [ ] Testable design patterns

### 3. Documentation Standards

- **Code Comments**: Explain why, not what
- **API Documentation**: Complete parameter and return documentation
- **Architecture Decisions**: Document significant design choices
- **User-Facing**: Keep explanations clear and educational

---

*This guide covers the essential patterns and practices for contributing to the Dutch Politics Simulation UI. For specific API details, see [API Reference](api-reference.md), and for component integration, see [Integration Guide](integration-guide.md).*