# Code

## Go to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- 🔸[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

## Implementation Guidelines
- **Encoding Safety**: Preserve UTF-8 encoding and avoid bulk read/write rewrites of files that can corrupt emoji/icon literals (mojibake).
- Prefer small targeted patches, and after icon-related edits run lint and quickly verify shared icon constants still render correctly.


### Markdown
- Use dashes instead of asterisks for bullet items
- Always update UPPERCASE.md files (such as AITASKS.md, AILOG.md, etc.) when tasks are completed or work is performed
- Put all chat task requests from the user on AITASKS.md first before working on them
- If the user says 'do tasks', always state what you are going to do and then wait for the user's adjustments and approval before proceeding
- AILOG: The top of AILOG.md should always feature a "Commit Message" section maintained by the AI, which must be cleared whenever the user says they have committed or appended the changes

### Javascript, Typescript, Ahk Coding Style
- **Indentation**: Use tabs for indentation.
- **Braces**: Always use braces for control structures (if, for, while, etc.).

#### Global Function Ordering
- if in a region, order by dependency within the region, meaning a function is listed after the ones it is dependent on
- not in a region, order by dependency
- if no dependencies, order alphabetically

### Regions
- classes are to be kept in a region named _classes
- classes are to be wrapped in a region named _class_{classname}

---
## Go back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- 🔸[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
