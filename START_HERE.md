# ⭐ START HERE - InferenceMAX Local MI300X Setup

**Complete configuration files for running GPTOSS benchmarks on your MI300X server (10.23.45.34) via GitHub Actions.**

## 🎯 What You Get

✅ **17 ready-to-use files** for running InferenceMAX benchmarks
✅ **Self-hosted GitHub Actions runner** configuration
✅ **4 perf changelog templates** for automated PR-based benchmarks
✅ **3 helper scripts** for local testing
✅ **Comprehensive documentation** with setup, usage, and troubleshooting

---

## 🚀 Quick Start (3 Steps)

### Step 1: Set Up Runner (One-Time)
```bash
# On your server (10.23.45.34)
ssh user@10.23.45.34
cd ~/InferenceMAX
bash test/scripts/setup_environment.sh

# Install GitHub Actions runner
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz

# Configure (get token from GitHub Settings → Actions → Runners → New)
./config.sh --url https://github.com/YOUR_ORG/InferenceMAX \
  --token YOUR_TOKEN --name mi300x-local_0 --labels mi300x-local_0,mi300x

# Start as service
sudo ./svc.sh install && sudo ./svc.sh start
```

### Step 2: Update Repository
```bash
# On your local machine
cd ~/InferenceMAX
cp test/runners/launch_mi300x-local.sh runners/
chmod +x runners/launch_mi300x-local.sh

# Edit .github/configs/runners.yaml - add 'mi300x-local_0' to mi300x list
# See: test/configs/runners-update.yaml

git add runners/ .github/configs/
git commit -m "Add mi300x-local_0 runner"
git push

# Set GitHub secrets: HF_TOKEN, REPO_PAT
# Go to: Settings → Secrets and variables → Actions
```

### Step 3: Run First Benchmark
```
GitHub: Actions → End-to-End Tests → Run workflow

Command:
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-tp 4 --max-conc 16 --config-files .github/configs/amd-master.yaml

Click: Run workflow
```

**That's it! Your first benchmark is running!** 🎉

---

## 📚 Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[QUICKSTART.md](QUICKSTART.md)** | 3-step setup guide | Read first! |
| **[INDEX.md](INDEX.md)** | Complete file index | Finding specific files |
| **[docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md)** | Detailed runner setup | Setting up runner |
| **[docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)** | All trigger methods | Running benchmarks |
| **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Common issues | When things break |

---

## 📊 Perf Changelog Examples (For Automated PRs)

**4 ready-to-use templates** - just copy to main `perf-changelog.yaml`:

| Template | Use Case | Runs | File |
|----------|----------|------|------|
| **Quick Test** | Fast validation | ~10 | [gptoss-fp4-quick.yaml](perf-changelog-examples/gptoss-fp4-quick.yaml) |
| **Specific Config** | TP=8 only | 3 | [gptoss-fp4-specific.yaml](perf-changelog-examples/gptoss-fp4-specific.yaml) |
| **Full Sweep** | All configs | ~45 | [gptoss-fp4-full.yaml](perf-changelog-examples/gptoss-fp4-full.yaml) |
| **Multi-Model** | GPTOSS + DeepSeek | ~20 | [multiple-models.yaml](perf-changelog-examples/multiple-models.yaml) |

**How to use:**
1. Copy example to `perf-changelog.yaml`
2. Update `date` and `author`
3. Create PR and add "sweep-enabled" label

---

## 🛠️ Helper Scripts

**On your server (10.23.45.34):**

```bash
# Check environment
bash test/scripts/setup_environment.sh

# Run single benchmark locally
export HF_TOKEN=hf_xxx
TP=8 CONC=16 bash test/scripts/run_local_benchmark.sh

# Run full sweep locally
export HF_TOKEN=hf_xxx
bash test/scripts/run_sweep.sh
```

---

## ✅ Files to Copy/Update

### Required Actions

1. **Copy runner script:**
   ```bash
   cp test/runners/launch_mi300x-local.sh runners/
   chmod +x runners/launch_mi300x-local.sh
   ```

