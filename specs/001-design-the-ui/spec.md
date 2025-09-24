# Feature Specification: Dutch Politics Simulation UI

**Feature Branch**: `001-design-the-ui`
**Created**: 2025-09-24
**Status**: Draft
**Input**: User description: "Design the UI for a Dutch politics simulation game (Godot 4 project already set). Focus on WHAT the player sees/does; avoid implementation details."

## Clarifications

### Session 2025-09-24
- Q: Which specific KPIs should be prominently displayed on Campaign Dashboard? → A: Poll %, Projected Seats, Funds, Days Left
- Q: What map filtering capabilities should be provided for the Netherlands map? → A: Party support, Issue salience, Voter turnout, Demographics
- Q: What are the essential interface elements for media event screens? → A: Question text, response buttons, sentiment meter, audience reach indicator
- Q: What data should coalition builder tooltips display during drag operations? → A: Party name, seats, ideology, red lines, compatibility score
- Q: Should the coalition majority requirement be corrected? → A: Yes. 150 seats total, 76 for majority

## User Scenarios & Testing

### Primary User Story
As a player learning about Dutch politics, I navigate through a comprehensive simulation where I can manage political campaigns, understand voting mechanics, form coalitions, and see the direct consequences of my decisions. Every interaction provides clear visual feedback and explanations so I understand both what happened and why it happened.

### Acceptance Scenarios
1. **Given** I start a new game, **When** I reach the Campaign Dashboard, **Then** I see current poll percentages, projected seats, and a clear "what changed today" summary with explanatory tooltips available for each metric
2. **Given** I'm viewing the Netherlands map, **When** I hover over any province, **Then** I see a tooltip showing support levels, key issues, and voter sentiment for that region
3. **Given** I'm in a TV interview, **When** I select a response option, **Then** I see immediate visual feedback on audience sentiment and receive a post-interview summary showing poll changes with explanations
4. **Given** I'm building a coalition, **When** I drag party cards together, **Then** I see real-time feasibility updates, policy conflicts highlighted, and seat count calculations toward the 76-seat majority from 150 total seats
5. **Given** I'm watching a parliamentary vote, **When** the voting concludes, **Then** I see the final tally, understand why each party voted as they did, and learn the legislation's effects

### Edge Cases
- What happens when I try to form an impossible coalition (conflicting red lines)?
- How does the system handle when I have insufficient funds for a campaign action?
- What feedback do I receive when accessing features before meeting prerequisites (e.g., coalition building before election)?

## Requirements

### Functional Requirements
- **FR-001**: System MUST provide a main menu with options for New Game, Continue, Scenarios, Settings, and Credits
- **FR-002**: System MUST display a Campaign Dashboard showing poll percentage, projected seats, funds, and days left with daily change summaries
- **FR-003**: System MUST provide explanatory tooltips for every displayed number, calculation, and game mechanic outcome
- **FR-004**: System MUST show a Netherlands map with visual heatmaps filterable by party support, issue salience, voter turnout, and demographics by province/municipality
- **FR-005**: System MUST support interactive media events (interviews, debates) displaying question text, response buttons, sentiment meter, and audience reach indicator with real-time feedback
- **FR-006**: System MUST provide a social media console where players compose posts and see reach/virality predictions and reactions
- **FR-007**: System MUST enable coalition building through drag-and-drop party cards with tooltips showing party name, seats, ideology, red lines, and compatibility score with real-time feasibility calculation toward 76-seat majority from 150 total seats
- **FR-008**: System MUST simulate parliamentary voting with whip lines, live vote tallies, and outcome explanations
- **FR-009**: System MUST display election results with seat distribution maps and detailed "why you won/lost" analysis
- **FR-010**: System MUST support full Dutch and English localization with scalable text (75%-200%)
- **FR-011**: System MUST provide accessibility features including keyboard navigation, color-blind friendly themes, and screen reader compatibility
- **FR-012**: System MUST maintain 60 FPS performance and sub-100ms response times on 1280×720 to 1920×1080 displays
- **FR-013**: System MUST provide persistent top navigation between main screens (Dashboard, Map, Media, Debate, Coalition, Parliament, Social)
- **FR-014**: System MUST show non-blocking notification toasts for minor changes and modal recap screens after major actions
- **FR-015**: System MUST support undo functionality for safe actions and confirmation dialogs for irreversible decisions

### Key Entities
- **Player/Party**: The political entity being managed, with attributes like name, ideology, resources, reputation, and current poll standing
- **Campaign Action**: Time-limited activities like rallies, advertisements, interviews, and social media posts that affect various metrics
- **Opinion Poll**: Regular measurement of voter sentiment with breakdowns by demographic, region, and issue
- **Election**: The culminating event with vote calculation, seat distribution using D'Hondt method, and coalition possibilities
- **Coalition**: Multi-party governing arrangement with shared policy agreements, ministry allocations, and stability metrics
- **Legislation**: Parliamentary bills with committee stages, party positions, voting records, and policy effects
- **Media Event**: Structured interactions (interviews, debates) with audience reach, sentiment tracking, and outcome effects
- **Geographic Region**: Dutch provinces and municipalities with unique voter profiles, key issues, and turnout patterns
- **Game State**: Overall simulation status including current date, active events, unlocked features, and save metadata

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed