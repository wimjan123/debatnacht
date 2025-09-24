# Quickstart Guide: Dutch Politics Simulation UI

## Project Setup

### Prerequisites
- Godot 4.2+ installed
- Basic understanding of GDScript and Control nodes
- Git repository initialized with project structure

### Repository Structure Creation
```bash
# Create main directories
mkdir -p ui/{scenes,themes}
mkdir -p ui/scenes/{main_menu,dashboard,map_view,media_events,coalition_builder,shared_components}
mkdir -p ui/themes/{accessibility_themes,localization}
mkdir -p presentation/{view_models,controllers,state_managers}
mkdir -p core_api
mkdir -p stubs/{sample_data,test_scenarios}
mkdir -p config/localization
mkdir -p tests/{unit,integration,ui}
```

### Initial Godot Project Setup
1. Create new Godot project in repository root
2. Configure project settings:
   - Set main scene to `ui/scenes/main_menu/MainMenu.tscn`
   - Enable localization under Project Settings > Localization
   - Add Dutch (nl) and English (en) locales
   - Set input map for accessibility shortcuts

### Core Interface Implementation

#### Step 1: Create Base Data Models
```gdscript
# Save as core_api/data_models.gd
extends RefCounted
class_name DataModels

# Copy content from contracts/data_models.gd
```

#### Step 2: Implement Simulation API Interface
```gdscript
# Save as core_api/simulation_api.gd
extends RefCounted
class_name SimulationAPI

# Copy interface from contracts/simulation_api.gd
```

#### Step 3: Create Stub Implementation
```gdscript
# Save as stubs/fake_simulation.gd
extends SimulationAPI
class_name FakeSimulation

# Implement all required methods with mock data
# Use seeded RandomNumberGenerator for deterministic results
var rng: RandomNumberGenerator

func _init():
    rng = RandomNumberGenerator.new()
    rng.seed = 12345  # Default test seed
```

### UI Foundation Setup

#### Step 4: Create Main Theme
```gdscript
# Create ui/themes/default_theme.tres in Godot editor
# Configure base colors, fonts, and component styles
# Ensure WCAG 2.1 AA contrast compliance (4.5:1 minimum)
```

#### Step 5: Implement Main Menu Scene
```gdscript
# Save as ui/scenes/main_menu/MainMenu.gd
extends Control
class_name MainMenu

@onready var new_game_button = $VBoxContainer/NewGameButton
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var scenarios_button = $VBoxContainer/ScenariosButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var credits_button = $VBoxContainer/CreditsButton

func _ready():
    # Configure button connections
    new_game_button.pressed.connect(_on_new_game_pressed)
    # ... other button connections

    # Set initial focus for keyboard navigation
    new_game_button.grab_focus()

func _on_new_game_pressed():
    get_tree().change_scene_to_file("res://ui/scenes/dashboard/Dashboard.tscn")
```

#### Step 6: Create Dashboard Controller
```gdscript
# Save as presentation/controllers/dashboard_controller.gd
extends Control
class_name DashboardController

@onready var poll_percentage_label = $KPIContainer/PollPercentage
@onready var projected_seats_label = $KPIContainer/ProjectedSeats
@onready var funds_label = $KPIContainer/Funds
@onready var days_left_label = $KPIContainer/DaysLeft

var simulation_api: SimulationAPI
var current_game_state: GameState

func _ready():
    simulation_api = FakeSimulation.new()
    # Initialize with test data

func update_kpis(polls: float, seats: int, funds: int, days_left: int):
    poll_percentage_label.text = "%.1f%%" % polls
    projected_seats_label.text = "%d seats" % seats
    funds_label.text = "€%s" % String.num(funds, 0)
    days_left_label.text = "%d days" % days_left
```

### Testing Framework Setup

#### Step 7: Create Test Base Class
```gdscript
# Save as tests/test_base.gd
extends RefCounted
class_name TestBase

# Helper methods for UI testing
func assert_equals(expected, actual, message: String = ""):
    assert(expected == actual, "Expected %s, got %s. %s" % [expected, actual, message])

func create_test_game_state() -> GameState:
    var state = GameState.new()
    state.rng_seed = 12345
    state.current_date = "2025-01-15"
    # ... populate with test data
    return state
```

