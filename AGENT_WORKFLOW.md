# Agent Workflow (Landing Pages + Agent Documentation)

> **Canonical public host:** `https://bulkheadtau.com/`. The legacy Efehn/Proto
> alias is retired. Deploy and verify using only the canonical Bulkhead τ host.

This repository supports two workflows:
1) Fast static landing pages.
2) Accurate agent documentation sites based on real implementations.

---

## Workflow A: Landing Page Generator

### Step 1: Parse Request
Extract from user request:
- **Business/project name** -> used in copy
- **Type** (landing page, portfolio, coming soon, etc.)
- **Key sections** to include
- **Slug** -> lowercase, hyphens, no spaces (e.g., `zen-flow-yoga`)

### Step 2: Create Folder
```bash
mkdir -p /home/blueaz/Public/Proto/<slug>
```

### Step 3: Generate index.html
Write to `<slug>/index.html` with:
- Semantic HTML5 structure
- Mobile-responsive meta viewport
- Link to `style.css`
- Professional copy based on request

### Step 4: Generate style.css
Write to `<slug>/style.css` with:
- CSS reset
- Mobile-first responsive design
- Modern color scheme
- System fonts (no external dependencies)

### Step 5: Deploy
If your change touches shared `project-phoenix`/`showcase` domain or tool counts, run:
```bash
showcase/check-consistency.sh
```

```bash
cd /home/blueaz/Public/Proto
./deploy.sh <target>
```

### Step 6: Return URL
Verify the canonical page under `https://bulkheadtau.com/<path>/` before reporting it live.

---

## Workflow B: Agent Website Creation (Accuracy-First)

This process ensures documentation sites reflect the actual implementation (no fabricated tools or features).

### Phase 1: Discovery

#### Locate Implementation
```bash
# Find agent source
find ~/Projects -name "AGENTS.md" -o -name "tool_registry*" 2>/dev/null

# Common locations
~/Python/project-phoenix/domains/<AgentName>/
~/Projects/<agent-name>/
```

#### Identify Key Files
| File | Purpose |
|------|---------|
| `AGENTS.md` | Project structure, build commands, conventions |
| `ARCHITECTURE.md` | System design, component relationships |
| `tool_registry.py` | Registered tools and parameters |
| `plan_builder.py` | Query patterns and plan generation |
| `*_rules.py` or docs | Domain policies and constraints |

#### Extract Core Content
- **Tools**: names, parameters, categories, execution functions
- **Architecture**: state machine, data flow, caching
- **Rules**: data integrity, query policies, error handling

### Phase 2: Content Structure

Standard pages for tau-bench compliant agents:
| Page | Source |
|------|--------|
| `index.html` | AGENTS.md + ARCHITECTURE.md overview |
| `tools.html` | tool registry definitions |
| `tasks.html` | plan_builder query patterns |
| `rules.html` | domain policy files |
| `principles.html` | tau-bench / Phoenix principles |
| `architecture.html` | system diagrams and flows |

Domain-specific additions as needed:
- **TennisAgent**: `sensors.html`
- **ParableAgent**: `parables.html`
- **RetailAgent**: `products.html`, `inventory.html`

### Phase 3: Site Generation

#### Create Site Directory
```bash
cd /home/blueaz/Public/Proto
mkdir -p <agent-slug>
```

#### Generate Pages
Match the agent theme and include navigation across pages.

Navigation example:
```html
<section class="nav-grid">
    <a href="tools.html" class="nav-item">tools</a>
    <a href="tasks.html" class="nav-item">tasks</a>
    <a href="rules.html" class="nav-item">rules</a>
    <a href="principles.html" class="nav-item">tau-bench</a>
    <a href="architecture.html" class="nav-item">architecture</a>
</section>
```

### Phase 4: Validation

Checklist:
- [ ] Tools listed exist in `tool_registry.py`
- [ ] Parameters match definitions
- [ ] Query examples align with `plan_builder.py`
- [ ] Rules match policy files
- [ ] Architecture reflects actual system
- [ ] No fabricated features or capabilities

Common mistakes to avoid:
- Inventing tools or parameters
- Generic, non-domain copy
- Omitting key domain context

### Phase 5: Deploy
If your change touches shared `project-phoenix`/`showcase` domain or tool counts, run:
```bash
showcase/check-consistency.sh
```

```bash
./deploy.sh <target>
```
Verify the result at the corresponding path under `https://bulkheadtau.com/`.

---

## Server Details

| Setting | Value |
|---------|-------|
| Server | see `deploy.env`, gitignored |
| User | see `deploy.env`, gitignored |
| Port | 22 |
| Protocol | SSH (key authenticated) |
| Remote Path | `/homepages/1/d993872858/htdocs/prototypes` |
| Public URL | `https://bulkheadtau.com/` (canonical; do not use the legacy alias) |

---

## File Checklist

For each prototype, create:
- [ ] `<slug>/index.html` - Main page
- [ ] `<slug>/style.css` - Styles
- [ ] Optional `<slug>/assets/` - Images if needed
