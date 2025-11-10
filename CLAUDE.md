# Daily Newsletter - Claude Code Documentation

This document explains how this project uses Claude Code and provides guidance for Claude when working with this codebase.

## Project Overview

An automated daily newsletter system that uses Claude Code in headless mode to:
1. Read user interests from `interests.md`
2. Search the web for recent news on those topics
3. Compile findings into an HTML newsletter
4. Send via email using SMTP

## Architecture

### Core Components

1. **run-newsletter.sh** - Main orchestration script
   - Loads environment variables from `.env`
   - Invokes Claude Code in headless mode with `-p` flag
   - Logs all output to `logs/newsletter-YYYY-MM-DD.log`
   - Uses full path to Claude: `/home/cdsupina/.local/bin/claude`

2. **send_email.py** - Email delivery script
   - Reads email configuration from environment variables
   - Accepts newsletter HTML file as argument
   - Sends via SMTP with TLS encryption
   - Provides detailed error messages for debugging

3. **setup-cron.sh** - Automation setup
   - Reads `NEWSLETTER_TIME` from `.env` (HH:MM format)
   - Converts to cron format (MINUTE HOUR * * *)
   - Manages cron job (add/update)
   - Allows manual override with cron syntax

4. **stop-cron.sh** - Automation control
   - Safely removes the cron job
   - Confirms removal with user feedback

### Configuration Files

**`.env`** - Runtime configuration:
```bash
EMAIL_TO=recipient@example.com           # Newsletter recipient
EMAIL_FROM=sender@example.com            # Visible sender address
SMTP_SERVER=smtp.gmail.com               # SMTP server
SMTP_PORT=587                            # SMTP port (587 for TLS)
SMTP_USERNAME=auth-user@example.com      # SMTP authentication username
SMTP_PASSWORD=app-password-here          # App password (not regular password)
NEWSLETTER_TIME=08:00                    # Delivery time (HH:MM format)
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

When `run-newsletter.sh` executes, it calls Claude Code like this:

```bash
/home/cdsupina/.local/bin/claude -p "Please perform the following task:

1. Read the file ~/Projects/daily-newsletter/interests.md to understand what topics I'm interested in
2. Use WebSearch to find recent and relevant news/information about each topic from the last 24 hours
3. Compile the findings into a well-formatted HTML newsletter with:
   - A brief introduction
   - Sections for each topic with 2-3 top stories/updates
   - Links to sources
   - A summary at the end
4. Save the newsletter HTML to ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
5. Send the email using the existing send_email.py script:
   - Run: python3 ~/Projects/daily-newsletter/send_email.py ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
   - The script will use environment variables for email configuration
6. Report success or any errors encountered

Work autonomously and complete all steps.

Thank you!"
```

## Task Workflow

1. **Read Interests**: Claude reads `interests.md` to understand topics
2. **Web Search**: Uses WebSearch tool to find recent news (last 24 hours)
3. **Content Compilation**: Creates HTML newsletter with:
   - Clean, readable formatting
   - Proper sections for each topic
   - 2-3 stories per topic with links
   - Introduction and summary
4. **Save Newsletter**: Writes to `newsletters/newsletter-YYYY-MM-DD.html`
5. **Send Email**: Executes `python3 send_email.py newsletters/newsletter-YYYY-MM-DD.html`
6. **Report Status**: Logs success or errors

## Common Issues and Solutions

### Issue: "claude: command not found" in cron

**Cause**: Cron doesn't have the same PATH as user sessions

**Solution**: Script uses full path `/home/cdsupina/.local/bin/claude`

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
5. **Full paths**: Always use full paths in cron-executed scripts

### When adding features:

1. **Update permissions**: New tools may need new permissions
2. **Update documentation**: Keep README.md and this file in sync
3. **Test in cron**: Run via cron to ensure it works in that environment
4. **Log everything**: Use `tee -a "$LOG_FILE"` for visibility

## File Locations

- **Newsletters**: `~/Projects/daily-newsletter/newsletters/newsletter-YYYY-MM-DD.html`
- **Logs**: `~/Projects/daily-newsletter/logs/newsletter-YYYY-MM-DD.log`
- **Config**: `~/Projects/daily-newsletter/.env`
- **Claude binary**: `/home/cdsupina/.local/bin/claude`
- **Global Claude settings**: `~/.claude/settings.json`
- **Local Claude settings**: `~/Projects/daily-newsletter/.claude/settings.json`

## Debugging

### Check if cron job is running:
```bash
crontab -l
ps aux | grep newsletter
```

### View latest log:
```bash
tail -f ~/Projects/daily-newsletter/logs/newsletter-$(date +%Y-%m-%d).log
```

### Test email sending:
```bash
cd ~/Projects/daily-newsletter
set -a && source .env && set +a
python3 send_email.py newsletters/newsletter-YYYY-MM-DD.html
```

### Test Claude Code manually:
```bash
cd ~/Projects/daily-newsletter
./run-newsletter.sh
```

## Notes for Future Claude Sessions

When working with this project:

1. **Don't regenerate existing files**: The permissions, scripts, and structure are working
2. **Read logs first**: Check `logs/` before making changes
3. **Test changes manually**: Always test with `./run-newsletter.sh` before cron
4. **Respect permissions**: The `.claude/settings.json` files are carefully configured
5. **Update documentation**: Keep README.md and CLAUDE.md in sync with changes
6. **Newsletter time**: Configured in `.env` as `NEWSLETTER_TIME=HH:MM`

## Success Criteria

A successful run should:
- Exit with code 0
- Create a newsletter file with today's date
- Send an email from `newsletter@metalmancy.tech` to `cdsupina@gmail.com`
- Log completion message with timestamp
- Take 2-3 minutes to complete

Any deviation indicates an issue that should be investigated via logs.
