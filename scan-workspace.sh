#!/bin/bash
# =============================================================
# 10x Claude Code Mastery — Workspace Scanner
# 
# The coaching system lives in its OWN directory, separate from
# your project. This script scans your project from the outside.
#
# Usage: bash scan-workspace.sh /path/to/your/project [optional: subdirectory]
#
# Example:
#   bash scan-workspace.sh ~/Documents/dominion-suite
#   bash scan-workspace.sh ~/Documents/dominion-suite src
# =============================================================

set -euo pipefail

EXCLUDE='node_modules|.git|dist|build|__pycache__|.next|.cache|coverage|.turbo|.venv|venv|.tox|.mypy_cache|.pytest_cache'

# ── Validate project path ──
PROJECT_PATH="${1:-}"
if [ -z "$PROJECT_PATH" ]; then
    echo ""
    echo "Usage: bash scan-workspace.sh /path/to/your/project [subdirectory]"
    echo ""
    echo "Example:"
    echo "  bash scan-workspace.sh ~/Documents/dominion-suite"
    echo "  bash scan-workspace.sh ~/Documents/dominion-suite src"
    echo ""
    exit 1
fi

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
    echo "❌ Directory not found: $1"
    exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     10x Claude Code Mastery — Workspace Bootstrap       ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Coaching directory: $(pwd)"
echo "║  Project to scan:   $PROJECT_PATH"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Create coaching directory structure (in current dir) ──
mkdir -p coaching/ratings

echo "📁 Created coaching/ directory structure"

# Save project path for the coach to reference
echo "$PROJECT_PATH" > coaching/project-path.txt
echo "📌 Project path saved to coaching/project-path.txt"

# ─── Step 1: Full workspace scan ───
echo ""
echo "━━━ Step 1/5: Scanning full workspace ━━━"
if command -v tree &> /dev/null; then
    tree -L 2 -I "$EXCLUDE" "$PROJECT_PATH" > coaching/workspace-map.txt 2>/dev/null
    echo "✅ Workspace map saved"
    echo "   $(wc -l < coaching/workspace-map.txt) lines"
else
    find "$PROJECT_PATH" -maxdepth 2 -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' | sort > coaching/workspace-map.txt
    echo "✅ Workspace map saved (using find — install 'tree' for better output)"
fi

