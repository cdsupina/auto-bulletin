Please perform the following task:

1. Read the file {{TOPICS_FILE}} to understand what topics I'm interested in

2. Check past newsletters to avoid repetition:
   - Read the 3 most recent newsletter files in {{OUTPUT_DIR}}
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
   - CRITICAL: When you fetch an article with WebFetch, record the EXACT URL you fetched - this is the URL you must use in the source link
   - Prefer direct article links over homepages - only link to a homepage if that IS the actual source (e.g., a new product announcement on a company's main page)

4. Read the newsletter template at {{TEMPLATE_FILE}} to understand the structure and style

5. Read the newsletter configuration at {{CONFIG_FILE}} to get branding values

6. Compile the findings into a well-formatted HTML newsletter using the template structure:
   - Replace {{TITLE}} with the value from {{CONFIG_FILE}}
   - Replace {{SUBTITLE}} with the value from {{CONFIG_FILE}}
   - Replace {{DATE}} with today's date in a readable format (e.g., "November 10, 2025")
   - Replace {{INTRO}} with a brief introduction paragraph
   - Replace {{FOOTER_BRAND}} with the value from {{CONFIG_FILE}}
   - Replace {{FOOTER_TAGLINE}} with the value from {{CONFIG_FILE}}
   - Replace {{FOOTER_CREDITS}} with the value from {{CONFIG_FILE}}
   - Use the section pattern from the template for each topic
   - Include appropriate emoji for each section (🦀 for Rust, 🤖 for AI, etc.)
   - Each story can use one of two formats:
     * PARAGRAPH FORMAT: For news articles, analysis, and general stories - includes title (h3), content paragraph(s), and a single source section at the bottom
       - Aim for approximately 100 words of story text (1-2 paragraphs)
       - Be concise and focus on the most important details
     * LIST FORMAT: For jobs, products, events, tools, or any content where you want to highlight 3-5 specific items with individual links - includes title (h3), optional intro paragraph, and then a list of items each with their own direct link
       - Keep intro paragraph brief (1-2 sentences if included)
       - Each list item description should be concise (1-2 sentences)
   - Use the LIST FORMAT when:
     * Presenting job openings (each job links to its posting)
     * Listing products or tools (each links to its page)
     * Highlighting events (each links to registration/details)
     * Showcasing specific examples where readers benefit from direct links to each item
     * The value is in the individual items rather than synthesizing them into a narrative
   - For LIST FORMAT, use contextually appropriate link text:
     * Job listings: "View listing →" or "Apply →"
     * Products/Tools: "Learn more →" or "Visit site →"
     * Events: "Register →" or "View event →"
     * Articles/Resources: "Read more →"
     * Choose the most natural phrasing for your specific content
   - Use the PARAGRAPH FORMAT when:
     * Covering news stories, updates, or announcements
     * Providing analysis or context that connects multiple sources
     * The narrative synthesis adds value beyond just listing items
   - IMPORTANT: Each story/update MUST include at least one source link
     * For PARAGRAPH FORMAT: Include a source section at the bottom with format: <strong>Source:</strong> <a href="URL">Article Title - Publication Name</a>
     * For LIST FORMAT: Each list item has its own direct link (no separate source section needed)
   - CRITICAL SOURCE LINK REQUIREMENTS:
     * Every source link MUST be meaningful and allow the reader to verify/read more about the story
     * Prefer specific article URLs (e.g., https://example.com/2025/11/article-name) over general pages
     * The URL should be the exact same URL you used with WebFetch to read the content
     * Homepage links are acceptable ONLY when the homepage itself is the source (e.g., a product launch page, official announcement page)
     * AVOID linking to generic section pages, category pages, or homepages when a specific article exists
     * Test: A reader clicking the link should land on content directly relevant to the story, with minimal extra navigation needed
   - DO NOT include a summary section at the end
   - It's okay to skip a topic section entirely if there is no genuinely new news for that topic
   - Use the <div class="divider"></div> between major topic sections for visual separation

7. Save the newsletter HTML to {{OUTPUT_DIR}}/newsletter-$(date +%Y-%m-%d).html
   - Always write/overwrite this file, even if it already exists
   - This is expected behavior - the script may be retrying or manually re-run

8. Send the email using the existing send_email.py script:
   - Run: python3 send_email.py {{CONFIG_FILE}} {{OUTPUT_DIR}}/newsletter-$(date +%Y-%m-%d).html
   - The script will read configuration from the specified config file

9. Report success or any errors encountered

Work autonomously and complete all steps. Do not ask for confirmation - always proceed with generating and overwriting the newsletter.
