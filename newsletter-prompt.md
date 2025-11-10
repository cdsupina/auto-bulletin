Please perform the following task:

1. Read the file ~/Projects/daily-newsletter/interests.md to understand what topics I'm interested in

2. Check past newsletters to avoid repetition:
   - Read the 3 most recent newsletter files in ~/Projects/daily-newsletter/newsletters/
   - Note what topics and stories were already covered
   - Only include information that is genuinely new or has notable recent updates
   - It's okay to mention a topic again if there's significant new developments

3. Use WebSearch to find recent and relevant news/information about each topic from the past week

4. Compile the findings into a well-formatted HTML newsletter with:
   - A brief introduction
   - Sections for each topic with 2-3 top stories/updates
   - IMPORTANT: Each story/update MUST include at least one source link
   - Format sources clearly (e.g., "Source: [Article Title](URL)" or as inline links)
   - DO NOT include a summary section at the end
   - It's okay to skip a topic section entirely if there is no genuinely new news for that topic

5. Save the newsletter HTML to ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html

6. Send the email using the existing send_email.py script:
   - Run: python3 ~/Projects/daily-newsletter/send_email.py ~/Projects/daily-newsletter/newsletters/newsletter-$(date +%Y-%m-%d).html
   - The script will use environment variables for email configuration

7. Report success or any errors encountered

Work autonomously and complete all steps.

Thank you!
