# efehnconsulting Legacy Recovery (2026-02-17)

## What happened
- `efehnconsulting.com` and related domains went through IONOS contract/domain/SSL reconfiguration.
- WordPress-backed paths intermittently failed with TLS errors and database connection errors.
- A direct WordPress restore path remained brittle because it depended on DB credentials/rights and app-level routing.

## Recovery approach
- Used backup archive: `~/Downloads/efehnconsulting.zip`.
- Extracted archive locally and identified IONOS page cache snapshots under:
  - `wp-content/cache/ionos-performance/https-efehnconsulting.com/`
- Built a static, DB-free site folder:
  - `efehnconsulting-legacy/`
- Rewrote old absolute links (`https://efehnconsulting.com/...`) to:
  - `https://proto.efehnconsulting.com/efehnconsulting-legacy/...`
- Copied required static assets (`wp-content/uploads`, theme assets, minimal wp-includes JS/CSS).

## Deploy result
- Deployed with: `./deploy.sh efehnconsulting-legacy`
- Live URL:
  - `https://proto.efehnconsulting.com/efehnconsulting-legacy/`
- Verified 200 responses for root and internal page(s).

## Why this is better
- No WordPress runtime dependency.
- No DB dependency.
- No plugin breakage risk for this restored snapshot.
- Can be updated/redeployed directly from this repo workflow.

## Notes
- This is a static snapshot of prior content/state.
- Dynamic WordPress features (admin, DB-backed APIs, forms/plugins) are not active in this restored version.
