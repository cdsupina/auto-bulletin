#!/usr/bin/env python3
"""
Email sender script for daily newsletter
Reads newsletter content from stdin or a file and sends via SMTP
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
    # Load newsletter configuration
    config_file = os.path.join(os.path.dirname(__file__), 'config.json')
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Error: Configuration file not found: {config_file}", file=sys.stderr)
        print("Please create config.json from config.example.json", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in configuration file: {e}", file=sys.stderr)
        sys.exit(1)

    # Get email configuration from config file
    to_email = config.get('email', {}).get('to')
    from_email = config.get('email', {}).get('from')
    smtp_server = config.get('smtp', {}).get('server')
    smtp_port = config.get('smtp', {}).get('port', 587)

    # Get SMTP credentials from environment variables (still secret)
    smtp_username = os.getenv('SMTP_USERNAME')
    smtp_password = os.getenv('SMTP_PASSWORD')

    # Validate configuration
    if not all([to_email, from_email, smtp_server, smtp_username, smtp_password]):
        print("Error: Missing email configuration", file=sys.stderr)
        print("Required in config.json: email.to, email.from, smtp.server", file=sys.stderr)
        print("Required in .env: SMTP_USERNAME, SMTP_PASSWORD", file=sys.stderr)
        sys.exit(1)

    # Get subject (default if not provided)
    subject = os.getenv('EMAIL_SUBJECT', f"Daily Newsletter - {datetime.now().strftime('%Y-%m-%d')}")

    # Read email body from stdin or file
    if len(sys.argv) > 1:
        # Read from file
        newsletter_file = sys.argv[1]
        try:
            with open(newsletter_file, 'r') as f:
                body = f.read()
        except FileNotFoundError:
            print(f"Error: File not found: {newsletter_file}", file=sys.stderr)
            sys.exit(1)
    else:
        # Read from stdin
        body = sys.stdin.read()

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
