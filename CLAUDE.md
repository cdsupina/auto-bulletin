# The Auto Bulletin - Claude Code Documentation

This document explains how this project uses Claude Code and provides guidance for Claude when working with this codebase.

## Project Overview

An automated newsletter system that uses Claude Code in headless mode to:
1. Read user interests from `interests.md`
2. Conduct thorough web research on those topics using WebSearch and WebFetch
3. Compile findings into an email-optimized HTML newsletter with Metalmancy branding
4. Send via email using SMTP

## Architecture

### Core Components

1. **run-newsletter.sh** - Main orchestration script with timeout and retry
   - Loads environment variables from `.env`
   - Reads timeout and retry configuration from `newsletter-config.json`
   - Invokes Claude Code in headless mode with `-p` flag and timeout wrapper
   - Reads prompt from `newsletter-prompt.md`
   - Implements automatic retry logic with configurable delays
   - Logs all output to `logs/newsletter-YYYY-MM-DD.log` including retry attempts
   - Sends alert email if all retry attempts fail
   - Uses path to Claude from `CLAUDE_PATH` env variable or defaults to `claude`

2. **send_email.py** - Email delivery script
   - Reads email configuration from environment variables
   - Accepts newsletter HTML file as argument
   - Sends via SMTP with TLS encryption
   - Provides detailed error messages for debugging

3. **send_alert.py** - Failure notification script
   - Sends alert emails when newsletter generation fails after all retries
   - Uses same SMTP configuration as send_email.py
   - Sends to sender's email address (EMAIL_FROM) for monitoring
   - Includes failure details: date, attempts, timeout, log file location

4. **setup-cron.sh** - Automation setup
   - Reads `schedule.time` and `schedule.timezone` from `newsletter-config.json`
   - Converts to cron format (MINUTE HOUR * * *)
   - Sets TZ environment variable in cron entry if timezone specified
   - Manages cron job (add/update)
   - Allows manual override with cron syntax

5. **stop-cron.sh** - Automation control
   - Safely removes the cron job
   - Confirms removal with user feedback

6. **newsletter-prompt.md** - Instructions for Claude Code
   - Contains the detailed prompt that Claude follows
   - Specifies research depth and quality expectations
   - Uses relative paths for portability

7. **newsletter-template-email.html** - Email-optimized HTML template
   - Table-based layout for email client compatibility
   - Inline styles (no external CSS)
   - Dark theme matching Metalmancy aesthetic
   - Placeholders for dynamic content ({{TITLE}}, {{DATE}}, etc.)

8. **newsletter-config.json** - Branding, schedule, and execution configuration
   - Newsletter title and subtitle
   - Footer branding and text
   - Schedule time and timezone
   - Execution settings: timeout, max retries, retry delay
   - Separates content configuration from secrets

### Configuration Files

**`.env`** - Runtime secrets (gitignored):
```bash
EMAIL_TO=recipient@example.com           # Newsletter recipient
EMAIL_FROM=sender@example.com            # Visible sender address
ALERT_EMAIL=admin@example.com            # Where to send failure alerts (defaults to SMTP_USERNAME)
SMTP_SERVER=smtp.gmail.com               # SMTP server
SMTP_PORT=587                            # SMTP port (587 for TLS)
SMTP_USERNAME=auth-user@example.com      # SMTP authentication username
SMTP_PASSWORD=app-password-here          # App password (not regular password)
CLAUDE_PATH=/path/to/claude              # Optional: Path to Claude Code binary
```

**`newsletter-config.json`** - Newsletter configuration:
```json
{
  "title": "The Auto Bulletin",
  "subtitle": "by Metalmancy",
  "footer_brand": "METALMANCY",
  "footer_tagline": "Your daily dose of news and updates",
  "footer_credits": "Generated with Claude Code",
  "schedule": {
    "time": "08:00",
    "timezone": "America/Chicago"
  },
  "execution": {
    "timeout_minutes": 15,
    "max_retries": 3,
    "retry_delay_minutes": 5
  }
}
```

