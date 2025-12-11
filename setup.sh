#!/bin/bash
# Auto-Bulletin Setup Script
# Interactive setup for deploying auto-bulletin on a new machine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}            Auto-Bulletin Setup Wizard                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Step $1:${NC} $2"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}→${NC} $1"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}

    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

prompt_password() {
    local prompt="$1"
    local password

    read -p "$prompt: " password
    echo "$password"
}

check_dependencies() {
    print_step "2" "Checking Dependencies"

    local missing_deps=()

    # Check Python 3
    if command -v python3 &> /dev/null; then
        print_success "Python 3 found: $(python3 --version)"
    else
        print_error "Python 3 not found"
        missing_deps+=("python3")
    fi

    # Check Claude Code
    local claude_cmd="${CLAUDE_PATH:-claude}"
    if command -v "$claude_cmd" &> /dev/null; then
        print_success "Claude Code found: $claude_cmd"
    else
        print_error "Claude Code not found"
        print_info "Install from: https://github.com/anthropics/claude-code"
        missing_deps+=("claude")
    fi

    # Check cron
    if command -v crontab &> /dev/null; then
        print_success "cron found"
    else
        print_error "cron not found"
        missing_deps+=("cron")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install instructions:"
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                claude)
                    echo "  Claude Code: curl -fsSL https://claude.ai/install.sh | sh"
                    ;;
                *)
                    echo "  $dep:"
                    echo "    Debian/Ubuntu: sudo apt install $dep"
                    echo "    Arch: sudo pacman -S $dep"
                    ;;
            esac
        done
        echo ""
        if ! prompt_yes_no "Continue anyway?"; then
            exit 1
        fi
    else
        print_success "All required dependencies found!"
    fi
}

setup_smtp() {
    print_step "3" "SMTP Configuration"

    if [ -f "$SCRIPT_DIR/.env" ]; then
        print_warning "Existing .env file found"
        if ! prompt_yes_no "Reconfigure SMTP settings?"; then
            print_info "Keeping existing SMTP configuration"
            return
        fi
    fi

    echo ""
    echo "Configure your email sending settings."
    echo "For Gmail, use an App Password (not your regular password):"
    echo "  https://support.google.com/accounts/answer/185833"
    echo ""

    local smtp_server=$(prompt_input "SMTP Server" "smtp.gmail.com")
    local smtp_port=$(prompt_input "SMTP Port" "587")
    local smtp_username=$(prompt_input "SMTP Username (email)")
    local smtp_password=$(prompt_password "SMTP Password/App Password")
    local claude_path=$(prompt_input "Claude Code path" "claude")

    cat > "$SCRIPT_DIR/.env" << EOF
# SMTP Configuration (shared across all newsletters)
SMTP_USERNAME=$smtp_username
SMTP_PASSWORD=$smtp_password
SMTP_SERVER=$smtp_server
SMTP_PORT=$smtp_port

# Claude Code Path (optional, defaults to 'claude')
CLAUDE_PATH=$claude_path
EOF

    chmod 600 "$SCRIPT_DIR/.env"
    print_success "SMTP configuration saved to .env"
}

test_smtp() {
    print_step "4" "Testing SMTP Connection"

    if ! prompt_yes_no "Send a test email to verify SMTP settings?" "y"; then
        print_info "Skipping SMTP test"
        return
    fi

    local test_email=$(prompt_input "Email address to send test to")

    print_info "Sending test email..."

    # Source the .env file
    set -a
    source "$SCRIPT_DIR/.env"
    set +a

    local result
    result=$(python3 << EOF
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

try:
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'Auto-Bulletin Test Email'
    msg['From'] = os.environ['SMTP_USERNAME']
    msg['To'] = '$test_email'

    text = "This is a test email from Auto-Bulletin setup."
    html = """
    <html>
    <body style="background-color: #1a1a2e; color: #eee; padding: 20px; font-family: sans-serif;">
        <h2 style="color: #00d4ff;">Auto-Bulletin Test</h2>
        <p>If you're reading this, your SMTP settings are configured correctly!</p>
    </body>
    </html>
    """

    msg.attach(MIMEText(text, 'plain'))
    msg.attach(MIMEText(html, 'html'))

    server = smtplib.SMTP(os.environ['SMTP_SERVER'], int(os.environ['SMTP_PORT']))
    server.starttls()
    server.login(os.environ['SMTP_USERNAME'], os.environ['SMTP_PASSWORD'])
    server.send_message(msg)
    server.quit()

    print("SUCCESS")
except Exception as e:
    print(f"FAILED: {e}")
EOF
)

    if [[ "$result" == "SUCCESS" ]]; then
        print_success "Test email sent! Check your inbox."
    else
        print_error "Failed to send test email: $result"
    fi
}

