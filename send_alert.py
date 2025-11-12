#!/usr/bin/env python3
"""
Alert email sender for newsletter generation failures
Usage: send_alert.py <config_file> <date> <attempts> <timeout_minutes> <log_file>
Sends a notification when newsletter generation fails after all retries
"""

import smtplib
import sys
import os
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_alert(subject, body, to_email, from_email, smtp_server, smtp_port, smtp_username, smtp_password):
    """Send an alert email via SMTP"""
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = from_email
        msg['To'] = to_email
        msg['Date'] = datetime.now().strftime('%a, %d %b %Y %H:%M:%S %z')

        # Create plain text version
        text_part = MIMEText(body, 'plain')
        msg.attach(text_part)

        # Connect to SMTP server
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.set_debuglevel(0)
            server.starttls()
            server.login(smtp_username, smtp_password)
            server.send_message(msg)
            return True

    except Exception as e:
        print(f"Error sending alert email: {e}", file=sys.stderr)
        return False

def main():
    # Check for required arguments
    if len(sys.argv) < 6:
        print("Usage: send_alert.py <config_file> <date> <attempts> <timeout_minutes> <log_file>", file=sys.stderr)
        sys.exit(1)

    # Get arguments
    config_file = sys.argv[1]
    date = sys.argv[2]
    attempts = sys.argv[3]
    timeout_minutes = sys.argv[4]
    log_file = sys.argv[5]

    # Load newsletter configuration
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Error: Configuration file not found: {config_file}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in configuration file: {e}", file=sys.stderr)
        sys.exit(1)

    # Get email configuration from config file
    from_email = config.get('email', {}).get('from')
    alert_email = config.get('email', {}).get('alert')

    # Get SMTP configuration from environment variables
    smtp_server = os.getenv('SMTP_SERVER')
    smtp_port = int(os.getenv('SMTP_PORT', '587'))
    smtp_username = os.getenv('SMTP_USERNAME')
    smtp_password = os.getenv('SMTP_PASSWORD')

    # Default alert_email to SMTP_USERNAME if not configured
    if not alert_email:
        alert_email = smtp_username

    # Validate configuration
    if not all([from_email, alert_email, smtp_server, smtp_username, smtp_password]):
        print("Error: Missing email configuration", file=sys.stderr)
        print("Required in config.json: email.from", file=sys.stderr)
        print("Required in .env: SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD", file=sys.stderr)
        sys.exit(1)

    # Get newsletter name from config if available
    newsletter_title = config.get('title', 'Newsletter')

    subject = f"{newsletter_title} Generation Failed - {date}"
    body = f"""Newsletter generation failed after all retry attempts.

Date: {date}
Attempts: {attempts}
Timeout per attempt: {timeout_minutes} minutes
Log file: {log_file}

The newsletter generation process timed out or failed on all retry attempts.
Please check the log file for details and investigate the issue.

This is an automated alert from the Auto Bulletin system.
"""

    # Send alert to the configured alert email address
    success = send_alert(
        subject=subject,
        body=body,
        to_email=alert_email,  # Send to ALERT_EMAIL (or SMTP_USERNAME if not set)
        from_email=from_email,
        smtp_server=smtp_server,
        smtp_port=smtp_port,
        smtp_username=smtp_username,
        smtp_password=smtp_password
    )

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
