---
title: TASKS
---

<!-- TEMPLATE: TASKS.template.md -->
<!-- 
TASKS
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file tracks immediate development tasks and feature checklists.
Always update this backlog at the beginning of your turn (when new chat instructions 
are received) and mark items completed ([x]) once verified.
-->

<!-- markdownlint-disable MD013 -->

# TASKS
<a id="a-tasks"></a>[TOC](#toc-tasks)

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
- 🔸 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [TASKS](#a-tasks) <a id="toc-tasks"></a> ^toc-tasks
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [💬 Incoming tasks from chat](#a-incomingtasksfromchat) <a id="toc-incomingtasksfromchat"></a> ^toc-incomingtasksfromchat
  - [🔄 New Changes](#a-newchanges) <a id="toc-newchanges"></a> ^toc-newchanges
  - [⚙️ New Settings](#a-newsettings) <a id="toc-newsettings"></a> ^toc-newsettings
  - [🕹️ New Commands](#a-newcommands) <a id="toc-newcommands"></a> ^toc-newcommands
  - [⌨️ New Bindings](#a-newbindings) <a id="toc-newbindings"></a> ^toc-newbindings
  - [🚀 New Features](#a-newfeatures) <a id="toc-newfeatures"></a> ^toc-newfeatures
  - [🛑 Blocked Items & Impediments](#a-blockeditemsimpediments) <a id="toc-blockeditemsimpediments"></a> ^toc-blockeditemsimpediments
  - [🗃️ Completed Backlog (Archive)](#a-completedbacklogarchive) <a id="toc-completedbacklogarchive"></a> ^toc-completedbacklogarchive
    - [🛠️ Settings](#a-settings) <a id="toc-settings"></a> ^toc-settings
    - [💻 Commands](#a-commands) <a id="toc-commands"></a> ^toc-commands
    - [🔗 Bindings](#a-bindings) <a id="toc-bindings"></a> ^toc-bindings
    - [📦 Features](#a-features) <a id="toc-features"></a> ^toc-features
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 💬 Incoming tasks from chat
<a id="a-incomingtasksfromchat"></a>[TOC](#toc-incomingtasksfromchat)
- [x] **Markdown Comment Cleaning Rule**: Strip hash (`#`) symbols from file header comments and `TEMPLATE:` single-line HTML comments across all Markdown documentation files.
- [x] **Skill Rule Addition**: Update `skills/markdown-transform/SKILL.md` and `skills/system_skills/markdown-transform/SKILL.md` with the refined rule: "This rule applies strictly to the first multi-line HTML comment block (file header comment) and single-line comments that start with TEMPLATE:".
- [x] **Server Cleanup & Single-View Constraints**: Purge web server files (`App.tsx`, `server.ts`, etc.) to enforce desktop AutoHotkey suite focus without unrequested server UI layers.
- [x] **Code Analysis & AIMD Documentation Update**: Perform thorough static analysis on `HotWinAHK.ahk`, `HotWinAHK.ini`, `HotWinAHK_aux.ahk`, and `HotWinAHK_tray.ahk` to update all AIMD Markdown documentation files (`TASKS.md`, `LOG.md`, `README.md`, `AGENTS.md`, `BUILD.md`, `CODE.md`, `DESIGN.md`, `FEATURES.md`, `MANUAL.md`, `SPEC.md`, `TERMS.md`, `TESTING.md`, `VERSIONS.md`, `ARCHIVE.md`).

## 🔄 New Changes
<a id="a-newchanges"></a>[TOC](#toc-newchanges)
- [x] Refactored `SKILL.md` in `skills/markdown-transform` and `skills/system_skills/markdown-transform` to restrict the hash-stripping comment rule to file headers and TEMPLATE comments.
- [x] Updated `AIMD/*.md` files to replace double curly brace placeholders with real AutoHotkey v2.0 domain details.

## ⚙️ New Settings
<a id="a-newsettings"></a>[TOC](#toc-newsettings)
- [x] `SilenceAll`: Boolean flag in `HotWinAHK.ini` under `[Settings]` controlling sound notifications across execution routines.
- [x] `SilentOnWinCmds`: Boolean flag suppressing audio confirmation on window commands.
- [x] `TipWinCmds`: Boolean flag displaying visual tooltips on window movement and docking actions.

## 🕹️ New Commands
<a id="a-newcommands"></a>[TOC](#toc-newcommands)
- [x] Command: `HelpScreen` - Interactive keyboard command reference panel (`Win+/`).
- [x] Command: `CmdPalette` - Fuzzy-search command palette for manual trigger and testing (`Win+\`).
- [x] Command: `DragWindow` - Translucent interactive mouse dragging & edge tucking (`Win+F6`).

## ⌨️ New Bindings
<a id="a-newbindings"></a>[TOC](#toc-newbindings)
- [x] Binding: `Win + Alt + Numpad 1-9` - Positions active window in 3x3 grid zones.
- [x] Binding: `Win + Alt + Arrow Keys` - Snaps active window to screen edge margins.
- [x] Binding: `Win + Ctrl + Pause` - Toggles suspension of all HotWinAHK hotkey triggers.

## 🚀 New Features
<a id="a-newfeatures"></a>[TOC](#toc-newfeatures)
- [x] Feature Name: AutoHotkey v2.0 Self-Compiling Static Hotkey Generator
  - Compiles `HotWinAHK.ini` configuration rules into `HotWinAHK_aux.ahk` at startup for zero-latency execution.

---

## 🛑 Blocked Items & Impediments
<a id="a-blockeditemsimpediments"></a>[TOC](#toc-blockeditemsimpediments)
- None. All tasks completed and verified.

---

## 🗃️ Completed Backlog (Archive)
<a id="a-completedbacklogarchive"></a>[TOC](#toc-completedbacklogarchive)
- [x] **TASK-001 - Markdown Comment Hash Removal & Skill Documentation Update** (By Lead Architect on 2026-07-23)
- [x] **TASK-002 - Web Server Purge & AIMD Documentation Alignment** (By Lead Architect on 2026-07-23)

### 🛠️ Settings
<a id="a-settings"></a>[TOC](#toc-settings)
- [x] Configured `HotWinAHK.ini` settings matrix with 200+ commands and default parameters (`SilenceAll=false`, `SilentOnWinCmds=false`, `TipWinCmds=true`).

### 💻 Commands
<a id="a-commands"></a>[TOC](#toc-commands)
- [x] Registered full command spectrum including `WindowPicker`, `Desk3d`, `SetHome`, `GoHome`, `MinimizeToTray`, `PickFromTray`, `AlwaysOnTop`, `SetOpacity70`.

### 🔗 Bindings
<a id="a-bindings"></a>[TOC](#toc-bindings)
- [x] Configured hotkeys for grid zones, edge docking, home snap, window history, and system utilities.

### 📦 Features
<a id="a-features"></a>[TOC](#toc-features)
- [x] High-performance window management suite written in AutoHotkey v2.0 with velocity edge tucking, 3x3 grid snapping, and tray stowing.

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
- 🔸 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: TASKS.template.md -->
