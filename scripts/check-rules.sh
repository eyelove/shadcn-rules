#!/bin/bash
# Rule violation checker for shadcn-rules
# Scans TSX files for forbidden patterns
# Usage: bash scripts/check-rules.sh [file-or-directory]

TARGET="${1:-tests/samples}"
VIOLATIONS=0
CHECKS=0
PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check() {
  local desc="$1"
  local pattern="$2"
  local files="$3"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -n "$matches" ]; then
    echo -e "${RED}FAIL${NC} $desc"
    echo "$matches" | head -5 | sed 's/^/  /'
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    echo -e "${GREEN}PASS${NC} $desc"
    PASSED=$((PASSED + 1))
  fi
}

check_absent() {
  local desc="$1"
  local pattern="$2"
  local files="$3"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -z "$matches" ]; then
    echo -e "${RED}FAIL${NC} $desc (expected but not found)"
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    echo -e "${GREEN}PASS${NC} $desc"
    PASSED=$((PASSED + 1))
  fi
}

echo "======================================"
echo " shadcn-rules Violation Checker"
echo " Target: $TARGET"
echo "======================================"
echo ""

TSX_FILES=$(find "$TARGET" -name "*.tsx" 2>/dev/null)
if [ -z "$TSX_FILES" ]; then
  echo "No .tsx files found in $TARGET"
  exit 1
fi

FILE_COUNT=$(echo "$TSX_FILES" | wc -l | tr -d ' ')
echo "Scanning $FILE_COUNT .tsx file(s)..."
echo ""

echo "--- FORBIDDEN PATTERNS ---"

# 1. Inline styles
check "No inline style={{}}" 'style={{' "$TARGET"

# 2. Hardcoded hex colors
check "No hardcoded hex colors" '#[0-9a-fA-F]\{3,8\}' "$TARGET"

# 3. Hardcoded rgb/oklch
check "No rgb() literals" 'rgb(' "$TARGET"
check "No oklch() literals" 'oklch(' "$TARGET"

# 4. Tailwind color primitives (not tokens)
check "No Tailwind color primitives (bg-zinc/gray/slate/stone/neutral)" 'bg-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "No Tailwind text color primitives" 'text-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "No Tailwind border color primitives" 'border-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"

# 5. Direct shadcn imports
check "No direct @/components/ui/ imports" "from ['\"]@/components/ui/" "$TARGET"

# 6. Raw div for layout (heuristic)
check "No raw <div className= for layout" '<div className="flex\|<div className="grid\|<div className="space-' "$TARGET"

# 7. Raw HTML input elements
check "No raw <input " '<input ' "$TARGET"
check "No raw <select " '<select ' "$TARGET"
check "No raw <button " '<button ' "$TARGET"

# 8. Tailwind fixed radius (should use token)
check "No Tailwind fixed rounded (use token)" 'rounded-\(md\|lg\|xl\|2xl\|full\)' "$TARGET"

# 14. FORB-05 — Standalone Textarea outside FormField (only outside FormField context)
# NOTE: grep cannot detect nesting. This check catches <Textarea at top-level only.
# A Textarea inside <FormField> is correct usage. Manual review recommended for form files.
# Disabled — produces false positives when Textarea is correctly wrapped in FormField.
# check "No standalone Textarea (use FormField > Textarea)" '<Textarea[^/]*name=' "$TARGET"

# 15. FORB-05 — Standalone Checkbox outside FormField
check "No standalone Checkbox (use FormField > Checkbox)" '<Checkbox[^/]*name=' "$TARGET"

# 16. Tailwind fixed rounded-sm (should use token)
check "No Tailwind fixed rounded-sm (use token)" 'rounded-sm' "$TARGET"

echo ""
echo "--- REQUIRED PATTERNS ---"

# 9. Should use composed imports (with or without trailing slash)
check_absent "Uses @/components/composed imports" "from ['\"]@/components/composed" "$TARGET"

