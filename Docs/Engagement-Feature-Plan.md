# Engagement Feature Plan — Rose, Bud, Thorn

## Goal
Increase repeat usage (daily + weekly return) while keeping the app private, local-first, and low-friction.

## What Feels Missing Today
Based on current shipped capabilities (capture, browse, search, summaries), the biggest gaps are:

1. **Re-entry triggers**: nothing nudges people back at the right moment.
2. **Continuity loops**: limited “pick up where you left off” experiences.
3. **Visible progress**: users cannot easily feel momentum over time.
4. **Guided reflection depth**: no lightweight prompts or coaching structure.
5. **Ritual surfaces beyond app launch**: no widget/shortcut/check-in shortcuts.

## Feature Ideas to Improve Repeated Engagement

### 1) Smart Daily Reminder System (High Impact / Medium Effort)
- Configurable reminder windows (morning, evening, custom).
- “Streak-safe” reminder logic that only pings if entry not done.
- End-of-day gentle nudge (“2 taps to finish today’s Rose”).
- Quiet mode + weekend rules.

**Engagement value:** increases daily return rate and completion consistency.

### 2) Streaks + Consistency Rings (High Impact / Low Effort)
- Consecutive-day streak counter.
- Weekly completion ring (e.g., 5/7 days reflected).
- “Personal best” milestones (non-gamified tone).
- Missed-day recovery framing (“Start a new run today”).

**Engagement value:** gives immediate progress feedback and habit reinforcement.

### 3) Home Widget + Quick Actions (High Impact / Medium Effort)
- Lock/home screen widget: “Today’s Rose/Bud/Thorn status”.
- One-tap quick capture for each category.
- Siri Shortcut intents: “Log a Rose”, “Open weekly summary”.

**Engagement value:** reduces friction and improves top-of-mind visibility.

### 4) Prompt Packs + Reflection Themes (Medium Impact / Medium Effort)
- Optional daily prompt for each category.
- Weekly themes (gratitude, resilience, relationships, work).
- Random prompt mode for reflection fatigue days.

**Engagement value:** helps users who stall on blank-page syndrome.

### 5) Weekly Review Ritual (High Impact / Medium Effort)
- “Sunday review” flow that composes key highlights from the week.
- Guided questions before viewing generated summary.
- Save “weekly intention” that carries into next week.

**Engagement value:** builds a strong weekly return loop beyond daily logging.

### 6) Trend & Insight Cards (Medium Impact / High Effort)
- Mood/tag trend snapshots.
- “Most common Bud category this month”.
- “You mentioned family in 4 Roses this week”.

**Engagement value:** creates curiosity and reasons to revisit historical data.

### 7) Memory Resurfacing (“On this day”) (Medium Impact / Medium Effort)
- Show reflections from the same date in prior years.
- Option to add a “then vs now” follow-up.

**Engagement value:** emotional resonance drives re-engagement.

### 8) Lightweight Accountability Features (Optional)
- Private weekly commitment check-ins.
- Optional export/share of selected weekly summary snippets.

**Engagement value:** external accountability can improve consistency for some users.

## Delivery Sequence

### Phase 1 (Fastest engagement gains)
1. Smart reminders.
2. Streaks + weekly completion ring.
3. Widget quick capture.

### Phase 2 (Depth + ritual)
4. Prompt packs.
5. Weekly review ritual.
6. Siri shortcuts.

### Phase 3 (Retention moat)
7. Insight cards.
8. Memory resurfacing.
9. Optional accountability/share flows.

---

## Phase 1 Build-Out (Detailed)

### 1.1 Objectives
- Increase daily capture completion by making re-entry timely and low-friction.
- Give users immediate progress feedback without heavy gamification.
- Add an at-a-glance surface that reduces launch friction.

### 1.2 Scope

#### A) Smart Daily Reminder System
**Deliverables**
- Reminder settings screen (on/off, time windows, weekend behavior).
- Local notifications engine with “send only if incomplete today” rule.
- End-of-day fallback reminder (single additional notification max).

