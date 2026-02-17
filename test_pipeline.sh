#!/bin/bash

# ============================================================================
# ECS160 HW2 Grading Script
# Aligned with rubric in Homework-2.md (7 points total)
#
# Rubric:
#   1. Moderation microservice correctly filters posts:              1 point
#   2. Hashtagging microservice generates hashtags via Gemini:       1 point
#   3. gRPC proto definition and code generation:                    1 point
#   4. gRPC communication between microservices works correctly:     1 point
#   5. Pipeline produces correct output for top-10 posts & replies:  1 point
#   6. Unit tests with proper mocking:                               1 point
#   7. Code quality and project organization:                        1 point
# ============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ── Per-rubric-item scoring ──
declare -a RUBRIC_PASS RUBRIC_TOTAL
RUBRIC_NAMES=(
    "Moderation microservice correctly filters posts"
    "Hashtagging microservice generates hashtags via Gemini"
    "gRPC proto definition and code generation"
    "gRPC communication between microservices works correctly"
    "Pipeline produces correct output for top-10 posts and replies"
    "Unit tests with proper mocking"
    "Code quality and project organization"
)
for i in {0..6}; do
    RUBRIC_PASS[$i]=0
    RUBRIC_TOTAL[$i]=0
done
CURRENT_RUBRIC=0

echo "=== ECS160 HW2 Grading Script ==="
echo "=== Total: 7 points ==="
echo ""

# ── Helpers ──
rpass() {
    echo "  PASS: $1"
    RUBRIC_PASS[$CURRENT_RUBRIC]=$(( ${RUBRIC_PASS[$CURRENT_RUBRIC]} + 1 ))
    RUBRIC_TOTAL[$CURRENT_RUBRIC]=$(( ${RUBRIC_TOTAL[$CURRENT_RUBRIC]} + 1 ))
}

rfail() {
    echo "  FAIL: $1"
    RUBRIC_TOTAL[$CURRENT_RUBRIC]=$(( ${RUBRIC_TOTAL[$CURRENT_RUBRIC]} + 1 ))
}

# Cleanup background processes on exit
cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    [ -n "$HASHTAGGING_PID" ] && kill "$HASHTAGGING_PID" 2>/dev/null
    [ -n "$MODERATION_PID" ] && kill "$MODERATION_PID" 2>/dev/null
    wait 2>/dev/null
}
trap cleanup EXIT

# ─────────────────────────────────────────────
# ENVIRONMENT SETUP (prerequisite, no points)
# ─────────────────────────────────────────────
echo "--- Environment Setup ---"

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "  ERROR: GOOGLE_API_KEY is not set. Set it before running."
    exit 1
fi
echo "  OK: GOOGLE_API_KEY is set"

if ! command -v python3 &>/dev/null; then
    echo "  ERROR: python3 not found"
    exit 1
fi
echo "  OK: python3 available ($(python3 --version 2>&1))"

if [ ! -f "input.csv" ]; then
    echo "  ERROR: input.csv not found"
    exit 1
fi
echo "  OK: input.csv exists"

