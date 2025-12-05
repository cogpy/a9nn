# Status Badges for a9nn

## Copy these badges to your main README.md

### All Badges (Horizontal Layout)
```markdown
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)
[![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml)
[![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml)
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)
[![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml)
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)
```

### Grouped by Category
```markdown
#### Build & Test
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)

#### Quality & Security
[![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml)
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)

#### Integration & Docs
[![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml)
[![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml)
```

### Minimal (Essential Only)
```markdown
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)
[![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml)
```

### Table Format
```markdown
| Category | Status |
|----------|--------|
| Build | [![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml) |
| Tests | [![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml) |
| Lint | [![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml) |
| E2E | [![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml) |
| CI | [![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml) |
| Docs | [![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml) |
| Security | [![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml) |
```

## Individual Badge Links

### Build Badge
```markdown
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
```
Shows status of multi-platform builds across gcc/clang and LuaJIT/Lua5.x

### Test Badge
```markdown
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)
```
Shows status of comprehensive test suites (main, NNECCO, Agent-Neuro)

### Lint Badge
```markdown
[![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml)
```
Shows code quality status with luacheck

### E2E Badge
```markdown
[![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml)
```
Shows end-to-end integration test status (runs daily)

### CI Badge
```markdown
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)
```
Shows unified CI pipeline status (lint → build → test)

### Docs Badge
```markdown
[![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml)
```
Shows documentation build and deployment status

### Security Badge
```markdown
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)
```
Shows security scanning status (runs weekly)

## Customization

### With Branch Specification
```markdown
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
```

### With Event Specification
```markdown
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg?event=push)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
```

### Flat Square Style
```markdown
![Build](https://img.shields.io/github/actions/workflow/status/cogpy/a9nn/build.yml?style=flat-square&label=build)
```

### With Label Customization
```markdown
![Build](https://img.shields.io/github/actions/workflow/status/cogpy/a9nn/build.yml?label=CI%20Build)
```

## Additional Shields

### Custom Shields.io Badges

#### Lua Version
```markdown
![Lua](https://img.shields.io/badge/Lua-5.1%20%7C%205.2%20%7C%20LuaJIT-blue)
```

#### License
```markdown
![License](https://img.shields.io/badge/license-BSD-green)
```

#### Version
```markdown
![Version](https://img.shields.io/github/v/tag/cogpy/a9nn?label=version)
```

#### Last Commit
```markdown
![Last Commit](https://img.shields.io/github/last-commit/cogpy/a9nn)
```

#### Issues
```markdown
![Issues](https://img.shields.io/github/issues/cogpy/a9nn)
```

#### Pull Requests
```markdown
![PRs](https://img.shields.io/github/issues-pr/cogpy/a9nn)
```

## Recommended README.md Section

Replace the old Travis CI badge with this:

```markdown
# a9nn - Neural Network Package

[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)
[![Docs](https://github.com/cogpy/a9nn/actions/workflows/docs.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/docs.yml)
![Lua](https://img.shields.io/badge/Lua-5.1%20%7C%205.2%20%7C%20LuaJIT-blue)
![License](https://img.shields.io/badge/license-BSD-green)

A comprehensive neural network framework for Torch7/LuaJIT with cognitive architectures and reinforcement learning agents.

## Features
...
```

## Preview

When added to README.md, the badges will look like this:

![CI](https://img.shields.io/badge/CI-passing-brightgreen)
![Build](https://img.shields.io/badge/Build-passing-brightgreen)
![Test](https://img.shields.io/badge/Test-passing-brightgreen)
![Security](https://img.shields.io/badge/Security-passing-brightgreen)
![Docs](https://img.shields.io/badge/Docs-passing-brightgreen)
![Lua](https://img.shields.io/badge/Lua-5.1%20%7C%205.2%20%7C%20LuaJIT-blue)
![License](https://img.shields.io/badge/license-BSD-green)

## Notes

- Badges automatically update when workflows run
- Click badges to view workflow details
- Green = passing, Red = failing, Yellow = in progress
- Badges cache for ~5 minutes on GitHub's CDN
