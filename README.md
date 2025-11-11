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

### 1. Configure Your Email

Copy the example environment file and add your email settings:

```bash
cp .env.example .env
nano .env
```

Edit `.env` with your details:
- `EMAIL_TO`: Your email address (where you'll receive the newsletter)
- `EMAIL_FROM`: Sender email address
- `SMTP_SERVER`: Your email provider's SMTP server
- `SMTP_PORT`: Usually 587 for TLS
- `SMTP_USERNAME`: Your email login
- `SMTP_PASSWORD`: Your email password (or app password)

**For Gmail users:**
- Use `smtp.gmail.com` and port `587`
- You'll need an [App Password](https://myaccount.google.com/apppasswords) (not your regular password)
- Enable 2-factor authentication first, then generate an app password at https://myaccount.google.com/apppasswords

### 2. Add Your Interests

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

### 3. Test It Manually

Before setting up automation, test the script:

```bash
./run-newsletter.sh
```

Check the `logs/` directory for output and verify you received an email.

### 4. Configure Newsletter Settings

Edit `newsletter-config.json` to customize branding and schedule:

```bash
nano newsletter-config.json
```

This file contains:
- Newsletter title and branding ("The Auto Bulletin by Metalmancy")
- Footer text
- Delivery schedule time and timezone

Then run the setup script to create a cron job:

```bash
./setup-cron.sh
```

To change the time later, just edit `schedule.time` in `newsletter-config.json` and run `./setup-cron.sh` again.

You can also override with a specific cron time:

```bash
# For 7:30 AM
./setup-cron.sh "30 7 * * *"

# For 6:00 PM
./setup-cron.sh "0 18 * * *"
```

### 5. Stop Automation (Optional)

To stop the daily newsletter:

```bash
./stop-cron.sh
```

### 6. Verify Cron Job

Check that your cron job is active:

```bash
crontab -l
```

You should see an entry pointing to your `run-newsletter.sh` script.

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
- Edit `newsletter-template-email.html` to change the design
- Edit `newsletter-config.json` to change branding text
- Edit `newsletter-prompt.md` to customize the research instructions

## Project Structure

```
auto-bulletin/
├── interests.md                  # Your topics (edit this!)
├── newsletter-config.json        # Newsletter branding and schedule
├── newsletter-template-email.html # Email-optimized HTML template
├── newsletter-prompt.md          # Instructions for Claude Code
├── .env                          # Email configuration (create from .env.example)
├── .env.example                  # Example configuration
├── run-newsletter.sh            # Main automation script
├── send_email.py                # Email sending script
├── setup-cron.sh                # Cron job setup script
├── stop-cron.sh                 # Stop cron job script
├── .claude/                     # Local Claude Code permissions
│   └── settings.json            # Write and Bash permissions
├── newsletters/                 # Saved newsletters (date-stamped HTML files)
├── logs/                        # Daily logs
├── README.md                   # This file
└── CLAUDE.md                   # Documentation for Claude Code
```

## Security Notes

- Keep your `.env` file private (never commit to git)
- Use app passwords instead of your main email password
- The `.env` file contains sensitive credentials - protect it!

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
