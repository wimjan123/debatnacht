# UI Components Documentation

## Overview

The Dutch Politics Simulation UI implements a comprehensive component system with constitutional compliance features, accessibility standards, and educational focus. All components follow WCAG 2.1 AA guidelines and maintain 60 FPS performance requirements.

## Scene Architecture

### Main Navigation Flow

```
MainMenu.tscn
├── Dashboard.tscn (Campaign Management)
├── MapView.tscn (Geographic Visualization)
├── CoalitionBuilder.tscn (Coalition Formation)
├── MediaEvent.tscn (Interviews & Debates)
├── ParliamentView.tscn (Legislative Process)
├── ElectionResults.tscn (Results Analysis)
├── SocialMediaConsole.tscn (Social Media)
└── Settings.tscn (Accessibility & Preferences)
```

### Shared Components

```
ui/scenes/shared_components/
├── tooltip_manager.gd      # Educational tooltips
├── notification_system.gd # User feedback system
├── accessibility_panel.gd # WCAG compliance controls
├── help_overlay.gd        # Contextual help system
└── performance_hud.gd     # Constitutional compliance monitoring
```

## Core UI Components

### 1. Dashboard (`ui/scenes/dashboard/Dashboard.tscn`)

Campaign management hub with real-time metrics and educational explanations.

#### Key Features
- **Poll Tracking**: Current standings with trend analysis
- **Resource Management**: Campaign funds and time remaining
- **Action Planning**: Available campaign activities with cost/benefit analysis
- **Daily Summary**: "What happened today" with explanatory content

#### Accessibility Features
```gd
# Dashboard.gd implementation highlights
func _setup_accessibility():
    # Screen reader support
    poll_percentage_label.set("accessible_name", "Current polling percentage")
    poll_percentage_label.set("accessible_description", "Your party's support level based on recent surveys")

    # High contrast theme support
    if AccessibilityManager.is_high_contrast_enabled():
        _apply_high_contrast_styling()

    # Keyboard navigation
    _setup_focus_chain([rally_button, advertisement_button, interview_button])

func _update_poll_display(new_percentage: float):
    # Visual update
    poll_percentage_label.text = "%.1f%%" % new_percentage

    # Accessibility announcement for significant changes
    var change = new_percentage - _last_poll_percentage
    if abs(change) > 1.0:
        AccessibilityManager.announce("Poll changed by %.1f percent" % change)

    # Educational tooltip
    _setup_educational_tooltip(poll_percentage_label, "poll_explanation", {
        "current": new_percentage,
        "trend": _calculate_trend(),
        "factors": _get_contributing_factors()
    })
```

#### Constitutional Compliance
- **Transparency**: All calculations explained via tooltips
- **Neutrality**: No bias toward specific political positions
- **Educational**: Clear explanations of democratic processes

### 2. MapView (`ui/scenes/map_view/MapView.tscn`)

Interactive Netherlands map with demographic and political data visualization.

#### Geographic Features
- **Province Visualization**: 12 Dutch provinces with accurate boundaries
- **Data Overlays**: Party support, issue salience, turnout, demographics
- **Interactive Tooltips**: Population, key issues, voting patterns
- **Accessibility Labels**: Province names and data readings