2. **Update runners.yaml:**
   ```bash
   # Edit .github/configs/runners.yaml
   # Add 'mi300x-local_0' to the mi300x list
   # Reference: test/configs/runners-update.yaml
   ```

3. **Commit changes:**
   ```bash
   git add runners/ .github/configs/
   git commit -m "Add mi300x-local_0 runner configuration"
   git push
   ```

### Optional Actions

4. **Add custom workflow (optional):**
   ```bash
   cp test/workflows/test-local-mi300x.yml .github/workflows/
   ```
   Gives you a simple dropdown UI for single benchmarks

---

## 📁 What's Included

```
test/
├── 📋 Navigation
│   ├── START_HERE.md (this file)
│   ├── INDEX.md
│   ├── QUICKSTART.md
│   └── README.md
│
├── 📚 Documentation (3 guides)
│   ├── SETUP_RUNNER.md
│   ├── TRIGGER_BENCHMARKS.md
│   └── TROUBLESHOOTING.md
│
├── ⚙️ Configuration (3 files)
│   ├── launch_mi300x-local.sh ✅
│   ├── runners-update.yaml ✅
│   └── local-mi300x-config.yaml
│
├── 📊 Examples (4 templates)
│   ├── gptoss-fp4-quick.yaml
│   ├── gptoss-fp4-specific.yaml
│   ├── gptoss-fp4-full.yaml
│   └── multiple-models.yaml
│
├── 💻 Scripts (3 helpers)
│   ├── setup_environment.sh
│   ├── run_local_benchmark.sh
│   └── run_sweep.sh
│
└── 🔄 Workflows (1 optional)
    └── test-local-mi300x.yml
```

---

## 🎯 Common Tasks

### Task: "I want to run a quick test"
→ **[QUICKSTART.md](QUICKSTART.md)** → Step 3

### Task: "I want to run all configurations"
→ **[docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)** → Method 1 (Full Sweep)

### Task: "I want automated PR-based benchmarks"
→ **[perf-changelog-examples/gptoss-fp4-quick.yaml](perf-changelog-examples/gptoss-fp4-quick.yaml)** → Copy to perf-changelog.yaml

### Task: "I want to test locally first"
→ **[scripts/run_local_benchmark.sh](scripts/run_local_benchmark.sh)**

### Task: "Runner is not working"
→ **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** → Runner Issues

### Task: "How do I check results?"
→ **[docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)** → Viewing Results

---

## 🔍 Quick Reference

### Check Runner Status
```bash
cd ~/actions-runner
sudo ./svc.sh status
```

### View Runner Logs
```bash
journalctl -u actions.runner.* -f
```

### Restart Runner
```bash
cd ~/actions-runner
sudo ./svc.sh stop && sudo ./svc.sh start
```

### Verify Runner in GitHub
```
Settings → Actions → Runners
Should see: mi300x-local_0 (Idle)
```

---

## 🆘 Need Help?

1. **Setup problems?** → [docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md)
2. **Running benchmarks?** → [docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md)
3. **Something broken?** → [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
4. **Quick overview?** → [QUICKSTART.md](QUICKSTART.md)
5. **Find a file?** → [INDEX.md](INDEX.md)

---

## 📊 Benchmark Command Examples

### Quick Test (Recommended First)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-tp 4 --max-conc 16 --config-files .github/configs/amd-master.yaml
```

### Full Sweep
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --config-files .github/configs/amd-master.yaml
```

### TP=8 Only
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --max-tp 8 --config-files .github/configs/amd-master.yaml
```

### All Sequence Lengths
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k 1k8k 8k1k --config-files .github/configs/amd-master.yaml
```

---

## 🎉 You're Ready!

**17 files created and ready to use.**

**Next steps:**
1. Follow [QUICKSTART.md](QUICKSTART.md) for 3-step setup
2. Run your first benchmark
3. Download results and celebrate! 🚀

**All documentation is in the `test/` folder.**

---

**Questions?** See [INDEX.md](INDEX.md) for complete file navigation.
