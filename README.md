# The Auto Bulletin

A fully automated newsletter system that uses Claude Code to search the web for topics you're interested in and emails you a daily newsletter with a custom dark-themed design.

## How It Works

This project uses **Claude Code's headless mode** to run autonomously on your Raspberry Pi:

1. A cron job triggers the script daily
2. Claude Code reads your `interests.md` file
3. Claude searches the web for recent news about your topics
4. Claude compiles a formatted newsletter
5. Claude sends it to your email via SMTP

No API credits needed - uses your local Claude Code installation!

## Setup Instructions

### 1. Configure Newsletter Settings

Copy the example configuration file:

```bash
cp config.example.json config.json
nano config.json
```

Edit the `email` and `smtp` sections with your details:
- `email.to`: Your email address (where you'll receive the newsletter)
- `email.from`: Sender email address
- `email.alert`: Where to send failure alerts (optional, defaults to SMTP_USERNAME)
- `smtp.server`: Your email provider's SMTP server
- `smtp.port`: Usually 587 for TLS

**For Gmail users:**
- Use `smtp.gmail.com` and port `587`

### 2. Configure SMTP Credentials

Copy the example environment file and add your SMTP authentication:

```bash
cp .env.example .env
nano .env
```

Edit `.env` with your credentials:
- `SMTP_USERNAME`: Your email login
- `SMTP_PASSWORD`: Your email password (or app password)
- `CLAUDE_PATH`: Path to Claude binary (optional, defaults to 'claude')

**For Gmail users:**
- You'll need an [App Password](https://myaccount.google.com/apppasswords) (not your regular password)
- Enable 2-factor authentication first, then generate an app password at https://myaccount.google.com/apppasswords

### 3. Add Your Interests

Edit `interests.md` and add the topics you want to track:

```bash
nano interests.md
```

Be specific about what you want to see in your newsletter. Examples:
- Latest developments in Raspberry Pi 5
- Python 3.12 new features
- SpaceX launch updates
- Linux security vulnerabilities
- etc.

### 4. Test It Manually

Before setting up automation, test the script:

```bash
./run-newsletter.sh
```

Check the `logs/` directory for output and verify you received an email.

### 5. Configure Newsletter Schedule

Edit `config.json` to customize delivery schedule:

```bash
nano config.json
```

This file contains:
- Newsletter title and branding ("The Auto Bulletin by Metalmancy")
- Footer text
- Delivery schedule time and timezone
- Execution settings: timeout duration, retry attempts, retry delays

Then run the setup script to create a cron job:

```bash
./setup-cron.sh
```

To change the time later, just edit `schedule.time` in `config.json` and run `./setup-cron.sh` again.

You can also override with a specific cron time:

```bash
# For 7:30 AM
./setup-cron.sh "30 7 * * *"

# For 6:00 PM
./setup-cron.sh "0 18 * * *"
```

### 6. Stop Automation (Optional)

To stop the daily newsletter:

```bash
./stop-cron.sh
```

### 7. Verify Cron Job

Check that your cron job is active:

```bash
crontab -l
```

You should see an entry pointing to your `run-newsletter.sh` script.

## Automatic Timeout & Retry

The newsletter system includes built-in reliability features:

**Timeout Protection:**
- Each newsletter generation has a 15-minute timeout (configurable)
- Prevents hung processes from blocking future runs
- Automatically kills and retries if Claude Code hangs

**Automatic Retries:**
- Up to 3 attempts per day (configurable)
- 5-minute delay between retries (configurable)
- Handles transient API issues automatically

**Failure Alerts:**
- If all retry attempts fail, sends an alert email
- Alert goes to `email.alert` (or SMTP_USERNAME if not set)
- Includes failure details and log file location

**Configuration:**
Edit the `execution` section in `config.json`:
```json
"execution": {
  "timeout_minutes": 15,
  "max_retries": 3,
  "retry_delay_minutes": 5
}
```

**Note:** Gmail blocks self-sent emails to aliases, so set `email.alert` to a different address than `email.from`.

## Troubleshooting

### Check Logs

View the latest log file:

```bash
ls -lt logs/
cat logs/newsletter-YYYY-MM-DD.log
```

### Cron Environment Issues

The script is already configured with the full path to Claude Code. If you move Claude Code or install it elsewhere, you'll need to update the path in `run-newsletter.sh`.

### Claude Code Not Installed

Make sure Claude Code is installed and accessible:

```bash
claude --version
```

If not installed, visit: https://code.claude.com/docs/

### Google Workspace "Send mail as" Setup

If using a Google Workspace email with an alternate address (like sending from newsletter@domain.com while authenticating as user@domain.com):

1. **Enable in Admin Console:**
   - Apps → Google Workspace → Gmail → End User Access
   - Enable "Allow per-user outbound gateways"

2. **Add "Send mail as" in Gmail:**
   - Log into Gmail as your main account
   - Settings → Accounts and Import → Send mail as
   - Add your alternate email address
   - It should auto-configure without requiring SMTP details

## Manual Run

To generate and send a newsletter immediately:

```bash
./run-newsletter.sh
```

## Customization

### Change Newsletter Frequency

Edit the cron schedule:

```bash
crontab -e
```

Cron syntax: `minute hour day month weekday`
- Daily at 8 AM: `0 8 * * *`
- Twice daily (8 AM & 8 PM): Add two lines: `0 8 * * *` and `0 20 * * *`
- Weekdays only at 7 AM: `0 7 * * 1-5`

### Modify Newsletter Format

The newsletter uses an email-optimized HTML template with the Metalmancy dark theme:
- Edit `template.html` to change the design
- Edit `config.json` to change branding text
- Edit `prompt.md` to customize the research instructions

## Project Structure

```
auto-bulletin/
├── interests.md                     # Your topics (edit this!)
├── config.json                      # Newsletter settings (create from .example.json)
├── config.example.json              # Example configuration with placeholders
├── template.html                    # Email-optimized HTML template
├── prompt.md                        # Instructions for Claude Code
├── .env                             # SMTP credentials (create from .env.example)
├── .env.example                     # Example credentials
├── run-newsletter.sh                # Main automation script with timeout/retry
├── send_email.py                    # Email sending script
├── send_alert.py                    # Failure notification script
├── setup-cron.sh                    # Cron job setup script
├── stop-cron.sh                     # Stop cron job script
├── .claude/                         # Local Claude Code permissions
│   └── settings.json                # Write and Bash permissions
├── newsletters/                     # Saved newsletters (date-stamped HTML files)
├── logs/                            # Daily logs
├── README.md                        # This file
└── CLAUDE.md                        # Documentation for Claude Code
```

## Security Notes

- Keep your `.env` and `config.json` files private (never commit to git)
- Use app passwords instead of your main email password
- Only commit the `.example` files with placeholder values

## Requirements

- Raspberry Pi (or any Linux system) with Claude Code installed
- Internet connection
- Email account with SMTP access
- Cron (included in most Linux distributions)

## Support

For issues with:
- **Claude Code**: https://github.com/anthropics/claude-code/issues
- **This project**: Check the logs in `logs/` directory first

Enjoy your automated daily newsletter!
