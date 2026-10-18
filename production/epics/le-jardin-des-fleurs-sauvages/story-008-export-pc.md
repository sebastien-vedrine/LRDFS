# Story 008: Export Windows et test sur PC

> **Epic**: Le jardin des fleurs sauvages
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
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

- [ ] Un preset d'export « Windows Desktop » existe dans `export_presets.cfg`.
- [ ] L'export produit un .exe qui se lance sur un autre PC Windows sans installer Godot.
- [ ] Une partie complète est jouée sur le PC cible, de la dédicace au message final, sans blocage.
- [ ] Une capture d'écran de la dédicace, du jardin, d'un souvenir et de l'écran final est conservée dans `production/qa/evidence/`.
- [ ] Le fichier est prêt à envoyer avant le 12 novembre 2026.

---

## Implementation Notes

- Godot 4.7.2 doit être installé avec ses export templates ; `commands.build` et le chemin de l'exécutable sont à régler via `/settings`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Rien après : dernière story.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`) + the retained screenshots above

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001–007
- Unlocks: None
