# Team presentation materials

Presentations are **versioned by milestone** so you can revisit an older deck without losing it.

| Folder | Scope | When to use |
|--------|--------|-------------|
| [phase5-team-review](./phase5-team-review/) | Phases 0–5, E2E PASS | Team demo after Phase 5; **leave intact** when Phase 6 starts |
| [phase6-team-review](./phase6-team-review/) | Phases 0–6, Config PASS | Team demo after Phase 6 |
| [phase7-team-review](./phase7-team-review/) | Phases 0–7, RPO monitor PASS | Full lab story |

Shared visual theme (colors, fonts, card layouts): [`theme.py`](./theme.py).

## Phase 5 deck (DR through E2E — frozen)

```powershell
python docs/presentations/phase5-team-review/generate_team_deck.py
```

**Output:** `docs/presentations/phase5-team-review/Home-Healthcare-AWS-Backup-DR-Phase5-Team-Deck.pptx`

## Phase 6 deck (includes Config)

```powershell
pip install python-pptx
python docs/presentations/phase6-team-review/generate_team_deck.py
```

**Output:** `docs/presentations/phase6-team-review/Home-Healthcare-AWS-Backup-DR-Phase6-Team-Deck.pptx`

**Demo guide:** [phase6-team-review/TEAM-DEMO-WALKTHROUGH.md](./phase6-team-review/TEAM-DEMO-WALKTHROUGH.md)

## Phase 7 deck

```powershell
python docs/presentations/phase7-team-review/generate_team_deck.py
```

**Output:** `docs/presentations/phase7-team-review/Home-Healthcare-AWS-Backup-DR-Phase7-Team-Deck.pptx`

## Theme

Dark navy background (`#0D1627`), **Segoe UI**, **teal** (`#48C0D8`), **orange** (`#F9A825`) highlight cards, three-column layout on key slides, footer + page numbers.

Layout code lives in `theme.py`; each phase folder owns **`SLIDES`** content and **`FOOTER_LEFT`** / output `.pptx` name.

## Start Phase 6 presentation (copy, don’t overwrite)

When Phase 6 work is ready for a team review:

```powershell
cd docs/presentations
Copy-Item -Recurse phase5-team-review phase6-team-review
```

Then in **`phase6-team-review/`** only:

1. Set `OUTPUT` to e.g. `Home-Healthcare-AWS-Backup-DR-Phase6-Team-Deck.pptx`
2. Set `FOOTER_LEFT` to e.g. `HOME HEALTHCARE AWS BACKUP/DR • PHASE 6 TEAM REVIEW`
3. Update `SLIDES` (Phase 6 slides, “what’s next”, scope bullets)
4. Update `TEAM-DEMO-WALKTHROUGH.md` (Config console steps, new evidence paths)
5. Add `phase6-team-review/README.md` header line describing Phase 6 scope
6. Run `python docs/presentations/phase6-team-review/generate_team_deck.py`

Do **not** edit `phase5-team-review/` for Phase 6 content unless you deliberately refresh the Phase 5 snapshot.

## Customization

Replace `[Your Name]` and `[Today]` on slide 1 in the phase-specific `generate_team_deck.py` before presenting (if you add those placeholders).
