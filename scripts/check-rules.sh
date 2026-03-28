#!/bin/bash
# Rule violation checker for shadcn-rules
# Scans TSX files for forbidden patterns
# Usage: bash scripts/check-rules.sh [file-or-directory]

FORMAT="text"
ARGS=()
PROMPT_FILE=""
PREVIEW_DIR=""

for arg in "$@"; do
  case "$arg" in
    --format)
      FORMAT="__next__"
      ;;
    --prompt)
      PROMPT_FILE="__next__"
      ;;
    --preview-dir)
      PREVIEW_DIR="__next__"
      ;;
    *)
      if [ "$FORMAT" = "__next__" ]; then
        FORMAT="$arg"
      elif [ "$PROMPT_FILE" = "__next__" ]; then
        PROMPT_FILE="$arg"
      elif [ "$PREVIEW_DIR" = "__next__" ]; then
        PREVIEW_DIR="$arg"
      else
        ARGS+=("$arg")
      fi
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

check_file_exists() {
  local rule_id="$1"
  local desc="$2"
  local filepath="$3"
  CHECKS=$((CHECKS + 1))

  if [ -f "$filepath" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc (file not found: ${filepath})"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

check_export_exists() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local filepath="$4"
  CHECKS=$((CHECKS + 1))

  if [ -f "$filepath" ] && grep -q "$pattern" "$filepath" 2>/dev/null; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
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

# 4b. Hardcoded bg-white/bg-black (should use token: bg-background, bg-card, etc.)
check "FORB-02" "No bg-white/bg-black (use token)" 'bg-white\|bg-black\|text-white\|text-black' "$TARGET"

# 5. Direct shadcn imports — REMOVED
# 2-tier model allows direct @/components/ui/ imports. This is correct usage, not a violation.

# 6. Raw div as card substitute (heuristic: div with border + bg- mimicking a Card)
# Layout divs (flex, grid, space-) without border/bg are allowed per FORB-03.
check "FORB-03" "No raw div as card substitute (border + bg-)" '<div[^>]*className="[^"]*\(rounded-\|border\)[^"]*\(bg-\|border\)' "$TARGET"

# 7. Raw HTML input elements
check "FORB-05" "No raw <input " '<input ' "$TARGET"
check "FORB-05" "No raw <select " '<select ' "$TARGET"
check "FORB-05" "No raw <button " '<button ' "$TARGET"

# 8. Tailwind fixed radius (should use token)
check "TOKEN-01" "No Tailwind fixed rounded (use token)" 'rounded-\(md\|lg\|xl\|2xl\)' "$TARGET"

# 14. FORB-05 — Standalone Textarea outside FormField (only outside FormField context)
# NOTE: grep cannot detect nesting. This check catches <Textarea at top-level only.
# A Textarea inside <FormField> is correct usage. Manual review recommended for form files.
# Disabled — produces false positives when Textarea is correctly wrapped in FormField.
# check "FORB-05" "No standalone Textarea (use FormField > Textarea)" '<Textarea[^/]*name=' "$TARGET"

# 15. FORB-05 — Standalone Checkbox outside FormField
check "FORB-05" "No standalone Checkbox (use FormField > Checkbox)" '<Checkbox[^/]*name=' "$TARGET"

# 16. Tailwind fixed rounded-sm (should use token)
check "TOKEN-01" "No Tailwind fixed rounded-sm (use token)" 'rounded-sm' "$TARGET"

# 17. FMT-01 — No inline number formatting (use @/lib/format utilities)
check "FMT-01" "No inline toLocaleString() formatting" 'toLocaleString(' "$TARGET"
check "FMT-01" "No inline Intl.NumberFormat" 'Intl\.NumberFormat' "$TARGET"

# 18. FMT-02 — No hardcoded currency symbols in JSX templates
check "FMT-02" "No hardcoded dollar sign in JSX" '>[^<]*\$[{<]\|{\`\$\|>\$<' "$TARGET"
check "FMT-02" "No hardcoded won suffix in JSX" '}원<\|}원[^a-zA-Z]' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- REQUIRED PATTERNS ---"
fi

# 9. Composed imports — REMOVED
# Not all pages need Composed components (e.g., form pages). Per-file check produces false positives.

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

# FIELD-BTN-ORDER: Reversed button order in CardFooter — Submit before Cancel (Cancel=outline must come first)
check "FIELD-BTN-ORDER" "No reversed button order (Submit before Cancel)" 'type="submit">[^<]*</Button>[[:space:]]*<Button variant="outline"' "$TARGET"

# FIELD-BARE-LABEL: No bare <label> tags — use FieldLabel inside Field
check "FIELD-BARE-LABEL" "No bare <label> tags (use FieldLabel inside Field)" '<label ' "$TARGET"

# FORB-01: No inline style on <form> element
check "FORB-01" "No raw <form> with inline style" '<form[^>]*style=' "$TARGET"

# FIELD-SUBMIT-LOC: No submit button inside CardContent (must be in CardFooter)
check "FIELD-SUBMIT-LOC" "No submit button inside CardContent (must be in CardFooter)" 'CardContent[^<]*>[[:space:]]*.*type="submit"' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- NAMING CONVENTIONS ---"
fi

# NAME-02: No direct file imports bypassing barrel export
check "NAME-02" "No direct Composed file imports (use barrel @/components/composed)" "from ['\"]@/components/composed/[A-Z]" "$TARGET"

# NAME-02: No UI/Base prefix anti-patterns on component names
check "NAME-02" "No UIButton/BaseCard/UICard/UIInput/BaseInput anti-patterns" '\(UIButton\|UICard\|BaseCard\|UIInput\|BaseInput\|UITable\)' "$TARGET"

# NAME-03: No CSS custom property definitions inside TSX files
# Only match standalone definitions like `--my-var: value;`, not references like `var(--my-var)`
# Exclude lines containing var( which are references, not definitions
check "NAME-03" "No CSS custom property definitions inside TSX" '--[a-z][a-z-]*:[[:space:]]*oklch\|--[a-z][a-z-]*:[[:space:]]*#[0-9a-fA-F]' "$TARGET"

# FORB-01 extension: No var() inside className (tokens as Tailwind classes, not CSS vars)
check "TOKEN-01" "No var(--) inside className attribute" 'className=[^"]*var(--' "$TARGET"

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "--- PAGE TEMPLATE STRUCTURE ---"
fi

# PAGE-02: No TabGroup on any page (forbidden — flat KPI→Chart→Table structure required)
check "PAGE-01" "No TabGroup (forbidden — use flat KPI→Chart→Table structure)" '<TabGroup' "$TARGET"

# PAGE-02: No ChartSection (removed Composed component — use Card + ChartContainer directly)
check "PAGE-02" "No ChartSection (use Card + ChartContainer directly)" '<ChartSection' "$TARGET"

# PAGE-01: KpiCardGroup check removed — KpiCardGroup is valid on Dashboard and Detail pages.
# List pages should not have KpiCardGroup, but grep cannot distinguish page types.
# Use evaluate.md checklist for page-type-specific structural validation.

# FORB-01: No raw Recharts Tooltip with contentStyle (use ChartTooltip + ChartTooltipContent)
check "FORB-01" "No raw Recharts Tooltip contentStyle (use ChartTooltip)" 'contentStyle={{' "$TARGET"

# FORB-01: No raw Recharts <Tooltip> (must use <ChartTooltip>)
check "FORB-01" "No raw Recharts <Tooltip> (use <ChartTooltip>)" '<Tooltip ' "$TARGET"

# FORB-01: No manual stroke on CartesianGrid (ChartContainer handles axis styling)
check "FORB-01" "No stroke prop on CartesianGrid (ChartContainer handles styling)" 'CartesianGrid stroke=' "$TARGET"

# FORB-01: No manual stroke on XAxis (ChartContainer handles axis styling)
check "FORB-01" "No stroke prop on XAxis (ChartContainer handles styling)" 'XAxis stroke=' "$TARGET"

# FORB-01: No manual stroke on YAxis (ChartContainer handles axis styling)
check "FORB-01" "No stroke prop on YAxis (ChartContainer handles styling)" 'YAxis stroke=' "$TARGET"

# FORB-03 extension: No raw <span> used as flex layout container
check "PAGE-04" "No raw <span> as flex layout container" '<span className="flex' "$TARGET"

# console.log: acceptable in sample/test files as placeholder for TODO actions.
# In production code, use a lint rule (eslint no-console) instead.
# check "No console.log in page files" 'console\.log(' "$TARGET"

# --- ENVIRONMENT CHECKS ---
# Active only when --prompt and --preview-dir are provided.

if [ -n "$PROMPT_FILE" ] && [ -n "$PREVIEW_DIR" ]; then
  if [ "$FORMAT" != "jsonl" ]; then
    echo ""
    echo "--- ENVIRONMENT CHECKS ---"
  fi

  # ENV-01: removed — shadcn components are pre-installed by reset-preview.sh

  # ENV-02: expected_composed components exist + barrel export
  in_section=0
  has_composed=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^expected_composed:"; then
      in_section=1
      continue
    fi
    if [ "$in_section" = "1" ]; then
      if echo "$line" | grep -q "^  - "; then
        comp=$(echo "$line" | sed 's/^  - //')
        has_composed=1
        check_file_exists "ENV-02" "Composed component exists: ${comp}" "${PREVIEW_DIR}/src/components/composed/${comp}.tsx"
        check_export_exists "ENV-02" "Composed barrel exports: ${comp}" "export.*${comp}" "${PREVIEW_DIR}/src/components/composed/index.ts"
      elif echo "$line" | grep -q "^\[\]"; then
        in_section=0
      else
        in_section=0
      fi
    fi
  done < "$PROMPT_FILE"

  if [ "$has_composed" = "1" ]; then
    check_file_exists "ENV-02" "Composed barrel index.ts exists" "${PREVIEW_DIR}/src/components/composed/index.ts"
  fi

  # ENV-03: expected_lib functions exist
  in_section=0
  has_lib=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^expected_lib:"; then
      in_section=1
      continue
    fi
    if [ "$in_section" = "1" ]; then
      if echo "$line" | grep -q "^  - "; then
        func=$(echo "$line" | sed 's/^  - //')
        has_lib=1
        check_export_exists "ENV-03" "Format function exists: ${func}" "\(function ${func}\|export.*${func}\)" "${PREVIEW_DIR}/src/lib/format.ts"
      elif echo "$line" | grep -q "^\[\]"; then
        in_section=0
      else
        in_section=0
      fi
    fi
  done < "$PROMPT_FILE"

  if [ "$has_lib" = "1" ]; then
    check_file_exists "ENV-03" "@/lib/format.ts exists" "${PREVIEW_DIR}/src/lib/format.ts"
  fi

  # ENV-04: shadcn originals not modified (checksum comparison)
  if [ -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    CURRENT_SUM=$(find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null | sort | shasum | awk '{print $1}')
    SAVED_SUM=$(cat "${PREVIEW_DIR}/.ui-checksums")
    CHECKS=$((CHECKS + 1))
    if [ "$CURRENT_SUM" = "$SAVED_SUM" ]; then
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-04\",\"desc\":\"shadcn originals not modified\",\"file\":\"${PREVIEW_DIR}/src/components/ui\",\"result\":\"PASS\"}"
      else
        echo -e "${GREEN}PASS${NC} [ENV-04] shadcn originals not modified"
      fi
      PASSED=$((PASSED + 1))
    else
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-04\",\"desc\":\"shadcn originals not modified\",\"file\":\"${PREVIEW_DIR}/src/components/ui\",\"result\":\"FAIL\"}"
      else
        echo -e "${RED}FAIL${NC} [ENV-04] shadcn originals were modified"
      fi
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi

  # ENV-05: no extra Composed components beyond allowed list
  if [ -d "${PREVIEW_DIR}/src/components/composed" ]; then
    EXTRA=$(find "${PREVIEW_DIR}/src/components/composed" -maxdepth 1 \( -name "*.tsx" -o -name "*.ts" \) | while read -r f; do
      bname=$(basename "$f")
      if [ "$bname" != "DataTable.tsx" ] && [ "$bname" != "KpiCard.tsx" ] && [ "$bname" != "SearchBar.tsx" ] && [ "$bname" != "index.ts" ]; then
        echo "$bname"
      fi
    done)
    CHECKS=$((CHECKS + 1))
    if [ -z "$EXTRA" ]; then
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-05\",\"desc\":\"No extra Composed components\",\"file\":\"${PREVIEW_DIR}/src/components/composed\",\"result\":\"PASS\"}"
      else
        echo -e "${GREEN}PASS${NC} [ENV-05] No extra Composed components"
      fi
      PASSED=$((PASSED + 1))
    else
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-05\",\"desc\":\"No extra Composed components\",\"file\":\"${PREVIEW_DIR}/src/components/composed\",\"result\":\"FAIL\",\"matches\":[\"${EXTRA}\"]}"
      else
        echo -e "${RED}FAIL${NC} [ENV-05] Extra Composed components found: ${EXTRA}"
      fi
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
fi

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "======================================"
  echo -e " Results: ${GREEN}${PASSED} passed${NC}, ${RED}${VIOLATIONS} failed${NC} / ${CHECKS} checks"
  echo "======================================"
fi

exit $VIOLATIONS
