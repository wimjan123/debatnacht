# Dutch Politics Simulation UI Documentation

**Educational Political Simulation demonstrating democratic processes in the Netherlands with full constitutional compliance**

## Quick Navigation

- [Project Overview](project-overview.md) - Purpose, architecture, and constitutional compliance features
- [Core Systems](core-systems.md) - EventBus, GameStateManager, and simulation integration
- [API Reference](api-reference.md) - Key classes, interfaces, and methods
- [Integration Guide](integration-guide.md) - Component interaction and data flows
- [Developer Guide](developer-guide.md) - Setup, compilation, and development patterns
- [UI Components](ui-components.md) - Scene structure and accessibility features

## About This Project

The Dutch Politics Simulation UI is an educational game built in **Godot 4.5** using **GDScript** that teaches users about democratic processes in the Netherlands. The project emphasizes:

- **Constitutional Compliance**: Transparency, accessibility, political neutrality
- **Educational Purpose**: Teaching democratic processes and political understanding
- **Technical Excellence**: WCAG 2.1 AA accessibility standards, 60 FPS performance
- **Architectural Quality**: Clean separation between simulation and presentation layers

## Key Technologies

- **Engine**: Godot 4.5 with GDScript
- **Architecture**: Clean Architecture with presentation/core API separation
- **Accessibility**: WCAG 2.1 AA compliant with screen reader support
- **Localization**: Full Dutch/English support with scalable text
- **Testing**: Comprehensive unit, integration, and accessibility test suites

## Getting Started

```bash
# Clone and setup
git clone [repository]
cd debatnacht

# Open in Godot 4.5+
godot project.godot

# Run tests
godot --headless --script tests/run_all_tests.gd
```

For detailed setup instructions, see the [Developer Guide](developer-guide.md).

## Documentation Structure

This documentation is structured for different audiences:

- **Project Stakeholders**: Start with [Project Overview](project-overview.md)
- **Developers/Maintainers**: Review [Core Systems](core-systems.md) and [API Reference](api-reference.md)
- **New Contributors**: Follow [Developer Guide](developer-guide.md) and [Integration Guide](integration-guide.md)
- **UI/UX Designers**: Focus on [UI Components](ui-components.md)

---

*Documentation generated for Dutch Politics Simulation UI - Last updated: 2025-09-25*