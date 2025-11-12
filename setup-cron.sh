#!/bin/bash

# Setup script for newsletter cron job
# Usage: ./setup-cron.sh <newsletter-name> [cron-time]
# Example: ./setup-cron.sh personal
# Example with custom time: ./setup-cron.sh personal "30 7 * * *"

# Check for newsletter name argument
if [ -z "$1" ]; then
    echo "Error: Newsletter name required"
    echo "Usage: $0 <newsletter-name> [cron-time]"
    echo ""
    echo "Available newsletters:"
    cd "$(dirname "$0")/.."
    ls -d newsletters/*/ 2>/dev/null | xargs -n 1 basename || echo "  (none)"
    echo ""
    echo "Example: $0 personal"
    echo "Example with custom time: $0 personal '30 7 * * *'"
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

# Get the full path to the run script
SCRIPT_PATH="$(pwd)/run-newsletter.sh"
CONFIG_FILE="$NEWSLETTER_DIR/config.json"

# Verify config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Setting up cron job for newsletter: $NEWSLETTER_NAME"

# Load newsletter time and timezone from config file
# Extract time from JSON using grep and sed
NEWSLETTER_TIME=$(grep -o '"time"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
NEWSLETTER_TZ=$(grep -o '"timezone"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')

if [ -n "$NEWSLETTER_TIME" ]; then
    HOUR=$(echo "$NEWSLETTER_TIME" | cut -d: -f1)
    MINUTE=$(echo "$NEWSLETTER_TIME" | cut -d: -f2)
    DEFAULT_CRON_TIME="$MINUTE $HOUR * * *"
    echo "Using time from config.json: $NEWSLETTER_TIME"

    if [ -n "$NEWSLETTER_TZ" ]; then
        echo "Using timezone: $NEWSLETTER_TZ"
    else
        echo "No timezone found, using system default"
    fi
else
    DEFAULT_CRON_TIME="0 8 * * *"
    echo "No time found in config.json, using default: 8:00 AM"
fi

# Allow override via command line argument
CRON_TIME="${2:-$DEFAULT_CRON_TIME}"

# Create cron entry with newsletter name argument and timezone if specified
if [ -n "$NEWSLETTER_TZ" ]; then
    CRON_ENTRY="$CRON_TIME TZ=$NEWSLETTER_TZ $SCRIPT_PATH $NEWSLETTER_NAME"
else
    CRON_ENTRY="$CRON_TIME $SCRIPT_PATH $NEWSLETTER_NAME"
fi

# Create unique identifier for this newsletter's cron job
CRON_IDENTIFIER="# auto-bulletin: $NEWSLETTER_NAME"

# Check if cron entry already exists for this newsletter
if crontab -l 2>/dev/null | grep -q "$CRON_IDENTIFIER"; then
    echo "Cron job already exists for '$NEWSLETTER_NAME'. Removing old entry..."
    # Remove old entry and its identifier line
    crontab -l 2>/dev/null | grep -v "$CRON_IDENTIFIER" | grep -v "$SCRIPT_PATH $NEWSLETTER_NAME" | crontab -
fi

# Add new cron entry with identifier
(crontab -l 2>/dev/null; echo "$CRON_IDENTIFIER"; echo "$CRON_ENTRY") | crontab -

echo ""
echo "Cron job added successfully!"
echo "Newsletter '$NEWSLETTER_NAME' will run daily at the specified time."
echo ""
echo "Current cron entry:"
crontab -l | grep -A 1 "$CRON_IDENTIFIER"
echo ""
echo "To modify the time or timezone:"
echo "  1. Edit schedule.time and schedule.timezone in $CONFIG_FILE"
echo "  2. Run ./setup-cron.sh $NEWSLETTER_NAME again"
echo ""
echo "Or override with: ./setup-cron.sh $NEWSLETTER_NAME 'MINUTE HOUR * * *'"
echo "Example for 7:30 AM: ./setup-cron.sh $NEWSLETTER_NAME '30 7 * * *'"
echo ""
echo "To view all newsletter cron jobs: crontab -l | grep 'auto-bulletin'"
echo "To remove this cron job: ./stop-cron.sh $NEWSLETTER_NAME"
