# InferenceMAX Test Configuration - Complete Index

All files needed to run GPTOSS benchmarks on your local MI300X server (10.23.45.34) using GitHub Actions.

## 📚 Start Here

1. **[QUICKSTART.md](QUICKSTART.md)** - Get started in 3 steps (⭐ START HERE)
2. **[README.md](README.md)** - Overview and file structure

## 📖 Documentation

### Setup Guides
- **[docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md)** - Install and configure GitHub Actions runner (one-time)
- **[docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)** - All methods to run benchmarks
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## ⚙️ Configuration Files

### Required Files (Copy to Main Repo)

1. **[runners/launch_mi300x-local.sh](runners/launch_mi300x-local.sh)**
   - **Copy to:** `runners/launch_mi300x-local.sh`
   - **Purpose:** Launch script for GitHub Actions benchmarks
   - **Action:** `cp test/runners/launch_mi300x-local.sh runners/`

2. **[configs/runners-update.yaml](configs/runners-update.yaml)**
   - **Apply to:** `.github/configs/runners.yaml`
   - **Purpose:** Add your runner to the mi300x list
   - **Action:** Manually edit `.github/configs/runners.yaml` to add `mi300x-local_0`

### Optional Files

3. **[workflows/test-local-mi300x.yml](workflows/test-local-mi300x.yml)**
   - **Copy to:** `.github/workflows/test-local-mi300x.yml` (optional)
   - **Purpose:** Simple dropdown UI for single benchmarks
   - **Action:** `cp test/workflows/test-local-mi300x.yml .github/workflows/`

### Reference Files

4. **[configs/local-mi300x-config.yaml](configs/local-mi300x-config.yaml)**
   - **Reference only** - Documents your server configuration

## 📝 Perf Changelog Examples

Use these examples to create entries in the main `perf-changelog.yaml` file for automated PR-based benchmarks.

### Quick Reference

| File | Use Case | Total Runs |
|------|----------|------------|
| **[gptoss-fp4-quick.yaml](perf-changelog-examples/gptoss-fp4-quick.yaml)** | Fast validation (1k1k only) | ~10 |
| **[gptoss-fp4-specific.yaml](perf-changelog-examples/gptoss-fp4-specific.yaml)** | Specific config (TP=8, limited CONC) | 3 |
| **[gptoss-fp4-full.yaml](perf-changelog-examples/gptoss-fp4-full.yaml)** | Complete sweep (all configs) | ~45 |
| **[multiple-models.yaml](perf-changelog-examples/multiple-models.yaml)** | Multiple models (GPTOSS + DeepSeek) | ~20 |

### How to Use

1. Pick an example file
2. Copy the entry to main `perf-changelog.yaml`
3. Update `date` and `author`
4. Create PR and add "sweep-enabled" label

## 🔧 Helper Scripts

### On Server (10.23.45.34)

**[scripts/setup_environment.sh](scripts/setup_environment.sh)**
- Run once to check/setup environment
- Verifies Docker, ROCm, Git, HF cache, runner
- Usage: `bash test/scripts/setup_environment.sh`

**[scripts/run_local_benchmark.sh](scripts/run_local_benchmark.sh)**
- Run single benchmark without GitHub Actions
- Useful for testing
- Usage: `export HF_TOKEN=xxx && TP=8 CONC=16 bash test/scripts/run_local_benchmark.sh`

**[scripts/run_sweep.sh](scripts/run_sweep.sh)**
- Run full sweep locally without GitHub Actions
- Runs all TP/CONC/seq-len combinations
- Usage: `export HF_TOKEN=xxx && bash test/scripts/run_sweep.sh`

## 🚀 Quick Command Reference

### Setup (One-Time)

```bash
# On server: Install runner
cd ~/actions-runner
./config.sh --url https://github.com/YOUR_ORG/InferenceMAX \
  --token TOKEN --name mi300x-local_0 --labels mi300x-local_0,mi300x
sudo ./svc.sh install && sudo ./svc.sh start

# On local: Update repo
cp test/runners/launch_mi300x-local.sh runners/
# Edit .github/configs/runners.yaml to add mi300x-local_0
git add runners/ .github/configs/
git commit -m "Add mi300x-local_0 runner"
git push
```

### Run Benchmarks (GitHub Actions)

**Quick Test:**
```
Actions → End-to-End Tests → Run workflow
Command: full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-tp 4 --max-conc 16 --config-files .github/configs/amd-master.yaml
```

**Full Sweep:**
```
Command: full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --config-files .github/configs/amd-master.yaml
```

### Run Locally (On Server)

```bash
# Single benchmark
export HF_TOKEN=hf_xxx
TP=8 CONC=16 ISL=1024 OSL=1024 bash test/scripts/run_local_benchmark.sh

# Full sweep
export HF_TOKEN=hf_xxx
bash test/scripts/run_sweep.sh
```

## 📋 Checklist

### One-Time Setup
- [ ] Install GitHub Actions runner on server
- [ ] Configure runner with correct name and labels
- [ ] Start runner as a service
- [ ] Verify runner shows "Idle" in GitHub
- [ ] Set GitHub secrets (HF_TOKEN, REPO_PAT)
- [ ] Copy `launch_mi300x-local.sh` to `runners/`
- [ ] Update `runners.yaml` to include `mi300x-local_0`
- [ ] Commit and push changes

### First Run
- [ ] Trigger quick test via GitHub Actions
- [ ] Monitor job execution
- [ ] Verify benchmark completes
- [ ] Download and check results
- [ ] Celebrate! 🎉

### Production Use
- [ ] Use perf-changelog for regular benchmarks
- [ ] Review results in PR comments
- [ ] Download artifacts for detailed analysis

## 📊 File Summary

```
Total files created: 16

Documentation:
  - 5 markdown guides
  - 1 quickstart
  - 1 index (this file)

Configuration:
  - 1 runner launch script
  - 2 config reference files
  - 1 custom workflow

Examples:
  - 4 perf-changelog templates

Scripts:
  - 3 helper scripts
```

## 🆘 Need Help?

1. **Setup issues:** See [docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md)
2. **Running benchmarks:** See [docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)
3. **Errors:** See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
4. **Quick start:** See [QUICKSTART.md](QUICKSTART.md)

## 🎯 Common Use Cases

### "I want to run a quick test"
→ Use [gptoss-fp4-quick.yaml](perf-changelog-examples/gptoss-fp4-quick.yaml) or manual workflow dispatch with `max-conc 16`

### "I want to test TP=8 performance"
→ Use [gptoss-fp4-specific.yaml](perf-changelog-examples/gptoss-fp4-specific.yaml) with `max-tp: 8`

### "I want to run all configurations"
→ Use [gptoss-fp4-full.yaml](perf-changelog-examples/gptoss-fp4-full.yaml)

### "I want to test locally before GitHub Actions"
→ Use [scripts/run_local_benchmark.sh](scripts/run_local_benchmark.sh)

### "Runner is not working"
→ See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) → Runner Issues section

---

**All files are ready to use! Follow [QUICKSTART.md](QUICKSTART.md) to get started.**
