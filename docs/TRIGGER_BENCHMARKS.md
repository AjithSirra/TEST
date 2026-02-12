# How to Trigger Benchmarks on Your MI300X Server

This guide explains the different methods to trigger benchmarks on your local MI300X server (10.23.45.34) using GitHub Actions.

## Prerequisites

- Self-hosted runner `mi300x-local_0` is set up and running
- GitHub secrets (`HF_TOKEN`, `REPO_PAT`) are configured
- Repository has been updated with runner configuration

## Method 1: Manual Workflow Dispatch (Recommended for Testing)

This is the **easiest and fastest** way to trigger specific benchmarks.

### Step-by-Step

1. **Go to GitHub Actions UI**
   - Navigate to your repository on GitHub
   - Click on the `Actions` tab
   - Select `End-to-End Tests` from the left sidebar

2. **Click "Run workflow"** button (top right)

3. **Enter CLI Command**

   In the "Command passed to generate matrix script" field, enter one of these commands:

#### Quick Test (Recommended First Run)
Test with just one configuration to verify everything works:
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-tp 4 --max-conc 16 --config-files .github/configs/amd-master.yaml
```
This runs: TP=1,2,4 with CONC up to 16 (about 10 configs)

#### Full GPTOSS FP4 Sweep
Run all configurations:
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --config-files .github/configs/amd-master.yaml
```
This runs: All TP/CONC/seq-len combinations (40-50 configs)

#### Specific Sequence Length
Run only 1k1k workloads:
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --config-files .github/configs/amd-master.yaml
```

#### TP=8 Only
Run only TP=8 configurations:
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --max-tp 8 --step-size 1 --config-files .github/configs/amd-master.yaml
```

4. **Click "Run workflow"** button

5. **Monitor Progress**
   - The workflow will appear in the Actions list
   - Click on it to see individual benchmark jobs
   - Each job shows live logs as it runs

### Advanced CLI Options

```bash
full-sweep [options] --config-files .github/configs/amd-master.yaml

Options:
  --single-node              Run single-node benchmarks (required)
  --model-prefix PREFIX      Filter by model (e.g., gptoss, dsr1)
  --precision PRECISION      Filter by precision (fp4, fp8)
  --framework FRAMEWORK      Filter by framework (vllm, sglang, trt)
  --runner-type TYPE         Filter by runner (mi300x, h200, etc.)
  --seq-lens LENS            Sequence lengths (1k1k, 1k8k, 8k1k)
  --max-tp N                 Maximum tensor parallelism
  --max-conc N               Maximum concurrency
  --step-size N              Step size for concurrency sweep
```

---

## Method 2: Perf Changelog (Automated on PR)

This method automatically triggers benchmarks when you create/update a Pull Request.

### Step-by-Step

1. **Create a branch**
   ```bash
   git checkout -b test-gptoss-perf
   ```

2. **Edit perf-changelog.yaml**

   Add an entry to the file `perf-changelog.yaml` in the repo root:

   ```yaml
   # Add to the END of perf-changelog.yaml
   - date: "2026-02-12"  # Update to today's date
     author: "your-github-username"
     description: "GPTOSS FP4 performance test on local MI300X"
     change-type: "test"
     configs:
       - model-prefix: gptoss
         precision: fp4
         framework: vllm
         runner: mi300x
         seq-lens: [1k1k]
         max-tp: 8
         max-conc: 16
   ```

   **Note:** See [../perf-changelog-examples/](../perf-changelog-examples/) for more examples

3. **Commit and push**
   ```bash
   git add perf-changelog.yaml
   git commit -m "Add GPTOSS FP4 benchmark for local MI300X"
   git push origin test-gptoss-perf
   ```

4. **Create Pull Request**
   - Go to GitHub and create a PR from your branch
   - Add the label **"sweep-enabled"** to the PR
   - Benchmarks will start automatically

5. **Monitor Progress**
   - Go to `Actions` tab
   - Find the "Run Sweep" workflow for your PR
   - Watch the benchmark jobs execute

6. **View Results**
   - Results appear as artifacts when the workflow completes
   - A summary is posted as a comment on your PR

### Perf Changelog Field Reference

```yaml
- date: "YYYY-MM-DD"           # Today's date
  author: "github-username"    # Your GitHub username
  description: "Description"   # What you're testing
  change-type: "test"          # Type: test, perf, feature, fix
  configs:
    - model-prefix: gptoss     # Model: gptoss, dsr1
      precision: fp4           # Precision: fp4, fp8
      framework: vllm          # Framework: vllm, sglang, trt
      runner: mi300x           # Runner type
      seq-lens: [1k1k]         # Sequence lengths
      max-tp: 8                # Optional: limit TP
      max-conc: 16             # Optional: limit concurrency
      min-tp: 1                # Optional: minimum TP
      conc-list: [4,8,16]      # Optional: specific concurrencies
```

