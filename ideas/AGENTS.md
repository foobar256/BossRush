# AGENTS.md

## What This Repo Is
This repo is for writing plain-English idea notes only (no code, no implementation
details) for a top-down bullet-hell boss-rush game:

- Move: `WASD`
- Aim: mouse
- Fight increasingly harder bosses

Write design notes that are actionable but engine-agnostic:
- What the player sees, what they do, and what decisions they make.
- What the boss/pattern signals (telegraphs) and how the player can respond (counterplay).
Avoid implementation details and hard values (stats, tuning, timings, exact counts).

## Organization (Loose)
Use folders only as a convenience; don’t over-structure.

- `overview.md` short pitch and current direction
- `bosses/` one file per boss concept
- `patterns/` one file per pattern concept
- `systems/` progression/meta ideas
- `sessions/` dated brainstorming notes

## File Naming
- Use `kebab-case.md`.
- Boss files: `bosses/boss-name.md`
- Pattern files: `patterns/pattern-name.md`
- Session files: `sessions/session-YYYY-MM-DD.md`

## Writing Style
- Use short bullets and clear headings.
- Prefer concrete verbs: “forces”, “blocks”, “funnels”, “tempts”, “punishes”, “rewards”.
- Describe pressure and readability: where danger comes from, where safety comes from, and what changes over time.
- Always include “Why it’s fun” and “Risks / confusion points”.
- Replace numbers with relative language: “slow/fast”, “brief/long”, “tight/generous”, “sparse/dense”, “near/far”.

## Boss Note Template (High Level)
Use this structure for `bosses/*.md`:

- Summary (brief)
- Identity / theme (short)
- What the player learns (skill test)
- Signature moments (setpieces)
- Phases (described in words only)
- How it escalates (no numbers)
- Telegraphs (how it communicates)
- Counterplay (how a good player responds)
- Rewards / unlock fantasies (conceptual)
- Risks / open questions

## Pattern Note Template (High Level)
Use this structure for `patterns/*.md`:

- Summary (brief)
- What it tests (movement/aim/discipline)
- What it looks like (shape language)
- How it starts (telegraphs)
- How it evolves (escalation idea)
- Counterplay (in words only)
- Variants (conceptual)
- Risks / open questions

## Sessions
Each `sessions/session-YYYY-MM-DD.md` should end with:

- Decisions (what direction we liked and why)
- Next notes to write (which boss/pattern/system to think about next)