#### Implementation
```gd
# MapView.gd core functionality
extends Control
class_name MapView

@export var hover_highlight_color: Color = Color(1.0, 1.0, 0.0, 0.3)
@export var selected_region_color: Color = Color(0.0, 1.0, 0.0, 0.5)

var region_areas: Dictionary = {}  # region_id -> Area2D
var current_filter: String = "party_support"
var current_filter_value: String = "player_party"

func _ready():
    _setup_region_areas()
    _setup_accessibility_features()
    _connect_region_signals()

func _setup_region_areas():
    # Create interactive areas for each Dutch province
    var provinces = ["noord-holland", "zuid-holland", "utrecht", "noord-brabant",
                    "gelderland", "overijssel", "limburg", "groningen",
                    "friesland", "drenthe", "flevoland", "zeeland"]

    for province in provinces:
        var area = _create_province_area(province)
        region_areas[province] = area
        add_child(area)

func _on_region_hover_entered(region_id: String):
    # Visual feedback
    _highlight_region(region_id, true)

    # Get data for tooltip
    var tooltip_data = simulation_api.get_region_tooltip_data(region_id, current_state)
    var formatted_content = _format_region_tooltip(tooltip_data)

    # Show educational tooltip
    EventBus.publish_tooltip_request(region_areas[region_id], formatted_content)

    # Accessibility support
    AccessibilityManager.announce("Entered region: %s" % region_id.replace("-", " ").capitalize())

func update_map_visualization(filter_type: String, filter_value: String):
    current_filter = filter_type
    current_filter_value = filter_value

    # Get regional data from simulation
    var regional_data = simulation_api.get_regional_data(filter_type, filter_value, current_state)

    # Update visual representation
    for region_id in regional_data:
        var intensity = regional_data[region_id]
        _update_region_color(region_id, intensity)

    # Update legend and accessibility
    _update_map_legend(filter_type, filter_value)
    _update_accessibility_descriptions(filter_type, regional_data)
```

#### Accessibility Implementation
- **Keyboard Navigation**: Arrow keys navigate between regions
- **Screen Reader**: Region names and data values announced
- **Color Independence**: Patterns and textures supplement color coding
- **High Contrast**: Alternative visual modes for visual impairments

### 3. CoalitionBuilder (`ui/scenes/coalition_builder/CoalitionBuilder.tscn`)

Drag-and-drop interface for exploring coalition possibilities with real-time validation.

#### Core Mechanics
- **Party Cards**: Draggable cards with party information
- **Coalition Area**: Drop zone with seat calculation
- **Compatibility Matrix**: Real-time feasibility analysis
- **Educational Feedback**: Explanations of coalition requirements

```gd
# CoalitionBuilder.gd key implementation
extends Control
class_name CoalitionBuilderView

const MIN_MAJORITY_SEATS = 76
const TOTAL_SEATS = 150

var available_parties: Array[DataModels.Party] = []
var selected_parties: Array[String] = []
var drag_preview: Control = null

func _setup_party_cards():
    for party in available_parties:
        var card = _create_party_card(party)
        party_grid.add_child(card)

        # Accessibility setup
        card.set("accessible_name", "%s - %d seats, %s ideology" % [
            party.display_name,
            party.seat_count,
            _describe_ideology(party.ideology_position)
        ])

func _create_party_card(party: DataModels.Party) -> Control:
    var card = preload("res://ui/scenes/coalition_builder/PartyCard.tscn").instantiate()

    # Visual setup
    card.party_name_label.text = party.display_name
    card.seat_count_label.text = "%d seats" % party.seat_count
    card.color_indicator.color = party.color

    # Drag functionality
    card.gui_input.connect(_on_party_card_input.bind(party.party_id))

    # Accessibility
    card.focus_mode = Control.FOCUS_ALL
    card.focus_entered.connect(_on_card_focus_entered.bind(party))

    return card

func _on_party_card_drag_started(party_id: String):
    var party = _get_party_by_id(party_id)

    # Create drag preview
    drag_preview = _create_drag_preview(party)
    get_viewport().add_child(drag_preview)

    # Accessibility announcement
    AccessibilityManager.announce("Dragging %s with %d seats" % [party.display_name, party.seat_count])

func _validate_coalition_composition():
    if selected_parties.is_empty():
        return

    # Get validation from simulation
    var validation = simulation_api.validate_coalition(selected_parties, current_state)

    # Update UI feedback
    _update_coalition_display(validation)

    # Educational explanation
    _show_coalition_explanation(validation)

func _update_coalition_display(validation: DataModels.CoalitionValidation):
    # Seat count display
    seat_counter_label.text = "%d / %d seats" % [validation.total_seats, TOTAL_SEATS]

    # Majority status
    if validation.has_majority:
        majority_indicator.text = "✓ Majority Achieved"
        majority_indicator.modulate = Color.GREEN
    else:
        var needed = MIN_MAJORITY_SEATS - validation.total_seats
        majority_indicator.text = "Need %d more seats" % needed
        majority_indicator.modulate = Color.ORANGE

    # Stability prediction
    stability_bar.value = validation.stability_score
    stability_explanation.text = _format_stability_explanation(validation)
```