---

## Method 3: Custom Workflow (Simple UI)

If you copied the custom workflow file, you get a simple dropdown UI.

### Step-by-Step

1. **Go to GitHub Actions UI**
   - Navigate to `Actions` tab
   - Select `Test Local MI300X` from the left sidebar

2. **Click "Run workflow"**

3. **Select Parameters** from dropdowns:
   - **Tensor Parallelism**: 1, 2, 4, or 8
   - **Concurrency**: 4, 8, 16, 32, or 64
   - **Input Sequence Length**: 1024 or 8192
   - **Output Sequence Length**: 1024 or 8192
   - **Run accuracy evaluation**: true/false

4. **Click "Run workflow"**

This runs a single benchmark with your selected parameters.

---

## Method 4: Test Specific Runner

Validate your runner works with all MI300X configurations:

### Step-by-Step

1. **Go to End-to-End Tests workflow**
2. **Click "Run workflow"**
3. **Enter command:**
   ```bash
   runner-model-sweep --single-node --runner-type mi300x --runner-node-filter mi300x-local --config-files .github/configs/amd-master.yaml
   ```

This runs ALL MI300X model configurations (GPTOSS, DeepSeek, etc.) on just your runner.

---

## Viewing Results

### During Execution

1. Go to `Actions` tab
2. Click on the running workflow
3. Expand the job matrix to see individual benchmarks
4. Click on any job to see:
   - Docker container logs
   - Model download progress
   - vLLM server startup
   - Benchmark execution
   - Results

### After Completion

1. **Download Artifacts**
   - Scroll to bottom of workflow page
   - Find "Artifacts" section
   - Download:
     - `results_bmk` - All benchmark JSON files
     - `eval-results` - Accuracy results (if enabled)
     - `run-stats` - Success rate statistics

2. **View Summary**
   - The workflow summary shows aggregated metrics
   - Success rate and any failures

3. **Analyze Results**
   ```bash
   # Download and extract artifacts
   unzip results_bmk.zip

   # View a result
   cat gptoss_fp4_vllm_tp8_*.json | jq

   # Extract throughput
   cat *.json | jq '.throughput'
   ```

---

## Common Configurations

### Test Everything (Full Sweep)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --config-files .github/configs/amd-master.yaml
```

### Quick Validation (1 sequence length, limited configs)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 1k1k --max-conc 16 --config-files .github/configs/amd-master.yaml
```

### High Throughput Focus (TP=1 only)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --max-tp 1 --config-files .github/configs/amd-master.yaml
```

### Low Latency Focus (TP=8 only)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --min-tp 8 --max-tp 8 --config-files .github/configs/amd-master.yaml
```

### Long Context (8k1k only)
```bash
full-sweep --single-node --model-prefix gptoss --runner-type mi300x --precision fp4 --seq-lens 8k1k --config-files .github/configs/amd-master.yaml
```

---

## Troubleshooting

### Benchmarks Not Starting

**Check runner status:**
```bash
# On server
cd ~/actions-runner
sudo ./svc.sh status
```

**Check runner is online:**
- Go to: Settings → Actions → Runners
- Verify `mi300x-local_0` shows "Idle" (green)

### Jobs Failing Immediately

**Check secrets are set:**
- Settings → Secrets and variables → Actions
- Verify `HF_TOKEN` and `REPO_PAT` exist

**Check logs:**
- Click on failed job
- Look for error messages in "Launch job script" step

### Docker Errors

**On server, check Docker:**
```bash
docker ps
docker info
```

**Check permissions:**
```bash
groups  # Should include 'docker'
```

### Model Download Failures

**Verify HF_TOKEN:**
- Test on server:
  ```bash
  export HF_TOKEN=your_token
  huggingface-cli whoami
  ```

### Results Not Appearing

**Check artifact upload step:**
- In the job logs, look for "Upload result artifact"
- Artifacts are uploaded even if benchmark fails

---

## Next Steps

1. **Start Small**: Run a quick test first (Method 1 with max-tp 4, max-conc 16)
2. **Verify Results**: Download artifacts and check JSON files
3. **Scale Up**: Run full sweep once you verify everything works
4. **Automate**: Use perf changelog (Method 2) for regular testing

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more help.
