# Web Prototypes - AI Landing Page Generator

> **Canonical public host:** `https://bulkheadtau.com/`. The legacy Efehn/Proto alias is retired;
> deploy and verify using only the canonical host.

## Quick Command

When user says: **"create a landing page for X"** or **"make a website about X"**

1. Generate site in `web_prototypes/<slug>/`
2. Deploy with `./deploy.sh <target>`.
3. Verify the resulting URL under `https://bulkheadtau.com/`.

## Workflow

```bash
cd /home/blueaz/Public/Proto

# 1. Create folder
mkdir -p <slug>

# 2. Generate index.html and style.css (AI creates content)

# 3. Deploy with ./deploy.sh <target>; verify at bulkheadtau.com.
```

## File Structure

Each prototype needs at minimum:
```
<slug>/
├── index.html
├── style.css
└── (optional: images/, script.js)
```

## HTML Template Pattern

Use modern, responsive HTML5:
- Mobile-first CSS
- System fonts (no external dependencies)
- Clean semantic HTML
- Professional color schemes

## Deploy Details

- **Server:** see `deploy.env` (gitignored); this repo is public
- **Path:** /homepages/1/d993872858/htdocs/prototypes/
- **Public URL:** https://bulkheadtau.com/ (canonical)

## Example Prompts

- "create a landing page for a coffee shop called Blue Brew"
- "make a portfolio site for a photographer"
- "build a coming soon page for an app called TaskFlow"
