# Repository Guidelines

## Project Structure & Module Organization
This repository hosts static prototype sites. Each site lives in its own folder (for example `demo-consulting/` or `parable-agent/`) and typically contains:
- `index.html` for markup
- `style.css` for styling
- optional `assets/` for images or other static files

Use `template/` as the baseline for new sites. The root also contains `deploy.sh` for publishing and workflow notes in `AGENT_WORKFLOW.md`.

## Build, Test, and Development Commands
There is no build step; edits are direct to HTML and CSS.

- `mkdir -p <slug>`: create a new site folder (use lowercase, hyphenated slugs like `zen-flow-yoga`).
- `showcase/check-consistency.sh`: validates shared domain/tool count copy across `project-phoenix` and `showcase` pages.
- `./deploy.sh <folder>`: rsyncs the site to the remote host and prints the live URL.

## Coding Style & Naming Conventions
- Indentation: 4 spaces in both HTML and CSS.
- File naming: keep the entry points as `index.html` and `style.css`.
- HTML: use semantic tags (`header`, `main`, `section`, `footer`) and keep structure readable.
- CSS: include a short reset at the top and prefer simple, explicit selectors.

## Testing Guidelines
No automated tests are set up. Validate changes by:
- Opening `index.html` in a browser for layout checks.
- Running `showcase/check-consistency.sh` when editing `project-phoenix` or `showcase` domain/tool counts.
- Deploying with `./deploy.sh <folder>` and verifying the live URL.

## Commit & Pull Request Guidelines
This repo is not currently under git history in this environment, so no commit convention is enforced. If you introduce git:
- Use short, imperative commit subjects (for example “Add hero section to demo-consulting”).
- PRs should include a brief summary, the target folder(s), and screenshots or a live URL when applicable.

## Deployment & Agent Workflow
For prototype creation and deployment, follow the process documented in `AGENT_WORKFLOW.md`, including the `./deploy.sh <folder>` command and the URL pattern:
`https://proto.efehnconsulting.com/<folder>/`.
