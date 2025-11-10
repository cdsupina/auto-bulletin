#!/bin/bash

# Setup script for daily newsletter cron job

echo "Setting up daily newsletter cron job..."

# Change to script directory
cd "$(dirname "$0")"

# Get the full path to the script
SCRIPT_PATH="$(pwd)/run-newsletter.sh"

# Load newsletter time and timezone from config file
if [ -f newsletter-config.json ]; then
    # Extract time from JSON using grep and sed
    NEWSLETTER_TIME=$(grep -o '"time"[[:space:]]*:[[:space:]]*"[^"]*"' newsletter-config.json | sed 's/.*"\([^"]*\)".*/\1/')
    NEWSLETTER_TZ=$(grep -o '"timezone"[[:space:]]*:[[:space:]]*"[^"]*"' newsletter-config.json | sed 's/.*"\([^"]*\)".*/\1/')

    if [ -n "$NEWSLETTER_TIME" ]; then
        HOUR=$(echo "$NEWSLETTER_TIME" | cut -d: -f1)
        MINUTE=$(echo "$NEWSLETTER_TIME" | cut -d: -f2)
        DEFAULT_CRON_TIME="$MINUTE $HOUR * * *"
        echo "Using time from newsletter-config.json: $NEWSLETTER_TIME"

        if [ -n "$NEWSLETTER_TZ" ]; then
            echo "Using timezone: $NEWSLETTER_TZ"
        else
            echo "No timezone found, using system default"
        fi
    else
        DEFAULT_CRON_TIME="0 8 * * *"
        echo "No time found in newsletter-config.json, using default: 8:00 AM"
    fi
else
    DEFAULT_CRON_TIME="0 8 * * *"
    echo "No newsletter-config.json found, using default: 8:00 AM"
fi

# Allow override via command line argument
CRON_TIME="${1:-$DEFAULT_CRON_TIME}"

# Create cron entry with timezone if specified
if [ -n "$NEWSLETTER_TZ" ]; then
    CRON_ENTRY="$CRON_TIME TZ=$NEWSLETTER_TZ $SCRIPT_PATH"
else
    CRON_ENTRY="$CRON_TIME $SCRIPT_PATH"
fi

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "Cron job already exists. Removing old entry..."
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
fi

# Add new cron entry
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo "Cron job added successfully!"
echo "Your newsletter will run daily at the specified time."
echo ""
echo "Current cron entry:"
crontab -l | grep "$SCRIPT_PATH"
echo ""
echo "To modify the time or timezone:"
echo "  1. Edit schedule.time and schedule.timezone in newsletter-config.json"
echo "  2. Run ./setup-cron.sh again"
echo ""
echo "Or override with: ./setup-cron.sh 'MINUTE HOUR * * *'"
echo "Example for 7:30 AM: ./setup-cron.sh '30 7 * * *'"
echo ""
echo "To view all cron jobs: crontab -l"
echo "To remove this cron job: crontab -e (then delete the line)"
