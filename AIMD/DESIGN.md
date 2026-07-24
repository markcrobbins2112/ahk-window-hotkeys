---
title: DESIGN
---

<!-- TEMPLATE: DESIGN.template.md -->
<!-- 
DESIGN
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
Use this document as the single source of truth for the system's design patterns, constraints, and data flow. 
Do not propose code or modifications that violate the patterns, structural layouts, or database schemas defined below.
-->

<!-- markdownlint-disable MD013 -->

# DESIGN
<a id="a-design"></a>[TOC](#toc-design)

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔸 [DESIGN.md](DESIGN.md)
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
- [DESIGN](#a-design) <a id="toc-design"></a> ^toc-design
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [🗺️ System Topology & Context Map](#a-systemtopologycontextmap) <a id="toc-systemtopologycontextmap"></a> ^toc-systemtopologycontextmap
  - [💻 High-Level Components & Communication](#a-highlevelcomponentscommunication) <a id="toc-highlevelcomponentscommunication"></a> ^toc-highlevelcomponentscommunication
  - [💾 Data Architecture & Schema Rules](#a-dataarchitectureschemarules) <a id="toc-dataarchitectureschemarules"></a> ^toc-dataarchitectureschemarules
  - [📂 Core File Structure Layout](#a-corefilestructurelayout) <a id="toc-corefilestructurelayout"></a> ^toc-corefilestructurelayout
  - [🚦 Design Principles & Guardrails](#a-designprinciplesguardrails) <a id="toc-designprinciplesguardrails"></a> ^toc-designprinciplesguardrails
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 🗺️ System Topology & Context Map
<a id="a-systemtopologycontextmap"></a>[TOC](#toc-systemtopologycontextmap)
- **Architecture Style:** Event-Driven Hotkey & UI Automation Layer (Procedural with Object-Oriented Component wrappers)
- **Primary Language Stack:** AutoHotkey v2 (Dynamic scripting language optimized for Windows desktop environments)
- **Frameworks & Core Runtimes:** Native AHK v2 Runtime engine utilizing the Win32 API and COM (Component Object Model) subsystems

## 💻 High-Level Components & Communication
<a id="a-highlevelcomponentscommunication"></a>[TOC](#toc-highlevelcomponentscommunication)
- **Frontend/Client:** Native Win32 GUI windows, system tray menus, and background keyboard/mouse hotkey hook listeners.
- **Backend Core:** AHK v2 runtime execution engine managing persistent event loops, dynamic thread state, and configuration mapping via native Map and Object structures.
- **External Integration:** Direct Win32 API calls via `DllCall()`, native OS automation hooks via `ComObject()`, and local hardware input/output simulation streams.

---

## 💾 Data Architecture & Schema Rules
<a id="a-dataarchitectureschemarules"></a>[TOC](#toc-dataarchitectureschemarules)
- **Storage Type:** Structured text INI files managed natively via the built-in `IniRead()` and `IniWrite()` engine functions.
- **State Constraints:** Clear logical grouping using localized `[Section]` headers and `Key=Value` string assignments, with mandatory fallback default values specified at the runtime initialization layer to prevent script crashes on missing configuration keys.


## 📂 Core File Structure Layout
<a id="a-corefilestructurelayout"></a>[TOC](#toc-corefilestructurelayout)
```text
📂 Project Root/                  # Root source, scripts, and INI configs
├── 📂 AIMD/                      # AI Primary Markdown specifications & logs
├── 📄 HotWinAHK.ahk              # Main execution engine and event orchestrator
├── 📄 HotWinAHK.ini              # Master user hotkey and settings configuration
├── 📄 HotWinAHK_aux.ahk          # Dynamically compiled static AHK hotkey mappings
├── 📄 HotWinAHK_tray.ahk         # System tray icon and window stowing menu delegate
├── 📄 tests.ini                  # Walkthrough test states, ratings, and diagnostic logs
└── 📄 windows-hotkeys-homes.ini  # Persistent saved home window positions and bounds
```

---

## 🚦 Design Principles & Guardrails
<a id="a-designprinciplesguardrails"></a>[TOC](#toc-designprinciplesguardrails)
- **Dependency Minimization:** Avoid adding external packages/libraries unless natively impossible.
- **Separation of Concerns:** Keep presentation/UI entirely decoupled from system-level business logic.
- **Security Constraints:** Enforce administrative self-elevation (`RunAs`) for Win32 API window control, and sanitize hotkey string parsing against unvalidated input sequences.

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔸 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: DESIGN.template.md -->
