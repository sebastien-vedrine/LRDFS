# Story 004: Les cinq autres souvenirs

> **Epic**: Le jardin des fleurs sauvages
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature (see Epic table)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + the MVP feature this story implements), scoped to this story:*

- [ ] Boston (églantine, Caleb) : concert annulé, Thayer l'emmène, billets en fosse.
- [ ] La bague aux soleils (tournesol) : brocante, « rayon de soleil », la bague gardée pendant toutes ces années ; réplique VO « You're sunshine, Salem, but even the sun doesn't always shine. »
- [ ] Forrest (myosotis) : traité avec pudeur, la scène de la piscine n'est jamais montrée ni décrite ; Seda parle sur la tombe de son frère.
- [ ] Seda (muguet) : « esprit de la forêt », hommage à Forrest.
- [ ] La renaissance (rose de Jéricho, Thayer) : la fleur gardée en serre ; réplique VO du tome 2 sur la renaissance.
- [ ] Chaque souvenir réutilise la scène de la Story 003 et se joue depuis son éclosion.

---

## Implementation Notes

- Contenu fourni par l'utilisateur à partir de résumés. Répliques en VO ; ne pas inventer de dialogue absent des sources. Faire relire le ton de la scène Forrest par l'utilisateur.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- L'écran final (005).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Story 005
