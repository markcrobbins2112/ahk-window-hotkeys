---
title: AGENTS
---

<!-- # TEMPLATE: AGENTS.template.md -->
<!-- 
# AGENTS
# Any text bounded by double curly braces {{like this}} is a placeholder for you to fill out.
# Replace those placeholders with real paths, rules, and project constraints.
#
# INSTRUCTIONS FOR THE AI AGENT:
# This file defines your operational boundaries, tools, platforms, and roles.
# Adhere strictly to the boundaries and prompts defined for your assigned persona.
-->

<!-- markdownlint-disable MD013 -->

# AGENTS

## 📑 AI Primary Files
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

## 🔍 Table of Contents
- [[#💻 Application]] ^toc-application
- [[#⚙️ Platform]] ^toc-platform
- [[#👥 Core Agent Roster & Personas]] ^toc-roster
- [[#🛠️ Global Execution Rules & Governance]] ^toc-governance
- [[#🚫 File Restrictions]] ^toc-restrictions
- [[#📂 Project Context]] ^toc-context
- [[#🚦 Interaction Rules & Handoff Protocols]] ^toc-protocols
- [[#🏗️ Verification and Architecture Anchors]] ^toc-anchors
- [[#📦 Build]] ^toc-build
- [[#🎨 Code Styling and Preferences]] ^toc-styling
- [[#🚀 Go to...]] ^toc-goto

<!-- 
  INSTRUCTION: Specify the core objective / purpose of the application.
  Provide a concise 1-2 sentence description of what system is being built.
-->
## 💻 Application
[[#^toc-application|TOC]]
- High-performance window-management suite written in AutoHotkey v2.0

<!-- 
  INSTRUCTION: List the environment, target runner, code editors, OS, 
  or platforms where this app compiles and executes.
-->
## ⚙️ Platform
[[#^toc-platform|TOC]]
- Windows 10+, AutoHotKey v2.0

---

## 👥 Core Agent Roster & Personas
[[#^toc-roster|TOC]]

### 1. Lead Architect
<!-- AI Purpose: Defines a specific AI persona, its strategic purpose, and operational mindset. -->
- **Persona Archetype:** Pragmatic, pedantic, patient
- **Core Responsibility:** Operational Design, opting for simplicity and power
- **System Prompt / Identity:**
  ```text
  You are an expert windows power user. Your goal is to manipulate windows interface effectively, Always prioritize ease of use and logical layout of commands and keys.
  ```

### 2. Code Review
- **Persona Archetype:** Find unseen edge cases, and opportunities for new fuctionality
- **Core Responsibility:** Warn when ill-advised development paths are emerging. Look for simplifications and code maintainence reasoning.
- **System Prompt / Identity:**
  ```text
  You are an automated code auditor. Focus entirely on failure states.
  ```
---

## 🛠️ Global Execution Rules & Governance
[[#^toc-governance|TOC]]

<!-- 
  INSTRUCTION: Document strict instructions regarding what the AI can and cannot modify.
  This includes package.json rules, read-only third party vendor folders, etc.
-->
## 🚫 File Restrictions
[[#^toc-restrictions|TOC]]
- Do not create new files, only work on the ahk or ini files.

### Ignore Files
- _MD/**/*.*

### Do NOT alter Files
- `.gitignore`
- `idx.md`
- `.markdownlint.jsonc`
- `build.js`
- `LICENSE`
- `+ahk-window-hotkeys`

### Inline Tasks
- Comments in the form of
  - `;! {instructions}` or 
  - `//! {instructions}` 
  found in source code are active AI Tasks

<!-- 
  INSTRUCTION: Detail the environment context (e.g., test fixtures, sandboxing, 
  permissions, emulator settings, mock data rules).
-->
## 📂 Project Context
[[#^toc-context|TOC]]
- HotWinAHK.ahk is the entry point to the program
- HotWinAHK.ini is used to create HowWinAHK_aux.ahk
- HotWinAHK_tray.ahk is used for tray management
- windows-hotkeys-homes.ini is data used to reposition windows

---

## 🏗️ Verification and Architecture Anchors
[[#^toc-anchors|TOC]]

<!-- 
  INSTRUCTION: List verification rules that MUST happen before complete cycles are closed.
  For example, running 'lint_applet' or 'compile_applet'.
-->
## 📦 Build
[[#^toc-build|TOC]]
- **Tasks given through chat**: Record tasks in TASKS.md
- **Take in other Tasks from TASKS.md**: 
  - New Changes
  - New Settings
  - New Commands
  - New Bindings
  - New Features
- **Record Tasks in LOG.md**
- **Record Commit Msg in LOG.md** 

## 🎨 Code Styling and Preferences
[[#^toc-styling|TOC]]
- See [CODE](AIMD/CODE.md)

---
## 🚀 Go to...
[[#^toc-goto|TOC]]
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

<!-- # TEMPLATE: AGENTS.template.md -->
