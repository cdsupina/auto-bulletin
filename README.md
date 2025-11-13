# The Auto Bulletin

A fully automated multi-newsletter system that uses Claude Code to search the web for topics you're interested in and emails you customized newsletters with a dark-themed design.

## Features

- 🤖 **Autonomous**: Runs in Claude Code headless mode - no API credits needed
- 📧 **Multiple Newsletters**: Run as many newsletters as you want with different recipients and topics
- 🔍 **Deep Research**: Claude conducts thorough web research using WebSearch and WebFetch
- ⏰ **Individual Schedules**: Each newsletter can run at different times
- 🎨 **Email-Optimized**: Dark theme template designed for email clients
- 🔄 **Retry Logic**: Automatic retries with configurable timeouts and alerts
- 🔒 **Secure**: SMTP credentials in gitignored `.env` file

## How It Works

1. A cron job triggers the script daily for each newsletter
2. Claude Code reads that newsletter's `topics.md` file
3. Claude searches the web for recent news about those topics
4. Claude compiles a formatted HTML newsletter
5. Claude sends it via email to the configured recipient

## Quick Start

### 1. Configure SMTP (One-Time Setup)

Create your SMTP configuration:

```bash
cp .env.example .env
nano .env
```

Edit `.env` with your email provider's settings:
- `SMTP_SERVER`: Your SMTP server (e.g., `smtp.gmail.com`)
- `SMTP_PORT`: Usually `587` for TLS
- `SMTP_USERNAME`: Your email login
- `SMTP_PASSWORD`: Your email password or app password
- `CLAUDE_PATH`: Path to Claude binary (optional, defaults to `claude`)

