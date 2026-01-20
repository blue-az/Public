# Web Prototypes - AI Landing Page Generator

## Quick Command

When user says: **"create a landing page for X"** or **"make a website about X"**

1. Generate site in `web_prototypes/<slug>/`
2. Deploy with `./deploy.sh <slug>`
3. Report the URL

## Workflow

```bash
cd /home/blueaz/Public/Proto

# 1. Create folder
mkdir -p <slug>

# 2. Generate index.html and style.css (AI creates content)

# 3. Deploy
./deploy.sh <slug>
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

- **Server:** access993872858.webspace-data.io
- **Path:** /homepages/1/d993872858/htdocs/prototypes/
- **URL:** https://proto.efehnconsulting.com/<slug>/
- **Access:** SSH key authenticated

## Example Prompts

- "create a landing page for a coffee shop called Blue Brew"
- "make a portfolio site for a photographer"
- "build a coming soon page for an app called TaskFlow"
