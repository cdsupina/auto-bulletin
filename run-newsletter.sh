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

/home/cdsupina/.local/bin/claude -p "Please perform the following task:

1. Read the file ~/Projects/daily-newsletter/interests.md to understand what topics I'm interested in
2. Use WebSearch to find recent and relevant news/information about each topic from the last 24 hours
3. Compile the findings into a well-formatted HTML newsletter with:
   - A brief introduction
   - Sections for each topic with 2-3 top stories/updates
   - Links to sources
   - A summary at the end
4. Save the newsletter HTML to ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
5. Send the email using the existing send_email.py script:
   - Run: python3 ~/Projects/daily-newsletter/send_email.py ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
   - The script will use environment variables for email configuration
6. Report success or any errors encountered

Work autonomously and complete all steps.

Thank you!" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

echo "========================================" | tee -a "$LOG_FILE"
echo "Newsletter generation completed at $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

exit $EXIT_CODE