**Implementation Notes**
- Add `ReminderPreferences` model in local settings.
- Add `ReminderScheduler` service that checks day completion state.
- Use existing entry corpus to determine completion status per day.

**Acceptance Criteria**
- Notifications never fire when daily entry is already complete.
- User can disable all reminders in one action.
- Reminder preferences persist across app relaunch.

#### B) Streaks + Weekly Completion Ring
**Deliverables**
- Today-screen header card with consecutive-day streak and 7-day completion ring.
- Copy variants for new streak, active streak, and streak reset.

**Implementation Notes**
- Introduce `EntryCompletionTracker` derived from existing entries.
- Ring is computed from local data only (no network).

**Acceptance Criteria**
- Ring updates immediately after first entry of the day.
- Streak logic is timezone-safe and DST-safe.
- Missed-day messaging remains encouraging and non-punitive.

#### C) Widget Quick Capture
**Deliverables**
- Small widget: completion status only.
- Medium widget: Rose/Bud/Thorn quick actions.
- Deep link routing into preselected capture category.

**Implementation Notes**
- Reuse `EntryCompletionTracker` to avoid duplicated logic.
- Ensure widget refresh occurs after save.

**Acceptance Criteria**
- Widget tap opens directly to selected category capture flow.
- Widget state reflects completion changes within expected refresh windows.

### 1.3 Rollout Plan
- **Milestone P1-M1:** Settings + scheduler foundation.
- **Milestone P1-M2:** Completion tracker + Today ring UI.
- **Milestone P1-M3:** Widget + deep links + polish.
- Ship behind feature flags and progressively enable by cohort.

### 1.4 Success Metrics
- Reminder-to-open conversion rate.
- Daily reflection completion rate (rolling 7-day).
- Percentage of users with at least 4/7 completion.

---

## Phase 2 Build-Out (Detailed)

### 2.1 Objectives
- Increase reflection depth so users can sustain journaling quality beyond quick capture.
- Establish a recurring weekly ritual that strengthens weekly return behavior.
- Expand low-friction entry points through voice and automation.

### 2.2 Scope

#### A) Prompt Packs + Reflection Themes
**Deliverables**
- Prompt library grouped by theme (gratitude, resilience, relationships, work).
- Daily optional prompts for Rose/Bud/Thorn with random fallback mode.
- Prompt settings (theme preference, hide specific prompt types).

**Implementation Notes**
- Add `PromptPack` and `PromptSelector` components with deterministic local rotation.
- Cache prompt state locally to avoid repetitive prompts in the same week.

**Acceptance Criteria**
- Users can complete entry without responding to any prompt.
- Prompt rotation avoids showing duplicate prompt text on consecutive days unless explicitly randomized.
- Prompt feature can be disabled globally in settings.

#### B) Weekly Review Ritual
**Deliverables**
- Guided weekly check-in flow with 3–5 reflection questions.
- “Preview highlights” step before generated summary view.
- Saveable weekly intention that appears in next week's review opener.

**Implementation Notes**
- Extend summaries flow with pre-summary guided question state.
- Store weekly intention in local documents adjacent to summary artifacts.

**Acceptance Criteria**
- Weekly review is completable in under 3 minutes.
- Existing summary generation remains deterministic and regenerable.
- Users can skip the guided prompts and proceed directly to summary.

#### C) Siri Shortcuts / App Intents
**Deliverables**
- “Log a Rose”, “Log a Bud”, “Log a Thorn” intents.
- “Open weekly summary” and “Start weekly review” intents.
- Optional shortcut tiles in settings for one-tap setup.

**Implementation Notes**
- Reuse deep-link routes created in Phase 1 for intent destinations.
- Ensure intent execution fails gracefully when app lock is enabled.

**Acceptance Criteria**
- Voice command opens the targeted in-app flow in one step.
- Intents respect privacy lock and never expose hidden content on lock screen.

