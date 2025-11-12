#!/bin/bash

# Script to remove newsletter cron job(s)
# Usage: ./stop-cron.sh [newsletter-name]
# Example: ./stop-cron.sh personal       (removes specific newsletter)
# Example: ./stop-cron.sh                (lists all auto-bulletin cron jobs)

# Change to the script directory (project root)
cd "$(dirname "$0")"

# Get the full path to the script
SCRIPT_PATH="$(pwd)/run-newsletter.sh"

if [ -n "$1" ]; then
    # Specific newsletter provided
    NEWSLETTER_NAME="$1"
    CRON_IDENTIFIER="# auto-bulletin: $NEWSLETTER_NAME"

    echo "Removing cron job for newsletter: $NEWSLETTER_NAME"

    # Check if cron entry exists for this newsletter
    if crontab -l 2>/dev/null | grep -q "$CRON_IDENTIFIER"; then
        echo "Found cron job for '$NEWSLETTER_NAME'"

        # Show the current cron entry
        echo ""
        echo "Current cron entry:"
        crontab -l | grep -A 1 "$CRON_IDENTIFIER"
        echo ""

        # Remove the cron entry and its identifier line
        crontab -l 2>/dev/null | grep -v "$CRON_IDENTIFIER" | grep -v "$SCRIPT_PATH $NEWSLETTER_NAME" | crontab -

        echo "Cron job removed successfully!"
        echo ""
        echo "Newsletter '$NEWSLETTER_NAME' will no longer run automatically."
        echo "To re-enable it, run: ./setup-cron.sh $NEWSLETTER_NAME"
    else
        echo "No cron job found for newsletter '$NEWSLETTER_NAME'."
        echo "Nothing to remove."
    fi
else
    # No newsletter specified - show all auto-bulletin cron jobs
    echo "Auto-bulletin newsletter cron jobs:"
    echo ""

    if crontab -l 2>/dev/null | grep -q "auto-bulletin"; then
        crontab -l | grep "auto-bulletin" -A 1
        echo ""
        echo "To remove a specific newsletter's cron job:"
        echo "  ./stop-cron.sh <newsletter-name>"
        echo ""
        echo "Examples:"
        crontab -l | grep "auto-bulletin:" | sed 's/# auto-bulletin: /  .\/stop-cron.sh /'
    else
        echo "  (none found)"
        echo ""
        echo "No auto-bulletin cron jobs are currently configured."
    fi
fi

echo ""
echo "All current cron jobs:"
crontab -l 2>/dev/null || echo "  (none)"
