# Story 003: Scène de souvenir + souvenir « rencontre »

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

- [ ] Quand une fleur éclot, une scène de souvenir s'ouvre : une illustration, quelques lignes de texte et une citation courte en VO.
- [ ] Le texte avance par un clic et la scène se ferme pour revenir au jardin.
- [ ] Le souvenir « rencontre » (cupcakes et limonade, Salem et Thayer) est joué de bout en bout avec la fleur de Salem (tournesol par défaut ; pivoine à confirmer).
- [ ] Les contenus (textes, citations, chemins d'illustrations) sont dans un fichier de données éditable sans toucher au code.
- [ ] Aucun texte long n'est recopié des livres ; seules les citations courtes sont en VO.

---

## Implementation Notes

- Source du contenu : résumés et citations fournis par l'utilisateur (pas les livres). La citation « You're sunshine, Salem, but even the sun doesn't always shine. » est réservée à la bague (Story 004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Les cinq autres souvenirs (004).

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

- Depends on: Story 002
- Unlocks: Story 004
