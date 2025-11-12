#!/usr/bin/env python3
"""
Email sender script for daily newsletter
Usage: send_email.py <config_file> <newsletter_file>
Reads newsletter content from a file and sends via SMTP using specified config
"""

import smtplib
import sys
import os
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email(subject, body, to_email, from_email, smtp_server, smtp_port, smtp_username, smtp_password):
    """Send an email via SMTP"""
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = from_email
        msg['To'] = to_email
        msg['Date'] = datetime.now().strftime('%a, %d %b %Y %H:%M:%S %z')

        # Attach HTML content
        html_part = MIMEText(body, 'html')
        msg.attach(html_part)

        # Connect to SMTP server
        print(f"Connecting to {smtp_server}:{smtp_port}...", file=sys.stderr)
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.set_debuglevel(0)  # Set to 1 for verbose SMTP debugging
            print("Starting TLS...", file=sys.stderr)
            server.starttls()
            print(f"Logging in as {smtp_username}...", file=sys.stderr)
            server.login(smtp_username, smtp_password)
            print(f"Sending email to {to_email}...", file=sys.stderr)
            server.send_message(msg)
            print("Email sent successfully!", file=sys.stderr)
            return True

    except smtplib.SMTPAuthenticationError as e:
        print(f"SMTP Authentication Error: {e}", file=sys.stderr)
        print("Check your username and password (use App Password for Gmail)", file=sys.stderr)
        return False
    except smtplib.SMTPException as e:
        print(f"SMTP Error: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error sending email: {e}", file=sys.stderr)
        return False

def main():
    # Check for required arguments
    if len(sys.argv) < 3:
        print("Usage: send_email.py <config_file> <newsletter_file>", file=sys.stderr)
        print("Example: send_email.py newsletters/personal/config.json newsletters/personal/output/newsletter-2025-11-11.html", file=sys.stderr)
        sys.exit(1)

    # Get config file path from argument
    config_file = sys.argv[1]
    newsletter_file = sys.argv[2]

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
    to_email = config.get('email', {}).get('to')
    from_email = config.get('email', {}).get('from')

    # Get SMTP configuration from environment variables
    smtp_server = os.getenv('SMTP_SERVER')
    smtp_port = int(os.getenv('SMTP_PORT', '587'))
    smtp_username = os.getenv('SMTP_USERNAME')
    smtp_password = os.getenv('SMTP_PASSWORD')

    # Validate configuration
    if not all([to_email, from_email, smtp_server, smtp_username, smtp_password]):
        print("Error: Missing email configuration", file=sys.stderr)
        print("Required in config.json: email.to, email.from", file=sys.stderr)
        print("Required in .env: SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD", file=sys.stderr)
        sys.exit(1)

    # Get subject (use newsletter title if available, otherwise default)
    newsletter_title = config.get('title', 'Newsletter')
    subject = os.getenv('EMAIL_SUBJECT', f"{newsletter_title} - {datetime.now().strftime('%Y-%m-%d')}")

    # Read email body from file
    try:
        with open(newsletter_file, 'r') as f:
            body = f.read()
    except FileNotFoundError:
        print(f"Error: File not found: {newsletter_file}", file=sys.stderr)
        sys.exit(1)

    if not body.strip():
        print("Error: Email body is empty", file=sys.stderr)
        sys.exit(1)

    # Send the email
    success = send_email(
        subject=subject,
        body=body,
        to_email=to_email,
        from_email=from_email,
        smtp_server=smtp_server,
        smtp_port=smtp_port,
        smtp_username=smtp_username,
        smtp_password=smtp_password
    )

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
