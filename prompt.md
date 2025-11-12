Please perform the following task:

1. Read the file interests.md to understand what topics I'm interested in

2. Check past newsletters to avoid repetition:
   - Read the 3 most recent newsletter files in newsletters/
   - Note what topics and stories were already covered
   - Only include information that is genuinely new or has notable recent updates
   - It's okay to mention a topic again if there's significant new developments
   - IMPORTANT: If today's newsletter already exists, regenerate it anyway with fresh research - this is expected behavior for retries and manual runs

3. Conduct thorough research to find recent and relevant news/information about each topic from the past week:
   - Use WebSearch to find initial stories and sources
   - Use WebFetch to read full articles and gather detailed information
   - For each topic, search multiple angles and sources to find the most interesting stories
   - Look for lesser-known but significant developments, not just mainstream headlines
   - Prioritize quality and depth over speed - take time to find genuinely valuable content
   - Aim for diverse sources across different publications and communities

4. Read the newsletter template at template.html to understand the structure and style

5. Read the newsletter configuration at config.json to get branding values

6. Compile the findings into a well-formatted HTML newsletter using the template structure:
   - Replace {{TITLE}} with the value from config.json
   - Replace {{SUBTITLE}} with the value from config.json
   - Replace {{DATE}} with today's date in a readable format (e.g., "November 10, 2025")
   - Replace {{INTRO}} with a brief introduction paragraph
   - Replace {{FOOTER_BRAND}} with the value from config.json
   - Replace {{FOOTER_TAGLINE}} with the value from config.json
   - Replace {{FOOTER_CREDITS}} with the value from config.json
   - Use the section pattern from the template for each topic
   - Include appropriate emoji for each section (🦀 for Rust, 🤖 for AI, etc.)
   - Each story should have: title (h3), content paragraph(s), and a source section
   - IMPORTANT: Each story/update MUST include at least one source link in the source section
   - Format sources as: <strong>Source:</strong> <a href="URL">Article Title - Publication Name</a>
   - DO NOT include a summary section at the end
   - It's okay to skip a topic section entirely if there is no genuinely new news for that topic
   - Use the <div class="divider"></div> between major topic sections for visual separation

7. Save the newsletter HTML to newsletters/newsletter-$(date +%Y-%m-%d).html
   - Always write/overwrite this file, even if it already exists
   - This is expected behavior - the script may be retrying or manually re-run

8. Send the email using the existing send_email.py script:
   - Run: python3 send_email.py newsletters/newsletter-$(date +%Y-%m-%d).html
   - The script will use environment variables for email configuration

9. Report success or any errors encountered

Work autonomously and complete all steps. Do not ask for confirmation - always proceed with generating and overwriting the newsletter.