# ─── Step 2: Deep scan of target subdirectory ───
echo ""
echo "━━━ Step 2/5: Deep scanning target subdirectory ━━━"
TARGET_DIR="${2:-}"
if [ -z "$TARGET_DIR" ]; then
    echo ""
    echo "Available top-level directories in $PROJECT_NAME:"
    echo "─────────────────────────────────"
    ls -d "$PROJECT_PATH"/*/ 2>/dev/null | xargs -I{} basename {} | head -20
    echo ""
    read -p "Which subdirectory is the heart of your app? (e.g., src, app, packages/core): " TARGET_DIR
fi

FULL_TARGET="$PROJECT_PATH/$TARGET_DIR"
if [ -d "$FULL_TARGET" ]; then
    if command -v tree &> /dev/null; then
        tree -L 4 -I "$EXCLUDE" "$FULL_TARGET" > coaching/deep-scan.txt 2>/dev/null
    else
        find "$FULL_TARGET" -maxdepth 4 -not -path '*/node_modules/*' -not -path '*/.git/*' | sort > coaching/deep-scan.txt
    fi
    echo "✅ Deep scan of '$TARGET_DIR' saved"
    echo "   $(wc -l < coaching/deep-scan.txt) lines"
    echo "$TARGET_DIR" > coaching/target-dir.txt
else
    echo "⚠️  Directory '$FULL_TARGET' not found. Skipping deep scan."
    echo "   You can re-run with: bash scan-workspace.sh $PROJECT_PATH <directory>"
fi

# ─── Step 3: Inventory existing Claude Code setup ───
echo ""
echo "━━━ Step 3/5: Inventorying existing Claude Code config ━━━"

SETUP_FILE="coaching/existing-setup.txt"
echo "=== Project: $PROJECT_NAME ===" > "$SETUP_FILE"
echo "=== Path: $PROJECT_PATH ===" >> "$SETUP_FILE"
echo "" >> "$SETUP_FILE"

echo "=== CLAUDE.md ===" >> "$SETUP_FILE"
cat "$PROJECT_PATH/CLAUDE.md" 2>/dev/null >> "$SETUP_FILE" || echo "(none found)" >> "$SETUP_FILE"

echo "" >> "$SETUP_FILE"
echo "=== .claude/ directory ===" >> "$SETUP_FILE"
ls -laR "$PROJECT_PATH/.claude/" 2>/dev/null >> "$SETUP_FILE" || echo "(no .claude/ directory)" >> "$SETUP_FILE"

echo "" >> "$SETUP_FILE"
echo "=== .claude/settings.json ===" >> "$SETUP_FILE"
cat "$PROJECT_PATH/.claude/settings.json" 2>/dev/null >> "$SETUP_FILE" || echo "(no settings.json)" >> "$SETUP_FILE"

echo "" >> "$SETUP_FILE"
echo "=== Existing skills ===" >> "$SETUP_FILE"
for f in "$PROJECT_PATH"/.claude/skills/*.md; do
    if [ -f "$f" ]; then
        echo "--- $(basename "$f") ---" >> "$SETUP_FILE"
        head -20 "$f" >> "$SETUP_FILE"
        echo "" >> "$SETUP_FILE"
    fi
done 2>/dev/null || echo "(no skills)" >> "$SETUP_FILE"

echo "" >> "$SETUP_FILE"
echo "=== Existing agents ===" >> "$SETUP_FILE"
for f in "$PROJECT_PATH"/.claude/agents/*.md "$PROJECT_PATH"/.claude/agents/*.yml "$PROJECT_PATH"/.claude/agents/*.yaml; do
    if [ -f "$f" ]; then
        echo "--- $(basename "$f") ---" >> "$SETUP_FILE"
        head -20 "$f" >> "$SETUP_FILE"
        echo "" >> "$SETUP_FILE"
    fi
done 2>/dev/null || echo "(no agents)" >> "$SETUP_FILE"

echo "" >> "$SETUP_FILE"
echo "=== Existing commands ===" >> "$SETUP_FILE"
for f in "$PROJECT_PATH"/.claude/commands/*.md; do
    if [ -f "$f" ]; then
        echo "--- $(basename "$f") ---" >> "$SETUP_FILE"
        head -10 "$f" >> "$SETUP_FILE"
        echo "" >> "$SETUP_FILE"
    fi
done 2>/dev/null || echo "(no commands)" >> "$SETUP_FILE"

echo "✅ Existing setup inventoried"

# ─── Step 4: Detect stack ───
echo ""
echo "━━━ Step 4/5: Detecting stack and dependencies ━━━"

STACK_FILE="coaching/stack-info.txt"
echo "=== Package Detection for $PROJECT_NAME ===" > "$STACK_FILE"

# Node/JS
if [ -f "$PROJECT_PATH/package.json" ]; then
    echo "DETECTED: Node.js project" >> "$STACK_FILE"
    echo "" >> "$STACK_FILE"
    echo "--- package.json (name, scripts, key deps) ---" >> "$STACK_FILE"
    cat "$PROJECT_PATH/package.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"Name: {d.get('name','?')}\")
    print(f\"Scripts: {json.dumps(d.get('scripts',{}), indent=2)}\")
    deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
    key_deps = {k:v for k,v in deps.items() if any(x in k for x in ['react','next','vue','nuxt','svelte','express','fastify','nest','prisma','drizzle','sequelize','mongoose','tailwind','typescript','vite','webpack','jest','vitest','playwright','cypress'])}
    print(f\"Key deps: {json.dumps(key_deps, indent=2)}\")
except: pass
" >> "$STACK_FILE" 2>/dev/null || cat "$PROJECT_PATH/package.json" | head -60 >> "$STACK_FILE"
fi

# Python
if [ -f "$PROJECT_PATH/requirements.txt" ]; then
    echo "DETECTED: Python project (requirements.txt)" >> "$STACK_FILE"
    cat "$PROJECT_PATH/requirements.txt" >> "$STACK_FILE"
fi
if [ -f "$PROJECT_PATH/pyproject.toml" ]; then
    echo "DETECTED: Python project (pyproject.toml)" >> "$STACK_FILE"
    head -40 "$PROJECT_PATH/pyproject.toml" >> "$STACK_FILE"
fi

# Rust
if [ -f "$PROJECT_PATH/Cargo.toml" ]; then
    echo "DETECTED: Rust project" >> "$STACK_FILE"
    head -30 "$PROJECT_PATH/Cargo.toml" >> "$STACK_FILE"
fi

# Go
if [ -f "$PROJECT_PATH/go.mod" ]; then
    echo "DETECTED: Go project" >> "$STACK_FILE"
    cat "$PROJECT_PATH/go.mod" >> "$STACK_FILE"
fi

# Docker
if [ -f "$PROJECT_PATH/docker-compose.yml" ] || [ -f "$PROJECT_PATH/docker-compose.yaml" ] || [ -f "$PROJECT_PATH/Dockerfile" ]; then
    echo "" >> "$STACK_FILE"
    echo "DETECTED: Docker setup" >> "$STACK_FILE"
    ls "$PROJECT_PATH"/docker* "$PROJECT_PATH"/Docker* 2>/dev/null >> "$STACK_FILE"
fi

# Monorepo signals
if [ -f "$PROJECT_PATH/turbo.json" ] || [ -f "$PROJECT_PATH/nx.json" ] || [ -f "$PROJECT_PATH/lerna.json" ] || [ -d "$PROJECT_PATH/packages" ] || [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ]; then
    echo "" >> "$STACK_FILE"
    echo "DETECTED: Monorepo" >> "$STACK_FILE"
    ls "$PROJECT_PATH"/turbo.json "$PROJECT_PATH"/nx.json "$PROJECT_PATH"/lerna.json "$PROJECT_PATH"/pnpm-workspace.yaml 2>/dev/null >> "$STACK_FILE"
    ls "$PROJECT_PATH"/packages/ 2>/dev/null >> "$STACK_FILE"
    ls "$PROJECT_PATH"/apps/ 2>/dev/null >> "$STACK_FILE"
fi

# Git info
echo "" >> "$STACK_FILE"
echo "=== Git Info ===" >> "$STACK_FILE"
cd "$PROJECT_PATH"
git log --oneline -10 2>/dev/null >> "$STACK_FILE" || echo "(not a git repo)" >> "$STACK_FILE"
echo "" >> "$STACK_FILE"
git branch --list 2>/dev/null >> "$STACK_FILE" || true
cd - > /dev/null

echo "✅ Stack detected and saved"

# ─── Step 5: Initialize progress tracking ───
echo ""
echo "━━━ Step 5/5: Initializing progress tracker ━━━"

cat > coaching/progress.md << PROGRESS
# 10x Claude Code Mastery — Progress Log

## Project: $PROJECT_NAME
## Project Path: $PROJECT_PATH

## Skills Mastered
<!-- Updated by the coach at the end of each day -->

## Rev 2.0 Roadmap Progress
<!-- Features identified, planned, shipped -->

## Daily Log

### Day 0 — Bootstrap
- [x] Workspace scanned
- [x] Target subdirectory identified
- [x] Existing Claude Code setup inventoried
- [x] Stack detected
- [ ] Day 1 plan generated (coach does this)

## Token Cost Tracking
| Day | Tokens Used | USD Cost | Notes |
|-----|------------|----------|-------|
| 0   |            |          | Bootstrap scan |
PROGRESS

# Initialize expansion ideas log
cat > coaching/expansion-ideas.md << IDEAS
# Expansion Ideas — Future Topics & Season 2 Candidates

<!-- The coach appends ideas here whenever you mention something you want to learn -->
<!-- These feed into the Season 2 proposal generated on Day 10 -->
IDEAS

echo "✅ Progress tracker and expansion log initialized"

# ─── Summary ───
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    Bootstrap Complete                    ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  Coaching dir: $(pwd)                                    "
echo "║  Project:      $PROJECT_PATH                             "
echo "║                                                          ║"
echo "║  Files created in coaching/:                             ║"
echo "║    • project-path.txt   — path to your project           ║"
echo "║    • workspace-map.txt  — full project tree              ║"
echo "║    • deep-scan.txt      — target dir deep dive           ║"
echo "║    • existing-setup.txt — current Claude Code config     ║"
echo "║    • stack-info.txt     — detected stack & deps          ║"
echo "║    • progress.md        — learning progress tracker      ║"
echo "║    • expansion-ideas.md — future topic log               ║"
echo "║    • ratings/           — daily session ratings dir       ║"
echo "║                                                          ║"
echo "║  Next step:                                              ║"
echo "║    cd into your PROJECT directory, open Claude Code,     ║"
echo "║    and paste the Day 1 boot prompt.                      ║"
echo "║                                                          ║"
echo "║  The boot prompt will tell Claude Code to read files     ║"
echo "║  from BOTH this coaching dir and your project.           ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
