#!/usr/bin/env bash
# .hooks/pre-push — Alesco GitFlow pre-push validation
#
# Canonical source: odoo-ai/config-templates/pre-push.template.sh
# Copy to <project>/.hooks/pre-push and activate with:
#   git config core.hooksPath .hooks
#
# Validates BEFORE push reaches the remote:
#   Phase 1 — Branch safety  (fail-fast)
#   Phase 2 — Code quality   (fail-at-end — shows all errors at once)
#
# Tools required : bash, python3, git
# Tools optional : xmllint (XML check skipped with WARN if missing)

set -euo pipefail

# ─── PHASE 1: Branch safety ───────────────────────────────────────────────────
# Blocks direct push to produccion / db_* — Alesco GitFlow requirement.

ERRORS_BRANCH=0

while read -r local_ref local_sha remote_ref remote_sha; do
    branch="${remote_ref#refs/heads/}"

    if [[ "$branch" == "produccion" || "$branch" =~ ^db_ ]]; then
        echo ""
        echo "  ERROR [pre-push]: direct push to '$branch' is blocked."
        echo ""
        echo "  Alesco GitFlow requires:"
        echo "    1. Commit on st_produccion (or st_<project>)"
        echo "    2. Push to st_produccion  →  validate in staging"
        echo "    3. Open PR: st_produccion → produccion"
        echo "    4. Merge PR after CI passes"
        echo ""
        echo "  Emergency bypass: git push --no-verify"
        echo ""
        exit 1
    fi

    # Capture push range for Phase 2
    ZERO="0000000000000000000000000000000000000000"
    if [[ "$remote_sha" == "$ZERO" ]]; then
        # New branch — compare from last tag or last 10 commits
        PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [[ -n "$PREV_TAG" ]]; then
            PUSH_RANGE="${PREV_TAG}..${local_sha}"
        else
            PUSH_RANGE="HEAD~10..HEAD"
        fi
    else
        PUSH_RANGE="${remote_sha}..${local_sha}"
    fi
done

# ─── PHASE 2: Code quality ────────────────────────────────────────────────────
# Validates only files changed in this push (fast — not the full repo).

PUSH_RANGE="${PUSH_RANGE:-HEAD~10..HEAD}"

CHANGED_PY=$(git diff --name-only "$PUSH_RANGE" 2>/dev/null \
    | grep '\.py$' \
    | grep -v '__pycache__' \
    | grep -v '/migrations/' \
    || true)

CHANGED_XML=$(git diff --name-only "$PUSH_RANGE" 2>/dev/null \
    | grep '\.xml$' \
    || true)

CHANGED_MANIFEST=$(git diff --name-only "$PUSH_RANGE" 2>/dev/null \
    | grep '__manifest__\.py$' \
    || true)

ERRORS=0

# ── 1. Conventional commits ──────────────────────────────────────────────────
echo "Checking: conventional commits..."
VALID_TYPES="feat|fix|docs|style|chore|refactor|perf|test"
COMMITS=$(git log "$PUSH_RANGE" --no-merges --format="%s" 2>/dev/null || true)