**`interests.md`** - User-defined topics:
- Free-form markdown file
- Claude reads this to understand what topics to search for
- Should be specific and clear

### Permissions

**Global permissions** (`~/.claude/settings.json`):
```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch"
    ]
  }
}
```

**Local permissions** (`.claude/settings.json`):
```json
{
  "permissions": {
    "allow": [
      "Bash(python3:*)",
      "Write"
    ]
  }
}
```

These permissions allow Claude Code to:
- Search the web and fetch content without prompting
- Create newsletter HTML files in the `newsletters/` directory
- Execute the Python email script

## How Claude Code Runs in Headless Mode

When `run-newsletter.sh` executes, it reads the prompt from `newsletter-prompt.md` and passes it to Claude Code in headless mode. The prompt instructs Claude to:

1. Read `interests.md` to understand topics
2. Check past newsletters to avoid repetition
3. Conduct thorough research using WebSearch and WebFetch
4. Read the template and config files
5. Compile findings into HTML using the template structure
6. Replace all placeholders with appropriate content
7. Save the newsletter HTML
8. Send the email using `send_email.py`
9. Report success or errors

## Task Workflow

1. **Read Interests**: Claude reads `interests.md` to understand topics
2. **Check History**: Reviews past 3 newsletters to avoid repetition
3. **Deep Research**: Uses WebSearch and WebFetch to find recent news
   - Searches multiple angles and sources
   - Looks for lesser-known but significant developments
   - Prioritizes quality and depth over speed
   - Aims for diverse sources
4. **Read Configuration**: Loads template and branding from files
5. **Content Compilation**: Creates HTML newsletter with:
   - Email-compatible table-based layout
   - Dark Metalmancy theme (purple/gold colors)
   - Proper sections with emoji icons
   - 2-3 stories per topic with source links
   - No summary section at end
6. **Save Newsletter**: Writes to `newsletters/newsletter-YYYY-MM-DD.html`
7. **Send Email**: Executes `python3 send_email.py newsletters/newsletter-YYYY-MM-DD.html`
8. **Report Status**: Logs success or errors

## Email Template Design

The newsletter uses `newsletter-template-email.html` which is optimized for email clients:

- **Table-based layout** - Better compatibility than div-based layouts
- **Inline styles** - All CSS in style="" attributes
- **No gradients** - Solid colors only for email client support
- **System fonts** - No web font imports
- **Dark theme** - Matches Metalmancy aesthetic:
  - Background: `#0e0e20`, `#27263a`
  - Accents: `#F0CD5A` (gold), `#8772d2` (purple)
  - Text: `#FFFFFE` (white), `#d1d1d1` (gray)

## Timeout and Retry Mechanism

The newsletter system includes automatic timeout and retry functionality to handle cases where Claude Code hangs or takes too long:

### How It Works

1. **Timeout Enforcement**: Each newsletter generation attempt is wrapped with the `timeout` command
   - Default: 15 minutes (configurable via `execution.timeout_minutes`)
   - If Claude doesn't complete within the timeout, the process is killed (exit code 124)

2. **Automatic Retries**: Failed attempts trigger automatic retries
   - Default: 3 attempts (configurable via `execution.max_retries`)
   - Includes 5-minute delay between retries (configurable via `execution.retry_delay_minutes`)
   - Each retry is logged with attempt number and timeout duration

3. **Alert on Total Failure**: If all retry attempts fail
   - `send_alert.py` sends a notification email to ALERT_EMAIL (or SMTP_USERNAME if not set)
   - Alert includes: date, number of attempts, timeout used, log file path
   - Allows for manual investigation and debugging
   - Note: Gmail blocks self-sent emails to aliases, so ALERT_EMAIL should be different from EMAIL_FROM

### Configuration

All timeout and retry settings are in `newsletter-config.json` under the `execution` section:

