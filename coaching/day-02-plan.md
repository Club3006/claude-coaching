# Day 2 Plan — Skills Architecture
# Date: 2026-04-16 (or whenever you run it)

## Adjustments from Day 1 Feedback
- **Slower pace.** One concept at a time. Do it, confirm it works, then move on.
- **Validate before building.** Start by ranking Rev 2.0 priorities with Craig before any code.
- **Desktop/Cowork woven in.** Skills aren't just for Claude Code — they show up in Cowork's Customize panel. Show the full picture.
- **One skill built deeply** instead of 2-3 shallow ones.

---

## Part A — Priority Validation (10 min)

Before building anything, rank the 5 Rev 2.0 items from the roadmap:

```
/Users/craigfuhr/Documents/claude-coaching/coaching/rev2-roadmap.md
```

Craig answers: which one, if shipped tomorrow, would create the most value for actual users?

Reorder the roadmap based on his answer. The Day 2 skill will be scoped to that P1 area.

---

## Part B — Build ONE Skill Deeply (40 min)

### What a skill is
A skill is a markdown file in `.claude/skills/` that Claude loads as context. Two modes:
- `disable-model-invocation: true` — pure context, no LLM call. Fast, free. Use for reference docs.
- (omit the flag) — active skill. Claude can reason about the content and act on it.

Skills appear in Cowork's **Customize panel** — this is where they become available to Claude Desktop sessions, not just terminal sessions. That's the connection to your Desktop workflow.

The open standard for skills is at agentskills.io — skills you write here can be shared across tools that support the standard.

### The skill to build
A backend reference skill for campaign_mgr that gives Claude instant knowledge of:
- The full CrmLead type shape
- All Supabase table schemas
- The enrichment service interfaces
- The IntelDossier shape

This is `disable-model-invocation: true` — it's a reference doc, not an active skill.

**Why this one first:** Every future agent or session working on campaign_mgr needs this context. Without it, Claude reads `lib/supabase.ts`, `services/intel.ts`, and `services/enrichment.ts` from scratch on every task — 3-4 tool calls wasted per session.

### Build it
```
/Users/craigfuhr/Documents/dominion-suite/.claude/skills/campaign-mgr-backend.md
```

Use `!` command embedding to pull live type definitions directly into the skill at invocation time:
```
!cat /Users/craigfuhr/Documents/dominion-suite/campaign_mgr/src/lib/supabase.ts
```

This keeps the skill current without manual updates.

### Validate it
After creating the skill, open a fresh Claude Code session in dominion-suite and ask:
"What fields are on CrmLead?" — it should answer without reading any files.

---

## Part C — Connect Skills to Cowork (20 min)

Open Claude Desktop. Go to the **Customize** panel (available since Cowork GA, April 9).

You'll see your skills listed. Toggle the campaign-mgr-backend skill on.

Now open a Cowork session and ask the same question: "What fields are on CrmLead?"

Same answer. No file reads. This is the full loop: skill written in Claude Code → available in Claude Desktop Cowork sessions → consistent context everywhere.

---

## Part D — Rate & Reflect (10 min)

Run the Session Rating Protocol (all 6 questions).

Write:
- `coaching/ratings/day-02-rating.md`
- Update `coaching/progress.md`
- Write `coaching/day-03-plan.md` (Day 3 theme: Hooks That Enforce Quality)

---

## Success Criteria for Day 2
- [ ] Rev 2.0 priorities re-ranked by Craig (not the coach)
- [ ] One skill file created and validated (answers question without file reads)
- [ ] Skill visible in Cowork Customize panel
- [ ] `!` command embedding understood and used
- [ ] Ctrl+B + /tasks completed from dominion-suite session (carry-over from Day 1)
