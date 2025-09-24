# Research: Dutch Politics Simulation UI

## Godot 4 Control Node Architecture

**Decision**: Use Container-based layouts with Control nodes for all UI screens
**Rationale**:
- Built-in anchor/margin system handles responsive layouts across resolution range (1280×720 to 1920×1080)
- Control nodes provide automatic focus management for keyboard navigation
- Theme system enables consistent styling and accessibility adjustments
**Alternatives considered**:
- Custom rendering with CanvasItem: Rejected due to accessibility overhead and no built-in keyboard navigation
- Node2D-based UI: Rejected due to lack of built-in layout management

## Localization Architecture

**Decision**: Godot TranslationServer with CSV-based translation files
**Rationale**:
- Native support for Dutch/English switching at runtime
- CSV format allows easy editing by non-programmers
- tr() function integration with Control nodes provides seamless text replacement
**Implementation details**:
- `localization/strings_en.csv` and `localization/strings_nl.csv`
- Keys use dot notation: `dashboard.poll_percentage`, `coalition.seats_needed`
- Pluralization support for dynamic content (seat counts, vote totals)

## Accessibility Compliance (WCAG 2.1 AA)

**Decision**: Theme-based accessibility with runtime switching
**Rationale**:
- Godot Theme resources support color overrides for contrast compliance
- Font size scaling through Theme.default_font_size property
- Built-in Control focus indicators for keyboard navigation
**Implementation approach**:
- Base theme meets AA contrast requirements (4.5:1 minimum)
- High contrast theme option for enhanced accessibility
- Text scaling from 75% to 200% through Theme.default_font_size
- Alternative indicators (icons + color) for color-blind users

## Performance Optimization Strategy

**Decision**: Scene instancing with object pooling for dynamic elements
**Rationale**:
- 60 FPS target requires efficient UI element management
- Party cards, tooltip popups, and notification toasts benefit from pooling
- Scene preloading prevents stutters during screen transitions
**Key techniques**:
- Pool tooltip instances rather than create/destroy
- Use CanvasLayer for modal overlays to reduce draw calls
- Batch updates to avoid multiple redraws per frame

## JSON Schema Design

**Decision**: Strict JSON schemas with validation for configuration and saves
**Rationale**:
- Constitutional requirement for data-driven configuration
- JSON format enables human editing and modding support
- Schema validation prevents corruption and provides clear error messages
**Schema structure**:
```
config/
├── parties.json         # Party definitions with ideology positions
├── policies.json        # Policy topics and stance options
├── scenarios.json       # Pre-defined election scenarios
├── game_balance.json    # Tunable parameters for simulation
└── localization/
    ├── strings_en.csv
    └── strings_nl.csv
```

## Seeded RNG Implementation

**Decision**: Single RandomNumberGenerator instance with predictable seed management
**Rationale**:
- Constitutional requirement for deterministic simulation
- All probability calculations use same seeded generator
- Save files include RNG seed for exact replay capability
**Implementation**:
- Singleton SimulationRNG class manages seed state
- UI displays current seed for user verification
- Debug mode allows manual seed input

## Drag-and-Drop Architecture

**Decision**: Custom drag-and-drop using Control node input events
**Rationale**:
- Coalition builder requires smooth party card dragging
- Godot's built-in drag-and-drop limited for complex UI interactions
- Custom implementation provides fine control over visual feedback
**Implementation pattern**:
- DragHandler component manages mouse/touch state
- Visual feedback through duplicate Control node overlay
- Drop zones use Area2D for collision detection

## Tooltip and Modal System

**Decision**: Centralized tooltip manager with pooled instances
**Rationale**:
- Constitutional requirement for explanatory tooltips on all metrics
- Consistent positioning and styling across all UI elements
- Performance optimization through instance reuse
**Features**:
- Automatic positioning to avoid screen edges
- Rich content support (text + icons + small charts)
- Keyboard-triggered tooltips for accessibility
- "Why?" panel for detailed explanations

## Input Mapping Strategy

**Decision**: InputMap with customizable key bindings
**Rationale**:
- Accessibility requires alternative input methods
- Dutch/international keyboard layout compatibility
- User customization improves accessibility
**Key mappings**:
- Tab/Shift+Tab for focus navigation
- Enter/Space for activation
- Escape for modal dismissal
- F1 for context help/tooltips
- Arrow keys for map navigation

## State Management Architecture

**Decision**: Centralized state with event-driven updates
**Rationale**:
- Complex UI requires coordinated updates between screens
- Undo functionality requires state snapshots
- Clear separation between UI state and simulation state
**Implementation**:
- GameState singleton maintains current game status
- UIState manages screen-specific display options
- Event bus for loose coupling between systems