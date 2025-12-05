# GitHub Actions Workflows

This directory contains comprehensive GitHub Actions workflows for building, testing, and maintaining the a9nn project.

## Workflows Overview

### 1. **build.yml** - Build Workflow
**Trigger**: Push to branches, pull requests, manual dispatch

**Purpose**: Build a9nn across multiple configurations
- Tests on Ubuntu 20.04 and 22.04
- Compiles with gcc and clang
- Supports LuaJIT 2.1, Lua 5.1, and Lua 5.2
- Caches OpenBLAS and Torch installations for faster builds
- Verifies installation and uploads artifacts

**Matrix Strategy**: Reduces redundant builds while ensuring compatibility

### 2. **test.yml** - Test Workflow
**Trigger**: Push to branches, pull requests, manual dispatch

**Purpose**: Run comprehensive test suites
- Main test suite (test.lua)
- NNECCO cognitive tests (test/test_nnecco.lua)
- Agent-Neuro tests (test/test_agent_neuro.lua)
- Generates test reports and logs
- Uploads test results as artifacts

**Coverage**: Core modules, cognitive agents, reinforcement learning

### 3. **lint.yml** - Lint Workflow
**Trigger**: Push to branches, pull requests, manual dispatch

**Purpose**: Code quality and style checking
- Runs luacheck with .luacheckrc configuration
- Checks all Lua files for style issues
- Validates core modules, NNECCO, and Agent modules
- Uploads lint results

**Standards**: Follows LuaJIT coding standards

### 4. **e2e.yml** - End-to-End Tests
**Trigger**: Push to main branches, pull requests, daily schedule (2 AM UTC), manual dispatch

**Purpose**: Integration and end-to-end testing
- Basic module loading tests
- Personality system integration
- AtomSpace hypergraph tests
- EchoReservoirProcessor tests
- NeuroAgent integration tests
- NNECCO Agent pipeline tests
- Complete neural network training pipeline

**Frequency**: Daily automated runs + on-demand

### 5. **ci.yml** - Combined CI Workflow
**Trigger**: Push to branches, pull requests, manual dispatch

**Purpose**: Unified continuous integration
- Runs lint check
- Builds and tests on multiple Lua versions
- Tests module imports
- Provides CI summary

**Strategy**: Sequential execution with dependency management

### 6. **release.yml** - Release Workflow
**Trigger**: Tag push (v*, release-*), manual dispatch with version input

**Purpose**: Create and publish releases
- Generates changelog
- Creates release archives
- Builds rockspec for release version
- Creates GitHub release with artifacts
- Builds release binaries for different Lua versions
- Packages for distribution

**Artifacts**: Source archives, binary packages, rockspecs

### 7. **docs.yml** - Documentation Workflow
**Trigger**: Push to main branches (doc changes), pull requests, manual dispatch

**Purpose**: Build and deploy documentation
- Validates documentation structure
- Builds MkDocs site (if configured)
- Checks markdown files
- Generates documentation index
- Deploys to GitHub Pages (on main branch)
- Uploads documentation artifacts

**Output**: Static documentation site

### 8. **security.yml** - Security & Dependencies
**Trigger**: Push to branches, pull requests, weekly schedule (Monday), manual dispatch

**Purpose**: Security and dependency analysis
- Checks rockspec dependencies
- Scans for hardcoded credentials
- Checks for unsafe function usage
- Validates file permissions
- License compliance checking
- Code quality analysis
- Generates security reports

**Reports**: Dependency report, license report, code quality report

## Workflow Dependencies

```
ci.yml
├── lint.yml (implicit)
└── build + test (combined)

release.yml
├── create-release
└── build-release-binaries (depends on create-release)

e2e.yml (standalone, comprehensive integration tests)

docs.yml (standalone, documentation)

security.yml (standalone, security checks)
```

## Caching Strategy

To optimize build times, workflows cache:
- **OpenBLAS** installation (~5-10 minutes build time)
- **Torch** installation (~15-20 minutes build time)

Cache keys are based on:
- OS version
- Compiler type
- Lua version

## Artifact Retention

| Workflow | Artifact | Retention |
|----------|----------|-----------|
| build.yml | Build artifacts | 7 days |
| test.yml | Test logs | 30 days |
| lint.yml | Lint results | 30 days |
| e2e.yml | E2E test reports | 30 days |
| release.yml | Release binaries | 90 days |
| docs.yml | Documentation | 90 days |
| security.yml | Security reports | 90 days |

## Manual Workflow Triggers

All workflows support manual triggering via `workflow_dispatch`:

```bash
# Using GitHub CLI
gh workflow run build.yml
gh workflow run test.yml
gh workflow run e2e.yml
gh workflow run release.yml -f version=v1.0.0
```

## Status Badges

Add these badges to your README.md:

```markdown
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)
[![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml)
[![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml)
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)
```

## Workflow Maintenance

### Updating Dependencies
1. Modify cache keys to invalidate old caches
2. Update Torch version in workflows
3. Update system dependency versions

### Adding New Tests
1. Create test file in `test/` directory
2. Update test.yml to include new test suite
3. Add to e2e.yml if integration test

### Troubleshooting

**Build Failures**:
- Check cache invalidation
- Verify system dependencies
- Review build logs in artifacts

**Test Failures**:
- Check test logs in artifacts
- Run tests locally with same Lua version
- Verify module dependencies

**Lint Issues**:
- Review .luacheckrc configuration
- Check luacheck output in artifacts
- Run luacheck locally before pushing

## Performance Considerations

- Builds take ~30-45 minutes on first run (with cache building)
- Cached builds complete in ~5-10 minutes
- Test suites run in ~2-5 minutes
- E2E tests may take up to 60 minutes

## Security Features

- No hardcoded secrets in workflows
- Uses GitHub-provided secrets
- Dependency scanning on schedule
- License compliance checking
- Code quality monitoring

## Future Enhancements

Potential improvements:
- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Docker container builds
- [ ] Multi-architecture support (ARM64)
- [ ] Automated dependency updates (Dependabot)
- [ ] Integration with external services

## Contributing

When adding or modifying workflows:
1. Test locally with act (GitHub Actions local runner)
2. Use `continue-on-error` for non-critical steps
3. Add comprehensive logging
4. Document workflow purpose and triggers
5. Use caching where appropriate
6. Set reasonable timeouts
7. Upload relevant artifacts

## Support

For workflow issues:
1. Check the Actions tab in GitHub
2. Review artifact logs
3. Check workflow run annotations
4. Open an issue with workflow run link
