# Rev 2.0 Roadmap — Dominion Campaign Manager
# Generated: Day 1 — 2026-04-15

## Priority Order

### P1 — Persist lead score to Supabase
**Problem:** `calculateLeadScore()` runs client-side on every panel open. Score never touches DB — no server-side sort/filter on 900+ leads.
**Solution:** Add `score` + `score_grade` columns to `leads` table. Persist on enrichment update. Update `useLeads` to sort at DB level.
**Pattern:** Multi-subagent with worktree isolation (Day 4)
**Impact:** Unlocks score-based sorting, filtering, and segmentation at scale.

### P2 — Materialize the intel dossier
**Problem:** Every lead panel open fires 4 sequential Supabase queries (intel_reports, lead_mortgages, lead_competitors, competitor_activity).
**Solution:** Supabase materialized view or edge function that assembles IntelDossier once. Cache with TTL. Single read per panel open.
**Pattern:** Advisor pattern — Opus designs, Sonnet implements (Day 8)
**Impact:** Panel load time reduction. Scales as deal volume grows.

### P3 — Wire modules/lead-intelligence into campaign_mgr
**Problem:** Full Lead Intelligence module (M1-M5) sits in modules/ with no connection to the live CRM. Enrichment logic is duplicated in campaign_mgr/src/services/.
**Solution:** Define the module's public interface as a skill. Implement wiring from campaign_mgr into the module's pipeline. Deprecate duplicate services.
**Pattern:** Skills architecture (Day 2) + multi-subagent implementation (Day 4)
**Impact:** Eliminates architectural debt. Single enrichment pipeline.

### P4 — Automate Seamless enrichment runner
**Problem:** seamless-enrichment-runner.ts runs manually. 900+ leads can't be kept fresh by hand.
**Solution:** Scheduled Cowork task — nightly run on leads not enriched in 30+ days. Seamless MCP already connected.
**Pattern:** Cowork scheduled tasks (Day 9)
**Impact:** Enrichment stays fresh without manual intervention.

### P5 — Quality gate: type-check on every write
**Problem:** No tests, no pre-commit hooks, no type enforcement. Vercel deploys on push with zero automated verification.
**Solution:** PostToolUse hook runs `npx tsc --noEmit` after every file write to campaign_mgr/src/. Pre-commit hook blocks type errors.
**Pattern:** Hooks (Day 3)
**Impact:** Type errors caught before they reach Vercel. Zero-cost quality floor.

## Notes
- Score persistence (P1) unlocks several downstream features: score-based campaign targeting, lead prioritization views, automated stage advancement triggers.
- Module wiring (P3) is the highest architectural leverage but also the most complex — do after hooks and skills are in place.
- All items above are independently executable. No sequential dependencies except P3 should follow P2 (dossier shape needs to be stable first).
