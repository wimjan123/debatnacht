# Tasks: Dutch Politics Simulation UI

**Input**: Design documents from `/specs/001-design-the-ui/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Godot project**: `ui/`, `presentation/`, `core_api/`, `stubs/`, `config/`, `tests/` at repository root
- Paths follow modular architecture from plan.md

## Phase 3.1: Setup
- [X] T001 Create Godot project structure with directories: ui/, presentation/, core_api/, stubs/, config/, tests/
- [X] T002 Initialize Godot 4.2+ project with Control-based UI configuration and localization settings
- [X] T003 [P] Configure project settings: main scene, localization (Dutch/English), input mapping for accessibility
- [X] T004 [P] Create base theme file ui/themes/default_theme.tres with WCAG 2.1 AA compliant colors and fonts
- [X] T005 [P] Create high contrast accessibility theme ui/themes/accessibility_themes/high_contrast_theme.tres

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests
- [X] T006 [P] Contract test for SimulationAPI interface compliance in tests/unit/test_simulation_api_contract.gd
- [X] T007 [P] Contract test for UI component interfaces in tests/unit/test_ui_contracts.gd
- [X] T008 [P] Contract test for data model validation rules in tests/unit/test_data_models.gd

### Integration Tests from User Stories
- [X] T009 [P] Integration test: Dashboard KPI display and tooltip explanations in tests/integration/test_dashboard_flow.gd
- [X] T010 [P] Integration test: Map visualization with region filtering in tests/integration/test_map_interaction.gd
- [X] T011 [P] Integration test: Media event response processing in tests/integration/test_media_events.gd
- [X] T012 [P] Integration test: Coalition builder drag-and-drop validation in tests/integration/test_coalition_builder.gd
- [X] T013 [P] Integration test: Parliamentary voting simulation in tests/integration/test_parliamentary_voting.gd

### Accessibility and Localization Tests
- [X] T014 [P] Test Dutch/English language switching in tests/integration/test_localization.gd
- [X] T015 [P] Test keyboard navigation and focus management in tests/integration/test_accessibility.gd
- [X] T016 [P] Test text scaling and high contrast themes in tests/integration/test_theme_switching.gd

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Data Models and Core API
- [X] T017 [P] Implement GameState class in core_api/data_models.gd with state transitions and validation
- [X] T018 [P] Implement Party class in core_api/data_models.gd with ideology positioning and campaign resources
- [X] T019 [P] Implement CampaignAction class in core_api/data_models.gd with cost and effect calculations
- [X] T020 [P] Implement OpinionPoll class in core_api/data_models.gd with demographic breakdown
- [X] T021 [P] Implement GeographicRegion class in core_api/data_models.gd with voter characteristics
- [X] T022 [P] Implement MediaEvent and related classes in core_api/data_models.gd
- [X] T023 [P] Implement Coalition and PolicyAgreement classes in core_api/data_models.gd
- [X] T024 [P] Implement Legislation and Election classes in core_api/data_models.gd
- [X] T025 Create SimulationAPI interface definition in core_api/simulation_api.gd (abstract base class)

### Stub Implementation for UI Development
- [X] T026 Implement FakeSimulation class in stubs/fake_simulation.gd with seeded random data generation
- [X] T027 [P] Create sample party data in stubs/sample_data/parties.json with diverse ideological spectrum
- [X] T028 [P] Create sample geographic data in stubs/sample_data/regions.json with Dutch provinces
- [X] T029 [P] Create sample scenario configurations in stubs/sample_data/scenarios.json
- [X] T030 [P] Create test polling data with deterministic seeded outcomes in stubs/test_scenarios/

### Localization System
- [X] T031 [P] Create English translation file config/localization/strings_en.csv with all UI text
- [X] T032 [P] Create Dutch translation file config/localization/strings_nl.csv with complete translations
- [X] T033 Implement LocalizationManager in presentation/managers/localization_manager.gd for runtime language switching

## Phase 3.4: UI Scene Development

### Shared Components (Foundation)
- [X] T034 [P] Create TooltipManager component in ui/scenes/shared_components/tooltip_manager.gd with explanation panels
- [X] T035 [P] Create NotificationSystem component in ui/scenes/shared_components/notification_system.gd
- [X] T036 [P] Create AccessibilityManager in presentation/managers/accessibility_manager.gd for theme/text scaling
- [X] T037 [P] Create NavigationController in presentation/controllers/navigation_controller.gd for screen transitions

### Main Screen Scenes
- [X] T038 [P] Create MainMenu scene in ui/scenes/main_menu/MainMenu.tscn with keyboard navigation
- [X] T039 Create DashboardController in presentation/controllers/dashboard_controller.gd with KPI updates
- [X] T040 Create Dashboard scene in ui/scenes/dashboard/Dashboard.tscn connected to DashboardController
- [X] T041 Create MapViewController in presentation/controllers/map_view_controller.gd with filtering
- [X] T042 Create MapView scene in ui/scenes/map_view/MapView.tscn with Netherlands geography
- [X] T043 Create MediaEventController in presentation/controllers/media_event_controller.gd
- [X] T044 Create MediaEvent scene in ui/scenes/media_events/MediaEvent.tscn with sentiment display
- [X] T045 Create CoalitionBuilderController in presentation/controllers/coalition_builder_controller.gd
- [X] T046 Create CoalitionBuilder scene in ui/scenes/coalition_builder/CoalitionBuilder.tscn with drag-and-drop

### Additional Core Scenes
- [X] T047 [P] Create ParliamentView scene in ui/scenes/parliament/ParliamentView.tscn for voting simulation
- [X] T048 [P] Create SocialMediaConsole scene in ui/scenes/social_media/SocialMediaConsole.tscn
- [X] T049 [P] Create ElectionResults scene in ui/scenes/results/ElectionResults.tscn with analysis breakdowns
- [X] T050 [P] Create Settings scene in ui/scenes/settings/Settings.tscn with accessibility options

## Phase 3.5: State Management and Integration
- [X] T051 Create GameStateManager singleton in presentation/state_managers/game_state_manager.gd
- [X] T052 Create UIStateManager for screen-specific state in presentation/state_managers/ui_state_manager.gd
- [X] T053 Implement EventBus system in presentation/managers/event_bus.gd for loose coupling
- [X] T054 Connect simulation API to UI controllers through presentation layer
- [X] T055 Implement save/load system with JSON serialization and version validation
- [X] T056 Add undo/redo functionality for safe user actions

## Phase 3.6: Performance and Polish
- [X] T057 [P] Implement object pooling for tooltips and notifications in presentation/managers/object_pool.gd
- [X] T058 [P] Add performance monitoring to maintain 60 FPS target in presentation/managers/performance_monitor.gd
- [X] T059 [P] Optimize scene loading with preloading and scene caching in presentation/managers/scene_manager.gd
- [X] T060 [P] Create comprehensive keyboard shortcuts and input handling in presentation/managers/input_handler.gd
- [X] T061 [P] Add comprehensive logging for debugging and constitutional transparency in presentation/managers/logging_manager.gd
- [X] T062 [P] Implement seeded RNG validation and display for simulation integrity in presentation/managers/rng_validator.gd

### Final Testing and Validation
- [X] T063 [P] Create end-to-end test scenarios for complete campaign simulation in tests/integration/test_full_campaign.gd
- [X] T064 [P] Performance validation tests for 60 FPS and <100ms response time in tests/performance/test_performance_validation.gd
- [X] T065 [P] Accessibility audit tests for WCAG 2.1 AA compliance in tests/accessibility/test_accessibility_audit.gd
- [X] T066 Run complete test suite and validate all constitutional requirements in tests/test_constitutional_compliance.gd
- [X] T067 Create build scripts and deployment configuration per quickstart guide in scripts/build.sh and scripts/deploy.sh

## Dependencies
- Setup (T001-T005) before all implementation
- Contract tests (T006-T008) before any core implementation
- Integration tests (T009-T016) before UI scene development
- Data models (T017-T024) before stub implementation (T026-T030)
- Shared components (T034-T037) before main scenes (T038-T050)
- State management (T051-T053) before integration (T054-T056)
- Core implementation before performance optimization (T057-T062)

## Parallel Example
```
# Launch contract tests together (T006-T008):
Task: "Contract test for SimulationAPI interface compliance in tests/unit/test_simulation_api_contract.gd"
Task: "Contract test for UI component interfaces in tests/unit/test_ui_contracts.gd"
Task: "Contract test for data model validation rules in tests/unit/test_data_models.gd"

# Launch data model implementation together (T017-T024):
Task: "Implement GameState class in core_api/data_models.gd with state transitions and validation"
Task: "Implement Party class in core_api/data_models.gd with ideology positioning and campaign resources"
Task: "Implement CampaignAction class in core_api/data_models.gd with cost and effect calculations"
[... etc for all parallel data model tasks]

# Launch shared component development (T034-T037):
Task: "Create TooltipManager component in ui/scenes/shared_components/tooltip_manager.gd"
Task: "Create NotificationSystem component in ui/scenes/shared_components/notification_system.gd"
Task: "Create AccessibilityManager in presentation/managers/accessibility_manager.gd"
Task: "Create NavigationController in presentation/controllers/navigation_controller.gd"
```

## Notes
- [P] tasks = different files, no dependencies between them
- Verify tests fail before implementing (TDD requirement)
- All file paths are absolute to repository root
- Constitutional compliance validation built into each phase
- Each task specifies exact file location for precise implementation
- Scene files (.tscn) created in Godot editor, controllers (.gd) implemented in code