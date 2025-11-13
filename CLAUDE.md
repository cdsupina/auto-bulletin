# The Auto Bulletin - Claude Code Documentation

This document explains how this project uses Claude Code and provides guidance for Claude when working with this codebase.

## Project Overview

An automated multi-newsletter system that uses Claude Code in headless mode to:
1. Read user interests from individual `topics.md` files
2. Conduct thorough web research on those topics using WebSearch and WebFetch
3. Compile findings into email-optimized HTML newsletters with custom branding
4. Send via email using SMTP
5. Support multiple independent newsletters with different recipients and schedules

## Architecture

### Core Components

1. **run-newsletter.sh** - Main orchestration script with timeout and retry
   - **Usage**: `./run-newsletter.sh <newsletter-name>`
   - Loads environment variables from `.env` (including SMTP config)
   - Reads timeout and retry configuration from `newsletters/{name}/config.json`
   - Invokes Claude Code in headless mode with `-p` flag and timeout wrapper
   - Dynamically generates prompt from `prompt.md` template with placeholders
   - Implements automatic retry logic with configurable delays
   - Logs all output to `newsletters/{name}/logs/newsletter-YYYY-MM-DD.log`
   - Sends alert email if all retry attempts fail
   - Uses path to Claude from `CLAUDE_PATH` env variable or defaults to `claude`

2. **send_email.py** - Email delivery script
   - **Usage**: `send_email.py <config_file> <newsletter_file>`
   - Reads email configuration (to array, from, alert) from specified config.json
   - Supports multiple recipients via email.to array
   - Reads SMTP configuration (server, port, credentials) from environment variables
   - Accepts newsletter HTML file path as argument
   - Sends via SMTP with TLS encryption
   - Provides detailed error messages for debugging

3. **send_alert.py** - Failure notification script
   - **Usage**: `send_alert.py <config_file> <date> <attempts> <timeout_minutes> <log_file>`
   - Sends alert emails when newsletter generation fails after all retries
   - Reads email configuration from specified config.json
   - Reads SMTP configuration from environment variables
   - Sends to `email.alert` address (or SMTP_USERNAME if not configured)
   - Includes failure details: date, attempts, timeout, log file location

4. **setup-cron.sh** - Automation setup
   - **Usage**: `./setup-cron.sh <newsletter-name> [cron-time]`
   - Reads `schedule.cron` and `schedule.timezone` from `newsletters/{name}/config.json`
   - Uses cron format directly (MINUTE HOUR DAY MONTH DAY-OF-WEEK)
   - Sets TZ environment variable in cron entry if timezone specified
   - Manages individual cron jobs per newsletter with unique identifiers
   - Allows manual override with cron syntax

5. **stop-cron.sh** - Automation control
   - **Usage**: `./stop-cron.sh [newsletter-name]`
   - With name: Removes specific newsletter's cron job
   - Without name: Lists all auto-bulletin cron jobs
   - Uses unique identifiers to manage multiple newsletters

6. **prompt.md** - Instructions template for Claude Code
   - Contains the detailed prompt that Claude follows
   - Uses placeholders: `{{TOPICS_FILE}}`, `{{OUTPUT_DIR}}`, `{{CONFIG_FILE}}`, `{{TEMPLATE_FILE}}`
   - Placeholders are substituted by run-newsletter.sh before passing to Claude
   - Specifies research depth and quality expectations

7. **template.html** - Email-optimized HTML template
   - Table-based layout for email client compatibility
   - Inline styles (no external CSS)
   - Dark theme matching Metalmancy aesthetic
   - Placeholders for dynamic content ({{TITLE}}, {{DATE}}, etc.)

8. **newsletters/{name}/config.json** - Per-newsletter configuration (gitignored except example)
   - Newsletter title and subtitle
   - Email addresses (to array for multiple recipients, from, alert)
   - Footer branding and text
   - Schedule cron pattern and timezone
   - Execution settings: timeout, max retries, retry delay