**For Gmail users:**
- Use an [App Password](https://support.google.com/accounts/answer/185833), not your regular password
- Server: `smtp.gmail.com`, Port: `587`

### 2. Create Your First Newsletter

Copy the example template:

```bash
cp -r newsletters/example newsletters/my-newsletter
cd newsletters/my-newsletter
```

Configure it:

```bash
# Edit newsletter settings
nano config.json
```

Update these fields:
- **title**: Newsletter name (appears in email subject)
- **subtitle**: Tagline or author attribution
- **email.to**: Recipient email address
- **email.from**: Sender email address
- **email.alert**: Where to send failure alerts (optional)
- **schedule.cron**: When to run (cron format, see below)
- **schedule.timezone**: Your timezone (e.g., `America/Chicago`)
- **footer_brand**, **footer_tagline**, **footer_credits**: Branding text

Add your topics:

```bash
# Edit topics of interest
nano topics.md
```

Be specific! Instead of "technology", try "Rust programming language updates and ecosystem news".

### 3. Test Your Newsletter

```bash
# From project root
./run-newsletter.sh my-newsletter
```

Check the output:
```bash
ls newsletters/my-newsletter/output/
tail -f newsletters/my-newsletter/logs/newsletter-$(date +%Y-%m-%d).log
```

### 4. Schedule Automated Delivery

```bash
# Set up daily cron job
./setup-cron.sh my-newsletter

# View configured jobs
crontab -l | grep auto-bulletin

# Stop a newsletter
./stop-cron.sh my-newsletter
```

## Creating Additional Newsletters

Want newsletters for different purposes or recipients? Just copy the template:

```bash
# Create a work newsletter
cp -r newsletters/example newsletters/work
cd newsletters/work
nano config.json      # Change email.to, title, schedule, etc.
nano topics.md        # Add work-related topics
cd ../..
./run-newsletter.sh work
./setup-cron.sh work

# Create a family newsletter
cp -r newsletters/example newsletters/family
# ... configure and schedule
```

Each newsletter is completely independent:
- Different recipients
- Different topics
- Different schedules
- Different branding

## Project Structure

```
auto-bulletin/
├── .env                       # SMTP config (gitignored, create from .env.example)
├── .env.example               # SMTP config template
├── run-newsletter.sh          # Main script (takes newsletter name)
├── send_email.py              # Email sender
├── send_alert.py              # Failure alert sender
├── setup-cron.sh              # Cron job setup (takes newsletter name)
├── stop-cron.sh               # Cron job removal (takes newsletter name)
├── prompt.md                  # Claude instruction template
├── template.html              # HTML email template
├── newsletters/
│   ├── example/               # Template for new newsletters
│   │   ├── config.json        # Newsletter settings template
│   │   ├── topics.md          # Topics template
│   │   ├── output/            # Generated newsletters go here
│   │   └── logs/              # Execution logs go here
│   └── your-newsletter/       # Your actual newsletters (gitignored)
│       ├── config.json
│       ├── topics.md
│       ├── output/
│       └── logs/
├── CLAUDE.md                  # Architecture documentation
└── README.md                  # This file
```

## Newsletter Configuration

Each newsletter's `config.json` contains:

```json
{
  "title": "Newsletter Title",
  "subtitle": "by Your Name",
  "footer_brand": "YOUR BRAND",
  "footer_tagline": "Your tagline here",
  "footer_credits": "Generated with Claude Code",
  "email": {
    "to": "recipient@example.com",
    "from": "sender@example.com",
    "alert": "admin@example.com"
  },
  "schedule": {
    "cron": "0 8 * * *",
    "timezone": "America/Chicago"
  },
  "execution": {
    "timeout_minutes": 15,
    "max_retries": 3,
    "retry_delay_minutes": 5
  }
}
```

## Schedule Configuration (Cron Format)

The `schedule.cron` field uses standard cron syntax for maximum flexibility:

```
MINUTE HOUR DAY MONTH DAY-OF-WEEK
```

Where:
- **MINUTE**: 0-59
- **HOUR**: 0-23 (0 = midnight, 23 = 11 PM)
- **DAY**: 1-31 (day of month)
- **MONTH**: 1-12
- **DAY-OF-WEEK**: 0-7 (0 and 7 = Sunday, 1 = Monday, etc.)
- **\***: Any value (wildcard)

### Common Examples

```json
"schedule": {
  "cron": "0 8 * * *",        // Daily at 8:00 AM
  "timezone": "America/Chicago"
}
```

```json
"schedule": {
  "cron": "0 8 * * 1,4",      // Monday and Thursday at 8:00 AM
  "timezone": "America/Chicago"
}
```

```json
"schedule": {
  "cron": "30 7 * * 1-5",     // Weekdays (Mon-Fri) at 7:30 AM
  "timezone": "America/Chicago"
}
```

```json
"schedule": {
  "cron": "0 19 * * 0",       // Weekly on Sunday at 7:00 PM
  "timezone": "America/Chicago"
}
```

**Important**: The newsletter intro will automatically reflect your schedule (e.g., "daily update" vs "weekly roundup"), so choose a cron pattern that matches how often you want to receive it.

## Topics File Format

The `topics.md` file uses free-form markdown. Be specific for better results!

**Good examples:**
- "Rust programming language: new releases, popular crates, async programming"
- "AI: Large language models, new model releases, RAG techniques"
- "Kubernetes: new features, interesting use cases, ecosystem tools"

**Less effective:**
- "technology"
- "programming"
- "news"

You can organize by categories, use lists, or write paragraphs. See `newsletters/example/topics.md` for a template.

## Timeout and Retry Mechanism

The system includes automatic timeout and retry:

- **Timeout**: Each run has a configurable timeout (default 15 minutes)
- **Retries**: Failed attempts automatically retry (default 3 attempts)
- **Delay**: Configurable delay between retries (default 5 minutes)
- **Alerts**: Email sent if all retries fail

Configure in `newsletters/{name}/config.json` under the `execution` section.

## Permissions

The project uses local permissions (`.claude/settings.json`) to allow Claude Code to operate autonomously:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3:*)",
      "Write",
      "WebSearch",
      "WebFetch"
    ]
  }
}
```

This allows Claude to:
- Search the web and fetch content for research
- Create newsletter HTML files
- Send emails via Python scripts

## Common Issues

### "Error: Newsletter name required"

Scripts now require a newsletter name:
```bash
./run-newsletter.sh my-newsletter
./setup-cron.sh my-newsletter
./stop-cron.sh my-newsletter
```

### "Error: Newsletter directory not found"

Check available newsletters:
```bash
ls -d newsletters/*/
```

### "Error: Configuration file not found"

Create `config.json` from the template:
```bash
cp newsletters/example/config.json newsletters/my-newsletter/config.json
```

### Newsletter not arriving

Check the log:
```bash
tail -f newsletters/my-newsletter/logs/newsletter-$(date +%Y-%m-%d).log
```

Common issues:
- SMTP credentials incorrect in `.env`
- Wrong email address in `config.json`
- Gmail blocking the app password (check Gmail security settings)

### SMTP Authentication Error

For Gmail:
1. Enable 2-factor authentication
2. Generate an [App Password](https://support.google.com/accounts/answer/185833)
3. Use the app password in `.env`, not your regular password

### Wrong sender address in Gmail

Google Workspace may override the From header. To fix:
1. Enable "Allow per-user outbound gateways" in Admin Console
2. Add alternate address as "Send mail as" in Gmail settings

## Managing Multiple Newsletters

```bash
# List all newsletters
ls -d newsletters/*/

# View all cron jobs
crontab -l | grep auto-bulletin

# Run a specific newsletter manually
./run-newsletter.sh newsletter-name

# Stop a specific newsletter
./stop-cron.sh newsletter-name

# View all configured newsletters (without argument)
./stop-cron.sh
```

## Security Notes

- Keep `.env` file private (contains SMTP credentials)
- Each newsletter's `config.json` and `topics.md` are gitignored
- Only the `newsletters/example/` template is tracked in git
- Use app passwords instead of main email passwords

## Requirements

- Claude Code (local installation)
- Python 3
- Bash shell
- SMTP email account (Gmail, etc.)
- Cron (for automated delivery)

## Customization

### Modify Newsletter Format

- Edit `template.html` to change the design
- Edit newsletter `config.json` to change branding text
- Edit `prompt.md` to customize research instructions

### Change Schedule

Edit `schedule.cron` and `schedule.timezone` in the newsletter's `config.json`, then:
```bash
./setup-cron.sh newsletter-name
```

See the "Schedule Configuration (Cron Format)" section above for examples.

## Contributing

This is a personal automation project, but feel free to fork and adapt for your needs!

## License

MIT License - See LICENSE file for details
