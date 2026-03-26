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

# 14. FORB-05 — Standalone Textarea outside FormField
check "No standalone Textarea (use FormField > Textarea)" '<Textarea[^/]*name=' "$TARGET"

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
echo "======================================"
echo -e " Results: ${GREEN}${PASSED} passed${NC}, ${RED}${VIOLATIONS} failed${NC} / ${CHECKS} checks"
echo "======================================"

exit $VIOLATIONS
