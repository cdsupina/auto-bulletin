#!/bin/bash

# Setup script for daily newsletter cron job

echo "Setting up daily newsletter cron job..."

# Change to script directory
cd "$(dirname "$0")"

# Get the full path to the script
SCRIPT_PATH="$(pwd)/run-newsletter.sh"

# Load environment variables to get the newsletter time
if [ -f .env ]; then
    source .env
fi

# Convert NEWSLETTER_TIME (HH:MM format) to cron format (MINUTE HOUR * * *)
if [ -n "$NEWSLETTER_TIME" ]; then
    HOUR=$(echo "$NEWSLETTER_TIME" | cut -d: -f1)
    MINUTE=$(echo "$NEWSLETTER_TIME" | cut -d: -f2)
    DEFAULT_CRON_TIME="$MINUTE $HOUR * * *"
    echo "Using time from .env: $NEWSLETTER_TIME"
else
    DEFAULT_CRON_TIME="0 8 * * *"
    echo "No NEWSLETTER_TIME found in .env, using default: 8:00 AM"
fi

# Allow override via command line argument
CRON_TIME="${1:-$DEFAULT_CRON_TIME}"

# Create cron entry
CRON_ENTRY="$CRON_TIME $SCRIPT_PATH"

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
echo "To modify the time:"
echo "  1. Edit NEWSLETTER_TIME in .env file (format: HH:MM)"
echo "  2. Run ./setup-cron.sh again"
echo ""
echo "Or override with: ./setup-cron.sh 'MINUTE HOUR * * *'"
echo "Example for 7:30 AM: ./setup-cron.sh '30 7 * * *'"
echo ""
echo "To view all cron jobs: crontab -l"
echo "To remove this cron job: crontab -e (then delete the line)"
