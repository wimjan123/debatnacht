# Project Overview

## Purpose & Mission

The Dutch Politics Simulation UI is an **educational political simulation** designed to teach users about democratic processes in the Netherlands through interactive gameplay. The project demonstrates a commitment to **constitutional compliance** with Dutch democratic principles, ensuring transparency, accessibility, and political neutrality.

## Core Educational Goals

### Democratic Process Understanding
- **Campaign Management**: Learn how political parties organize campaigns, manage resources, and engage voters
- **Coalition Formation**: Understand the Dutch multi-party system and coalition government formation
- **Parliamentary Procedure**: Experience legislative processes, voting mechanisms, and party negotiations
- **Electoral Systems**: Learn the D'Hondt proportional representation method used in Dutch elections

### Civic Engagement
- **Informed Decision Making**: Provide transparent calculations and explanations for all game mechanics
- **Policy Impact Visualization**: Show clear cause-and-effect relationships between actions and outcomes
- **Multi-perspective Learning**: Present balanced viewpoints without favoring specific political ideologies
- **Real-world Relevance**: Use authentic Dutch political structures and historical patterns

## Constitutional Compliance Framework

### Transparency Requirements
- **Open Calculations**: All algorithms and decision-making processes are explainable and auditable
- **Clear Explanations**: Every game mechanic provides tooltips and detailed "why this happened" information
- **Source Attribution**: Political data and mechanisms reference authentic Dutch parliamentary procedures
- **Version Control**: All changes to simulation logic are tracked and documented

### Accessibility Standards (WCAG 2.1 AA)
- **Screen Reader Support**: Full navigation and content access via assistive technologies
- **Keyboard Navigation**: Complete functionality without mouse/touch input
- **Visual Accessibility**: High contrast themes, scalable text (75%-200%), color-blind friendly palettes
- **Cognitive Support**: Clear information hierarchy, consistent patterns, help system integration

### Political Neutrality
- **Balanced Representation**: No party or ideology receives preferential treatment in mechanics or UI
- **Educational Focus**: Emphasizes process understanding over specific political outcomes
- **Cultural Sensitivity**: Respects Dutch political traditions while remaining accessible to international users
- **Content Review**: Regular validation against neutrality standards and educational objectives

## System Architecture

### Clean Architecture Implementation
```
┌─ Presentation Layer ─────────────────────────────┐
│  ┌─ UI Scenes ┐  ┌─ Controllers ┐  ┌─ Managers ┐ │
│  │ Dashboard  │  │ Navigation   │  │ EventBus  │ │
│  │ MapView    │  │ Media Event  │  │ StateMan  │ │
│  │ Coalition  │  │ Coalition    │  │ Audio/A11y│ │
│  └────────────┘  └──────────────┘  └───────────┘ │
├──────────────────────────────────────────────────┤
│  Integration Layer - SimulationIntegration.gd    │
├──────────────────────────────────────────────────┤
│  Core API Layer                                  │
│  ┌─ SimulationAPI Interface ┐  ┌─ Data Models ┐  │
│  │ Contract definition      │  │ Game entities│  │
│  │ Method signatures        │  │ Result types │  │
│  │ Data validation          │  │ UI state     │  │
│  └─────────────────────────┘  └──────────────┘  │
├──────────────────────────────────────────────────┤
│  Implementation Layer                            │
│  ┌─ FakeSimulation ┐  ┌─ Future: AgentAPI ┐      │
│  │ Stub data       │  │ LLM integration   │      │
│  │ Test scenarios  │  │ Dynamic content   │      │
│  │ Deterministic   │  │ Advanced AI       │      │
│  └─────────────────┘  └───────────────────┘      │
└──────────────────────────────────────────────────┘
```

### Separation of Concerns
- **Presentation Layer**: Godot scenes, UI controllers, input handling, visual feedback
- **Integration Layer**: Adapts simulation data for UI consumption, handles state synchronization
- **Core API**: Defines contracts between simulation and UI, provides data models and validation
- **Implementation Layer**: Pluggable simulation backends (currently FakeSimulation, future agent-based)

## Key Features & Capabilities

