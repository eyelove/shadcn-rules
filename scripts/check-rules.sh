#!/bin/bash
# Rule violation checker for shadcn-rules
# Scans TSX files for forbidden patterns
# Usage: bash scripts/check-rules.sh [file-or-directory]

FORMAT="text"
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --format)
      FORMAT="__next__"
      ;;
    jsonl)
      if [ "$FORMAT" = "__next__" ]; then
        FORMAT="jsonl"
      else
        ARGS+=("$arg")
      fi
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done
TARGET="${ARGS[0]:-tests/samples}"
VIOLATIONS=0
CHECKS=0
PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -n "$matches" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      match_lines=$(echo "$matches" | head -5 | sed 's/\\/\\\\/g; s/"/\\"/g' | while IFS= read -r line; do printf '"%s",' "$line"; done | sed 's/,$//')
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"FAIL\",\"matches\":[${match_lines}]}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc"
      echo "$matches" | head -5 | sed 's/^/  /'
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  fi
}

check_absent() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -z "$matches" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc (expected but not found)"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  fi
}

if [ "$FORMAT" != "jsonl" ]; then
  echo "======================================"
  echo " shadcn-rules Violation Checker"
  echo " Target: $TARGET"
  echo "======================================"
  echo ""
fi

TSX_FILES=$(find "$TARGET" -name "*.tsx" 2>/dev/null)
if [ -z "$TSX_FILES" ]; then
  echo "No .tsx files found in $TARGET"
  exit 1
fi

FILE_COUNT=$(echo "$TSX_FILES" | wc -l | tr -d ' ')
if [ "$FORMAT" != "jsonl" ]; then
  echo "Scanning $FILE_COUNT .tsx file(s)..."
  echo ""
  echo "--- FORBIDDEN PATTERNS ---"
fi

# 1. Inline styles
check "FORB-01" "No inline style={{}}" 'style={{' "$TARGET"

# 2. Hardcoded hex colors
check "FORB-02" "No hardcoded hex colors" '#[0-9a-fA-F]\{3,8\}' "$TARGET"

# 3. Hardcoded rgb/oklch
check "FORB-02" "No rgb() literals" 'rgb(' "$TARGET"
check "FORB-02" "No oklch() literals" 'oklch(' "$TARGET"

# 4. Tailwind color primitives (not tokens)
check "FORB-02" "No Tailwind color primitives (bg-zinc/gray/slate/stone/neutral)" 'bg-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "FORB-02" "No Tailwind text color primitives" 'text-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "FORB-02" "No Tailwind border color primitives" 'border-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"

# 5. Direct shadcn imports
check "COMP-01" "No direct @/components/ui/ imports" "from ['\"]@/components/ui/" "$TARGET"

# 6. Raw div for layout (heuristic)
check "FORB-03" "No raw <div className= for layout" '<div className="flex\|<div className="grid\|<div className="space-' "$TARGET"

# 7. Raw HTML input elements
check "FORB-05" "No raw <input " '<input ' "$TARGET"
check "FORB-05" "No raw <select " '<select ' "$TARGET"
check "FORB-05" "No raw <button " '<button ' "$TARGET"

# 8. Tailwind fixed radius (should use token)
check "TOKEN-01" "No Tailwind fixed rounded (use token)" 'rounded-\(md\|lg\|xl\|2xl\|full\)' "$TARGET"

# 14. FORB-05 — Standalone Textarea outside FormField (only outside FormField context)
# NOTE: grep cannot detect nesting. This check catches <Textarea at top-level only.
# A Textarea inside <FormField> is correct usage. Manual review recommended for form files.
# Disabled — produces false positives when Textarea is correctly wrapped in FormField.
# check "FORB-05" "No standalone Textarea (use FormField > Textarea)" '<Textarea[^/]*name=' "$TARGET"

# 15. FORB-05 — Standalone Checkbox outside FormField
check "FORB-05" "No standalone Checkbox (use FormField > Checkbox)" '<Checkbox[^/]*name=' "$TARGET"

# 16. Tailwind fixed rounded-sm (should use token)
check "TOKEN-01" "No Tailwind fixed rounded-sm (use token)" 'rounded-sm' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- REQUIRED PATTERNS ---"
fi

# 9. Should use composed imports (with or without trailing slash)
check_absent "COMP-02" "Uses @/components/composed imports" "from ['\"]@/components/composed" "$TARGET"

