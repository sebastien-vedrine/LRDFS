# Story 005: Écran final et message

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

- [ ] Quand les six fleurs ont éclos, une scène finale montre la naissance de Soleil.
- [ ] Le message « Joyeux 25 ans Amandine, je t'aime » s'affiche ensuite.
- [ ] Le message est éditable dans un fichier de données (l'utilisateur pourra l'ajuster).
- [ ] Une session complète (première graine à message final) dure environ 15 à 20 minutes.

---

## Implementation Notes

- Le message vient de l'utilisateur ; ne pas le réécrire sans demande.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- La dédicace d'ouverture (006).

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

- Depends on: Story 004
- Unlocks: Story 006