### Campaign Management Dashboard
- **Real-time Metrics**: Poll percentages, projected seats, campaign funds, days remaining
- **Activity Planning**: Rally organization, advertisement campaigns, media appearances
- **Impact Visualization**: Clear feedback on action consequences with explanatory tooltips
- **Resource Management**: Budget allocation, time planning, strategic prioritization

### Interactive Map System
- **Geographic Visualization**: Netherlands provinces with detailed demographic data
- **Multiple Views**: Party support, issue salience, voter turnout, demographic breakdowns
- **Tooltip Information**: Population, key issues, voting history, projection details
- **Filter System**: Dynamic overlays for different data perspectives

### Media Event System
- **Interview Simulation**: TV, radio, and debate participation with live audience feedback
- **Response Management**: Multiple-choice answers with risk/reward calculations
- **Sentiment Tracking**: Real-time audience reaction meters and post-event analysis
- **Impact Calculation**: Direct translation of media performance to poll changes

### Coalition Builder
- **Drag-and-Drop Interface**: Intuitive party card system for coalition exploration
- **Compatibility Scoring**: Real-time feasibility updates based on party ideologies
- **Seat Calculations**: Clear path to 76-seat majority requirement (out of 150 total)
- **Policy Conflict Resolution**: Visual highlighting of agreements and red lines

### Parliamentary Voting
- **Legislative Process**: Bill introduction, committee review, floor voting
- **Party Whip System**: Realistic voting behavior based on party positions
- **Live Tallies**: Real-time vote counting with outcome predictions
- **Impact Analysis**: Clear explanation of legislation effects on game state

### Election Results & Analysis
- **D'Hondt Simulation**: Authentic Dutch proportional representation calculation
- **Regional Breakdown**: Province-by-province results with demographic analysis
- **Coalition Scenarios**: Post-election government formation possibilities
- **Performance Review**: "Why you won/lost" analysis with campaign effectiveness metrics

## Technical Excellence Standards

### Performance Requirements
- **60 FPS Target**: Maintained across all gameplay scenarios on standard hardware
- **Response Time**: Sub-100ms UI interactions for immediate user feedback
- **Memory Efficiency**: Object pooling and resource management for extended gameplay
- **Scalability**: Support for 1280×720 to 1920×1080 displays with UI scaling

### Quality Assurance
- **Automated Testing**: Unit tests for data models, integration tests for workflows
- **Accessibility Auditing**: Regular WCAG compliance validation with assistive technology testing
- **Performance Monitoring**: Built-in performance tracking with constitutional compliance reporting
- **Constitutional Validation**: Regular review of neutrality, transparency, and educational effectiveness

### Localization & Internationalization
- **Language Support**: Full Dutch and English localization with professional translations
- **Cultural Adaptation**: Dutch political terminology with English explanations where needed
- **Text Scaling**: 75%-200% text size support for accessibility compliance
- **Regional Formats**: Date, currency, and number formatting appropriate to locale

## Future Development Roadmap

### Phase 1: Enhanced Simulation (Current)
- Complete FakeSimulation implementation with all feature coverage
- Comprehensive testing and accessibility validation
- Performance optimization and constitutional compliance audit

### Phase 2: Agent-Based Intelligence
- Integration of LLM-based political agents for dynamic content generation
- Advanced coalition negotiation with realistic party behavior simulation
- Dynamic media event generation based on current political climate

### Phase 3: Extended Features
- Historical scenario support (past Dutch elections)
- Multiplayer coalition negotiations
- Advanced analytics and performance tracking
- Custom scenario creation tools

## Success Metrics

### Educational Impact
- User comprehension of Dutch democratic processes (measured via integrated assessment)
- Engagement time and feature usage patterns indicating deep learning
- Accessibility compliance verification with real user testing

### Technical Excellence
- Performance benchmarks meeting constitutional requirements (60 FPS, sub-100ms response)
- Zero critical accessibility violations in WCAG 2.1 AA testing
- Clean architecture maintainability scores and code quality metrics

### Constitutional Compliance
- Political neutrality validation through content analysis
- Transparency verification via explainability testing
- Community feedback integration for continuous improvement

---

*For technical implementation details, see [Core Systems](core-systems.md) and [API Reference](api-reference.md)*