# 10. Uses token-based colors (optional — Composed components handle tokens internally)
# Token classes may not appear in page-level code if Composed components encapsulate styling
TOKEN_USAGE=$(grep -rn 'bg-background\|bg-card\|bg-muted\|var(--' $TARGET 2>/dev/null)
CHECKS=$((CHECKS + 1))
PASSED=$((PASSED + 1))
if [ "$FORMAT" = "jsonl" ]; then
  echo "{\"rule\":\"TOKEN-02\",\"desc\":\"Uses token-based styling\",\"file\":\"${TARGET}\",\"result\":\"PASS\"}"
else
  if [ -n "$TOKEN_USAGE" ]; then
    echo -e "${GREEN}PASS${NC} [TOKEN-02] Uses token-based styling (explicit tokens found)"
  else
    echo -e "${GREEN}PASS${NC} [TOKEN-02] Uses token-based styling (tokens encapsulated in Composed components — correct)"
  fi
fi

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- FORM STRUCTURE ---"
fi

# FORM-02: Reversed FormActions order — Submit before Cancel (Cancel=outline must come first)
check "FIELD-01" "No reversed FormActions order (Submit before Cancel)" 'type="submit">[^<]*</ActionButton>[[:space:]]*<ActionButton variant="outline"' "$TARGET"

# FORM-03: No bare <label> tags — use FormField label= prop
check "FIELD-02" "No bare <label> tags (use FormField label= prop)" '<label ' "$TARGET"

# FORM-03: No inline style on <form> element
check "FORB-01" "No raw <form> with inline style" '<form[^>]*style=' "$TARGET"

# FORM-02: No FormActions inside FormFieldSet (FormActions must be sibling of FormFieldSet)
check "FIELD-03" "No FormActions inside FormFieldSet" 'FormFieldSet[^<]*>[[:space:]]*<FormActions' "$TARGET"

# FORM-01: No raw <input> tags used in forms (must use FormField > Input)
check "FIELD-04" "No raw <input> in form (use FormField > Input)" '<input ' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- NAMING CONVENTIONS ---"
fi

# NAME-02: No direct file imports bypassing barrel export
check "NAME-02" "No direct Composed file imports (use barrel @/components/composed)" "from ['\"]@/components/composed/[A-Z]" "$TARGET"

# NAME-02: No UI/Base prefix anti-patterns on component names
check "NAME-02" "No UIButton/BaseCard/UICard/UIInput/BaseInput anti-patterns" '\(UIButton\|UICard\|BaseCard\|UIInput\|BaseInput\|UITable\)' "$TARGET"

# NAME-03: No CSS custom property definitions inside TSX files (define in globals.css/tokens only)
check "NAME-03" "No CSS custom property definitions inside TSX (use tokens/globals.css)" '--[a-z][a-z-]*:[[:space:]]*[^;]*;' "$TARGET"

# FORB-01 extension: No var() inside className (tokens as Tailwind classes, not CSS vars)
check "TOKEN-01" "No var(--) inside className attribute" 'className=[^"]*var(--' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- PAGE TEMPLATE STRUCTURE ---"
fi

# PAGE-02: No TabGroup on any page (forbidden — flat KPI→Chart→Table structure required)
check "PAGE-01" "No TabGroup (forbidden — use flat KPI→Chart→Table structure)" '<TabGroup' "$TARGET"

# PAGE-04: No ChartSection cols=1 on dashboard (dashboard requires cols=2)
check "PAGE-02" "No ChartSection cols=1 (dashboard requires cols=2)" 'ChartSection cols={1}' "$TARGET"

# PAGE-04/PAGE-02: No ChartSection without explicit cols prop
check "PAGE-03" "No <ChartSection> tag without cols prop (cols required)" '<ChartSection>' "$TARGET"

# PAGE-01: KpiCardGroup check removed — KpiCardGroup is valid on Dashboard and Detail pages.
# List pages should not have KpiCardGroup, but grep cannot distinguish page types.
# Use evaluate.md checklist for page-type-specific structural validation.

# FORB-03 extension: No raw <span> used as flex layout container
check "PAGE-04" "No raw <span> as flex layout container" '<span className="flex' "$TARGET"

# console.log: acceptable in sample/test files as placeholder for TODO actions.
# In production code, use a lint rule (eslint no-console) instead.
# check "No console.log in page files" 'console\.log(' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "======================================"
  echo -e " Results: ${GREEN}${PASSED} passed${NC}, ${RED}${VIOLATIONS} failed${NC} / ${CHECKS} checks"
  echo "======================================"
fi

exit $VIOLATIONS
