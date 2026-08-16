# AVD Reference Library — GitHub Pages site

Source for the Air Vehicle Design reference library, published at
<https://idopt-lab.github.io/air-vehicle-design/>.

## How it is published

The site is built by `.github/workflows/pages.yml` on every push to `main` that touches
`references/**`. It is **not** served by Pages' "deploy from a branch" mode — that mode
can only serve `/` or `/docs`, and `docs/` is reserved here for code documentation. The
workflow runs the same `github-pages` Jekyll build, so `remote_theme` works exactly as it
would natively.

One-time repository setting:

**Settings → Pages → Build and deployment → Source: GitHub Actions**

No local Ruby or Jekyll install is needed.

### baseurl

This is a project site, so it serves under a subpath and `_config.yml` must carry:

```yaml
url: "https://idopt-lab.github.io"
baseurl: "/air-vehicle-design"
```

Every internal link on the site is written as `{{ site.baseurl }}/page/`. If `baseurl` is
emptied or the repository is renamed, all of them 404. There is no way to notice this
locally without a full Jekyll build, so treat it as load-bearing.

### Editing workflow

Work on the long-lived `references` branch, then merge to `main` to publish:

```bash
git checkout references
# ...edit under references/...
git commit -am "references: ..."
git push
# open a PR, merge to main -> the workflow publishes
git checkout references && git merge main    # fast-forward so the branch doesn't drift
```

Merging is what publishes. Pushing to the `references` branch alone changes nothing on
the live site.

## Theme

Uses [just-the-docs](https://just-the-docs.com/) via `remote_theme`, which GitHub Pages
supports natively. It provides the left sidebar navigation and full-text search with no
build configuration.

To preview locally (optional):

```bash
gem install bundler jekyll
bundle init
bundle add jekyll github-pages webrick
bundle exec jekyll serve
```

## File layout

| File | Page |
|------|------|
| `index.md` | Start Here — ID scheme, availability tags, page index |
| `course-modules.md` | Course Modules — Raj's 22 decks, syllabi, reference crosswalk |
| `foundations.md` | Foundations & Design Process |
| `requirements-conops.md` | Requirements & Concept of Operations |
| `aerodynamics.md` | Aerodynamics |
| `configuration-fuselage.md` | Configuration & Fuselage |
| `propulsion-performance.md` | Propulsion & Performance |
| `stability-control.md` | Stability & Control |
| `structures-weights.md` | Structures & Weights |
| `cost.md` | Cost & Value |
| `survivability-stealth.md` | Survivability & Stealth |
| `subsystems-avionics.md` | Subsystems & Avionics |
| `operations-environment.md` | Operations, Market & Environment |
| `electrified-aircraft.md` | Electrified Aircraft |
| `case-studies.md` | Mission Case Studies |
| `project-management-ethics.md` | Project Management & Ethics |
| `industry-news.md` | Industry News & Current Events |

## Adding a reference

Follow the existing pattern. Within a topic, under `### Primary References` or
`### Secondary References`:

```markdown
1. **CAT-TOP-P01** — [Title](https://url)
   Author, A. B., "Full Title," *Publication*, Vol., No., Year, pp. doi:...
   One or two sentences on what it is and when to use it.
   `Open`
```

Availability tag is one of `Open`, `Publisher`, or `Citation only`.
Category codes are listed on the Start Here page. Keep IDs stable once published —
students will be citing them.

An optional `VT access: [...](url)` line goes immediately above the tag, for entries that
Virginia Tech subscribes to through Knovel, Wiley, ScienceDirect or ProQuest. These come
from Prof. Raj's *List of Primary References* (August 2024) with search-session query
strings stripped. The public link stays the main one — the VT link is an extra, because
the site is meant to work for readers outside VT too.

If you add or renumber an entry that appears in Prof. Raj's list, update the crosswalk
table at the bottom of `course-modules.md` — it is what lets students follow a citation
from his slides into this library.

## Link maintenance

All external links were verified when the site was built. A few hosts
(DTIC, ScienceDirect, AIAA ARC, Medium, Aviation Week) block automated checkers but work
normally in a browser. If you add an automated link checker to CI, allowlist those hosts
to avoid false failures.
