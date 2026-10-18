# Test Evidence: Geste planter/arroser et floraison

> **Story**: `production/epics/le-jardin-des-fleurs-sauvages/story-002-planter-arroser.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-18
> **Tester**: Claude (captures, script de logique sans affichage) + Sébastien (partie jouée, accord visuel)
> **Build / Commit**: working tree sur `master`, après `cca7c31` (non commité)

---

## What Was Tested

La boucle ramasser une graine, la planter, l'arroser jusqu'à la floraison, pour les six fleurs dans l'ordre de la fiche, et le rendu des fleurs.

**Acceptance criteria covered**: AC-1, AC-2, AC-3, AC-4, AC-5

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Amandine peut ramasser une graine, la planter à un emplacement libre, puis l'arroser par un geste simple (clic). | PASS | Confirmé par Sébastien en jouant ; vérifié aussi par un script sans affichage. |
| AC-2 | Il n'existe aucun échec possible : aucune action ne bloque ni ne perd la progression. | PASS | Script : planter sur une place occupée refusé, graine conservée. Sébastien : jamais bloqué sur les six. |
| AC-3 | Arroser une graine plantée déclenche une animation de floraison lisible. | PASS | Capture `demo-blooming.png` (tournesol) ; accord visuel de Sébastien. |
| AC-4 | Une fleur épanouie reste dans le jardin et son éclosion déclenche l'événement de souvenir lié (signal `flower_bloomed`). | PASS | Script : le signal part 6 fois, les six fleurs restent. La scène de souvenir elle-même est la story 003. |
| AC-5 | Les six graines se débloquent dans l'ordre de la fiche : rencontre, Boston, bague, Forrest, Seda, renaissance. | PASS | Script : ordre vérifié. Sébastien : les six dans l'ordre. |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `planter-arroser/demo-seeds.png` | Graine lumineuse et « Ramasser la graine » | AC-1 |
| 2 | `planter-arroser/demo-watering.png` | Graine plantée, éclaboussure, « Arroser » | AC-1 |
| 3 | `planter-arroser/demo-blooming.png` | Tournesol en floraison, étincelles | AC-3 |
| 4 | `planter-arroser/demo-garden-full.png` | Six fleurs (première version), vue de départ | AC-4 |
| 5 | `planter-arroser/demo2-garden-full.png` | Six fleurs, après agrandissement des trois petites | AC-4 |
| 6 | `planter-arroser/demo2-garden-full-close.png` | Myosotis, muguet, rose de Jéricho de près | AC-3, AC-4 |

---

## Test Conditions

- **Game state at start**: partie neuve ; captures prises avec l'option de démonstration `--demo-state=<état>` (réservée au test).
- **Platform / hardware**: Windows 10, NVIDIA GTX 1070 Ti, 1280×720.
- **Framerate during test**: non remesuré pour cette story (1,5 ms par image mesuré pour le jardin de la story 001).
- **Any special setup required**: états de démonstration pour les captures ; partie réelle jouée par Sébastien.

---

## Observations

- Depuis le point de départ, le myosotis, le muguet et la rose de Jéricho restent discrets dans l'herbe ; de près, ils se lisent bien.
- Manette non testée.
- Le ressenti du geste (poids, réactivité) reste à valider en test de jeu plus large.
- L'animation de floraison n'a été vue en cours d'éclosion que sur le tournesol ; les autres fleurs ont été vues épanouies.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | Sébastien | 2026-10-18 | [x] Approved |

Accord donné par l'utilisateur après avoir joué et vu les captures.