#### Educational Features
- **Real-time Validation**: Immediate feedback on coalition viability
- **Compatibility Explanations**: Why parties do/don't work together
- **Historical Context**: References to actual Dutch coalition patterns
- **Process Education**: Explanation of coalition formation procedures

### 4. MediaEvent (`ui/scenes/media_events/MediaEvent.tscn`)

Interactive media appearances with audience feedback and educational outcomes.

#### Event Types
- **TV Interviews**: High-reach, moderate risk interactions
- **Radio Interviews**: Medium-reach, lower risk format
- **Debates**: Multi-party, high-stakes exchanges
- **Press Conferences**: Controlled messaging opportunities

```gd
# MediaEvent.gd implementation
extends Control
class_name MediaEventView

var current_event: DataModels.MediaEvent
var current_question: DataModels.MediaQuestion
var response_options: Array[DataModels.ResponseOption] = []
var audience_sentiment: float = 0.0

func start_media_event(event: DataModels.MediaEvent):
    current_event = event

    # Setup event context
    event_title_label.text = event.title
    audience_size_label.text = "Audience: %s viewers" % _format_number(event.audience_reach)

    # Initialize sentiment meter
    _setup_sentiment_meter()

    # Present first question
    _present_question(event.questions[0])

func _present_question(question: DataModels.MediaQuestion):
    current_question = question

    # Display question
    question_text_label.text = question.question_text

    # Setup response options
    response_options = question.response_options
    _create_response_buttons()

    # Accessibility
    AccessibilityManager.announce("Question: " + question.question_text)

    # Start response timer if applicable
    if question.time_limit > 0:
        _start_response_timer(question.time_limit)

func _create_response_buttons():
    # Clear existing buttons
    for child in response_container.get_children():
        child.queue_free()

    for i in range(response_options.size()):
        var option = response_options[i]
        var button = Button.new()

        # Button setup
        button.text = option.option_text
        button.pressed.connect(_on_response_selected.bind(i))

        # Risk/tone indicators
        var risk_indicator = _create_risk_indicator(option.risk_level)
        var tone_label = Label.new()
        tone_label.text = "(%s approach)" % option.tone

        # Accessibility
        button.set("accessible_name", "Response option: %s. %s approach, %s risk" % [
            option.option_text,
            option.tone,
            _describe_risk_level(option.risk_level)
        ])

        # Layout
        var container = HBoxContainer.new()
        container.add_child(button)
        container.add_child(risk_indicator)
        container.add_child(tone_label)

        response_container.add_child(container)

func _on_response_selected(option_index: int):
    var selected_option = response_options[option_index]

    # Process response through simulation
    var response_result = simulation_api.process_media_response(
        selected_option, current_question, current_state
    )

    # Show immediate audience reaction
    _animate_audience_reaction(response_result.sentiment_change)

    # Update running totals
    audience_sentiment += response_result.sentiment_change

    # Educational feedback
    _show_response_analysis(selected_option, response_result)

    # Continue or conclude event
    _advance_to_next_question()

func _show_response_analysis(option: DataModels.ResponseOption, result: DataModels.MediaResponse):
    var analysis_text = "Your %s response:\n" % option.tone
    analysis_text += "Audience reaction: %s\n" % _describe_sentiment(result.sentiment_change)
    analysis_text += "Explanation: %s\n" % result.explanation

    # Show in analysis panel
    analysis_panel.show_analysis(analysis_text)

    # Accessibility announcement
    AccessibilityManager.announce("Response received %s audience reaction" % _describe_sentiment(result.sentiment_change))
```

#### Accessibility Features
- **Response Reading**: Options read aloud with context
- **Sentiment Description**: Numerical values converted to descriptive text
- **Timer Announcements**: Remaining time communicated clearly
- **Result Explanation**: Detailed outcome descriptions

