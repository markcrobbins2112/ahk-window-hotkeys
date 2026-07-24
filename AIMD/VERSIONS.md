---
title: VERSIONS
---

<!-- TEMPLATE: VERSIONS.template.md -->
<!-- 
VERSIONS
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with semantic version history and deployment updates.

INSTRUCTIONS FOR THE AI AGENT:
Use this document to trace the evolution of the software across versions. 
When deploying a new stable release or version milestone, document it at the TOP of this file using semantic versioning.
-->

<!-- markdownlint-disable MD013 -->

# VERSIONS
<a id="a-versions"></a>[TOC](#toc-versions)

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
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔸 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [VERSIONS](#a-versions) <a id="toc-versions"></a> ^toc-versions
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [🚀 Stable Releases & Milestones](#a-stablereleasesmilestones) <a id="toc-stablereleasesmilestones"></a> ^toc-stablereleasesmilestones
    - [🏷️ v2.1.0 (2026-07-23) - Pure AutoHotkey v2 Desktop Suite & Decoupled Test Database](#a-v21020260723pureautohotkeyv2desktopsuitedecoupledtestdatabase) <a id="toc-v21020260723pureautohotkeyv2desktopsuitedecoupledtestdatabase"></a> ^toc-v21020260723pureautohotkeyv2desktopsuitedecoupledtestdatabase
    - [🏷️ v2.0.0 (2026-06-22) - Modular HotWinAHK Architecture & Interactive UI Overhaul](#a-v20020260622modularhotwinahkarchitectureinteractiveuioverhaul) <a id="toc-v20020260622modularhotwinahkarchitectureinteractiveuioverhaul"></a> ^toc-v20020260622modularhotwinahkarchitectureinteractiveuioverhaul
  - [🏗️ Pre-Release Iterations (Alpha/Beta Sandbox)](#a-prereleaseiterationsalphabetasandbox) <a id="toc-prereleaseiterationsalphabetasandbox"></a> ^toc-prereleaseiterationsalphabetasandbox
    - [🏷️ v1.0.0 (2026-01-15) - Initial Hotkey Window Manager Launch](#a-v10020260115initialhotkeywindowmanagerlaunch) <a id="toc-v10020260115initialhotkeywindowmanagerlaunch"></a> ^toc-v10020260115initialhotkeywindowmanagerlaunch
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 🚀 Stable Releases & Milestones
<a id="a-stablereleasesmilestones"></a>[TOC](#toc-stablereleasesmilestones)
### 🏷️ v2.1.0 (2026-07-23) - Pure AutoHotkey v2 Desktop Suite & Decoupled Test Database
<a id="a-v21020260723pureautohotkeyv2desktopsuitedecoupledtestdatabase"></a>[TOC](#toc-v21020260723pureautohotkeyv2desktopsuitedecoupledtestdatabase)
- **Added / Enhanced:**
  - Complete decoupling of test metrics and walkthrough execution logs into [`tests.ini`](../tests.ini).
  - Thorough documentation overhaul across all 14 AI primary files in accordance with `markdown-transform` guidelines.
- **Fixed / Patched:**
  - Stripped all legacy Node.js Express server bridge files and web preview scaffolds.
  - Enforced strict "No Hash Symbols in Comments" rule across project header comments and `TEMPLATE:` comments.
- **Breaking Changes & Remediations:**
  - Removed server entry points (`server.ts`, `App.tsx`, `vite.config.ts`, `tsconfig.json`).
    - *Remediation:* Run [`HotWinAHK.ahk`](../HotWinAHK.ahk) directly with native AutoHotkey v2.0+.

### 🏷️ v2.0.0 (2026-06-22) - Modular HotWinAHK Architecture & Interactive UI Overhaul
<a id="a-v20020260622modularhotwinahkarchitectureinteractiveuioverhaul"></a>[TOC](#toc-v20020260622modularhotwinahkarchitectureinteractiveuioverhaul)
- **Summary:** Complete refactoring of HotWinAHK to feature dynamic on-the-fly INI hotkey compilation, Desk3D parallax mode, and interactive window picker GUIs.
- **Core Capabilities:**
  - Dynamic INI-to-AHK hotkey compilation engine ([`HotWinAHK_aux.ahk`](../HotWinAHK_aux.ahk)).
  - Standalone tray helper isolation ([`HotWinAHK_tray.ahk`](../HotWinAHK_tray.ahk)).

---

## 🏗️ Pre-Release Iterations (Alpha/Beta Sandbox)
<a id="a-prereleaseiterationsalphabetasandbox"></a>[TOC](#toc-prereleaseiterationsalphabetasandbox)
### 🏷️ v1.0.0 (2026-01-15) - Initial Hotkey Window Manager Launch
<a id="a-v10020260115initialhotkeywindowmanagerlaunch"></a>[TOC](#toc-v10020260115initialhotkeywindowmanagerlaunch)
- **Milestone:** Baseline window snapping and border docking release.

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
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔸 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: VERSIONS.template.md -->
