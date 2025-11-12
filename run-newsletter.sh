#!/bin/bash

# Multi-Newsletter Automation Script with Timeout and Retry
# Usage: ./run-newsletter.sh <newsletter-name>
# Example: ./run-newsletter.sh personal

# Check for newsletter name argument
if [ -z "$1" ]; then
    echo "Error: Newsletter name required"
    echo "Usage: $0 <newsletter-name>"
    echo "Example: $0 personal"
    exit 1
fi

NEWSLETTER_NAME="$1"

# Change to the script directory (project root)
cd "$(dirname "$0")"

# Validate newsletter directory exists
NEWSLETTER_DIR="newsletters/$NEWSLETTER_NAME"
if [ ! -d "$NEWSLETTER_DIR" ]; then
    echo "Error: Newsletter directory not found: $NEWSLETTER_DIR"
    echo "Available newsletters:"
    ls -d newsletters/*/ 2>/dev/null | xargs -n 1 basename || echo "  (none)"
    exit 1
fi

# Load environment variables from project root
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Path to newsletter config
CONFIG_FILE="$NEWSLETTER_DIR/config.json"

# Verify config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Read configuration from newsletter's config.json
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required to read configuration"
    exit 1
fi

# Parse configuration using Python
CONFIG=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    exec_config = config.get('execution', {})
    print(f\"{exec_config.get('timeout_minutes', 15)}\")
    print(f\"{exec_config.get('max_retries', 3)}\")
    print(f\"{exec_config.get('retry_delay_minutes', 5)}\")
except Exception as e:
    print('15')
    print('3')
    print('5')
    print(f'Warning: Could not read config: {e}', file=sys.stderr)
")

# Read configuration values
TIMEOUT_MINUTES=$(echo "$CONFIG" | sed -n '1p')
MAX_RETRIES=$(echo "$CONFIG" | sed -n '2p')
RETRY_DELAY_MINUTES=$(echo "$CONFIG" | sed -n '3p')
TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
RETRY_DELAY_SECONDS=$((RETRY_DELAY_MINUTES * 60))

# Set up paths
TODAY=$(date +%Y-%m-%d)
OUTPUT_DIR="$NEWSLETTER_DIR/output"
LOG_DIR="$NEWSLETTER_DIR/logs"
LOG_FILE="$LOG_DIR/newsletter-$TODAY.log"
TOPICS_FILE="$NEWSLETTER_DIR/topics.md"

# Create directories if they don't exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# Verify topics file exists
if [ ! -f "$TOPICS_FILE" ]; then
    echo "Error: Topics file not found: $TOPICS_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Read prompt template and substitute placeholders
PROMPT_TEMPLATE=$(cat prompt.md)
PROMPT=$(echo "$PROMPT_TEMPLATE" | sed "s|{{TOPICS_FILE}}|$TOPICS_FILE|g" | sed "s|{{OUTPUT_DIR}}|$OUTPUT_DIR|g" | sed "s|{{CONFIG_FILE}}|$CONFIG_FILE|g" | sed "s|{{TEMPLATE_FILE}}|template.html|g")

# Use Claude path from environment or default to 'claude'
CLAUDE_CMD="${CLAUDE_PATH:-claude}"

# Function to run Claude with timeout
run_claude_with_timeout() {
    local attempt=$1

    echo "========================================" | tee -a "$LOG_FILE"
    echo "Newsletter: $NEWSLETTER_NAME" | tee -a "$LOG_FILE"
    echo "Generation attempt $attempt of $MAX_RETRIES" | tee -a "$LOG_FILE"
    echo "Started at $(date)" | tee -a "$LOG_FILE"
    echo "Timeout: $TIMEOUT_MINUTES minutes" | tee -a "$LOG_FILE"
    echo "Configuration: $CONFIG_FILE" | tee -a "$LOG_FILE"
    echo "Topics: $TOPICS_FILE" | tee -a "$LOG_FILE"
    echo "Output: $OUTPUT_DIR" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    # Run Claude with timeout
    timeout ${TIMEOUT_SECONDS}s $CLAUDE_CMD -p "$PROMPT" 2>&1 | tee -a "$LOG_FILE"

    local exit_code=${PIPESTATUS[0]}

    echo "========================================" | tee -a "$LOG_FILE"
    echo "Attempt $attempt completed at $(date)" | tee -a "$LOG_FILE"
    echo "Exit code: $exit_code" | tee -a "$LOG_FILE"

    # Check if timeout occurred (exit code 124)
    if [ $exit_code -eq 124 ]; then
        echo "Status: TIMEOUT after $TIMEOUT_MINUTES minutes" | tee -a "$LOG_FILE"
    elif [ $exit_code -eq 0 ]; then
        echo "Status: SUCCESS" | tee -a "$LOG_FILE"
    else
        echo "Status: FAILED" | tee -a "$LOG_FILE"
    fi

    echo "========================================" | tee -a "$LOG_FILE"

    return $exit_code
}

# Main retry loop
ATTEMPT=1
SUCCESS=false

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    run_claude_with_timeout $ATTEMPT
    EXIT_CODE=$?

    # Check if successful
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Newsletter generation succeeded on attempt $ATTEMPT" | tee -a "$LOG_FILE"
        SUCCESS=true
        break
    fi

    # If not the last attempt, wait before retrying
    if [ $ATTEMPT -lt $MAX_RETRIES ]; then
        echo "Waiting $RETRY_DELAY_MINUTES minutes before retry..." | tee -a "$LOG_FILE"
        sleep $RETRY_DELAY_SECONDS
        ATTEMPT=$((ATTEMPT + 1))
    else
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

# Final status
if [ "$SUCCESS" = true ]; then
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Newsletter generation completed successfully" | tee -a "$LOG_FILE"
    echo "Final completion time: $(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    exit 0
else
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Newsletter generation FAILED after $MAX_RETRIES attempts" | tee -a "$LOG_FILE"
    echo "Sending alert email..." | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    # Send alert email
    python3 send_alert.py "$CONFIG_FILE" "$TODAY" "$MAX_RETRIES" "$TIMEOUT_MINUTES" "$(pwd)/$LOG_FILE" 2>&1 | tee -a "$LOG_FILE"

    exit 1
fi
