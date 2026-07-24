---
title: AGENTS
---

<!-- TEMPLATE: AGENTS.template.md -->
<!-- 
AGENTS
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file defines your operational boundaries, tools, platforms, and roles.
Adhere strictly to the boundaries and prompts defined for your assigned persona.
-->

<!-- markdownlint-disable MD013 -->

# AGENTS
<a id="a-agents"></a>[TOC](#toc-agents)

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔸 [AGENTS.md](AGENTS.md)
- 🔹 [ARCHIVE.md](AIMD/ARCHIVE.md)
- 🔹 [BUILD.md](AIMD/BUILD.md)
- 🔹 [CODE.md](AIMD/CODE.md)
- 🔹 [DESIGN.md](AIMD/DESIGN.md)
- 🔹 [FEATURES.md](AIMD/FEATURES.md)
- 🔹 [LOG.md](AIMD/LOG.md)
- 🔹 [MANUAL.md](AIMD/MANUAL.md)
- 🔹 [README.md](README.md)
- 🔹 [SPEC.md](AIMD/SPEC.md)
- 🔹 [TASKS.md](AIMD/TASKS.md)
- 🔹 [TERMS.md](AIMD/TERMS.md)
- 🔹 [TESTING.md](AIMD/TESTING.md)
- 🔹 [VERSIONS.md](AIMD/VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [AGENTS](#a-agents) <a id="toc-agents"></a> ^toc-agents
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [💻 Application](#a-application) <a id="toc-application"></a> ^toc-application
  - [⚙️ Platform](#a-platform) <a id="toc-platform"></a> ^toc-platform
  - [👥 Core Agent Roster & Personas](#a-coreagentrosterpersonas) <a id="toc-coreagentrosterpersonas"></a> ^toc-coreagentrosterpersonas
    - [1. Lead Architect](#a-1leadarchitect) <a id="toc-1leadarchitect"></a> ^toc-1leadarchitect
    - [2. Code Review](#a-2codereview) <a id="toc-2codereview"></a> ^toc-2codereview
  - [🛠️ Global Execution Rules & Governance](#a-globalexecutionrulesgovernance) <a id="toc-globalexecutionrulesgovernance"></a> ^toc-globalexecutionrulesgovernance
  - [🚫 File Restrictions](#a-filerestrictions) <a id="toc-filerestrictions"></a> ^toc-filerestrictions
    - [Ignore Files](#a-ignorefiles) <a id="toc-ignorefiles"></a> ^toc-ignorefiles
    - [Do NOT alter Files](#a-donotalterfiles) <a id="toc-donotalterfiles"></a> ^toc-donotalterfiles
    - [Inline Tasks](#a-inlinetasks) <a id="toc-inlinetasks"></a> ^toc-inlinetasks
  - [📂 Project Context](#a-projectcontext) <a id="toc-projectcontext"></a> ^toc-projectcontext
  - [🏗️ Verification and Architecture Anchors](#a-verificationandarchitectureanchors) <a id="toc-verificationandarchitectureanchors"></a> ^toc-verificationandarchitectureanchors
  - [📦 Build](#a-build) <a id="toc-build"></a> ^toc-build
  - [🎨 Code Styling and Preferences](#a-codestylingandpreferences) <a id="toc-codestylingandpreferences"></a> ^toc-codestylingandpreferences
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 💻 Application
<a id="a-application"></a>[TOC](#toc-application)
- High-performance window-management suite written in AutoHotkey v2.0

<!-- 
  INSTRUCTION: List the environment, target runner, code editors, OS, 
  or platforms where this app compiles and executes.
-->
## ⚙️ Platform
<a id="a-platform"></a>[TOC](#toc-platform)
- Windows 10+, AutoHotKey v2.0

---

## 👥 Core Agent Roster & Personas
<a id="a-coreagentrosterpersonas"></a>[TOC](#toc-coreagentrosterpersonas)
### 1. Lead Architect
<a id="a-1leadarchitect"></a>[TOC](#toc-1leadarchitect)
<!-- AI Purpose: Defines a specific AI persona, its strategic purpose, and operational mindset. -->
- **Persona Archetype:** Pragmatic, pedantic, patient
- **Core Responsibility:** Operational Design, opting for simplicity and power
- **System Prompt / Identity:**
  ```text
  You are an expert windows power user. Your goal is to manipulate windows interface effectively, Always prioritize ease of use and logical layout of commands and keys.
  ```

### 2. Code Review
<a id="a-2codereview"></a>[TOC](#toc-2codereview)
- **Persona Archetype:** Find unseen edge cases, and opportunities for new fuctionality
- **Core Responsibility:** Warn when ill-advised development paths are emerging. Look for simplifications and code maintainence reasoning.
- **System Prompt / Identity:**
  ```text
  You are an automated code auditor. Focus entirely on failure states.
  ```
---

## 🛠️ Global Execution Rules & Governance
<a id="a-globalexecutionrulesgovernance"></a>[TOC](#toc-globalexecutionrulesgovernance)
<!-- 
  INSTRUCTION: Document strict instructions regarding what the AI can and cannot modify.
  This includes package.json rules, read-only third party vendor folders, etc.
-->
## 🚫 File Restrictions
<a id="a-filerestrictions"></a>[TOC](#toc-filerestrictions)
- Do not create new files, only work on the ahk or ini files.

### Ignore Files
<a id="a-ignorefiles"></a>[TOC](#toc-ignorefiles)
- _MD/**/*.*

### Do NOT alter Files
<a id="a-donotalterfiles"></a>[TOC](#toc-donotalterfiles)
- `.gitignore`
- `idx.md`
- `.markdownlint.jsonc`
- `build.js`
- `LICENSE`
- `+ahk-window-hotkeys`

### Inline Tasks
<a id="a-inlinetasks"></a>[TOC](#toc-inlinetasks)
- Comments in the form of
  - `;! {instructions}` or 
  - `//! {instructions}` 
  found in source code are active AI Tasks

<!-- 
  INSTRUCTION: Detail the environment context (e.g., test fixtures, sandboxing, 
  permissions, emulator settings, mock data rules).
-->
## 📂 Project Context
<a id="a-projectcontext"></a>[TOC](#toc-projectcontext)
- [HotWinAHK.ahk](HotWinAHK.ahk) is the entry point to the program
- [HotWinAHK.ini](HotWinAHK.ini) is used to create HowWinAHK_aux.ahk
- [HotWinAHK_tray.ahk](HotWinAHK_tray.ahk) is used for tray management
- [windows-hotkeys-homes.ini](windows-hotkeys-homes.ini) is data used to reposition windows

---

## 🏗️ Verification and Architecture Anchors
<a id="a-verificationandarchitectureanchors"></a>[TOC](#toc-verificationandarchitectureanchors)
<!-- 
  INSTRUCTION: List verification rules that MUST happen before complete cycles are closed.
  For example, running 'lint_applet' or 'compile_applet'.
-->
## 📦 Build
<a id="a-build"></a>[TOC](#toc-build)
- **Tasks given through chat**: Record tasks in [TASKS.md](AIMD/TASKS.md)
- **Take in other Tasks from [TASKS.md](AIMD/TASKS.md)**: 
  - New Changes
  - New Settings
  - New Commands
  - New Bindings
  - New Features
- **Record Tasks in [LOG.md](AIMD/LOG.md)**
- **Record Commit Msg in [LOG.md](AIMD/LOG.md)** 

## 🎨 Code Styling and Preferences
<a id="a-codestylingandpreferences"></a>[TOC](#toc-codestylingandpreferences)
- See [CODE](AIMD/CODE.md)

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔸 [AGENTS.md](AGENTS.md)
- 🔹 [ARCHIVE.md](AIMD/ARCHIVE.md)
- 🔹 [BUILD.md](AIMD/BUILD.md)
- 🔹 [CODE.md](AIMD/CODE.md)
- 🔹 [DESIGN.md](AIMD/DESIGN.md)
- 🔹 [FEATURES.md](AIMD/FEATURES.md)
- 🔹 [LOG.md](AIMD/LOG.md)
- 🔹 [MANUAL.md](AIMD/MANUAL.md)
- 🔹 [README.md](README.md)
- 🔹 [SPEC.md](AIMD/SPEC.md)
- 🔹 [TASKS.md](AIMD/TASKS.md)
- 🔹 [TERMS.md](AIMD/TERMS.md)
- 🔹 [TESTING.md](AIMD/TESTING.md)
- 🔹 [VERSIONS.md](AIMD/VERSIONS.md)

<!-- TEMPLATE: AGENTS.template.md -->