```json
"execution": {
  "timeout_minutes": 15,        // Max time per attempt
  "max_retries": 3,              // Total attempts
  "retry_delay_minutes": 5       // Wait time between retries
}
```

### Log Output

The enhanced logging shows:
- Attempt number (e.g., "Attempt 2 of 3")
- Timeout setting for each attempt
- Exit code and status (SUCCESS, TIMEOUT, FAILED)
- Retry delays
- Final outcome summary

### When Timeouts Occur

Common causes of timeouts:
- WebSearch API slow responses or rate limiting
- Claude API temporary issues
- Network connectivity problems
- Overly complex research tasks taking longer than expected

The retry mechanism handles these transient issues automatically without manual intervention.

## Common Issues and Solutions

### Issue: Newsletter looks wrong on mobile Gmail

**Cause**: Gmail mobile app's dark mode inverts colors

**Solution**: Template uses inline styles and solid colors to minimize conflicts. May need to add color-scheme meta tags if issues persist.

### Issue: "claude: command not found" in cron

**Cause**: Cron doesn't have the same PATH as user sessions

**Solution**: Set `CLAUDE_PATH` in `.env` with full path to Claude binary

### Issue: WebSearch permission denied

**Cause**: Global permissions not configured

**Solution**: Add WebSearch to `~/.claude/settings.json` allow list

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

1. **Always test manually first**: Run `./run-newsletter.sh` before updating cron
2. **Check logs**: Every run creates a timestamped log in `logs/`
3. **Preserve permissions**: Don't modify `.claude/settings.json` without understanding impact
4. **Environment variables**: All sensitive data goes in `.env`, never hardcode
5. **Use relative paths**: Keep the project portable, avoid hardcoded absolute paths
6. **Config in JSON**: Use `newsletter-config.json` for branding/schedule, not `.env`

### When adding features:

1. **Update permissions**: New tools may need new permissions
2. **Update documentation**: Keep README.md and this file in sync
3. **Test in cron**: Run via cron to ensure it works in that environment
4. **Log everything**: Use `tee -a "$LOG_FILE"` for visibility
5. **Email compatibility**: Test changes in multiple email clients if modifying template

## File Locations (Relative to Project Root)

- **Newsletters**: `newsletters/newsletter-YYYY-MM-DD.html`
- **Logs**: `logs/newsletter-YYYY-MM-DD.log`
- **Config**: `newsletter-config.json` (branding/schedule), `.env` (secrets)
- **Template**: `newsletter-template-email.html`
- **Prompt**: `newsletter-prompt.md`
- **Local Claude settings**: `.claude/settings.json`

## Debugging

### Check if cron job is running:
```bash
crontab -l
ps aux | grep newsletter
```

### View latest log:
```bash
tail -f logs/newsletter-$(date +%Y-%m-%d).log
```

### Test email sending:
```bash
set -a && source .env && set +a
python3 send_email.py newsletters/newsletter-YYYY-MM-DD.html
```

### Test Claude Code manually:
```bash
./run-newsletter.sh
```

## Notes for Future Claude Sessions

When working with this project:

1. **Don't regenerate existing files**: The permissions, scripts, and structure are working
2. **Read logs first**: Check `logs/` before making changes
3. **Test changes manually**: Always test with `./run-newsletter.sh` before cron
4. **Respect permissions**: The `.claude/settings.json` files are carefully configured
5. **Update documentation**: Keep README.md and CLAUDE.md in sync with changes
6. **Newsletter configuration**: Time and branding in `newsletter-config.json`, secrets in `.env`
7. **Use relative paths**: Keep project portable

## Success Criteria

A successful run should:
- Exit with code 0
- Create a newsletter file with today's date
- Send an email with proper Metalmancy dark theme styling
- Display correctly in desktop and mobile email clients
- Log completion message with timestamp
- Take several minutes to complete (due to thorough research)

Any deviation indicates an issue that should be investigated via logs.
