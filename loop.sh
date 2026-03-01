#!/bin/bash
# TF405 Ralph Loop
# Usage: ./loop.sh [options] [plan] [max_iterations]
#
# Options (must come before plan/iterations):
#   --signal PHRASE     Check agent output for PHRASE; warn if missing
#   --format FORMAT     Output format: text (default), json, stream-json
#
# Examples:
#   ./loop.sh                                   # Build mode, unlimited
#   ./loop.sh 10                                # Build mode, max 10 iterations
#   ./loop.sh plan                              # Plan mode, unlimited
#   ./loop.sh plan 3                            # Plan mode, max 3 iterations
#   ./loop.sh --signal "TASK COMPLETE" 10       # With completion signal check
#   ./loop.sh --format stream-json 5            # Stream JSON output to log
#   ./loop.sh --signal "DONE" --format json 10  # Both flags combined

# Parse optional flags
SIGNAL=""
OUTPUT_FORMAT="text"
while [[ "$1" == --* ]]; do
    case "$1" in
        --signal)  SIGNAL="$2"; shift 2 ;;
        --format)  OUTPUT_FORMAT="$2"; shift 2 ;;
        *)         echo "Unknown flag: $1"; exit 1 ;;
    esac
done

# Parse mode and iterations
if [ "$1" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
OUTFILE=".looplog.txt"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛩️  TF405 — Ralph Loop"
echo "Mode:   $MODE"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "Format: $OUTPUT_FORMAT"
[ -n "$SIGNAL" ] && echo "Signal: $SIGNAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n======================== LOOP $ITERATION ========================\n"

    # Build prompt, appending signal instruction if specified
    PROMPT=$(cat "$PROMPT_FILE")
    if [ -n "$SIGNAL" ]; then
        PROMPT="$PROMPT"$'\n\n'"Return \"$SIGNAL\" and HALT when done."
    fi

    # Run Claude Code with the prompt (log overwritten each iteration)
    : > "$OUTFILE"
    echo "$PROMPT" | claude -p \
        --dangerously-skip-permissions \
        --verbose \
        --output-format "$OUTPUT_FORMAT" \
        | tee "$OUTFILE"

    # Check for completion signal
    if [ -n "$SIGNAL" ]; then
        if grep -q "$SIGNAL" "$OUTFILE" 2>/dev/null; then
            echo ">>> Signal \"$SIGNAL\" received on iteration $ITERATION"
        else
            echo ">>> WARNING: \"$SIGNAL\" not found in output on iteration $ITERATION"
        fi
    fi

    # Push changes after each iteration (if git is set up)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || true
    fi

    echo -e "\n======================== END LOOP $ITERATION ========================\n"
done