### 5. ParliamentView (`ui/scenes/parliament/ParliamentView.tscn`)

Legislative process visualization with voting mechanics and educational content.

#### Parliament Features
- **Hemicycle Layout**: Authentic Dutch parliament seating arrangement
- **Party Positions**: Visual representation of party stances on legislation
- **Live Voting**: Real-time vote counting with explanations
- **Procedure Education**: Step-by-step legislative process explanation

```gd
# ParliamentView.gd core functionality
extends Control
class_name ParliamentView

const TOTAL_SEATS = 150
var current_legislation: DataModels.Legislation
var vote_animations_playing: bool = false

func _setup_parliament_layout():
    # Create hemicycle seating arrangement
    var parties = GameStateManager.get_current_state().parties
    var seat_assignments = _calculate_seat_positions(parties)

    for party in parties:
        var seats = seat_assignments[party.party_id]
        for seat_position in seats:
            var seat = _create_parliament_seat(party, seat_position)
            parliament_container.add_child(seat)

func present_legislation(legislation: DataModels.Legislation):
    current_legislation = legislation

    # Display legislation details
    bill_title_label.text = legislation.title
    bill_description_text.text = legislation.description
    sponsor_label.text = "Sponsored by: %s" % _get_party_display_name(legislation.sponsor_party)

    # Show predicted party positions
    _display_party_positions(legislation.support_level)

    # Educational content
    _setup_legislative_explanation(legislation)

    # Accessibility
    AccessibilityManager.announce("New legislation: %s" % legislation.title)

func _display_party_positions(support_levels: Dictionary):
    for party_id in support_levels:
        var position = support_levels[party_id]
        var party_seats = _get_party_seats(party_id)

        # Color code seats based on position
        var color = _get_position_color(position)
        for seat in party_seats:
            seat.modulate = color

        # Update party position display
        _update_party_position_indicator(party_id, position)

func start_parliamentary_vote():
    vote_animations_playing = true

    # Calculate vote outcome
    var vote_result = simulation_api.calculate_voting_outcome(current_legislation, current_state)

    # Animate voting process
    _animate_vote_counting(vote_result)

    # Educational narration
    _provide_vote_explanation(vote_result)

func _animate_vote_counting(result: DataModels.VotingResult):
    # Animate seat colors changing as votes are "cast"
    var vote_sequence = _create_vote_animation_sequence(result)

    for vote_step in vote_sequence:
        # Update seat colors
        _update_seat_colors_for_vote(vote_step.party_id, vote_step.vote_type)

        # Update running totals
        _update_vote_tally_display(vote_step.running_totals)

        # Accessibility updates
        if vote_step.announce:
            AccessibilityManager.announce("%s votes %s" % [
                vote_step.party_display_name,
                vote_step.vote_type
            ])

        # Wait for animation
        await get_tree().create_timer(0.5).timeout

func _show_vote_results(result: DataModels.VotingResult):
    # Final tally display
    votes_for_label.text = "For: %d" % result.votes_for
    votes_against_label.text = "Against: %d" % result.votes_against
    abstentions_label.text = "Abstentions: %d" % result.abstentions

    # Result announcement
    if result.legislation_passed:
        result_label.text = "✓ LEGISLATION PASSED"
        result_label.modulate = Color.GREEN
    else:
        result_label.text = "✗ LEGISLATION FAILED"
        result_label.modulate = Color.RED

    # Educational explanation
    _show_vote_analysis(result)

    # Accessibility
    var result_text = "Legislation %s with %d votes for, %d against" % [
        "passed" if result.legislation_passed else "failed",
        result.votes_for,
        result.votes_against
    ]
    AccessibilityManager.announce(result_text)
```

## Shared UI Systems

### 1. Tooltip System (`ui/scenes/shared_components/tooltip_manager.gd`)

Educational tooltip system providing explanations for all game mechanics.

