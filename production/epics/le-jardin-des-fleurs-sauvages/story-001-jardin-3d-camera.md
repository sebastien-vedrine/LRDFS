# Story 001: Jardin 3D, caméra et déplacement

> **Epic**: Le jardin des fleurs sauvages
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-18

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

- [x] Une scène Godot 3D unique représente un petit jardin à l'abandon, style low-poly aux couleurs douces.
- [x] Amandine peut se déplacer dans le jardin et regarder autour d'elle au clavier/souris ; la manette fonctionne en support partiel.
- [x] Le jardin a des emplacements visibles où planter les 6 fleurs.
- [x] Le jeu tient 60 fps sur un PC modeste (budget de 16,6 ms par image).
- [x] `run/main_scene` de `project.godot` pointe vers cette scène et le jeu se lance.

---

## Implementation Notes

- Aucun personnage animé : la vue reste simple. Peu de modèles très simples (délai : 12 novembre).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Le geste planter/arroser (Story 002), les souvenirs (003–004).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/jardin-3d-camera-evidence.md`

**Status**: [x] Created — see Completion Notes

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

---

## Completion Notes
**Completed**: 2026-10-18
**Criteria**: 5/5 passing — AC-2 vérifié au clavier/souris seulement (manette non testée) ; AC-4 mesuré sur la machine de test seulement (~1,5 ms/image, GTX 1070 Ti)
**Deviations**: ADVISORY — valeurs de repli en dur dans `player.gd` et champ de vision 75° (TD-002) ; polish visuel demandé en fin de projet (TD-001)
**Test Evidence**: Visual/Feel — fiche `production/qa/evidence/jardin-3d-camera-evidence.md` (accord signé 2026-10-18), captures dans `production/qa/evidence/jardin-3d-camera/` (rendu final : `05-path-fixed.png`)
**Code Review**: Skipped (solo)
