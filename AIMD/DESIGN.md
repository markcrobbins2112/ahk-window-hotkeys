---
title: DESIGN
---

<!-- # TEMPLATE: DESIGN.template.md -->
<!-- 
# DESIGN
# Any text bounded by double curly braces {{like this}} is a placeholder for you to fill out.
# Replace those placeholders with real paths, rules, and project constraints.
#
# INSTRUCTIONS FOR THE AI AGENT:
# Use this document as the single source of truth for the system's design patterns, constraints, and data flow. 
# Do not propose code or modifications that violate the patterns, structural layouts, or database schemas defined below.
-->

<!-- markdownlint-disable MD013 -->

# DESIGN

## 📑 AI Primary Files
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

## 🔍 Table of Contents
- [[#🗺️ System Topology & Context Map]] ^toc-topology
- [[#💻 High-Level Components & Communication]] ^toc-components
- [[#💾 Data Architecture & Schema Rules]] ^toc-data
- [[#📂 Core File Structure Layout]] ^toc-layout
- [[#🚦 Design Principles & Guardrails]] ^toc-guardrails
- [[#🚀 Go to...]] ^toc-goto

## 🗺️ System Topology & Context Map
[[#^toc-topology|TOC]]
- **Architecture Style:** Event-Driven Hotkey & UI Automation Layer (Procedural with Object-Oriented Component wrappers)
- **Primary Language Stack:** AutoHotkey v2 (Dynamic scripting language optimized for Windows desktop environments)
- **Frameworks & Core Runtimes:** Native AHK v2 Runtime engine utilizing the Win32 API and COM (Component Object Model) subsystems

## 💻 High-Level Components & Communication
[[#^toc-components|TOC]]
- **Frontend/Client:** Native Win32 GUI windows, system tray menus, and background keyboard/mouse hotkey hook listeners.
- **Backend Core:** AHK v2 runtime execution engine managing persistent event loops, dynamic thread state, and configuration mapping via native Map and Object structures.
- **External Integration:** Direct Win32 API calls via `DllCall()`, native OS automation hooks via `ComObject()`, and local hardware input/output simulation streams.

---

## 💾 Data Architecture & Schema Rules
[[#^toc-data|TOC]]
- **Storage Type:** Structured text INI files managed natively via the built-in `IniRead()` and `IniWrite()` engine functions.
- **State Constraints:** Clear logical grouping using localized `[Section]` headers and `Key=Value` string assignments, with mandatory fallback default values specified at the runtime initialization layer to prevent script crashes on missing configuration keys.


## 📂 Core File Structure Layout
[[#^toc-layout|TOC]]
```text
📂 Project Root/ # source and ini
├── 📂 AIMD/     # AI Markdown
├── 📂 {{tests_dir}}/      # Automated validation suites and fixture mock blocks
├── 📂 {{assets_dir}}/     # Graphic binaries, configuration templates, resources
└── 📂 docs/               # Technical specifications and human runbook maps
```

---

## 🚦 Design Principles & Guardrails
[[#^toc-guardrails|TOC]]
- **Dependency Minimization:** Avoid adding external packages/libraries unless natively impossible.
- **Separation of Concerns:** Keep presentation/UI entirely decoupled from system-level business logic.
- **Security Constraints:** {{Specify validation rules, e.g., Absolute sanitization metrics on incoming path parameters against injection mutations}}

---
## 🚀 Go to...
[[#^toc-goto|TOC]]
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

<!-- # TEMPLATE: DESIGN.template.md -->
