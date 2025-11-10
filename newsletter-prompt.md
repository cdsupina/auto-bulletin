Please perform the following task:

1. Read the file ~/Projects/daily-newsletter/interests.md to understand what topics I'm interested in

2. Check past newsletters to avoid repetition:
   - Read the 3 most recent newsletter files in ~/Projects/daily-newsletter/newsletters/
   - Note what topics and stories were already covered
   - Only include information that is genuinely new or has notable recent updates
   - It's okay to mention a topic again if there's significant new developments

3. Use WebSearch to find recent and relevant news/information about each topic from the past week

4. Read the newsletter template at ~/Projects/auto-bulletin/newsletter-template-email.html to understand the structure and style

5. Read the newsletter configuration at ~/Projects/auto-bulletin/newsletter-config.json to get branding values

6. Compile the findings into a well-formatted HTML newsletter using the template structure:
   - Replace {{TITLE}} with the value from newsletter-config.json
   - Replace {{SUBTITLE}} with the value from newsletter-config.json
   - Replace {{DATE}} with today's date in a readable format (e.g., "November 10, 2025")
   - Replace {{INTRO}} with a brief introduction paragraph
   - Replace {{FOOTER_BRAND}} with the value from newsletter-config.json
   - Replace {{FOOTER_TAGLINE}} with the value from newsletter-config.json
   - Replace {{FOOTER_CREDITS}} with the value from newsletter-config.json
   - Use the section pattern from the template for each topic
   - Include appropriate emoji for each section (🦀 for Rust, 🤖 for AI, etc.)
   - Each story should have: title (h3), content paragraph(s), and a source section
   - IMPORTANT: Each story/update MUST include at least one source link in the source section
   - Format sources as: <strong>Source:</strong> <a href="URL">Article Title - Publication Name</a>
   - DO NOT include a summary section at the end
   - It's okay to skip a topic section entirely if there is no genuinely new news for that topic
   - Use the <div class="divider"></div> between major topic sections for visual separation

7. Save the newsletter HTML to ~/Projects/auto-bulletin/newsletters/newsletter-$(date +%Y-%m-%d).html

8. Send the email using the existing send_email.py script:
   - Run: python3 ~/Projects/daily-newsletter/send_email.py ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
   - The script will use environment variables for email configuration

9. Report success or any errors encountered

Work autonomously and complete all steps.

Thank you!
