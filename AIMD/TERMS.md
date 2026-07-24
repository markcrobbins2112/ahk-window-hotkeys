---
title: TERMS
---

<!-- TEMPLATE: TERMS.template.md -->
<!-- 
TERMS
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real project terms, definitions, and acronym boundaries.

INSTRUCTIONS FOR THE AI AGENT:
Use this document to resolve semantic naming conventions, acronyms, and systemic definitions. 
When generating code comments, documentation, or logs, always use these exact terms to describe structural components.
-->

<!-- markdownlint-disable MD013 -->

# TERMS
<a id="a-terms"></a>[TOC](#toc-terms)

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔸 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [TERMS](#a-terms) <a id="toc-terms"></a> ^toc-terms
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [🔤 Core Glossary A-Z](#a-coreglossaryaz) <a id="toc-coreglossaryaz"></a> ^toc-coreglossaryaz
    - [Tuck / Untuck](#a-tuckuntuck) <a id="toc-tuckuntuck"></a> ^toc-tuckuntuck
    - [Velocity Bump](#a-velocitybump) <a id="toc-velocitybump"></a> ^toc-velocitybump
  - [🗂️ System Acronym Quick-Reference](#a-systemacronymquickreference) <a id="toc-systemacronymquickreference"></a> ^toc-systemacronymquickreference
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 🔤 Core Glossary A-Z
<a id="a-coreglossaryaz"></a>[TOC](#toc-coreglossaryaz)
### Tuck / Untuck
<a id="a-tuckuntuck"></a>[TOC](#toc-tuckuntuck)
- **Definition:** Stowing an active window frame off-screen against a monitor boundary, leaving only a tiny clickable/hoverable margin edge visible (Tuck), and restoring it when triggered (Untuck).
- **Code Implementation Context:** Managed via `TuckWindow()` and `UntuckWindow()` functions in [`HotWinAHK.ahk`](../HotWinAHK.ahk).
- **Synonyms / Avoid:** Avoid using "hide/unhide" or "minimize/restore" as Tuck refers specifically to margin docking.

### Velocity Bump
<a id="a-velocitybump"></a>[TOC](#toc-velocitybump)
- **Definition:** Accelerating the mouse pointer rapidly against a screen margin to untuck a stowed window without needing hotkeys or clicking.
- **Code Implementation Context:** Evaluated every 25ms in the main loop of [`HotWinAHK.ahk`](../HotWinAHK.ahk) by calculating Euclidean cursor travel distance.

---

## 🗂️ System Acronym Quick-Reference
<a id="a-systemacronymquickreference"></a>[TOC](#toc-systemacronymquickreference)
| Acronym / Token | Full Expansion | Technical Scope |
| :--- | :--- | :--- |
| **`AHK`** | AutoHotkey | The scripting language and execution engine for HotWinAHK. |
| **`HWND`** | Handle to Window | Win32 unique identifier for an active window instance. |
| **`COM`** | Component Object Model | Microsoft binary-code interface standard used for shell integration. |

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔸 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: TERMS.template.md -->
