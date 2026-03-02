# IA Blueprint 2026 Q1

## Scope
- Top-level IA remains unchanged:
`Today`, `Browse`, `Summaries`, `Search`, `Settings`.
- Focus is on clarity, hierarchy, and route consistency inside existing sections.

## Section Purpose and Primary CTA

## Today
- Purpose: Daily capture and reflection for Rose/Bud/Thorn entries.
- Primary task: Create or update today's reflection quickly.
- First-screen CTA: Enter short reflections and capture media.
- Secondary tasks: Toggle favorite, expand journal details, share day card.

## Browse
- Purpose: Revisit prior days with timeline or calendar models.
- Primary task: Find and open a past day.
- First-screen CTA: Select a day card/month day and open day details.
- Secondary tasks: Filter by favorites/media/date windows, refresh snapshots.

## Summaries
- Purpose: Generate and review weekly/current summary artifacts.
- Primary task: Generate current summary.
- First-screen CTA: `Generate Current`.
- Secondary tasks: Start weekly review, open summary artifact, open resurfaced memory day.

## Search
- Purpose: Retrieve past entries by text/type/media filters.
- Primary task: Run focused search and open matching day detail.
- First-screen CTA: `Search`.
- Secondary tasks: adjust Rose/Bud/Thorn toggles, media filter, keyboard dismissal.

## Settings
- Purpose: Configure reminders, prompts, privacy lock, and feature modules.
- Primary task: Adjust behavior settings safely.
- First-screen CTA: Toggle reminders and lock state.
- Secondary tasks: prompt customization, shortcuts launch, module flags.

## Route Topology
- `Today` -> `Day Detail`:
Deep link and browse/summaries paths converge on `DayDetailView`.
- `Browse` -> `Day Detail`:
Selected day opens full editor.
- `Summaries` -> `Summary Detail`:
Select artifact to inspect/share/regenerate.
- `Summaries` -> `Day Detail`:
Resurfaced memory opens source day.
- `Search` -> `Day Detail`:
Search results navigate to selected day.

## Cross-Link Rules
- Cross-links should use explicit intent text:
`View Day Details`, `Open Summary`, `Generate Current`.
- Keep one dominant action per viewport:
Today capture, Browse select/open, Summaries generate, Search execute.
- Keep toolbar CTAs supportive, not competing with primary in-body actions.

## Hierarchy Refinements
- Use grouped action clusters:
Primary action (`borderedProminent`) + related secondary actions (`bordered`).
- Prevent CTA crowding in toolbars:
Move low-frequency actions to contextual sections where possible.
- Ensure tappable controls meet minimum touch target standards via shared modifiers/tokens.
