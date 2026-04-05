---
paths:
  - "src/ui/**"
  - "src/components/**"
  - "src/pages/**"
  - "src/views/**"
  - "app/components/**"
---

# Frontend Quality Standards

These standards only load when working on frontend files.

## F001: No inline styles for reusable components
Reusable components should use the project's styling system (CSS modules, Tailwind, 
styled-components, etc.) consistently. Inline styles are acceptable only for 
truly one-off dynamic values (e.g. computed positions).
- weight: medium
- source: base

## F002: Loading and error states
Every component that fetches data must handle three states:
loading, success, and error. No component should render a blank screen on error.
- weight: high
- source: base

## F003: Accessible interactive elements
Buttons, links, and form controls must have accessible labels.
Images must have alt text. Forms must have associated labels.
- weight: medium
- source: base
