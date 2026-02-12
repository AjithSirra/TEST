# InferenceMAX Local MI300X - Quick Start Guide

Get your local MI300X server (10.23.45.34) running InferenceMAX benchmarks in **3 steps**.

## Prerequisites

- Server: 10.23.45.34 with 8x MI300 GPUs
- SSH access to the server
- GitHub repository access
- HuggingFace account and token

---

## Step 1: Set Up Self-Hosted Runner (One-Time Setup)

### On Your Server (10.23.45.34)

```bash
# SSH to server
ssh user@10.23.45.34

# Run environment setup
cd /path/to/InferenceMAX
bash test/scripts/setup_environment.sh

# Install GitHub Actions runner
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz

# Configure runner (get token from GitHub Settings → Actions → Runners → New)
./config.sh \
  --url https://github.com/YOUR_ORG/InferenceMAX \
  --token YOUR_REGISTRATION_TOKEN \
  --name mi300x-local_0 \
  --labels mi300x-local_0,mi300x

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

**Detailed instructions:** See [docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md)

---

## Step 2: Configure Repository (One-Time Setup)

### Update Configuration Files

```bash
# On your local machine, in the InferenceMAX repo

# 1. Copy runner launch script
cp test/runners/launch_mi300x-local.sh runners/
chmod +x runners/launch_mi300x-local.sh

# 2. Update runners.yaml
# Edit .github/configs/runners.yaml
# Add 'mi300x-local_0' to the mi300x list (see test/configs/runners-update.yaml)

# 3. Commit changes
git add runners/launch_mi300x-local.sh .github/configs/runners.yaml
git commit -m "Add mi300x-local_0 runner configuration"
git push
```

### Set GitHub Secrets

Go to: `Settings` → `Secrets and variables` → `Actions`

Add these secrets:
- **HF_TOKEN**: Your HuggingFace token (e.g., `hf_xxxxxxxxxxxx`)
- **REPO_PAT**: GitHub Personal Access Token (for checkout)

---

## Step 3: Run Your First Benchmark

### Option A: Manual Workflow Dispatch (Recommended First)

1. **Go to GitHub Actions**
   - Navigate to: `Actions` → `End-to-End Tests`
   - Click: **"Run workflow"**

2. **Enter this command:**
   ```bash
   full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-tp 4 --max-conc 16 --config-files .github/configs/amd-master.yaml
   ```

3. **Click "Run workflow"**

4. **Monitor progress** in the Actions tab

**This runs:** ~10 benchmark configurations (TP=1,2,4 with CONC up to 16, 1k1k only)

### Option B: Automated via Pull Request

1. **Create a branch:**
   ```bash
   git checkout -b test-gptoss-perf
   ```

2. **Add to perf-changelog.yaml:**
   ```yaml
   - date: "2026-02-12"
     author: "your-github-username"
     description: "GPTOSS FP4 quick test on local MI300X"
     change-type: "test"
     configs:
       - model-prefix: gptoss
         precision: fp4
         framework: vllm
         runner: mi300x
         seq-lens: [1k1k]
         max-tp: 4
         max-conc: 16
   ```

3. **Commit and push:**
   ```bash
   git add perf-changelog.yaml
   git commit -m "Add GPTOSS FP4 benchmark"
   git push origin test-gptoss-perf
   ```

4. **Create PR and add "sweep-enabled" label**

**See more examples:** [perf-changelog-examples/](perf-changelog-examples/)

---

## What's Next?

### View Results

After benchmark completes:
1. Go to workflow run page
2. Scroll to **Artifacts** section
3. Download `results_bmk`
4. Extract and view JSON files:
   ```bash
   unzip results_bmk.zip
   cat gptoss_fp4_vllm_*.json | jq
   ```

### Run More Configurations

**Full sweep (all configs):**
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --config-files .github/configs/amd-master.yaml
```

**Specific TP only:**
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --max-tp 8 --config-files .github/configs/amd-master.yaml
```

**All sequence lengths:**
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k 1k8k 8k1k --config-files .github/configs/amd-master.yaml
```

---

## File Reference

```
test/
├── README.md                              # Overview
├── QUICKSTART.md                          # This file
├── docs/
│   ├── SETUP_RUNNER.md                   # Detailed runner setup
│   ├── TRIGGER_BENCHMARKS.md             # All methods to run benchmarks
│   └── TROUBLESHOOTING.md                # Common issues
├── runners/
│   └── launch_mi300x-local.sh            # ✅ Copy to runners/
├── configs/
│   ├── runners-update.yaml               # ✅ Apply to .github/configs/runners.yaml
│   └── local-mi300x-config.yaml          # Reference config
├── workflows/
│   └── test-local-mi300x.yml             # Optional: Copy to .github/workflows/
├── perf-changelog-examples/
│   ├── gptoss-fp4-full.yaml              # Example: Full sweep
│   ├── gptoss-fp4-quick.yaml             # Example: Quick test
│   ├── gptoss-fp4-specific.yaml          # Example: Specific config
│   └── multiple-models.yaml              # Example: Multiple models
└── scripts/
    ├── run_local_benchmark.sh            # Run single benchmark locally
    ├── run_sweep.sh                      # Run sweep locally
    └── setup_environment.sh              # Environment setup
```

---

## Quick Commands Reference

### Check Runner Status
```bash
# On server
cd ~/actions-runner
sudo ./svc.sh status
```

### Restart Runner
```bash
# On server
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Run Benchmark Locally (Without GitHub Actions)
```bash
# On server, in InferenceMAX repo
export HF_TOKEN=hf_xxxxxxxxxxxx
TP=8 CONC=16 ISL=1024 OSL=1024 bash test/scripts/run_local_benchmark.sh
```

### Check GitHub Runner
Go to: `Settings` → `Actions` → `Runners`
Should see: **mi300x-local_0** (Idle)

---

## Troubleshooting

### Runner Not Showing
```bash
cd ~/actions-runner
sudo ./svc.sh status
journalctl -u actions.runner.* -n 50
```

### Docker Issues
```bash
docker ps
sudo usermod -aG docker $USER  # Then logout/login
```

### Benchmark Failures
Check logs in GitHub Actions job, or see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## Support Files Created

- ✅ Runner launch script
- ✅ Environment setup script
- ✅ Benchmark runner scripts
- ✅ Perf changelog examples (4 variants)
- ✅ Custom workflow (optional)
- ✅ Detailed documentation (3 guides)

**You're ready to run InferenceMAX benchmarks! 🚀**

For detailed information, see:
- [docs/SETUP_RUNNER.md](docs/SETUP_RUNNER.md) - Full runner setup
- [docs/TRIGGER_BENCHMARKS.md](docs/TRIGGER_BENCHMARKS.md) - All trigger methods
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues
