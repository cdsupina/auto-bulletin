#!/usr/bin/env python3
"""
Alert email sender for newsletter generation failures
Sends a notification to the sender when newsletter generation fails after all retries
"""

import smtplib
import sys
import os
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
    # Get configuration from environment variables
    from_email = os.getenv('EMAIL_FROM')
    alert_email = os.getenv('ALERT_EMAIL', os.getenv('SMTP_USERNAME'))  # Default to SMTP_USERNAME if not set
    smtp_server = os.getenv('SMTP_SERVER')
    smtp_port = int(os.getenv('SMTP_PORT', 587))
    smtp_username = os.getenv('SMTP_USERNAME')
    smtp_password = os.getenv('SMTP_PASSWORD')

    # Validate configuration
    if not all([from_email, alert_email, smtp_server, smtp_username, smtp_password]):
        print("Error: Missing email configuration in environment variables", file=sys.stderr)
        sys.exit(1)

    # Get failure details from command line arguments
    if len(sys.argv) < 4:
        print("Usage: send_alert.py <date> <attempts> <timeout_minutes> <log_file>", file=sys.stderr)
        sys.exit(1)

    date = sys.argv[1]
    attempts = sys.argv[2]
    timeout_minutes = sys.argv[3]
    log_file = sys.argv[4]

    subject = f"Newsletter Generation Failed - {date}"
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
