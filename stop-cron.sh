#!/bin/bash

# Script to remove the daily newsletter cron job

echo "Removing daily newsletter cron job..."

# Change to script directory
cd "$(dirname "$0")"

# Get the full path to the script
SCRIPT_PATH="$(pwd)/run-newsletter.sh"

# Check if cron entry exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "Found cron job for newsletter script"

    # Show the current cron entry
    echo ""
    echo "Current cron entry:"
    crontab -l | grep "$SCRIPT_PATH"
    echo ""

    # Remove the cron entry
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -

    echo "Cron job removed successfully!"
    echo ""
    echo "The daily newsletter will no longer run automatically."
    echo "To re-enable it, run: ./setup-cron.sh"
else
    echo "No cron job found for the newsletter script."
    echo "Nothing to remove."
fi

echo ""
echo "Current cron jobs:"
crontab -l 2>/dev/null || echo "No cron jobs configured."
