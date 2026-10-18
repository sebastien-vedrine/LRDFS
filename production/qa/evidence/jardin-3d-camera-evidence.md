# Test Evidence: Jardin 3D, caméra et déplacement

> **Story**: `production/epics/le-jardin-des-fleurs-sauvages/story-001-jardin-3d-camera.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-18
> **Tester**: Claude (captures et mesure) + Sébastien (déplacement, fluidité, accord visuel)
> **Build / Commit**: working tree sur `main` (aucun commit à cette date)

---

## What Was Tested

Le jardin 3D au point d'apparition : ciel, végétation, six emplacements, chemin ; le déplacement et la souris ; la fluidité. Godot 4.7.2, Forward+, lancé en fenêtre 1280×720.

**Acceptance criteria covered**: AC-1, AC-2, AC-3, AC-4, AC-5

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Une scène Godot 3D unique représente un petit jardin à l'abandon, style low-poly aux couleurs douces. | PASS | Vu sur `05-path-fixed.png` : herbe haute, arbres, nuages. |
| AC-2 | Amandine peut se déplacer et regarder autour d'elle au clavier/souris ; la manette fonctionne en support partiel. | PASS (clavier/souris) | Confirmé par Sébastien. Manette : NON VÉRIFIÉE (touches définies, aucun test avec une manette). |
| AC-3 | Le jardin a des emplacements visibles où planter les 6 fleurs. | PASS | Six emplacements en arc, comptés sur l'image. |
| AC-4 | Le jeu tient 60 fps sur un PC modeste (budget de 16,6 ms par image). | PASS (sur la machine de test) | Mesure : ~1,5 ms par image (GTX 1070 Ti, 1280×720, vsync coupé, 10 s). Confirmé « fluide » par Sébastien. Pas mesuré sur un PC modeste. |
| AC-5 | `run/main_scene` de `project.godot` pointe vers cette scène et le jeu se lance. | PASS | `res://src/gameplay/garden/garden.tscn` ; lancé sans erreur. |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `jardin-3d-camera/01-spawn-view.png` | Première version : jardin propre, ciel uni | historique |
| 2 | `jardin-3d-camera/03-spawn-view-final.png` | Après correction du ciel et de l'herbe | historique |
| 3 | `jardin-3d-camera/04-richer-pass.png` | Passe riche : éclairage, herbe dense, nuages ; chemin flou | historique |
| 4 | `jardin-3d-camera/05-path-fixed.png` | Rendu final : chemin net, six emplacements | AC-1, AC-3 |

---

## Test Conditions

- **Game state at start**: lancement direct de la scène du jardin.
- **Platform / hardware**: Windows 10, NVIDIA GTX 1070 Ti, 1280×720.
- **Framerate during test**: ~1,5 ms par image (moyenne, p99 1,52 ms, max 1,84 ms).
- **Any special setup required**: aucun.

---

## Observations

- Rendu accepté comme « bon début » ; l'utilisateur souhaite un polish visuel en fin de projet (TD-001).
- Le chemin est pâle et sans texture par rapport à l'herbe.
- Manette non testée ; fluidité non mesurée sur un PC modeste ; le ressenti (poids, réactivité) est à valider en test de jeu.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | Sébastien | 2026-10-18 | [x] Approved |

Accord donné par l'utilisateur, avec polish prévu en fin de projet (TD-001).