if [[ -n "$COMMITS" ]]; then
    while IFS= read -r MSG; do
        [[ -z "$MSG" ]] && continue
        [[ "$MSG" =~ ^\[skip ]] && continue
        if ! echo "$MSG" | grep -qE "^(${VALID_TYPES})(\([^)]+\))?: .+"; then
            echo "  FAIL [commit]: $MSG"
            echo "        Expected: type(scope): description"
            echo "        Valid types: feat fix docs style chore refactor perf test"
            ERRORS=$((ERRORS + 1))
        fi
    done <<< "$COMMITS"
    [[ "$ERRORS" -eq 0 ]] && echo "  OK: conventional commits"
fi

# ── 2. Python syntax ─────────────────────────────────────────────────────────
if [[ -n "$CHANGED_PY" ]]; then
    echo "Checking: Python syntax..."
    PY_ERRORS=0
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        if ! python3 -m py_compile "$f" 2>/dev/null; then
            echo "  FAIL [syntax]: $f"
            python3 -m py_compile "$f" 2>&1 | sed 's/^/    /'
            PY_ERRORS=$((PY_ERRORS + 1))
        fi
    done <<< "$CHANGED_PY"
    [[ "$PY_ERRORS" -eq 0 ]] && echo "  OK: Python syntax"
    ERRORS=$((ERRORS + PY_ERRORS))
fi

# ── 3. XML well-formedness ───────────────────────────────────────────────────
if [[ -n "$CHANGED_XML" ]]; then
    echo "Checking: XML well-formedness..."
    if command -v xmllint &>/dev/null; then
        XML_ERRORS=0
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            if ! xmllint --noout "$f" 2>/dev/null; then
                echo "  FAIL [xml]: $f"
                xmllint --noout "$f" 2>&1 | sed 's/^/    /'
                XML_ERRORS=$((XML_ERRORS + 1))
            fi
        done <<< "$CHANGED_XML"
        [[ "$XML_ERRORS" -eq 0 ]] && echo "  OK: XML well-formed"
        ERRORS=$((ERRORS + XML_ERRORS))
    else
        echo "  WARN [xml]: xmllint not found — skipping XML check"
        echo "              Install: apt-get install libxml2-utils  (or brew install libxml2)"
    fi
fi

# ── 4. Manifest OCA validation ───────────────────────────────────────────────
if [[ -n "$CHANGED_MANIFEST" ]]; then
    echo "Checking: OCA manifest fields..."
    MANIFEST_ERRORS=0

    python3 - <<PYEOF
import ast, sys

manifests = """${CHANGED_MANIFEST}""".strip().splitlines()
required = ["name", "version", "author", "license", "website", "depends"]
errors = 0

for path in manifests:
    path = path.strip()
    if not path or not __import__('os').path.exists(path):
        continue
    try:
        with open(path) as f:
            m = ast.literal_eval(f.read())
    except Exception as e:
        print(f"  FAIL [manifest]: {path} -- parse error: {e}")
        errors += 1
        continue

    missing = [k for k in required if k not in m]
    if missing:
        print(f"  FAIL [manifest]: {path} -- missing fields: {missing}")
        errors += 1
        continue

    ver = m.get("version", "")
    if not ver.startswith("19."):
        print(f"  FAIL [manifest]: {path} -- version must start with 19. (got: {ver})")
        errors += 1
        continue

    print(f"  OK: {m.get('name','?')} v{ver}")

sys.exit(errors)
PYEOF
    MANIFEST_ERRORS=$?
    ERRORS=$((ERRORS + MANIFEST_ERRORS))
fi

# ── 5. No raw SQL interpolation ──────────────────────────────────────────────
if [[ -n "$CHANGED_PY" ]]; then
    echo "Checking: no raw SQL interpolation..."
    SQL_VIOLATIONS=""
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        HITS=$(grep -nE "_?cr\.execute\(['\"][^'\"]*%[^s\)]" "$f" 2>/dev/null || true)
        [[ -n "$HITS" ]] && SQL_VIOLATIONS="${SQL_VIOLATIONS}${f}:\n${HITS}\n"
    done <<< "$CHANGED_PY"
    if [[ -n "$SQL_VIOLATIONS" ]]; then
        echo "  FAIL [sql]: Raw SQL interpolation found — use SQL() builder (Odoo 19):"
        printf "%b" "$SQL_VIOLATIONS" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
    else
        echo "  OK: no raw SQL interpolation"
    fi
fi

# ── 6. No deprecated x2many tuples ──────────────────────────────────────────
if [[ -n "$CHANGED_PY" ]]; then
    echo "Checking: no deprecated x2many tuples..."
    X2M_VIOLATIONS=""
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        HITS=$(grep -nE "append\(\(0,\s*0,\s*\{|=\s*\[\s*\(0,\s*0,\s*\{" "$f" 2>/dev/null || true)
        [[ -n "$HITS" ]] && X2M_VIOLATIONS="${X2M_VIOLATIONS}${f}:\n${HITS}\n"
    done <<< "$CHANGED_PY"
    if [[ -n "$X2M_VIOLATIONS" ]]; then
        echo "  FAIL [x2many]: Deprecated tuple syntax — use Command.create() (Odoo 19):"
        printf "%b" "$X2M_VIOLATIONS" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
    else
        echo "  OK: no deprecated x2many tuples"
    fi
fi

# ── 7. No print() — warning only ─────────────────────────────────────────────
if [[ -n "$CHANGED_PY" ]]; then
    PRINT_HITS=""
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        HITS=$(grep -nE "^\s+print\(|^print\(" "$f" 2>/dev/null || true)
        [[ -n "$HITS" ]] && PRINT_HITS="${PRINT_HITS}${f}:\n${HITS}\n"
    done <<< "$CHANGED_PY"
    if [[ -n "$PRINT_HITS" ]]; then
        echo "  WARN [print]: print() found — replace with _logger (not blocking):"
        printf "%b" "$PRINT_HITS" | sed 's/^/    /'
    fi
fi

# ── 8. No emojis in source files ─────────────────────────────────────────────
CHANGED_SOURCES=""
[[ -n "$CHANGED_PY" ]] && CHANGED_SOURCES="$CHANGED_PY"
[[ -n "$CHANGED_XML" ]] && CHANGED_SOURCES="${CHANGED_SOURCES}"$'\n'"$CHANGED_XML"

if [[ -n "$CHANGED_SOURCES" ]]; then
    echo "Checking: no emojis in source files..."
    EMOJI_HITS=""
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        HITS=$(grep -PnE '[\x{1F000}-\x{1FFFF}\x{2600}-\x{27BF}]' "$f" 2>/dev/null || true)
        [[ -n "$HITS" ]] && EMOJI_HITS="${EMOJI_HITS}${f}:\n${HITS}\n"
    done <<< "$CHANGED_SOURCES"
    if [[ -n "$EMOJI_HITS" ]]; then
        echo "  FAIL [emoji]: Emojis found in source files:"
        printf "%b" "$EMOJI_HITS" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
    else
        echo "  OK: no emojis"
    fi
fi

# ─── RESULT ───────────────────────────────────────────────────────────────────
echo ""
if [[ "$ERRORS" -gt 0 ]]; then
    echo "  PRE-PUSH FAILED — $ERRORS error(s) found. Fix and retry."
    echo "  Emergency bypass: git push --no-verify"
    echo ""
    exit 1
else
    echo "  PRE-PUSH OK — all checks passed."
    echo ""
    exit 0
fi
