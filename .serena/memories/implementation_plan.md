# Implementation Plan Context

## Project: Dutch Politics Simulation UI (debatnacht)
**Tech Stack**: GDScript/Godot 4.2+ with Control-based UI, JSON config, localization system
**Architecture**: Modular separation - ui/, presentation/, core_api/, stubs/, config/, tests/

## Constitutional Requirements
- Simulation integrity with seeded RNG
- Transparency with explanatory tooltips  
- Political neutrality (no real figures)
- Accessibility (WCAG 2.1 AA, Dutch/English, keyboard navigation)
- Performance (60 FPS, <100ms response)
- Test-driven development
- Data-driven JSON configuration
- Versioned save system

## Directory Structure
```
ui/                      # UI scenes and themes
├── scenes/
│   ├── main_menu/
│   ├── dashboard/
│   ├── map_view/
│   ├── media_events/
│   ├── coalition_builder/
│   └── shared_components/
└── themes/
    ├── default_theme.tres
    └── accessibility_themes/

presentation/            # View-model layer
├── controllers/
├── state_managers/
└── managers/

core_api/               # Interface definitions only
├── simulation_api.gd
├── data_models.gd
└── events.gd

stubs/                  # Mock data providers
├── fake_simulation.gd
├── sample_data/
└── test_scenarios/

config/                 # JSON configuration files
├── parties.json
├── policies.json
├── scenarios.json
└── localization/

tests/
├── unit/
├── integration/
└── performance/
```

## Implementation Approach
- Phase 3.1: Setup and foundation (T001-T005)
- Phase 3.2: Tests first - TDD (T006-T016) - MUST FAIL before implementation
- Phase 3.3: Core implementation (T017-T056) - Only after tests fail
- Phase 3.4: UI scenes (overlaps with 3.3)  
- Phase 3.5: Integration (T051-T056)
- Phase 3.6: Performance and polish (T057-T067)