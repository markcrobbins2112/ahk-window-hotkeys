---
title: ARCHIVE
---

<!-- TEMPLATE: ARCHIVE.template.md -->
<!-- 
ARCHIVE
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with sunset modules or deprecated code logic.

INSTRUCTIONS FOR THE AI AGENT:
Use this document to review retired systems, obsolete specifications, and discarded logic paths. 
Do not resurrect code snippets or architectural patterns from this file into the active codebase unless requested.
-->

<!-- markdownlint-disable MD013 -->

# ARCHIVE
<a id="a-archive"></a>[TOC](#toc-archive)

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔸 [ARCHIVE.md](ARCHIVE.md)
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
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [ARCHIVE](#a-archive) <a id="toc-archive"></a> ^toc-archive
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [🚪 Retired Features & Components](#a-retiredfeaturescomponents) <a id="toc-retiredfeaturescomponents"></a> ^toc-retiredfeaturescomponents
    - [❌ Web Server Preview & Node.js Bridge](#a-webserverpreviewnodejsbridge) <a id="toc-webserverpreviewnodejsbridge"></a> ^toc-webserverpreviewnodejsbridge
    - [❌ Combined Single-File Configuration Database](#a-combinedsinglefileconfigurationdatabase) <a id="toc-combinedsinglefileconfigurationdatabase"></a> ^toc-combinedsinglefileconfigurationdatabase
  - [💾 Legacy Code Snippets & Discarded Scripts](#a-legacycodesnippetsdiscardedscripts) <a id="toc-legacycodesnippetsdiscardedscripts"></a> ^toc-legacycodesnippetsdiscardedscripts
    - [📜 Legacy Express / Vite Web Server Scaffold](#a-legacyexpressvitewebserverscaffold) <a id="toc-legacyexpressvitewebserverscaffold"></a> ^toc-legacyexpressvitewebserverscaffold
  - [📑 Obsolete Specifications & Scrapped Ideas](#a-obsoletespecificationsscrappedideas) <a id="toc-obsoletespecificationsscrappedideas"></a> ^toc-obsoletespecificationsscrappedideas
    - [💡 Live Web UI Dashboard for AutoHotkey Hotkeys](#a-livewebuidashboardforautohotkeyhotkeys) <a id="toc-livewebuidashboardforautohotkeyhotkeys"></a> ^toc-livewebuidashboardforautohotkeyhotkeys
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 🚪 Retired Features & Components
<a id="a-retiredfeaturescomponents"></a>[TOC](#toc-retiredfeaturescomponents)
### ❌ Web Server Preview & Node.js Bridge
<a id="a-webserverpreviewnodejsbridge"></a>[TOC](#toc-webserverpreviewnodejsbridge)
- **Active Lifespan:** Initial Scaffold to 2026-07-23 (Retired on 2026-07-23)
- **Reason for Retirement:** User explicitly requested removal of all server infrastructure (`server.ts`, `App.tsx`, `vite.config.ts`, `tsconfig.json`) to keep the repository strictly focused as a standalone AutoHotkey v2.0 Windows application suite.
- **Superseded By:** Standalone desktop AutoHotkey runtime (`HotWinAHK.ahk`).

### ❌ Combined Single-File Configuration Database
<a id="a-combinedsinglefileconfigurationdatabase"></a>[TOC](#toc-combinedsinglefileconfigurationdatabase)
- **Active Lifespan:** Initial design to 2026-06-22
- **Reason for Retirement:** Walkthrough test logs and interactive keyboard/command state tracking cluttered user settings in `HotWinAHK.ini`.
- **Superseded By:** Decoupled `tests.ini` database file specifically dedicated to test metrics and walkthrough execution states.

---

## 💾 Legacy Code Snippets & Discarded Scripts
<a id="a-legacycodesnippetsdiscardedscripts"></a>[TOC](#toc-legacycodesnippetsdiscardedscripts)
### 📜 Legacy Express / Vite Web Server Scaffold
<a id="a-legacyexpressvitewebserverscaffold"></a>[TOC](#toc-legacyexpressvitewebserverscaffold)
- **Context:** Node.js Express server configured on port 3000 to proxy requests and render web previews.
- **Why it was replaced:** AutoHotkey v2.0 is a native Windows desktop executable that operates directly via Win32 API hooks rather than web server environments.
- **Legacy Implementation:**
  ```text
  ; --- OBSOLETE DO NOT USE ---
  import express from 'express';
  const app = express();
  app.listen(3000);
  ```

---

## 📑 Obsolete Specifications & Scrapped Ideas
<a id="a-obsoletespecificationsscrappedideas"></a>[TOC](#toc-obsoletespecificationsscrappedideas)
### 💡 Live Web UI Dashboard for AutoHotkey Hotkeys
<a id="a-livewebuidashboardforautohotkeyhotkeys"></a>[TOC](#toc-livewebuidashboardforautohotkeyhotkeys)
- **Proposed on:** 2026-06-10
- **The Concept:** Web-based browser UI for configuring hotkey maps and previewing active window layouts.
- **Why it failed/was dropped:** Native AutoHotkey v2.0 GUIs (`HelpScreen`, `CmdPalette`, `Settings`) provide direct Win32 overlay access with zero browser latency or external Node dependencies.

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔸 [ARCHIVE.md](ARCHIVE.md)
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
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: ARCHIVE.template.md -->