9. **newsletters/example/** - Template directory (tracked in git)
   - Contains `config.json` and `topics.md` templates
   - Users copy this directory to create new newsletters
   - Only newsletter directory tracked in git (others gitignored)

### Configuration Files

**`.env`** - Project-level SMTP configuration (gitignored):
```bash
SMTP_SERVER=smtp.gmail.com              # SMTP server address
SMTP_PORT=587                            # SMTP port (usually 587 for TLS)
SMTP_USERNAME=auth-user@example.com      # SMTP authentication username
SMTP_PASSWORD=app-password-here          # App password (not regular password)
CLAUDE_PATH=/path/to/claude              # Optional: Path to Claude Code binary
```

**`newsletters/{name}/config.json`** - Per-newsletter configuration (gitignored):
```json
{
  "title": "The Auto Bulletin",
  "subtitle": "by Metalmancy",
  "footer_brand": "METALMANCY",
  "footer_tagline": "Your daily dose of news and updates",
  "footer_credits": "Generated with Claude Code",
  "email": {
    "to": ["recipient@example.com", "another@example.com"],
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

**`newsletters/{name}/topics.md`** - Per-newsletter topics:
- Free-form markdown file
- Claude reads this to understand what topics to search for
- Should be specific and clear
- Each newsletter can have completely different topics

### Directory Structure

```
auto-bulletin/
├── .env                          # SMTP config + credentials (gitignored)
├── .env.example                  # SMTP config template (committed)
├── run-newsletter.sh             # Main script
├── send_email.py                 # Email sender
├── send_alert.py                 # Alert sender
├── setup-cron.sh                 # Cron setup
├── stop-cron.sh                  # Cron removal
├── prompt.md                     # Claude instruction template
├── template.html                 # HTML email template
├── newsletters/
│   ├── example/                  # Template (committed)
│   │   ├── config.json
│   │   ├── topics.md
│   │   ├── output/
│   │   └── logs/
│   └── {name}/                   # User newsletters (gitignored)
│       ├── config.json
│       ├── topics.md
│       ├── output/
│       └── logs/
├── .claude/
│   └── settings.json             # Local permissions
└── CLAUDE.md                     # This file
```

### Permissions

**Local permissions** (`.claude/settings.json`):
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

These permissions allow Claude Code to:
- Search the web and fetch content without prompting
- Create newsletter HTML files in the `newsletters/{name}/output/` directory
- Execute the Python email scripts

**Note**: Local permissions are preferred over global permissions for better security. They limit these capabilities to this specific project directory, following the principle of least privilege. No global permissions in `~/.claude/settings.json` are required.

## How Claude Code Runs in Headless Mode

When `run-newsletter.sh <name>` executes:

1. **Load Configuration**:
   - Exports all `.env` variables (SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD)
   - Reads `newsletters/{name}/config.json` for execution settings
   - Sets paths: OUTPUT_DIR, LOG_DIR, TOPICS_FILE, CONFIG_FILE

2. **Generate Prompt**:
   - Reads `prompt.md` template
   - Substitutes placeholders:
     - `{{TOPICS_FILE}}` → `newsletters/{name}/topics.md`
     - `{{OUTPUT_DIR}}` → `newsletters/{name}/output`
     - `{{CONFIG_FILE}}` → `newsletters/{name}/config.json`
     - `{{TEMPLATE_FILE}}` → `template.html`

3. **Run Claude**:
   - Passes generated prompt to Claude Code with `-p` flag
   - Claude inherits environment variables (including SMTP config)
   - Wrapped with timeout command (default 15 minutes)

4. **Claude's Tasks**:
   - Read topics from specified topics file
   - Check past 3 newsletters in output directory
   - Conduct thorough research using WebSearch and WebFetch
   - Read template and config files
   - Compile findings into HTML using template structure
   - Replace all placeholders with appropriate content
   - Save newsletter to output directory
   - Send email using `send_email.py` (inherits SMTP env vars)
   - Report success or errors

5. **Retry Logic**:
   - If Claude fails or times out, automatically retry
   - Configurable retry count and delay
   - Each retry logged separately

6. **Alert on Failure**:
   - If all retries fail, `send_alert.py` sends notification
   - Alert includes: newsletter name, failure details, log file path

## Multi-Newsletter Support

The system supports unlimited newsletters, each completely independent:

### Creating a New Newsletter

```bash
# Copy template
cp -r newsletters/example newsletters/work

# Configure
cd newsletters/work
nano config.json      # Set email.to, title, schedule
nano topics.md        # Add topics
cd ../..

# Test
./run-newsletter.sh work

# Schedule
./setup-cron.sh work
```

### Newsletter Isolation

Each newsletter has:
- **Own config**: Different recipients, titles, schedules
- **Own topics**: Completely different topics
- **Own output**: Separate directory for generated newsletters
- **Own logs**: Isolated execution logs
- **Own cron job**: Individual schedule with unique identifier

### Shared Resources

All newsletters share:
- **SMTP configuration**: Same email server and credentials (`.env`)
- **Template**: Same HTML template (`template.html`)
- **Prompt logic**: Same research instructions (`prompt.md`)
- **Scripts**: Same execution scripts

This architecture allows:
- Personal newsletter at 8 AM
- Work newsletter at 9 AM
- Family newsletter weekly
- Each with different recipients and topics

## Task Workflow

For each newsletter execution:

1. **Read Topics**: Claude reads `newsletters/{name}/topics.md`
2. **Check History**: Reviews past 3 newsletters in `newsletters/{name}/output/`
3. **Deep Research**: Uses WebSearch and WebFetch to find recent news
   - Searches multiple angles and sources
   - Looks for lesser-known but significant developments
   - Prioritizes quality and depth over speed
   - Aims for diverse sources
4. **Read Configuration**: Loads template and branding from files
5. **Determine Frequency**: Parses the cron schedule to determine newsletter frequency (daily, twice weekly, weekly, etc.) to use accurate language in the intro paragraph
6. **Content Compilation**: Creates HTML newsletter with:
   - Email-compatible table-based layout
   - Dark Metalmancy theme (purple/gold colors)
   - Proper sections with emoji icons
   - 2-3 stories per topic with source links
   - No summary section at end
7. **Save Newsletter**: Writes to `newsletters/{name}/output/newsletter-YYYY-MM-DD.html`
8. **Send Email**: Executes `python3 send_email.py <config> <newsletter>`
9. **Report Status**: Logs success or errors

## Email Template Design

The newsletter uses `template.html` which is optimized for email clients:

- **Table-based layout** - Better compatibility than div-based layouts
- **Inline styles** - All CSS in style="" attributes
- **No gradients** - Solid colors only for email client support
- **System fonts** - No web font imports
- **Dark theme** - Matches Metalmancy aesthetic:
  - Background: `#0e0e20`, `#27263a`
  - Accents: `#F0CD5A` (gold), `#8772d2` (purple)
  - Text: `#FFFFFE` (white), `#d1d1d1` (gray)

## Timeout and Retry Mechanism

The newsletter system includes automatic timeout and retry functionality:

### How It Works

1. **Timeout Enforcement**: Each newsletter generation attempt is wrapped with `timeout`
   - Default: 15 minutes (configurable via `execution.timeout_minutes`)
   - If Claude doesn't complete within the timeout, the process is killed (exit code 124)

2. **Automatic Retries**: Failed attempts trigger automatic retries
   - Default: 3 attempts (configurable via `execution.max_retries`)
   - Includes 5-minute delay between retries (configurable via `execution.retry_delay_minutes`)
   - Each retry is logged with attempt number and timeout duration

3. **Alert on Total Failure**: If all retry attempts fail
   - `send_alert.py` sends a notification email to `email.alert`
   - Alert includes: newsletter name, date, attempts, timeout, log file path
   - Allows for manual investigation and debugging

### Configuration

All timeout and retry settings are in `newsletters/{name}/config.json` under the `execution` section:

```json
"execution": {
  "timeout_minutes": 15,        // Max time per attempt
  "max_retries": 3,              // Total attempts
  "retry_delay_minutes": 5       // Wait time between retries
}
```

## Common Issues and Solutions

### Issue: Newsletter looks wrong on mobile Gmail

**Cause**: Gmail mobile app's dark mode inverts colors

**Solution**: Template uses inline styles and solid colors to minimize conflicts.

### Issue: "Error: Newsletter name required"

**Cause**: Forgot to specify which newsletter to run

**Solution**: All scripts now require newsletter name:
```bash
./run-newsletter.sh newsletter-name
./setup-cron.sh newsletter-name
./stop-cron.sh newsletter-name
```

### Issue: "Error: Newsletter directory not found"

**Cause**: Newsletter doesn't exist

**Solution**: Create from template:
```bash
cp -r newsletters/example newsletters/your-name
```

### Issue: WebSearch permission denied

**Cause**: Local permissions not configured

**Solution**: Add `"WebSearch"` and `"WebFetch"` to `.claude/settings.json` allow list in the project directory

### Issue: Can't write newsletter file

**Cause**: Local Write permission not configured

**Solution**: Add `"Write"` to `.claude/settings.json` allow list

### Issue: Can't execute Python script

**Cause**: Bash permission too restrictive

**Solution**: Use `"Bash(python3:*)"` to allow all python3 commands

### Issue: Email shows wrong sender address

**Cause**: Google Workspace overriding From header

**Solution**:
1. Enable "Allow per-user outbound gateways" in Admin Console
2. Add alternate address as "Send mail as" in Gmail settings

## Development Guidelines

### When modifying this project:

1. **Always test manually first**: Run `./run-newsletter.sh <name>` before updating cron
2. **Check logs**: Every run creates a timestamped log in `newsletters/{name}/logs/`
3. **Preserve permissions**: Don't modify `.claude/settings.json` without understanding impact
4. **Configuration split**:
   - SMTP credentials in `.env` (shared, gitignored)
   - Newsletter settings in `newsletters/{name}/config.json` (per-newsletter, gitignored)
5. **Use relative paths**: Keep the project portable
6. **Template pattern**: Users copy `newsletters/example/` to create new newsletters

### When adding features:

1. **Update permissions**: New tools may need new permissions
2. **Update documentation**: Keep README.md and this file in sync
3. **Test with multiple newsletters**: Ensure changes work for all newsletters
4. **Log everything**: Use `tee -a "$LOG_FILE"` for visibility
5. **Email compatibility**: Test changes in multiple email clients if modifying template

## File Locations (Relative to Project Root)

- **Newsletters**: `newsletters/{name}/output/newsletter-YYYY-MM-DD.html`
- **Logs**: `newsletters/{name}/logs/newsletter-YYYY-MM-DD.log`
- **Config**:
  - `.env` (SMTP config) - gitignored
  - `.env.example` (template) - committed
  - `newsletters/{name}/config.json` (newsletter settings) - gitignored
  - `newsletters/example/config.json` (template) - committed
- **Topics**: `newsletters/{name}/topics.md` - gitignored (except example)
- **Template**: `template.html` - committed
- **Prompt**: `prompt.md` - committed
- **Local Claude settings**: `.claude/settings.json` - gitignored

## Debugging

### List all newsletters:
```bash
ls -d newsletters/*/
```

### Check if cron jobs are running:
```bash
crontab -l | grep auto-bulletin
```

### View latest log for a newsletter:
```bash
tail -f newsletters/{name}/logs/newsletter-$(date +%Y-%m-%d).log
```

### Test email sending manually:
```bash
# Load .env first
set -a && source .env && set +a
python3 send_email.py newsletters/{name}/config.json newsletters/{name}/output/newsletter-YYYY-MM-DD.html
```

### Test specific newsletter manually:
```bash
./run-newsletter.sh newsletter-name
```

## Notes for Future Claude Sessions

When working with this project:

1. **Don't regenerate existing files**: The permissions, scripts, and structure are working
2. **Read logs first**: Check `newsletters/{name}/logs/` before making changes
3. **Test changes manually**: Always test with `./run-newsletter.sh <name>` before cron
4. **Respect permissions**: The `.claude/settings.json` files are carefully configured
5. **Update documentation**: Keep README.md and CLAUDE.md in sync with changes
6. **Configuration structure**:
   - `.env` - SMTP server, port, credentials (shared across all newsletters)
   - `newsletters/{name}/config.json` - Email addresses, branding, schedule, execution settings (per-newsletter)
7. **Use relative paths**: Keep project portable
8. **Template pattern**: `newsletters/example/` is the only newsletter tracked in git
9. **Newsletter independence**: Each newsletter is completely isolated (own config, topics, output, logs)

## Success Criteria

A successful newsletter run should:
- Exit with code 0
- Create a newsletter file in `newsletters/{name}/output/` with today's date
- Send an email with proper Metalmancy dark theme styling
- Display correctly in desktop and mobile email clients
- Log completion message with timestamp in `newsletters/{name}/logs/`
- Take several minutes to complete (due to thorough research)

Any deviation indicates an issue that should be investigated via logs.

## Multi-Newsletter Example

```bash
# Personal newsletter at 8:00 AM
./setup-cron.sh personal

# Work newsletter at 9:00 AM
./setup-cron.sh work

# Family newsletter with different schedule
./setup-cron.sh family

# View all configured newsletters
./stop-cron.sh
```

Each runs independently with its own:
- Topics (topics.md)
- Recipient (config.json)
- Schedule (config.json)
- Output and logs
