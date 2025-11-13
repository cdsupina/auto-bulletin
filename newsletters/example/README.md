# Example Newsletter Template

This directory serves as a template for creating new newsletters. Copy it to create your own newsletter:

```bash
cp -r newsletters/example newsletters/your-newsletter
```

## Files in This Directory

- **config.json** - Newsletter configuration (title, branding, email addresses, schedule, etc.)
- **topics.md** - Topics you want the newsletter to cover
- **output/** - Directory where generated newsletters are saved
- **logs/** - Directory where execution logs are saved

## Custom HTML Template (Optional)

By default, all newsletters use the shared `template.html` at the project root. To use a custom template for this specific newsletter:

1. Copy the default template:
   ```bash
   cp template.html newsletters/your-newsletter/template.html
   ```

2. Customize the template to your liking (colors, fonts, layout, etc.)

3. The system will automatically use your custom template instead of the shared one

**Important**: Custom templates must:
- Maintain the same placeholder syntax (`{{TITLE}}`, `{{DATE}}`, etc.)
- Follow email-safe HTML practices (inline styles, table layouts, no external resources)
- Be tested before scheduling automated delivery

This allows you to have newsletters with completely different designs while sharing the same research and delivery infrastructure.
