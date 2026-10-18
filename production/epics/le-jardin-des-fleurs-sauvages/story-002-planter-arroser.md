# Story 002: Geste planter/arroser et floraison

> **Epic**: Le jardin des fleurs sauvages
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
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

- [ ] Amandine peut ramasser une graine, la planter à un emplacement libre, puis l'arroser par un geste simple (clic).
- [ ] Il n'existe aucun échec possible : aucune action ne bloque ni ne perd la progression.
- [ ] Arroser une graine plantée déclenche une animation de floraison lisible.
- [ ] Une fleur épanouie reste dans le jardin et son éclosion déclenche l'événement de souvenir lié (signal `flower_bloomed`).
- [ ] Les six graines se débloquent dans l'ordre de la fiche : rencontre, Boston, bague, Forrest, Seda, renaissance.

---

## Implementation Notes

- Les valeurs (durées, nombre de gestes) vivent dans un fichier de données, pas en dur. Les graines à ramasser sont posées dans le jardin.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Le contenu des souvenirs (003–004).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/planter-arroser-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003
