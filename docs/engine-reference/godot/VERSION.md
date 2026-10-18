# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7.2 |
| **Installed at pin time** | 4.7.2.stable.official.ed1daf0bf (matches the pin) — probed 2026-10-18 at `C:/Users/Sebastien/Downloads/Godot_v4.7.2-stable_win64_console.exe`; `godot` itself is not on PATH. |
| **Release Date** | 4.7: 2026-06-18 · 4.7.2 (maintenance): 2026-08-18 (per the official download archive, https://godotengine.org/download/archive/4.7.2-stable/) |
| **Project Pinned** | 2026-10-18 (previously 4.6, pinned 2026-02-12) |
| **Last Docs Verified** | 2026-10-18 (4.6→4.7 only; 4.4–4.6 sections verified 2026-02-12) |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
4.6 and 4.7 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.
**Risk level for 4.7.2: HIGH — beyond training data.**

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | 2026-06-18 | HIGH | AreaLight3D, HDR output, Control offset transforms, Tween.tween_await(), Jolt SoftBody3D/WorldBoundaryShape3D behaviour changes |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/
- Download archive (dates): https://godotengine.org/download/archive/4.7.2-stable/

## Not sourceable (as of 2026-10-18)

- NOT SOURCEABLE — 4.7 release date, not stated at the migration guide or the 4.7 release page; the date above comes from the download archive listing found via search, not from a fetched page body.
- NOT SOURCEABLE — Windows-specific export changes in 4.7, not mentioned at https://godotengine.org/releases/4.7/ or the migration guide.
- NOT SOURCEABLE — a `Forward+`/D3D12 rendering change in 4.7, none listed at either page; this is absence of mention, not confirmation that nothing changed.