### 2.3 Rollout Plan
- **Milestone P2-M1:** Prompt library + daily prompt insertion in capture flow.
- **Milestone P2-M2:** Weekly ritual flow + intention persistence.
- **Milestone P2-M3:** Siri intents + settings integration.
- Gradual rollout after validating completion impact and sentiment signals.

### 2.4 Success Metrics
- Prompt-assisted entry completion rate.
- Weekly review open-to-complete conversion.
- Percentage of active users triggering at least one shortcut per week.

---

## Phase 3 Build-Out (Detailed)

### 3.1 Objectives
- Create long-term retention loops powered by meaningful historical insights.
- Increase emotional resonance by reconnecting users with prior reflections.
- Add optional accountability without compromising privacy posture.

### 3.2 Scope

#### A) Trend & Insight Cards
**Deliverables**
- Monthly and weekly insight cards on tag frequency, category distribution, and recurring themes.
- “Notable changes” cards (e.g., increase/decrease vs prior period).
- Explainability line for every card (what data was used and from which period).

**Implementation Notes**
- Compute aggregates from local entry corpus and existing summaries/index artifacts.
- Add an `InsightEngine` with deterministic calculations and versioned card templates.

**Acceptance Criteria**
- Insight cards are reproducible from the same local dataset.
- No external API calls are required for card generation.
- Users can hide insight cards entirely from settings.

#### B) Memory Resurfacing (“On This Day”)
**Deliverables**
- Daily “On this day” module with 1–3 surfaced past reflections.
- “Then vs now” follow-up prompt to encourage comparative journaling.
- Dismiss/snooze controls to avoid repetitive resurfacing.

**Implementation Notes**
- Match entries by month/day with timezone-aware day keys.
- Respect hidden/private entries and lock-state constraints.

**Acceptance Criteria**
- Resurfaced memories are never shown from locked/hidden items without unlock.
- Users can disable resurfacing globally.
- Dismissed memory items are not re-shown within the configured cooldown period.

#### C) Lightweight Accountability + Share Flows
**Deliverables**
- Optional private weekly commitments with completion check-in.
- Controlled export/share for selected summary snippets only.
- Clear redaction preview before export.

**Implementation Notes**
- Keep sharing strictly user-initiated (no auto-share, no cloud sync dependency).
- Reuse existing export directory conventions in document store.

**Acceptance Criteria**
- No content leaves device without explicit user action.
- Share preview clearly shows exactly what text will be exported.
- Feature can be entirely disabled in settings.

### 3.3 Rollout Plan
- **Milestone P3-M1:** Insight engine foundation + first card set.
- **Milestone P3-M2:** On-this-day resurfacing + suppression controls.
- **Milestone P3-M3:** Commitment check-ins + selective share flow.
- Release as opt-in beta first, then graduate features by engagement and sentiment thresholds.

### 3.4 Success Metrics
- Insight card revisit rate (opens per active user).
- Memory resurfacing interaction rate (view, reflect, dismiss).
- Weekly commitment completion rate.
- Export/share completion rate with no increase in privacy-related support issues.

## Product Guardrails
- Keep all insights generated locally from on-device documents.
- Allow complete opt-out of reminders, streak visuals, and widgets.
- Avoid punitive language for missed days.
- Keep capture under 10 seconds for quick mode.

## Success Metrics to Track
- **D1/D7/D30 retention**.
- **Daily active reflection rate** (% of days with at least one entry).
- **Weekly review completion rate**.
- **Reminder-to-open conversion**.
- **Median time-to-first-entry after reminder**.

## Suggested Next Implementation Ticket
Start with a single vertical slice:

**“Daily Reminder + Completion Ring”**
- Add local notification scheduling preferences.
- Add `EntryCompletionTracker` derived from existing entry corpus.
- Expose ring in Today screen header.
- Track local analytics events (privacy-preserving, on-device counts only).

This slice delivers immediate behavior change potential while staying aligned with local-first architecture.
