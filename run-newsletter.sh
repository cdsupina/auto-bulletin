#!/bin/bash

# Daily Newsletter Automation Script
# This script uses Claude Code in headless mode to generate and send your daily newsletter

# Change to the project directory
cd "$(dirname "$0")"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Log file
LOG_FILE="logs/newsletter-$(date +%Y-%m-%d).log"
mkdir -p logs

# Run Claude Code in headless mode
echo "========================================" | tee -a "$LOG_FILE"
echo "Starting newsletter generation at $(date)" | tee -a "$LOG_FILE"
echo "Environment check:" | tee -a "$LOG_FILE"
echo "  EMAIL_TO: $EMAIL_TO" | tee -a "$LOG_FILE"
echo "  EMAIL_FROM: $EMAIL_FROM" | tee -a "$LOG_FILE"
echo "  SMTP_SERVER: $SMTP_SERVER:$SMTP_PORT" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Read prompt from file
PROMPT=$(cat newsletter-prompt.md)

/home/cdsupina/.local/bin/claude -p "$PROMPT" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

echo "========================================" | tee -a "$LOG_FILE"
echo "Newsletter generation completed at $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

exit $EXIT_CODE