# Set up virtual environment
if [ ! -d "venv" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate
pip install -q -r requirements.txt 2>/dev/null
echo "  OK: Virtual environment and dependencies ready"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 3: gRPC Proto Definition and Code Generation (1 point)
#   Static checks — no services need to be running.
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=2
echo "--- Rubric 3: gRPC Proto Definition and Code Generation (1 pt) ---"

# Locate .proto file
PROTO_FILE=$(find . -name "*.proto" -not -path "./venv/*" 2>/dev/null | head -1)
if [ -n "$PROTO_FILE" ]; then
    rpass "Proto file found: $PROTO_FILE"
else
    rfail "No .proto file found"
fi

# Validate proto contents
if [ -n "$PROTO_FILE" ]; then
    if grep -q "service" "$PROTO_FILE" 2>/dev/null; then
        rpass "Proto defines a gRPC service"
    else
        rfail "Proto does not define a gRPC service"
    fi

    if grep -q "rpc" "$PROTO_FILE" 2>/dev/null; then
        rpass "Proto defines an RPC method"
    else
        rfail "Proto does not define an RPC method"
    fi

    if grep -q "message" "$PROTO_FILE" 2>/dev/null; then
        rpass "Proto defines message types"
    else
        rfail "Proto does not define message types"
    fi
fi

# Check for generated protobuf/gRPC stubs
PB2_COUNT=$(find . -name "*_pb2.py" -not -path "./venv/*" 2>/dev/null | wc -l | tr -d ' ')
PB2_GRPC_COUNT=$(find . -name "*_pb2_grpc.py" -not -path "./venv/*" 2>/dev/null | wc -l | tr -d ' ')

if [ "$PB2_COUNT" -gt 0 ]; then
    rpass "Generated protobuf Python files found ($PB2_COUNT file(s))"
else
    rfail "No generated *_pb2.py files found"
fi

if [ "$PB2_GRPC_COUNT" -gt 0 ]; then
    rpass "Generated gRPC Python stubs found ($PB2_GRPC_COUNT file(s))"
else
    rfail "No generated *_pb2_grpc.py files found"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 7: Code Quality and Project Organization (1 point)
#   Static checks — no services need to be running.
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=6
echo "--- Rubric 7: Code Quality and Project Organization (1 pt) ---"

# Separate directories for each component
MOD_DIR=$(find . -maxdepth 2 -type d -name "*moderat*" -not -path "./venv/*" 2>/dev/null | head -1)
HASH_DIR=$(find . -maxdepth 2 -type d -name "*hashtag*" -not -path "./venv/*" 2>/dev/null | head -1)
CLIENT_DIR=$(find . -maxdepth 2 -type d -name "*client*" -not -path "./venv/*" 2>/dev/null | head -1)

if [ -n "$MOD_DIR" ]; then
    rpass "Moderation service directory exists: $MOD_DIR"
else
    rfail "No moderation service directory found"
fi

if [ -n "$HASH_DIR" ]; then
    rpass "Hashtagging service directory exists: $HASH_DIR"
else
    rfail "No hashtagging service directory found"
fi

if [ -n "$CLIENT_DIR" ]; then
    rpass "Client directory exists: $CLIENT_DIR"
else
    rfail "No client directory found"
fi

if [ -f "requirements.txt" ]; then
    rpass "requirements.txt exists"
else
    rfail "requirements.txt missing"
fi

README=$(find . -maxdepth 1 -iname "readme*" 2>/dev/null | head -1)
if [ -n "$README" ]; then
    rpass "README found"
else
    rfail "README missing"
fi

echo "  NOTE: Manual review recommended for code style and documentation quality."
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 6: Unit Tests with Proper Mocking (1 point)
#   Runs pytest — services should NOT be needed if tests are properly mocked.
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=5
echo "--- Rubric 6: Unit Tests with Proper Mocking (1 pt) ---"

# Locate test files
TEST_FILES=$(find . -name "test_*.py" -o -name "*_test.py" | grep -v venv | grep -v __pycache__)
TEST_COUNT=0
if [ -n "$TEST_FILES" ]; then
    TEST_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
fi

if [ "$TEST_COUNT" -gt 0 ]; then
    rpass "Found $TEST_COUNT test file(s)"
    echo "$TEST_FILES" | while read -r f; do echo "    - $f"; done
else
    rfail "No test files found (test_*.py or *_test.py)"
fi

# Check for mocking usage
if [ -n "$TEST_FILES" ]; then
    MOCK_FILES=$(echo "$TEST_FILES" | xargs grep -l "mock\|Mock\|patch\|MagicMock" 2>/dev/null || true)
    if [ -n "$MOCK_FILES" ]; then
        rpass "Tests use mocking (mock/patch/MagicMock found)"
    else
        rfail "Tests do not appear to use mocking"
    fi
fi

# Run pytest
if [ "$TEST_COUNT" -gt 0 ]; then
    echo "  Running pytest..."
    PYTEST_OUTPUT=$(python3 -m pytest $TEST_FILES -v 2>&1)
    PYTEST_EXIT=$?

    if [ $PYTEST_EXIT -eq 0 ]; then
        rpass "All unit tests pass"
    else
        rfail "Some unit tests failed (exit code: $PYTEST_EXIT)"
        echo "$PYTEST_OUTPUT" | tail -20
    fi

    # Check sufficient coverage (at least 4 test cases)
    NUM_TESTS=$(echo "$PYTEST_OUTPUT" | grep -o '[0-9]* passed' | grep -o '[0-9]*' || echo "0")
    if [ -n "$NUM_TESTS" ] && [ "$NUM_TESTS" -ge 4 ]; then
        rpass "Sufficient test coverage ($NUM_TESTS tests)"
    else
        rfail "Insufficient test coverage (${NUM_TESTS:-0} tests, expected >= 4)"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# START SERVICES (prerequisite for rubric items 1, 2, 4, 5)
# ─────────────────────────────────────────────────────────────────────────────
echo "--- Starting Services ---"

SERVICES_STARTED=true

# Discover service files
HASHTAGGING_PY=$(find . -name "*hashtagging*service*.py" -not -path "./venv/*" \
    -not -name "test_*" -not -name "*_pb2*" 2>/dev/null | head -1)
MODERATION_PY=$(find . -name "*moderat*service*.py" -not -path "./venv/*" \
    -not -name "test_*" -not -name "*_pb2*" 2>/dev/null | head -1)

# Start Hashtagging Service (gRPC server)
if [ -n "$HASHTAGGING_PY" ]; then
    HASH_SERVICE_DIR=$(dirname "$HASHTAGGING_PY")
    HASH_SERVICE_FILE=$(basename "$HASHTAGGING_PY")
    cd "$HASH_SERVICE_DIR"
    python3 "$HASH_SERVICE_FILE" > /tmp/hashtagging_service.log 2>&1 &
    HASHTAGGING_PID=$!
    cd "$SCRIPT_DIR"
    sleep 2

    if ps -p $HASHTAGGING_PID > /dev/null 2>&1; then
        echo "  OK: Hashtagging service started (PID: $HASHTAGGING_PID)"
    else
        echo "  ERROR: Hashtagging service failed to start"
        cat /tmp/hashtagging_service.log 2>/dev/null
        SERVICES_STARTED=false
    fi
else
    echo "  ERROR: Hashtagging service file not found"
    SERVICES_STARTED=false
fi

# Start Moderation Service (FastAPI)
if [ -n "$MODERATION_PY" ]; then
    MOD_SERVICE_DIR=$(dirname "$MODERATION_PY")
    MOD_MODULE=$(basename "$MODERATION_PY" .py)
    cd "$MOD_SERVICE_DIR"
    uvicorn "${MOD_MODULE}:app" --port 8001 > /tmp/moderation_service.log 2>&1 &
    MODERATION_PID=$!
    cd "$SCRIPT_DIR"

    # Wait for moderation service to be ready
    MAX_RETRIES=10
    RETRY_COUNT=0
    MODERATION_READY=false
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        sleep 1
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/docs 2>/dev/null | grep -q "200"; then
            MODERATION_READY=true
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done

    if $MODERATION_READY && ps -p $MODERATION_PID > /dev/null 2>&1; then
        echo "  OK: Moderation service started and ready (PID: $MODERATION_PID)"
    else
        echo "  ERROR: Moderation service failed to start or become ready"
        cat /tmp/moderation_service.log 2>/dev/null
        SERVICES_STARTED=false
    fi
else
    echo "  ERROR: Moderation service file not found"
    SERVICES_STARTED=false
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 1: Moderation Microservice Correctly Filters Posts (1 point)
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=0
echo "--- Rubric 1: Moderation Microservice Correctly Filters Posts (1 pt) ---"

if ! $SERVICES_STARTED; then
    rfail "Services not running — cannot test moderation"
else
    # Clean post should pass moderation
    RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "What a beautiful sunny day outside!"}')
    RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)

    if [ "$RESULT" != "FAILED" ] && [ -n "$RESULT" ]; then
        rpass "Clean post passes moderation"
    else
        rfail "Clean post did not pass moderation (got: $RESULT)"
    fi

    # Each banned word should be caught
    BANNED_WORDS=("illegal" "fraud" "scam" "exploit" "dox" "swatting" "hack" "crypto" "bots")
    BANNED_PASS=0
    BANNED_TOTAL=${#BANNED_WORDS[@]}

    for WORD in "${BANNED_WORDS[@]}"; do
        RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
            -H "Content-Type: application/json" \
            -d "{\"post_content\": \"This post contains the word $WORD in it\"}")
        RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)
        if [ "$RESULT" = "FAILED" ]; then
            BANNED_PASS=$((BANNED_PASS + 1))
        else
            echo "    missed: '$WORD' was not blocked (got: $RESULT)"
        fi
    done

    if [ "$BANNED_PASS" -eq "$BANNED_TOTAL" ]; then
        rpass "All $BANNED_TOTAL banned words correctly blocked"
    else
        rfail "Only $BANNED_PASS/$BANNED_TOTAL banned words blocked"
    fi

    # Case-insensitive detection
    RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "HACK the planet"}')
    RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)
    if [ "$RESULT" = "FAILED" ]; then
        rpass "Banned word detection is case-insensitive"
    else
        rfail "Banned word detection is not case-insensitive (HACK was not caught)"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 2: Hashtagging Microservice Generates Hashtags via Gemini (1 point)
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=1
echo "--- Rubric 2: Hashtagging Microservice Generates Hashtags via Gemini (1 pt) ---"

