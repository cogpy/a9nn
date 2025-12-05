# Quick Reference: GitHub Actions Workflows

## Workflow Triggers Quick Reference

| Workflow | Push | PR | Tag | Schedule | Manual |
|----------|------|----|----|----------|--------|
| build.yml | ✓ | ✓ | | | ✓ |
| test.yml | ✓ | ✓ | | | ✓ |
| lint.yml | ✓ | ✓ | | | ✓ |
| e2e.yml | ✓ main | ✓ | | Daily 2AM | ✓ |
| ci.yml | ✓ | ✓ | | | ✓ |
| release.yml | | | ✓ | | ✓ |
| docs.yml | ✓ docs | ✓ docs | | | ✓ |
| security.yml | ✓ main | ✓ | | Weekly Mon | ✓ |

## Common Commands

### View Workflow Status
```bash
# List all workflows
gh workflow list

# View workflow runs
gh workflow view build.yml

# Watch a workflow run
gh run watch
```

### Trigger Workflows Manually
```bash
# Trigger build
gh workflow run build.yml

# Trigger test
gh workflow run test.yml

# Trigger E2E
gh workflow run e2e.yml

# Trigger release with version
gh workflow run release.yml -f version=v1.0.0
```

### Check Workflow Results
```bash
# List recent runs
gh run list --workflow=build.yml

# View run details
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

## Workflow Matrix Configurations

### build.yml
```yaml
OS: [ubuntu-20.04, ubuntu-22.04]
Compiler: [gcc, clang]
Lua: [LUAJIT21, LUA51, LUA52]
# Total: 12 configurations (with exclusions: 8)
```

### test.yml
```yaml
OS: [ubuntu-20.04]
Lua: [LUAJIT21, LUA51]
# Total: 2 configurations
```

### ci.yml
```yaml
Lua: [LUAJIT21, LUA51]
# Total: 2 configurations
```

## Status Badge URLs

Add these to your README.md:

```markdown
<!-- Build Status -->
[![Build](https://github.com/cogpy/a9nn/actions/workflows/build.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/build.yml)

<!-- Test Status -->
[![Test](https://github.com/cogpy/a9nn/actions/workflows/test.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/test.yml)

<!-- Lint Status -->
[![Lint](https://github.com/cogpy/a9nn/actions/workflows/lint.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/lint.yml)

<!-- E2E Status -->
[![E2E](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/e2e.yml)

<!-- CI Status -->
[![CI](https://github.com/cogpy/a9nn/actions/workflows/ci.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/ci.yml)

<!-- Security Status -->
[![Security](https://github.com/cogpy/a9nn/actions/workflows/security.yml/badge.svg)](https://github.com/cogpy/a9nn/actions/workflows/security.yml)
```

## Cache Keys Reference

### OpenBLAS Cache
```
Key: {os}-{compiler}-openblas-v1
Example: ubuntu-20.04-gcc-openblas-v1
```

### Torch Cache
```
Key: {os}-{compiler}-{lua}-torch-v1
Example: ubuntu-20.04-gcc-LUAJIT21-torch-v1
```

**To Invalidate**: Increment version number (v1 → v2)

## Environment Variables

All workflows use:
```yaml
TORCH_LUA_VERSION: ${{ matrix.lua }}
INSTALL_PREFIX: ${{ github.workspace }}/torch/install
```

Additional for specific needs:
```yaml
CC: ${{ matrix.compiler }}  # build.yml only
```

## Artifact Names

| Workflow | Artifact Pattern | Example |
|----------|------------------|---------|
| build.yml | `build-{os}-{compiler}-{lua}` | `build-ubuntu-20.04-gcc-LUAJIT21` |
| test.yml | `test-logs-{os}-{lua}` | `test-logs-ubuntu-20.04-LUAJIT21` |
| lint.yml | `luacheck-results` | `luacheck-results` |
| e2e.yml | `e2e-test-report` | `e2e-test-report` |
| release.yml | `release-binary-{lua}` | `release-binary-LUAJIT21` |
| docs.yml | `documentation` | `documentation` |
| security.yml | `dependency-report`, `license-report`, `code-quality-report` | - |

## Timing Reference

### Expected Duration (with cache)

| Workflow | First Run | Cached Run |
|----------|-----------|------------|
| build.yml | 45-60 min | 5-10 min |
| test.yml | 35-45 min | 5-8 min |
| lint.yml | 2-3 min | 2-3 min |
| e2e.yml | 50-60 min | 8-15 min |
| ci.yml | 40-50 min | 8-12 min |
| release.yml | 60-90 min | 30-45 min |
| docs.yml | 2-5 min | 2-5 min |
| security.yml | 3-5 min | 3-5 min |

### Timeout Limits

| Workflow | Timeout |
|----------|---------|
| e2e.yml | 60 min |
| Others | Default (360 min) |

## Common Issues & Quick Fixes

### Issue: Build Fails - OpenBLAS
```bash
# Fix: Update cache key version in workflow
# Edit .github/workflows/build.yml
# Change: openblas-v1 → openblas-v2
```

### Issue: Test Fails - Module Not Found
```bash
# Check if luarocks install succeeded
# Look for: "luarocks make rocks/nn-scm-1.rockspec"
# in build logs
```

### Issue: Cache Full
```bash
# GitHub has 10GB cache limit per repo
# Solution: Clean old cache entries
gh cache list
gh cache delete <cache-key>
```

### Issue: Workflow Syntax Error
```bash
# Validate YAML locally
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"

# Or use actionlint
actionlint .github/workflows/build.yml
```

## Dependencies Installation Order

All build/test workflows follow this order:
1. Checkout repository
2. Setup caches
3. Install system dependencies (apt-get)
4. Build/restore OpenBLAS
5. Build/restore Torch
6. Build a9nn (luarocks)
7. Run tests/validation

## Test Execution Order

### test.yml
1. Main test suite (test.lua)
2. NNECCO tests (test/test_nnecco.lua)
3. Agent-Neuro tests (test/test_agent_neuro.lua)

### e2e.yml
1. Basic module loading
2. Personality system
3. AtomSpace
4. EchoReservoirProcessor
5. NeuroAgent
6. NNECCO Agent
7. Complete training pipeline

## Monitoring Checklist

Daily:
- [ ] Check CI status on main branch
- [ ] Review failed workflow runs
- [ ] Check artifact sizes

Weekly:
- [ ] Review security scan results
- [ ] Check cache utilization
- [ ] Review E2E test trends

Monthly:
- [ ] Update cache versions if needed
- [ ] Review and clean old artifacts
- [ ] Check for workflow updates

## Release Process

1. Update version in code
2. Update CHANGELOG
3. Create and push tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. Release workflow automatically:
   - Creates GitHub release
   - Builds binaries
   - Generates rockspec
   - Uploads artifacts

## Emergency Procedures

### Disable All Workflows
```bash
# Disable specific workflow
gh workflow disable build.yml

# Re-enable
gh workflow enable build.yml
```

### Cancel Running Workflows
```bash
# Cancel all runs for a workflow
gh run list --workflow=build.yml --status=in_progress | \
  awk '{print $7}' | xargs -n1 gh run cancel
```

### Force Cache Rebuild
Edit workflow file and increment all cache versions:
- `openblas-v1` → `openblas-v2`
- `torch-v1` → `torch-v2`

## Resource Limits

GitHub Actions free tier:
- **Storage**: 500 MB (artifacts + caches combined)
- **Minutes**: 2000 minutes/month (Linux)
- **Concurrent jobs**: 20
- **Max job duration**: 6 hours
- **Max workflow duration**: 35 days

## Contact & Support

- **Workflow Issues**: Open issue with `workflow` label
- **Documentation**: See `.github/workflows/README.md`
- **Implementation Details**: See `.github/workflows/IMPLEMENTATION_SUMMARY.md`