```gd
# TooltipManager.gd
extends Node
class_name TooltipManager

var current_tooltip: Control = null
var tooltip_delay: float = 0.5
var tooltip_timer: Timer

func show_educational_tooltip(target: Control, content_key: String, context: Dictionary = {}):
    # Get educational content
    var content = _generate_educational_content(content_key, context)

    # Create tooltip
    var tooltip = ObjectPool.get_pooled_tooltip()
    tooltip.setup(target, content)

    # Position appropriately
    var position = _calculate_tooltip_position(target, tooltip)
    tooltip.global_position = position

    # Show with animation
    tooltip.modulate.a = 0.0
    get_viewport().add_child(tooltip)

    var tween = create_tween()
    tween.tween_property(tooltip, "modulate:a", 1.0, 0.3)

    # Accessibility support
    if AccessibilityManager.is_screen_reader_enabled():
        AccessibilityManager.announce(tooltip.get_text_content())

    current_tooltip = tooltip

func _generate_educational_content(content_key: String, context: Dictionary) -> String:
    match content_key:
        "poll_explanation":
            return _format_poll_explanation(context)
        "coalition_compatibility":
            return _format_coalition_explanation(context)
        "campaign_cost":
            return _format_cost_explanation(context)
        "voting_outcome":
            return _format_voting_explanation(context)
        _:
            return "No explanation available for: " + content_key

func _format_poll_explanation(context: Dictionary) -> String:
    var current = context.get("current", 0.0)
    var trend = context.get("trend", "stable")
    var factors = context.get("factors", [])

    var explanation = "Current Polling: %.1f%%\n\n" % current
    explanation += "Trend: %s\n\n" % trend.capitalize()

    if factors.size() > 0:
        explanation += "Contributing Factors:\n"
        for factor in factors:
            explanation += "• %s\n" % factor

    explanation += "\n📚 About Polling: Opinion polls measure voter intentions through representative samples. "
    explanation += "The margin of error indicates statistical uncertainty in the results."

    return explanation
```

### 2. Notification System (`ui/scenes/shared_components/notification_system.gd`)

Non-blocking feedback system for user actions and game events.

```gd
# NotificationSystem.gd
extends Control
class_name NotificationSystem

const MAX_NOTIFICATIONS = 5
var active_notifications: Array[Control] = []

func show_notification(message: String, type: String = "info", duration: float = 5.0):
    # Create notification
    var notification = _create_notification(message, type)

    # Position in stack
    var position = _calculate_notification_position()
    notification.position = position

    # Add to scene
    add_child(notification)
    active_notifications.append(notification)

    # Auto-dismiss timer
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = true
    timer.timeout.connect(_dismiss_notification.bind(notification))
    notification.add_child(timer)
    timer.start()

    # Manage stack size
    _enforce_notification_limit()

    # Accessibility
    if type in ["error", "warning", "success"]:
        AccessibilityManager.announce("%s: %s" % [type.capitalize(), message])

func _create_notification(message: String, type: String) -> Control:
    var notification = preload("res://ui/scenes/shared_components/NotificationToast.tscn").instantiate()

    # Setup content
    notification.message_label.text = message
    notification.type_indicator.texture = _get_type_icon(type)
    notification.background.color = _get_type_color(type)

    # Dismiss button
    notification.dismiss_button.pressed.connect(_dismiss_notification.bind(notification))

    # Accessibility
    notification.set("accessible_name", "%s notification: %s" % [type.capitalize(), message])

    return notification
```

### 3. Accessibility Panel (`ui/scenes/shared_components/accessibility_panel.gd`)

WCAG 2.1 AA compliance controls integrated throughout the application.