if ! $SERVICES_STARTED; then
    rfail "Services not running — cannot test hashtagging"
else
    # First clean post
    RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "Just hiked to the top of the mountain at sunrise!"}')
    RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)

    if [[ "$RESULT" == \#* ]]; then
        rpass "Returns a valid hashtag ($RESULT)"
    else
        rfail "Did not return a valid hashtag (got: $RESULT)"
    fi

    # Hashtag should be a single token (no spaces)
    if [ -n "$RESULT" ] && [[ "$RESULT" != *" "* ]]; then
        rpass "Hashtag is a single token (no spaces)"
    else
        rfail "Hashtag contains spaces or is empty: '$RESULT'"
    fi

    # Second clean post — verify LLM generates different hashtags
    RESPONSE2=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "My homemade pasta turned out incredible tonight"}')
    RESULT2=$(echo "$RESPONSE2" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)

    if [[ "$RESULT2" == \#* ]]; then
        rpass "Second post also returns a hashtag ($RESULT2)"
    else
        rfail "Second post did not return a hashtag (got: $RESULT2)"
    fi

    # Verify the hashtagging service code uses Gemini / an LLM client
    if [ -n "$HASHTAGGING_PY" ]; then
        if grep -qE "genai|gemini|generate_content|GenerativeModel" "$HASHTAGGING_PY" 2>/dev/null; then
            rpass "Hashtagging service code integrates with Gemini"
        else
            rfail "Hashtagging service does not appear to use Gemini"
        fi
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 4: gRPC Communication Between Microservices Works Correctly (1 point)
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=3
echo "--- Rubric 4: gRPC Communication Between Microservices (1 pt) ---"

if ! $SERVICES_STARTED; then
    rfail "Services not running — cannot test gRPC communication"
else
    # End-to-end: clean post flows HTTP -> moderation -> gRPC -> hashtagging -> back
    RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "The sunset over the ocean was absolutely breathtaking today"}')
    RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)

    if [[ "$RESULT" == \#* ]]; then
        rpass "End-to-end chain works: moderation -> gRPC -> hashtagging ($RESULT)"
    else
        rfail "End-to-end chain failed (got: $RESULT)"
    fi

    # Banned post should be blocked before reaching hashtagging via gRPC
    RESPONSE=$(curl -s -X POST "http://localhost:8001/moderate" \
        -H "Content-Type: application/json" \
        -d '{"post_content": "This crypto scheme is terrible"}')
    RESULT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null)

    if [ "$RESULT" = "FAILED" ]; then
        rpass "Moderation blocks before gRPC call for banned content"
    else
        rfail "Moderation did not block before gRPC call (got: $RESULT)"
    fi

    # Verify moderation service code uses gRPC client stubs
    if [ -n "$MODERATION_PY" ]; then
        if grep -qE "grpc|pb2_grpc|insecure_channel|Stub" "$MODERATION_PY" 2>/dev/null; then
            rpass "Moderation service code uses gRPC client"
        else
            rfail "Moderation service code does not appear to use gRPC"
        fi
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RUBRIC 5: Pipeline Produces Correct Output for Top-10 Posts & Replies (1 pt)
# ─────────────────────────────────────────────────────────────────────────────
CURRENT_RUBRIC=4
echo "--- Rubric 5: Pipeline Produces Correct Output for Top-10 Posts and Replies (1 pt) ---"

if ! $SERVICES_STARTED; then
    rfail "Services not running — cannot test pipeline"
else
    # Find client entry point
    CLIENT_MAIN=$(find . -path "*/client*/main.py" -not -path "./venv/*" 2>/dev/null | head -1)
    if [ -z "$CLIENT_MAIN" ]; then
        CLIENT_MAIN=$(find . -name "main.py" -not -path "./venv/*" 2>/dev/null | head -1)
    fi

    if [ -n "$CLIENT_MAIN" ]; then
        CLIENT_MAIN_DIR=$(dirname "$CLIENT_MAIN")
        cd "$CLIENT_MAIN_DIR"
        CLIENT_OUTPUT=$(python3 main.py "$SCRIPT_DIR/input.csv" 2>&1)
        CLIENT_EXIT=$?
        cd "$SCRIPT_DIR"

        if [ $CLIENT_EXIT -eq 0 ]; then
            rpass "Client exited successfully"
        else
            rfail "Client exited with error (code: $CLIENT_EXIT)"
        fi

        # Verify 10 posts are processed
        POST_COUNT=$(echo "$CLIENT_OUTPUT" | grep -ciE "^---.*post|^post [0-9]" || echo "0")
        if [ "$POST_COUNT" -eq 10 ]; then
            rpass "Exactly 10 posts processed"
        elif [ "$POST_COUNT" -gt 0 ]; then
            rfail "Processed $POST_COUNT posts (expected 10)"
        else
            rfail "Could not identify 10 processed posts in output"
        fi

        # Verify output contains hashtags
        HASHTAG_COUNT=$(echo "$CLIENT_OUTPUT" | grep -c "#" || echo "0")
        if [ "$HASHTAG_COUNT" -gt 0 ]; then
            rpass "Output contains hashtags ($HASHTAG_COUNT lines)"
        else
            rfail "Output contains no hashtags"
        fi

        # Check for [DELETED] handling (banned-word posts should appear as [DELETED])
        if echo "$CLIENT_OUTPUT" | grep -qi "\[DELETED\]"; then
            rpass "Output shows [DELETED] for moderated posts"
        else
            echo "  NOTE: No [DELETED] entries found (may be expected if top-10 have no banned words)"
        fi

        # Check for reply handling (lines with --> prefix)
        if echo "$CLIENT_OUTPUT" | grep -q "^-->"; then
            rpass "Output includes replies with --> prefix"
        else
            echo "  NOTE: No reply indicators (-->) found in output"
        fi

        # Print full client output for manual review
        echo ""
        echo "  --- Client Output (for manual review) ---"
        echo "$CLIENT_OUTPUT" | sed 's/^/  | /'
        echo "  --- End Client Output ---"
    else
        rfail "Client main.py not found"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SERVICE LOGS (for reference)
# ─────────────────────────────────────────────────────────────────────────────
echo "--- Service Logs (for reference) ---"
echo ""
echo "Moderation Service (last 5 lines):"
tail -5 /tmp/moderation_service.log 2>/dev/null || echo "  (no log)"
echo ""
echo "Hashtagging Service (last 5 lines):"
tail -5 /tmp/hashtagging_service.log 2>/dev/null || echo "  (no log)"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SCORE
# ─────────────────────────────────────────────────────────────────────────────
echo "=========================================="
echo "         GRADING SUMMARY (7 pts)          "
echo "=========================================="
echo ""

TOTAL_SCORE="0"
for i in {0..6}; do
    P=${RUBRIC_PASS[$i]}
    T=${RUBRIC_TOTAL[$i]}
    if [ "$T" -eq 0 ]; then
        SCORE="0.0"
    else
        SCORE=$(awk "BEGIN { r=$P/$T; if (r >= 1.0) print 1.0; else if (r >= 0.5) print 0.5; else print 0.0 }")
    fi
    TOTAL_SCORE=$(awk "BEGIN { printf \"%.1f\", $TOTAL_SCORE + $SCORE }")
    printf "  Rubric %d: %s / 1  (%d/%d checks)  %s\n" "$((i+1))" "$SCORE" "$P" "$T" "${RUBRIC_NAMES[$i]}"
done

echo ""
echo "=========================================="
printf "  TOTAL SCORE: %s / 7\n" "$TOTAL_SCORE"
echo "=========================================="
echo ""
echo "NOTE: Rubric 7 (Code Quality) score above is based on automated checks only."
echo "      Manual review is recommended for code style and documentation."

echo "=== Script generated by Claude Code using Claude Sonnet 4.5 (please report any errors to the instructor) ==="