#### Step 8: Create First Integration Test
```gdscript
# Save as tests/integration/test_dashboard_flow.gd
extends TestBase
class_name TestDashboardFlow

func test_dashboard_displays_correct_kpis():
    var dashboard = preload("res://ui/scenes/dashboard/Dashboard.tscn").instantiate()
    var test_state = create_test_game_state()

    dashboard.update_from_game_state(test_state)

    # Verify KPI display matches game state
    assert_equals("35.2%", dashboard.poll_percentage_label.text)
    assert_equals("54 seats", dashboard.projected_seats_label.text)
```

### Localization Setup

#### Step 9: Create Translation Files
```csv
# Save as config/localization/strings_en.csv
key,en
dashboard.poll_percentage,Poll Percentage
dashboard.projected_seats,Projected Seats
dashboard.funds,Campaign Funds
dashboard.days_left,Days Until Election
tooltip.poll_explanation,Your party's current polling percentage based on recent surveys
```

```csv
# Save as config/localization/strings_nl.csv
key,nl
dashboard.poll_percentage,Peiling Percentage
dashboard.projected_seats,Verwachte Zetels
dashboard.funds,Campagnefonds
dashboard.days_left,Dagen Tot Verkiezingen
tooltip.poll_explanation,Het huidige peilingspercentage van uw partij op basis van recente enquêtes
```

#### Step 10: Configure Localization in Project
```gdscript
# In project autoload or main scene initialization
func setup_localization():
    # Load translations
    var en_translation = load("res://config/localization/strings_en.translation")
    var nl_translation = load("res://config/localization/strings_nl.translation")

    # Add to translation server
    TranslationServer.add_translation(en_translation)
    TranslationServer.add_translation(nl_translation)

    # Set default locale
    TranslationServer.set_locale("en")
```

### Accessibility Implementation

#### Step 11: Create Accessibility Manager
```gdscript
# Save as presentation/managers/accessibility_manager.gd
extends Control
class_name AccessibilityManager

@export var default_font_size: int = 16
@export var min_scale: float = 0.75
@export var max_scale: float = 2.0

var current_theme: Theme

func _ready():
    current_theme = get_theme()

func set_text_scale(scale_factor: float):
    scale_factor = clamp(scale_factor, min_scale, max_scale)
    current_theme.default_font_size = int(default_font_size * scale_factor)

func set_high_contrast_mode(enabled: bool):
    if enabled:
        # Load high contrast theme variant
        current_theme = load("res://ui/themes/high_contrast_theme.tres")
    else:
        current_theme = load("res://ui/themes/default_theme.tres")
```

### Performance Optimization Setup

#### Step 12: Create Object Pool for Dynamic Elements
```gdscript
# Save as presentation/managers/object_pool.gd
extends RefCounted
class_name ObjectPool

var tooltip_pool: Array[Control] = []
var notification_pool: Array[Control] = []

func get_tooltip() -> Control:
    if tooltip_pool.is_empty():
        return preload("res://ui/scenes/shared_components/Tooltip.tscn").instantiate()
    else:
        return tooltip_pool.pop_back()

func return_tooltip(tooltip: Control):
    tooltip.hide()
    tooltip_pool.push_back(tooltip)
```

## Validation Testing

### Manual Testing Checklist
- [ ] Main menu displays with proper keyboard focus
- [ ] Dashboard shows placeholder KPI values
- [ ] Text scales correctly from 75% to 200%
- [ ] Language switches between Dutch and English
- [ ] High contrast theme loads without errors
- [ ] Tooltips appear on hover and keyboard focus
- [ ] All UI elements are keyboard accessible

### Automated Test Execution
```bash
# Run unit tests in Godot
godot --headless --script res://tests/run_all_tests.gd

# Expected output: All tests pass with seeded random results
```

### Performance Validation
```gdscript
# Add to dashboard controller for performance monitoring
func _process(delta):
    if Engine.get_frames_per_second() < 55:
        push_warning("Performance below 60 FPS threshold: %d" % Engine.get_frames_per_second())
```

### Constitutional Compliance Verification
- [ ] Seeded RNG produces identical results with same seed
- [ ] All displayed numbers have explanatory tooltips
- [ ] No references to real political figures or parties
- [ ] Dutch and English text complete and accurate
- [ ] WCAG 2.1 AA contrast ratios validated
- [ ] Keyboard navigation covers all interactive elements
- [ ] JSON configuration files are human-readable
- [ ] Save files include version metadata

## Next Steps
After completing this quickstart:
1. Run `/tasks` command to generate detailed implementation tasks
2. Begin TDD implementation of core simulation mathematics
3. Expand UI components to cover all 10 main screens
4. Implement comprehensive tooltip and explanation systems
5. Add advanced accessibility features (screen reader support)
6. Create complete test scenarios for all user workflows