```gd
# AccessibilityPanel.gd
extends Control
class_name AccessibilityPanel

var accessibility_settings: Dictionary = {}

func _ready():
    _load_accessibility_preferences()
    _setup_accessibility_controls()
    _connect_accessibility_signals()

func _setup_accessibility_controls():
    # Text scaling
    text_scale_slider.min_value = 0.75
    text_scale_slider.max_value = 2.0
    text_scale_slider.step = 0.25
    text_scale_slider.value = accessibility_settings.get("text_scale", 1.0)

    # High contrast toggle
    high_contrast_checkbox.button_pressed = accessibility_settings.get("high_contrast", false)

    # Screen reader support
    screen_reader_checkbox.button_pressed = accessibility_settings.get("screen_reader", false)

    # Keyboard navigation help
    keyboard_help_button.pressed.connect(_show_keyboard_shortcuts)

func _on_text_scale_changed(new_scale: float):
    accessibility_settings["text_scale"] = new_scale
    AccessibilityManager.set_text_scale(new_scale)
    _save_accessibility_preferences()

func _on_high_contrast_toggled(enabled: bool):
    accessibility_settings["high_contrast"] = enabled
    AccessibilityManager.set_high_contrast_enabled(enabled)
    _save_accessibility_preferences()

func _show_keyboard_shortcuts():
    var shortcuts_text = """
    Keyboard Shortcuts:

    General Navigation:
    • Tab / Shift+Tab: Navigate between elements
    • Enter / Space: Activate buttons
    • Escape: Close dialogs
    • F1: Context-sensitive help

    Campaign Dashboard:
    • 1-4: Select campaign action types
    • Ctrl+S: Quick save game

    Map View:
    • Arrow Keys: Navigate between regions
    • Space: Select/deselect region
    • M: Change map filter

    Coalition Builder:
    • Tab: Navigate party cards
    • Space: Add/remove from coalition
    • Enter: Confirm coalition

    Media Events:
    • 1-4: Select response options
    • Space: Repeat question
    """

    var dialog = AcceptDialog.new()
    dialog.title = "Keyboard Shortcuts"
    dialog.dialog_text = shortcuts_text
    get_viewport().add_child(dialog)
    dialog.popup_centered()

    # Accessibility
    AccessibilityManager.announce("Keyboard shortcuts dialog opened")
```

## Theme System and Styling

### 1. Default Theme (`ui/themes/default_theme.tres`)

Base theme with educational styling and constitutional compliance colors.

### 2. Accessibility Themes (`ui/themes/accessibility_themes/`)

WCAG 2.1 AA compliant themes for various visual needs:

- **High Contrast Theme**: Enhanced contrast ratios for low vision
- **Colorblind Friendly Theme**: Distinguishable colors for color vision deficiency
- **Large Text Theme**: Increased font sizes and spacing
- **Motion Reduced Theme**: Minimal animations for vestibular sensitivities

### 3. Dynamic Theme Application

```gd
# Theme management system
func apply_accessibility_theme(theme_name: String):
    var theme_path = "res://ui/themes/accessibility_themes/%s_theme.tres" % theme_name

    if ResourceLoader.exists(theme_path):
        var accessibility_theme = load(theme_path) as Theme

        # Apply to all relevant nodes
        _apply_theme_recursively(get_tree().root, accessibility_theme)

        # Update theme-dependent elements
        _update_color_dependent_elements(accessibility_theme)

        # Notify components of theme change
        EventBus.publish_theme_changed(theme_name)

func _apply_theme_recursively(node: Node, theme: Theme):
    if node is Control:
        var control = node as Control
        if control.theme == null:  # Don't override custom themes
            control.theme = theme

    for child in node.get_children():
        _apply_theme_recursively(child, theme)
```

## Performance Optimization

### 1. Object Pooling Integration

All frequently created UI elements use object pooling:

```gd
# Tooltip pooling
var tooltip_pool: Array[Control] = []
var max_tooltips: int = 10

func get_pooled_tooltip() -> Control:
    if tooltip_pool.is_empty():
        return _create_new_tooltip()

    return tooltip_pool.pop_back()

func return_pooled_tooltip(tooltip: Control):
    tooltip.hide()
    tooltip.reset()

    if tooltip_pool.size() < max_tooltips:
        tooltip_pool.append(tooltip)
    else:
        tooltip.queue_free()
```

### 2. Lazy Loading

Expensive UI elements load on demand:

