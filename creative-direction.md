# Creative Direction: Nearterm

## Direction Summary
Nearterm should feel like a focused native helper rather than a miniature dashboard. Use native materials, compact system typography, plain content rows, and restrained semantic color. The interface should reveal hierarchy through spacing, weight, and subtle state surfaces rather than dividers or card chrome.

## Visual Thesis
Create a quiet, content-first menu-bar utility: a compact header and one small control cluster establish context, while reminder rows carry the experience through crisp type, light metadata, and minimal interactive feedback.

## Influence Hierarchy
Primary structure: compact single-column macOS utility layout with a 360-point popover and consistent 16-point edge spacing.

Secondary language: plain interactive rows, native controls, small icon-only actions, and subtle rounded state backgrounds.

Atmosphere: calm, lightweight, and system-native.

Accent layer: semantic color only for overdue state, list identity, selection, and primary actions.

Outliers / do not overweight: timer-specific progress treatments and the source app's playback states.

## Core Principles
- Content first: reminders should be visually stronger than surrounding chrome.
- Native restraint: prefer system controls, fonts, colors, and materials.
- State through nuance: use low-opacity fills and text color rather than heavy borders.
- Compact clarity: keep labels legible without turning the helper into a full-size window.

## Execution Rules
- Keep the popover 360 points wide with 16-point outer padding.
- Use 14 points between major vertical regions and 2–4 points between related row content.
- Set the title at 15-point semibold, reminder titles at 14-point regular, and metadata at 12 points.
- Use 6-point vertical and 8-point horizontal row padding with continuous 8-point corners.
- Consolidate utility actions into one compact menu; do not give refresh and quit equal visual weight to reminder content.
- Reserve red for overdue reminders and keep state fills below roughly 12% opacity.

## Visual System
### Color
Use macOS semantic foreground and background colors. List colors remain small identity dots. Red communicates overdue status; the system accent color is reserved for primary buttons and selected controls.

### Layout and Grid
Use one flush-left column. Header, segmented navigation, and content share the same width. Scrolling occurs only inside the content region.

### Typography
Use the system sans throughout with modest weight changes. Avoid oversized empty-state typography, all-caps except for small recurring-section labels, and decorative type.

### Imagery and Art Direction
No imagery. SF Symbols provide supporting cues at native optical sizes.

### Design Elements
Use borderless icon controls, segmented navigation, plain rows, tiny list-color dots, and continuous rounded hover/state fills. Avoid persistent dividers, nested cards, shadows, and ornamental backgrounds.

### Spacing and Rhythm
Major regions use a steady 14-point rhythm. Rows form a tighter 2-point stack so the reminder list reads as one coherent flow. Empty states gain more space because they contain less information.

## Composition Recipes
### Standard Reminder View
Compact title row with one action menu; segmented view selector; scrollable plain rows with title and one metadata line.

### Recurring View
Use small secondary section labels, a 4-point label-to-content gap, and 14 points between recurrence groups.

### Empty or Permission State
Center one small symbol, a concise 14-point message, and at most one primary action. Keep the surrounding field quiet.

## Application Guidance
### Do
- Let typography and spacing establish hierarchy.
- Use hover fills as lightweight affordances.
- Keep actions discoverable but visually subordinate.
- Preserve semantic colors and native accessibility behavior.

### Avoid
- Full-width separators between every region.
- Large content-unavailable illustrations.
- Multiple toolbar icons competing with the title.
- Strong card backgrounds around ordinary reminder rows.

### Agent Instructions
Build Nearterm as a compact, system-native helper. Use a 360-point single-column popover on macOS, 16-point padding, small system typography, plain rows with subtle hover and overdue fills, and semantic color only. Consolidate secondary actions and keep reminder content dominant.

## Quality Bar
- The popover reads clearly at a glance without feeling dense.
- Reminder titles dominate metadata and chrome.
- Hover, overdue, loading, denied, and empty states are distinct but restrained.
- The interface feels native in both light and dark appearances.
- No decorative element exists without a functional role.

## Source Analysis Appendix
| Source | User Intent | Visual Read | Role | Take | Leave | Serendipitous Insight |
|---|---|---|---|---|---|---|
| FlowSession menu-bar helper | Apply the same UI thinking to Nearterm | Compact 360-point popover, 16-point padding, 14-point vertical rhythm, native type, plain rows, subtle active fills, icon-only controls | Primary structure and secondary language | Compact grid, content hierarchy, native control styling, restrained row states | Timer progress, playback grammar, meeting-specific controls | Consolidating utility actions makes the content feel more purposeful and less like a toolbar-driven app |