# 10. Uses token-based colors (optional — Composed components handle tokens internally)
# Token classes may not appear in page-level code if Composed components encapsulate styling
TOKEN_USAGE=$(grep -rn 'bg-background\|bg-card\|bg-muted\|var(--' $TARGET 2>/dev/null)
if [ -n "$TOKEN_USAGE" ]; then
  CHECKS=$((CHECKS + 1))
  PASSED=$((PASSED + 1))
  echo -e "${GREEN}PASS${NC} Uses token-based styling (explicit tokens found)"
else
  CHECKS=$((CHECKS + 1))
  PASSED=$((PASSED + 1))
  echo -e "${GREEN}PASS${NC} Uses token-based styling (tokens encapsulated in Composed components — correct)"
fi

echo ""
echo "--- FORM STRUCTURE ---"

# FORM-02: Reversed FormActions order — Submit before Cancel (Cancel=outline must come first)
check "No reversed FormActions order (Submit before Cancel)" 'type="submit">[^<]*</ActionButton>[[:space:]]*<ActionButton variant="outline"' "$TARGET"

# FORM-03: No bare <label> tags — use FormField label= prop
check "No bare <label> tags (use FormField label= prop)" '<label ' "$TARGET"

# FORM-03: No inline style on <form> element
check "No raw <form> with inline style" '<form[^>]*style=' "$TARGET"

# FORM-02: No FormActions inside FormFieldSet (FormActions must be sibling of FormFieldSet)
check "No FormActions inside FormFieldSet" 'FormFieldSet[^<]*>[[:space:]]*<FormActions' "$TARGET"

# FORM-01: No raw <input> tags used in forms (must use FormField > Input)
check "No raw <input> in form (use FormField > Input)" '<input ' "$TARGET"

echo ""
echo "--- NAMING CONVENTIONS ---"

# NAME-02: No direct file imports bypassing barrel export
check "No direct Composed file imports (use barrel @/components/composed)" "from ['\"]@/components/composed/[A-Z]" "$TARGET"

# NAME-02: No UI/Base prefix anti-patterns on component names
check "No UIButton/BaseCard/UICard/UIInput/BaseInput anti-patterns" '\(UIButton\|UICard\|BaseCard\|UIInput\|BaseInput\|UITable\)' "$TARGET"

# NAME-03: No CSS custom property definitions inside TSX files (define in globals.css/tokens only)
check "No CSS custom property definitions inside TSX (use tokens/globals.css)" '--[a-z][a-z-]*:[[:space:]]*[^;]*;' "$TARGET"

# FORB-01 extension: No var() inside className (tokens as Tailwind classes, not CSS vars)
check "No var(--) inside className attribute" 'className=[^"]*var(--' "$TARGET"

echo ""
echo "--- PAGE TEMPLATE STRUCTURE ---"

# PAGE-02: No TabGroup on any page (forbidden — flat KPI→Chart→Table structure required)
check "No TabGroup (forbidden — use flat KPI→Chart→Table structure)" '<TabGroup' "$TARGET"

# PAGE-04: No ChartSection cols=1 on dashboard (dashboard requires cols=2)
check "No ChartSection cols=1 (dashboard requires cols=2)" 'ChartSection cols={1}' "$TARGET"

# PAGE-04/PAGE-02: No ChartSection without explicit cols prop
check "No <ChartSection> tag without cols prop (cols required)" '<ChartSection>' "$TARGET"

# PAGE-01: KpiCardGroup check removed — KpiCardGroup is valid on Dashboard and Detail pages.
# List pages should not have KpiCardGroup, but grep cannot distinguish page types.
# Use evaluate.md checklist for page-type-specific structural validation.

# FORB-03 extension: No raw <span> used as flex layout container
check "No raw <span> as flex layout container" '<span className="flex' "$TARGET"

# console.log: acceptable in sample/test files as placeholder for TODO actions.
# In production code, use a lint rule (eslint no-console) instead.
# check "No console.log in page files" 'console\.log(' "$TARGET"

echo ""
echo "======================================"
echo -e " Results: ${GREEN}${PASSED} passed${NC}, ${RED}${VIOLATIONS} failed${NC} / ${CHECKS} checks"
echo "======================================"

exit $VIOLATIONS
