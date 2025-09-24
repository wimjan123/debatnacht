<!--
Sync Impact Report:
Version change: 1.0.0 → 1.0.0 (new constitution)
Modified principles: N/A (new constitution)
Added sections: All sections (new constitution)
Removed sections: N/A
Templates requiring updates:
  ✅ Updated plan-template.md reference compatibility
  ✅ Updated spec-template.md compatibility
  ✅ Updated tasks-template.md compatibility
Follow-up TODOs: None - all placeholders filled
-->

# Debatnacht Constitution

## Core Principles

### I. Simulation Integrity (NON-NEGOTIABLE)
All simulation mechanics MUST be deterministic and reproducible. Seeded random number generation MUST be used for all probabilistic calculations including polling, voter behavior, and election outcomes. Every simulation run with identical seed values MUST produce identical results. All core mathematical algorithms (D'Hondt method, coalition formation logic, polling calculations) MUST be validated through comprehensive test suites with known correct outcomes.

**Rationale**: Political simulation credibility depends on consistent, explainable results that users can trust and verify.

### II. Transparency & Explainability
Every game mechanic, decision, and outcome MUST be explainable to users. Interactive tooltips MUST provide context for all UI elements, statistics, and game states. Comprehensive logging MUST track all significant game events with clear cause-and-effect relationships. Users MUST be able to understand why specific electoral outcomes occurred and how their actions influenced results.

**Rationale**: Educational value requires users to understand political processes, not just experience them.

### III. Political Neutrality
Content MUST maintain strict political neutrality and respect for all democratic viewpoints. Real political figures, parties, or controversial policies MUST NOT be referenced directly. Game mechanics MUST fairly represent diverse political ideologies without bias. All political scenarios MUST be presented as educational tools, not advocacy for specific positions.

**Rationale**: Educational effectiveness requires objectivity and respect for democratic pluralism.

### IV. Accessibility Excellence
The game MUST support Dutch and English languages with complete localization. Visual design MUST meet WCAG 2.1 AA standards for contrast and readability. Text scaling MUST be supported from 75% to 200% without UI breakage. All interactive elements MUST be keyboard accessible. Color-blind users MUST be able to distinguish all critical game elements through alternative visual indicators.

**Rationale**: Democratic education tools must be accessible to all citizens regardless of ability or language preference.

### V. Performance Standards
The 2D UI MUST maintain 60 FPS performance on mid-range hardware (5-year-old systems). Response time for all user interactions MUST be under 100ms. Game startup time MUST be under 10 seconds. Memory usage MUST not exceed 1GB during normal gameplay. All performance targets MUST be validated through automated benchmarking.

**Rationale**: Smooth performance is essential for user engagement and educational effectiveness.

## Technical Standards

### Test-Driven Development (NON-NEGOTIABLE)
All core mathematical functions (D'Hondt calculations, polling algorithms, coalition formation) MUST follow strict TDD methodology. Tests MUST be written and failing before implementation begins. Unit tests MUST achieve 95%+ coverage for simulation logic. Integration tests MUST verify end-to-end scenarios with known outcomes.

### Data-Driven Configuration
Game content (parties, policies, scenarios) MUST be defined in JSON configuration files separate from code. All text content MUST support internationalization through separate language files. Game balance parameters MUST be configurable without code changes. Version compatibility MUST be maintained through schema validation.

### Save System Integrity
Save files MUST include versioning metadata to support backward compatibility. Save data MUST be validated on load with clear error reporting for corruption. Migration paths MUST be provided for save files from previous versions. Save file format MUST be human-readable JSON for debugging and potential modding.

## Quality Assurance

All code MUST pass automated linting and static analysis before merge. Performance profiling MUST be conducted for any changes affecting core simulation loops. Localization testing MUST verify both Dutch and English functionality. Accessibility testing MUST validate keyboard navigation and screen reader compatibility.

**Security**: User-generated content (if any) MUST be validated and sanitized. Save files MUST be validated to prevent code injection attacks. Network communications (if implemented) MUST use secure protocols.

## Governance

This constitution supersedes all other development practices and decisions. All feature implementations and pull requests MUST demonstrate compliance with these principles. Deviations MUST be explicitly justified with documented rationale and stakeholder approval.

**Amendment Process**: Constitutional changes require documentation of impact, justification for change, and validation that existing implementations remain compliant. Major principle changes require version increment and migration planning.

**Compliance Review**: All significant features MUST undergo constitutional compliance review before merge. Performance benchmarks MUST be executed for each release. Accessibility audits MUST be conducted quarterly.

**Version**: 1.0.0 | **Ratified**: 2025-09-24 | **Last Amended**: 2025-09-24