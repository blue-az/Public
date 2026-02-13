# Deploy Checklist (fallacy-agent)

Local edits are not live until deploy runs.

## 1) Edit Files
- Update files under `/home/blueaz/Public/Proto/fallacy-agent/`.

## 2) Deploy
- From `/home/blueaz/Public/Proto` run:
  - `./deploy.sh fallacy-agent`

## 3) Verify Live
- Open: `https://proto.efehnconsulting.com/fallacy-agent/`
- Hard refresh: `Ctrl+Shift+R`
- Confirm expected changes (counts/layout/new links).

## 4) Quick Sanity
- Ensure `index.html` links still resolve:
  - `fallacies.html`
  - `case-studies.html`
  - `meta-principles.html`
  - `causal-drivers.html`
  - `defense-strategies.html`
  - `tools.html`
  - `guestbook.html`