setup_newsletter() {
    print_step "5" "Create a Newsletter"

    echo ""
    echo "Each newsletter has its own topics, recipient, and schedule."
    echo "You can create multiple newsletters later using this same process."
    echo ""

    if ! prompt_yes_no "Create a new newsletter now?" "y"; then
        print_info "Skipping newsletter creation"
        print_info "You can create one later by copying newsletters/example/"
        return
    fi

    local name=$(prompt_input "Newsletter name (lowercase, no spaces)" "my-newsletter")
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    local newsletter_dir="$SCRIPT_DIR/newsletters/$name"

    if [ -d "$newsletter_dir" ]; then
        print_warning "Newsletter '$name' already exists"
        if ! prompt_yes_no "Reconfigure it?"; then
            return
        fi
    else
        mkdir -p "$newsletter_dir"
        print_success "Created newsletter directory: newsletters/$name"
    fi

    # Get newsletter details
    local title=$(prompt_input "Newsletter title" "The Auto Bulletin")
    local subtitle=$(prompt_input "Subtitle/author" "by Metalmancy")

    # Get recipient emails (comma-separated)
    echo ""
    echo "Enter recipient email addresses (comma-separated for multiple):"
    local recipients_input=$(prompt_input "Recipient email(s)")

    # Source .env to get SMTP_USERNAME for default
    if [ -f "$SCRIPT_DIR/.env" ]; then
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
    fi
    local sender=$(prompt_input "Sender email address" "$SMTP_USERNAME")

    # Use first recipient as default for alerts
    local first_recipient=$(echo "$recipients_input" | cut -d',' -f1 | tr -d ' ')
    local alert_email=$(prompt_input "Alert email (for failures)" "$first_recipient")

    echo ""
    echo "Schedule (cron format):"
    echo "  0 8 * * *   = 8:00 AM daily"
    echo "  0 8 * * 1-5 = 8:00 AM weekdays"
    echo "  0 9 * * 0   = 9:00 AM Sundays"
    local schedule=$(prompt_input "Cron schedule" "0 8 * * *")
    local timezone=$(prompt_input "Timezone" "America/Chicago")

    # Execution settings
    echo ""
    echo "Execution settings:"
    local timeout=$(prompt_input "Timeout in minutes" "15")
    local max_retries=$(prompt_input "Max retries on failure" "3")

    # Convert comma-separated recipients to JSON array
    local recipients_json=$(echo "$recipients_input" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/.*/"&"/' | paste -sd ',' | sed 's/^/[/;s/$/]/')

    # Create config.json
    cat > "$newsletter_dir/config.json" << EOF
{
    "title": "$title",
    "subtitle": "$subtitle",
    "footer_brand": "AUTO-BULLETIN",
    "footer_tagline": "Your personalized news digest",
    "footer_credits": "Generated with Claude Code",
    "email": {
        "to": $recipients_json,
        "from": "$sender",
        "alert": "$alert_email"
    },
    "schedule": {
        "cron": "$schedule",
        "timezone": "$timezone"
    },
    "execution": {
        "timeout_minutes": $timeout,
        "max_retries": $max_retries,
        "retry_delay_minutes": 5
    }
}
EOF

    print_success "Created config.json"

    # Create topics.md if it doesn't exist
    if [ ! -f "$newsletter_dir/topics.md" ]; then
        echo ""
        echo "Now let's set up your topics of interest."
        echo "Be specific! Instead of 'technology', try 'Rust programming news'"
        echo ""

        if prompt_yes_no "Open topics.md in editor now?" "y"; then
            # Create a starter template
            cat > "$newsletter_dir/topics.md" << 'EOF'
# Topics of Interest

Add your topics below. Be specific for better results!

## Technology
-

## Other
-
EOF
            # Try to open in editor
            if [ -n "$EDITOR" ]; then
                $EDITOR "$newsletter_dir/topics.md"
            elif command -v nano &> /dev/null; then
                nano "$newsletter_dir/topics.md"
            elif command -v vim &> /dev/null; then
                vim "$newsletter_dir/topics.md"
            else
                print_warning "No editor found. Edit newsletters/$name/topics.md manually."
            fi
        else
            cp "$SCRIPT_DIR/newsletters/example/topics.md" "$newsletter_dir/topics.md" 2>/dev/null || \
            cat > "$newsletter_dir/topics.md" << 'EOF'
# Topics of Interest

## Technology
- Programming language updates and news
- Open source project releases

## General
- Science and technology breakthroughs
EOF
            print_info "Created topics.md with example content"
            print_info "Edit newsletters/$name/topics.md to customize"
        fi
    fi

    # Create output and logs directories
    mkdir -p "$newsletter_dir/output" "$newsletter_dir/logs"

    print_success "Newsletter '$name' configured!"

    # Offer to set up cron
    echo ""
    if prompt_yes_no "Set up cron job for this newsletter now?" "y"; then
        "$SCRIPT_DIR/setup-cron.sh" "$name"
        print_success "Cron job configured!"
    else
        print_info "Run './setup-cron.sh $name' later to enable scheduling"
    fi

    # Offer to test the newsletter
    echo ""
    if prompt_yes_no "Run a test generation for '$name'? (This may take several minutes)" "n"; then
        print_info "Running newsletter: $name"
        print_info "This may take several minutes..."
        echo ""
        "$SCRIPT_DIR/run-newsletter.sh" "$name"
    else
        print_info "Run './run-newsletter.sh $name' later to test"
    fi
}

verify_claude_auth() {
    print_step "1" "Verifying Claude Code Authentication"

    local claude_cmd="${CLAUDE_PATH:-claude}"

    print_info "Checking Claude Code authentication..."

    # Try a simple command to verify auth
    if $claude_cmd --version &> /dev/null; then
        print_success "Claude Code is accessible"
    else
        print_error "Cannot run Claude Code"
        print_info "You may need to run: claude login"
        if prompt_yes_no "Attempt to login now?"; then
            $claude_cmd login
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}                    Setup Complete!                         ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Quick reference:"
    echo ""
    echo "  Create a newsletter:    cp -r newsletters/example newsletters/NAME"
    echo "  Configure newsletter:   Edit newsletters/NAME/config.json"
    echo "  Set topics:             Edit newsletters/NAME/topics.md"
    echo "  Enable scheduling:      ./setup-cron.sh NAME"
    echo "  Disable scheduling:     ./stop-cron.sh NAME"
    echo "  Manual run:             ./run-newsletter.sh NAME"
    echo "  View logs:              cat newsletters/NAME/logs/newsletter-DATE.log"
    echo ""
    echo "Documentation: README.md"
    echo ""
}

main() {
    print_header

    echo "This wizard will help you set up Auto-Bulletin on this machine."
    echo "You can re-run this script at any time to reconfigure."
    echo ""

    if ! prompt_yes_no "Continue with setup?" "y"; then
        echo "Setup cancelled."
        exit 0
    fi

    verify_claude_auth
    check_dependencies
    setup_smtp
    test_smtp
    setup_newsletter
    print_summary
}

# Run main function
main "$@"