```gd
# Coalition compatibility matrix lazy loading
var compatibility_cache: Dictionary = {}

func _on_party_combination_requested(party_a: String, party_b: String):
    var cache_key = "%s_%s" % [party_a, party_b]

    if not compatibility_cache.has(cache_key):
        var compatibility = simulation_api.calculate_coalition_compatibility(
            party_a, party_b, current_state
        )
        compatibility_cache[cache_key] = compatibility

    return compatibility_cache[cache_key]
```

### 3. Constitutional Performance Monitoring

Built-in monitoring ensures constitutional 60 FPS requirement:

```gd
func _process(_delta):
    # Monitor frame rate
    var fps = Engine.get_frames_per_second()
    if fps < 60:
        PerformanceMonitor.report_fps_violation(fps)

    # Monitor response time
    if Input.is_anything_pressed():
        _start_response_timer()

func _on_ui_interaction_complete():
    var response_time = _end_response_timer()
    if response_time > 100:  # >100ms violates constitutional requirement
        PerformanceMonitor.report_response_violation(response_time)
```

## Testing UI Components

### 1. Accessibility Testing

```gd
# Automated accessibility validation
func test_component_accessibility(component: Control):
    # Check focus navigation
    var focusable_nodes = _get_focusable_nodes(component)
    for node in focusable_nodes:
        assert_true(_has_accessible_name(node), "Missing accessible name: " + str(node))
        assert_true(_has_valid_focus_neighbors(node), "Invalid focus chain: " + str(node))

    # Check color contrast
    _verify_color_contrast_ratios(component)

    # Check text scaling
    _test_text_scaling_compatibility(component)

func test_keyboard_navigation(component: Control):
    # Simulate tab navigation through component
    var focusable_order = _get_focus_order(component)

    for i in range(focusable_order.size() - 1):
        var current = focusable_order[i]
        var expected_next = focusable_order[i + 1]

        current.grab_focus()
        _simulate_tab_key()

        var actual_next = component.get_viewport().gui_get_focus_owner()
        assert_eq(actual_next, expected_next, "Focus order incorrect")
```

### 2. Performance Testing

```gd
# UI performance validation
func test_component_performance(component: Control):
    var start_time = Time.get_ticks_usec()

    # Simulate user interactions
    _simulate_heavy_interaction(component)

    var end_time = Time.get_ticks_usec()
    var duration_ms = (end_time - start_time) / 1000.0

    # Constitutional compliance check
    assert_lt(duration_ms, 16.67, "UI interaction exceeded 60 FPS requirement")

func test_memory_usage(component: Control):
    var initial_memory = OS.get_static_memory_usage()

    # Create and destroy component multiple times
    for i in range(100):
        var instance = component.duplicate()
        add_child(instance)
        instance.queue_free()

    # Force garbage collection
    get_tree().process_frame.emit()

    var final_memory = OS.get_static_memory_usage()
    var memory_increase = final_memory - initial_memory

    # Should not have significant memory leaks
    assert_lt(memory_increase, 1000000, "Memory leak detected")  # 1MB threshold
```

## Best Practices Summary

### UI Development Guidelines

**Constitutional Compliance:**
- ✅ Maintain 60 FPS performance in all interactions
- ✅ Provide educational explanations for all game mechanics
- ✅ Ensure political neutrality in visual design
- ✅ Support transparency through clear information display

**Accessibility Standards:**
- ✅ Follow WCAG 2.1 AA guidelines consistently
- ✅ Provide keyboard navigation for all functionality
- ✅ Include screen reader support with descriptive labels
- ✅ Support text scaling from 75% to 200%
- ✅ Use color-independent design patterns

**Performance Requirements:**
- ✅ Use object pooling for frequently created elements
- ✅ Implement lazy loading for expensive operations
- ✅ Monitor and report performance violations
- ✅ Optimize for target resolution range (1280×720 to 1920×1080)

**Code Quality:**
- ✅ Separate UI logic from business logic
- ✅ Use EventBus for loose coupling
- ✅ Implement proper cleanup in _exit_tree()
- ✅ Follow consistent naming and styling conventions

---

*For technical implementation details, see [Developer Guide](developer-guide.md) and [Integration Guide](integration-guide.md).*