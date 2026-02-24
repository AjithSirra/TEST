# Manual Testing & Benchmark Triggering Guide

This guide covers how to manually trigger benchmarks, run full sweep commands, and perform end-to-end testing of the InferenceX benchmarking system.

## Table of Contents
- [Overview](#overview)
- [Manual Benchmark Triggering Methods](#manual-benchmark-triggering-methods)
- [End-to-End Test Flow](#end-to-end-test-flow)
- [Local Testing](#local-testing)
- [GitHub Actions Manual Triggers](#github-actions-manual-triggers)
- [Debugging & Validation](#debugging--validation)
- [Common Test Scenarios](#common-test-scenarios)

## Overview

The InferenceX system supports multiple ways to trigger benchmarks:
1. **Automatic**: Push to `perf-changelog.yaml` on `main_rocm` branch
2. **Manual PR**: Create PR with `sweep-enabled` label
3. **Workflow Dispatch**: Manually trigger GitHub workflow
4. **Local Docker**: Run benchmark scripts locally in Docker
5. **Direct Script**: Execute benchmark scripts directly on hardware

## Manual Benchmark Triggering Methods

### Method 1: Via perf-changelog.yaml (Production Flow)

This is the standard production flow that triggers a full sweep.

#### Step-by-Step Process

**1. Edit perf-changelog.yaml**

```bash
# Navigate to repository
cd c:/Users/asirra/OneDrive\ -\ Advanced\ Micro\ Devices\ Inc/Desktop/Projects/MI_Team/InferenceMAX_rocm

# Create a new branch
git checkout -b test/manual-minimax-sweep

# Edit perf-changelog.yaml
nano perf-changelog.yaml
```

Add entry:
```yaml
- date: 2026-02-24
  description: "Manual test: MiniMax-M2.5 FP8 MI355X SGLang full sweep"
  config-keys:
    - minimaxm2.5-fp8-mi355x-sglang
```

**2. Commit and Push**

```bash
git add perf-changelog.yaml
git commit -m "Manual test: Trigger MiniMax-M2.5 full sweep"
git push origin test/manual-minimax-sweep
```

**3. Create Pull Request with sweep-enabled Label**

```bash
# Using GitHub CLI
gh pr create \
  --title "Manual Test: MiniMax-M2.5 Full Sweep" \
  --body "Testing full sweep benchmark for MiniMax-M2.5 on MI355X with SGLang" \
  --label "sweep-enabled" \
  --base main_rocm
```

**4. Monitor Workflow**

```bash
# Watch workflow status
gh run watch

# Or view in browser
gh pr view --web
```

**Expected Workflow Execution:**
```
1. check-newline job (< 1 min)
   └─ Validates YAML format ✓

2. setup job (< 2 min)
   └─ Generates matrix configuration
   └─ Outputs: search-space-config JSON

3. Parallel sweep jobs (15-45 min each)
   ├─ sweep-single-node-1k1k
   │   ├─ minimaxm2.5_fp8_tp4_conc4_mi355x (12 min)
   │   ├─ minimaxm2.5_fp8_tp4_conc8_mi355x (15 min)
   │   ├─ minimaxm2.5_fp8_tp4_conc16_mi355x (18 min)
   │   ├─ minimaxm2.5_fp8_tp4_conc32_mi355x (22 min)
   │   └─ minimaxm2.5_fp8_tp4_conc64_mi355x (28 min)
   │
   └─ sweep-single-node-8k1k
       └─ [Same concurrency sweep with ISL=8192]

4. collect-results job (< 3 min)
   └─ Aggregates all benchmark results

5. collect-evals job (< 2 min)
   └─ If evaluations were run

Total Time: ~45-60 minutes for full sweep
```

---

### Method 2: Manual Workflow Dispatch

If your workflow supports `workflow_dispatch`, you can trigger it manually.

#### Option A: Using GitHub CLI

```bash
gh workflow run run-sweep.yml \
  --ref main_rocm \
  -f config_keys='["minimaxm2.5-fp8-mi355x-sglang"]' \
  -f run_eval='false'
```

#### Option B: Using GitHub Web UI

1. Navigate to: `https://github.com/YOUR_ORG/InferenceMAX_rocm/actions`
2. Select workflow: `run-sweep.yml`
3. Click "Run workflow" button
4. Select branch: `main_rocm`
5. Enter parameters:
   - Config keys: `minimaxm2.5-fp8-mi355x-sglang`
   - Run eval: `false` (or `true` for evaluations)
6. Click "Run workflow"

#### Option C: Using GitHub API

```bash
# Set variables
GITHUB_TOKEN="your_github_token"
REPO_OWNER="your_org"
REPO_NAME="InferenceMAX_rocm"

# Trigger workflow
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/run-sweep.yml/dispatches" \
  -d '{
    "ref": "main_rocm",
    "inputs": {
      "config_keys": "[\"minimaxm2.5-fp8-mi355x-sglang\"]",
      "run_eval": "false"
    }
  }'
```

---

### Method 3: Single Benchmark Run (Specific Config)

Test a single configuration without full sweep.

```bash
# Manually trigger single benchmark job
gh workflow run benchmark-tmpl.yml \
  --ref main_rocm \
  -f runner='mi355x' \
  -f image='rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218' \
  -f model='MiniMaxAI/MiniMax-M2.5' \
  -f precision='fp8' \
  -f framework='sglang' \
  -f tp='4' \
  -f conc='16' \
  -f isl='1024' \
  -f osl='1024' \
  -f run_eval='false'
```

---

## End-to-End Test Flow

### Complete E2E Test: MiniMax-M2.5 Full Sweep

This section walks through a complete end-to-end test.

#### Prerequisites

```bash
# 1. Verify GitHub runner is online
gh api /repos/YOUR_ORG/InferenceMAX_rocm/actions/runners | jq '.runners[] | select(.status=="online")'

# 2. Verify config exists
grep -A 20 "minimaxm2.5-fp8-mi355x-sglang" .github/configs/amd-master.yaml

# 3. Verify benchmark script exists
ls -la benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh
```

#### Step 1: Setup Test Branch

```bash
# Create test branch
git checkout main_rocm
git pull origin main_rocm
git checkout -b test/e2e-minimax-sweep-$(date +%Y%m%d-%H%M%S)
```

#### Step 2: Add Changelog Entry

```bash
cat >> perf-changelog.yaml << EOF
- date: $(date +%Y-%m-%d)
  description: "E2E Test: MiniMax-M2.5 FP8 MI355X SGLang - Full Sweep $(date +%H:%M:%S)"
  config-keys:
    - minimaxm2.5-fp8-mi355x-sglang
EOF
```

#### Step 3: Validate Changelog Format

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('perf-changelog.yaml'))"

# Verify newline at end of file
tail -c 1 perf-changelog.yaml | od -An -tx1 | grep -q '0a' && echo "✓ Newline present" || echo "✗ Missing newline"
```

#### Step 4: Commit and Push

```bash
git add perf-changelog.yaml
git commit -m "E2E Test: MiniMax-M2.5 full sweep - $(date +%Y-%m-%d)"
git push origin HEAD
```

#### Step 5: Create PR with sweep-enabled Label

```bash
gh pr create \
  --title "E2E Test: MiniMax-M2.5 Full Sweep $(date +%Y-%m-%d)" \
  --body "## E2E Test Description

**Model**: MiniMax-M2.5
**Hardware**: MI355X
**Framework**: SGLang
**Precision**: FP8

**Expected Configs**:
- ISL=1024, OSL=1024: TP=4, CONC=[4,8,16,32,64] (5 jobs)
- ISL=8192, OSL=1024: TP=4, CONC=[4,8,16,32,64] (5 jobs)

**Total Jobs**: 10 benchmark jobs

**Test Checklist**:
- [ ] check-newline job passes
- [ ] setup job generates correct matrix
- [ ] All sweep jobs complete successfully
- [ ] Results are collected and aggregated
- [ ] Artifacts are uploaded
- [ ] Summary table is generated

**Expected Duration**: ~45-60 minutes
" \
  --label "sweep-enabled" \
  --base main_rocm
```

#### Step 6: Monitor Workflow Execution

```bash
# Get PR number
PR_NUMBER=$(gh pr view --json number -q .number)

# Watch workflow
gh run watch

# View logs for specific job (replace <run-id>)
gh run view <run-id> --log

# Check job status
gh run list --workflow=run-sweep.yml --limit 1
```

#### Step 7: Validate Results

**A. Check Workflow Jobs**

```bash
# Get latest run ID
RUN_ID=$(gh run list --workflow=run-sweep.yml --limit 1 --json databaseId -q '.[0].databaseId')

# List all jobs
gh run view $RUN_ID --json jobs -q '.jobs[] | "\(.name): \(.conclusion)"'

# Expected output:
# check-newline: success
# setup: success
# sweep-single-node-1k1k (tp=4, conc=4): success
# sweep-single-node-1k1k (tp=4, conc=8): success
# sweep-single-node-1k1k (tp=4, conc=16): success
# sweep-single-node-1k1k (tp=4, conc=32): success
# sweep-single-node-1k1k (tp=4, conc=64): success
# sweep-single-node-8k1k (tp=4, conc=4): success
# ... (10 total sweep jobs)
# collect-results: success
```

**B. Download and Verify Artifacts**

```bash
# Create results directory
mkdir -p e2e_test_results/$(date +%Y%m%d)
cd e2e_test_results/$(date +%Y%m%d)

# Download all artifacts
gh run download $RUN_ID

# List downloaded artifacts
ls -lh

# Expected artifacts:
# bmk_minimaxm2.5_fp8_tp4_conc4_mi355x.tar.gz
# bmk_minimaxm2.5_fp8_tp4_conc8_mi355x.tar.gz
# bmk_minimaxm2.5_fp8_tp4_conc16_mi355x.tar.gz
# ... (10 total)
# agg_results.tar.gz
# server_logs/ (if preserved)
```

**C. Extract and Validate Benchmark Results**

```bash
# Extract all benchmark artifacts
for artifact in bmk_*.tar.gz; do
    tar -xzf "$artifact"
done

# Verify JSON results exist
ls -1 agg_*.json | wc -l
# Expected: 10

# Validate JSON structure
python3 << 'PYTHON_SCRIPT'
import json
import glob

results = []
for file in glob.glob("agg_*.json"):
    with open(file) as f:
        data = json.load(f)
        results.append(data)

        # Validate required fields
        required_fields = [
            "model", "hardware", "framework", "precision",
            "tp", "conc", "isl", "osl",
            "request_throughput", "output_throughput",
            "mean_ttft_ms", "mean_tpot_ms", "mean_e2el_ms"
        ]

        missing = [field for field in required_fields if field not in data]
        if missing:
            print(f"❌ {file}: Missing fields: {missing}")
        else:
            print(f"✓ {file}: All required fields present")
            print(f"  - Throughput: {data['output_throughput']:.0f} tok/s")
            print(f"  - TTFT: {data['mean_ttft_ms']:.1f} ms")
            print(f"  - TPOT: {data['mean_tpot_ms']:.1f} ms")

print(f"\n✓ Total results validated: {len(results)}/10")
PYTHON_SCRIPT
```

**D. Generate Test Summary**

```bash
python3 << 'PYTHON_SCRIPT'
import json
import glob
from tabulate import tabulate

results = []
for file in sorted(glob.glob("agg_*.json")):
    with open(file) as f:
        data = json.load(f)
        results.append([
            data.get("model_prefix", "N/A"),
            f"TP={data['tp']}",
            f"C={data['conc']}",
            f"{data['isl']}/{data['osl']}",
            f"{data['output_throughput']:.0f}",
            f"{data['mean_ttft_ms']:.1f}",
            f"{data['mean_tpot_ms']:.2f}",
            f"{data['mean_e2el_ms']:.0f}"
        ])

headers = ["Model", "TP", "Conc", "ISL/OSL", "Tok/s", "TTFT", "TPOT", "E2EL"]
print(tabulate(results, headers=headers, tablefmt="grid"))
PYTHON_SCRIPT
```

**Expected Output:**
```
┌───────────┬──────┬──────┬─────────┬────────┬────────┬────────┬────────┐
│ Model     │ TP   │ Conc │ ISL/OSL │ Tok/s  │ TTFT   │ TPOT   │ E2EL   │
├───────────┼──────┼──────┼─────────┼────────┼────────┼────────┼────────┤
│ minimaxm2.5│ TP=4│ C=4  │ 1024/1024│ 800   │ 45.2   │ 14.20  │ 1450   │
│ minimaxm2.5│ TP=4│ C=8  │ 1024/1024│ 1200  │ 52.1   │ 13.10  │ 1380   │
│ minimaxm2.5│ TP=4│ C=16 │ 1024/1024│ 1600  │ 61.3   │ 12.50  │ 1340   │
│ minimaxm2.5│ TP=4│ C=32 │ 1024/1024│ 1850  │ 75.8   │ 12.20  │ 1320   │
│ minimaxm2.5│ TP=4│ C=64 │ 1024/1024│ 2000  │ 98.2   │ 12.00  │ 1300   │
│ minimaxm2.5│ TP=4│ C=4  │ 8192/1024│ 750   │ 180.5  │ 14.50  │ 1500   │
│ minimaxm2.5│ TP=4│ C=8  │ 8192/1024│ 1100  │ 195.2  │ 13.80  │ 1450   │
│ minimaxm2.5│ TP=4│ C=16 │ 8192/1024│ 1450  │ 215.6  │ 13.20  │ 1420   │
│ minimaxm2.5│ TP=4│ C=32 │ 8192/1024│ 1700  │ 245.1  │ 12.90  │ 1400   │
│ minimaxm2.5│ TP=4│ C=64 │ 8192/1024│ 1850  │ 288.5  │ 12.70  │ 1380   │
└───────────┴──────┴──────┴─────────┴────────┴────────┴────────┴────────┘
```

#### Step 8: Verify Server Logs (Optional)

```bash
# Extract server logs if available
tar -xzf server_logs.tar.gz 2>/dev/null || echo "No server logs artifact"

# Check for errors in server logs
if [ -d server_logs ]; then
    echo "=== Checking server logs for errors ==="
    grep -i "error\|exception\|failed" server_logs/*.log || echo "✓ No errors found"
fi
```

#### Step 9: Cleanup

```bash
# Return to repository root
cd ../../

# Merge PR if tests passed
gh pr merge $PR_NUMBER --squash --delete-branch

# Or close without merging
gh pr close $PR_NUMBER --delete-branch
```

---

## Local Testing

### Local Docker Testing (No GitHub Actions)

Test benchmark scripts locally using Docker before triggering full sweep.

#### Setup Environment

```bash
# Set environment variables
export MODEL="MiniMaxAI/MiniMax-M2.5"
export TP=4
export CONC=16
export ISL=1024
export OSL=1024
export MAX_MODEL_LEN=32768
export RANDOM_RANGE_RATIO=0.8
export RESULT_FILENAME="local_test_minimaxm2.5_fp8_tp4_conc16_mi355x"
export PRECISION=fp8
export FRAMEWORK=sglang
export HF_TOKEN="your_huggingface_token"
export PORT=8888
export MEM_FRAC_STATIC=0.8
```

#### Run Docker Container

```bash
# Pull image
docker pull rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218

# Run benchmark
docker run --rm \
  --device=/dev/kfd \
  --device=/dev/dri \
  --shm-size=128g \
  --ipc=host \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -e MODEL="$MODEL" \
  -e TP="$TP" \
  -e CONC="$CONC" \
  -e ISL="$ISL" \
  -e OSL="$OSL" \
  -e MAX_MODEL_LEN="$MAX_MODEL_LEN" \
  -e RANDOM_RANGE_RATIO="$RANDOM_RANGE_RATIO" \
  -e RESULT_FILENAME="$RESULT_FILENAME" \
  -e HF_TOKEN="$HF_TOKEN" \
  -e PORT="$PORT" \
  -e MEM_FRAC_STATIC="$MEM_FRAC_STATIC" \
  -v $(pwd):/workspace \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -w /workspace \
  rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218 \
  bash /workspace/benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh
```

#### Validate Local Results

```bash
# Check result file exists
ls -lh ${RESULT_FILENAME}.json

# Pretty print results
python3 -m json.tool ${RESULT_FILENAME}.json

# Quick summary
python3 << PYTHON_SCRIPT
import json
with open("${RESULT_FILENAME}.json") as f:
    data = json.load(f)
    print(f"✓ Benchmark completed successfully")
    print(f"  - Output Throughput: {data.get('output_throughput', 'N/A')} tok/s")
    print(f"  - Mean TTFT: {data.get('mean_ttft_ms', 'N/A')} ms")
    print(f"  - Mean TPOT: {data.get('mean_tpot_ms', 'N/A')} ms")
    print(f"  - Request Throughput: {data.get('request_throughput', 'N/A')} req/s")
PYTHON_SCRIPT
```

---

### Direct Script Execution (On Bare Metal)

For testing directly on hardware without Docker.

```bash
# Navigate to repository
cd /path/to/InferenceMAX_rocm

# Set environment variables
export MODEL="MiniMaxAI/MiniMax-M2.5"
export TP=4
export CONC=16
export ISL=1024
export OSL=1024
export MAX_MODEL_LEN=32768
export RANDOM_RANGE_RATIO=0.8
export RESULT_FILENAME="baremetal_test"
export HF_TOKEN="your_token"

# Set GPU visibility
export ROCR_VISIBLE_DEVICES=0,1,2,3  # For TP=4
export HIP_VISIBLE_DEVICES=$ROCR_VISIBLE_DEVICES

# Run benchmark script
bash benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh
```

---

## GitHub Actions Manual Triggers

### Trigger Full Sweep via API

```bash
#!/bin/bash

# Configuration
GITHUB_TOKEN="your_github_token"
REPO_OWNER="your_org"
REPO_NAME="InferenceMAX_rocm"
CONFIG_KEY="minimaxm2.5-fp8-mi355x-sglang"

# Create temporary changelog
TEMP_BRANCH="test/api-trigger-$(date +%s)"
git checkout -b $TEMP_BRANCH

# Add changelog entry
cat >> perf-changelog.yaml << EOF
- date: $(date +%Y-%m-%d)
  description: "API Triggered: $CONFIG_KEY"
  config-keys:
    - $CONFIG_KEY
EOF

# Commit and push
git add perf-changelog.yaml
git commit -m "API trigger: $CONFIG_KEY"
git push origin $TEMP_BRANCH

# Create PR via API
PR_NUMBER=$(curl -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls" \
  -d "{
    \"title\": \"API Test: $CONFIG_KEY\",
    \"head\": \"$TEMP_BRANCH\",
    \"base\": \"main_rocm\",
    \"body\": \"Automated test via API\"
  }" | jq -r '.number')

# Add sweep-enabled label
curl -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$PR_NUMBER/labels" \
  -d '{"labels": ["sweep-enabled"]}'

echo "PR #$PR_NUMBER created and labeled"
echo "Monitor: https://github.com/$REPO_OWNER/$REPO_NAME/pull/$PR_NUMBER"
```

---

## Debugging & Validation

### Pre-Flight Checks

```bash
#!/bin/bash
echo "=== Pre-Flight Checks ==="

# 1. Check runner availability
echo "1. Checking GitHub runners..."
gh api /repos/$REPO_OWNER/$REPO_NAME/actions/runners \
  | jq -r '.runners[] | select(.status=="online") | "\(.name): \(.status)"'

# 2. Validate config exists
echo "2. Validating config..."
CONFIG_KEY="minimaxm2.5-fp8-mi355x-sglang"
if grep -q "$CONFIG_KEY" .github/configs/amd-master.yaml; then
    echo "✓ Config found: $CONFIG_KEY"
else
    echo "✗ Config not found: $CONFIG_KEY"
    exit 1
fi

# 3. Check benchmark script
echo "3. Checking benchmark script..."
SCRIPT_NAME="minimaxm2.5_fp8_mi355x_sglang.sh"
if [ -f "benchmarks/$SCRIPT_NAME" ]; then
    echo "✓ Script exists: $SCRIPT_NAME"
    if [ -x "benchmarks/$SCRIPT_NAME" ]; then
        echo "✓ Script is executable"
    else
        echo "⚠ Script not executable, fixing..."
        chmod +x "benchmarks/$SCRIPT_NAME"
    fi
else
    echo "✗ Script not found: $SCRIPT_NAME"
    exit 1
fi

# 4. Validate YAML syntax
echo "4. Validating perf-changelog.yaml..."
python3 -c "import yaml; yaml.safe_load(open('perf-changelog.yaml'))" \
  && echo "✓ YAML syntax valid" \
  || echo "✗ YAML syntax invalid"

# 5. Check Docker image availability
echo "5. Checking Docker image..."
IMAGE="rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218"
if docker manifest inspect $IMAGE > /dev/null 2>&1; then
    echo "✓ Docker image exists: $IMAGE"
else
    echo "✗ Docker image not found: $IMAGE"
fi

echo "=== Pre-Flight Checks Complete ==="
```

### Post-Run Validation

```bash
#!/bin/bash
echo "=== Post-Run Validation ==="

RUN_ID=$1  # Pass GitHub run ID

# 1. Check all jobs succeeded
echo "1. Checking job statuses..."
FAILED_JOBS=$(gh run view $RUN_ID --json jobs \
  -q '.jobs[] | select(.conclusion != "success") | .name')

if [ -z "$FAILED_JOBS" ]; then
    echo "✓ All jobs succeeded"
else
    echo "✗ Failed jobs:"
    echo "$FAILED_JOBS"
fi

# 2. Verify artifact count
echo "2. Checking artifacts..."
ARTIFACT_COUNT=$(gh run view $RUN_ID --json artifacts -q '.artifacts | length')
echo "  Artifacts found: $ARTIFACT_COUNT"

# 3. Download and validate results
echo "3. Downloading results..."
mkdir -p validation_$(date +%Y%m%d_%H%M%S)
cd validation_$(date +%Y%m%d_%H%M%S)
gh run download $RUN_ID

# 4. Count JSON results
JSON_COUNT=$(find . -name "agg_*.json" | wc -l)
echo "  JSON results: $JSON_COUNT"

# 5. Validate each result
echo "4. Validating results..."
python3 << 'PYTHON_SCRIPT'
import json
import glob
import sys

errors = []
for file in glob.glob("**/agg_*.json", recursive=True):
    try:
        with open(file) as f:
            data = json.load(f)

        # Check throughput is reasonable
        if data.get('output_throughput', 0) < 100:
            errors.append(f"{file}: Low throughput ({data.get('output_throughput')} tok/s)")

        # Check latency is reasonable
        if data.get('mean_tpot_ms', 0) > 100:
            errors.append(f"{file}: High TPOT ({data.get('mean_tpot_ms')} ms)")

        print(f"✓ {file}")
    except Exception as e:
        errors.append(f"{file}: {str(e)}")

if errors:
    print("\n✗ Validation errors:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)
else:
    print("\n✓ All results validated successfully")
PYTHON_SCRIPT

echo "=== Validation Complete ==="
```

---

## Common Test Scenarios

### Scenario 1: Quick Smoke Test (Single Config)

Test a single configuration quickly (~15 minutes).

```bash
# Edit perf-changelog.yaml with single low-concurrency config
cat >> perf-changelog.yaml << EOF
- date: $(date +%Y-%m-%d)
  description: "Smoke test: MiniMax-M2.5 TP=4 CONC=4"
  config-keys:
    - minimaxm2.5-fp8-mi355x-sglang
EOF

# Modify amd-master.yaml temporarily to limit sweep
# (Or use workflow_dispatch with specific params)
```

### Scenario 2: Regression Test (Compare Two Runs)

Compare results from two different runs.

```bash
#!/bin/bash

# Run 1 (baseline)
echo "Running baseline..."
gh workflow run run-sweep.yml --ref main_rocm -f config_keys='["minimaxm2.5-fp8-mi355x-sglang"]'
BASELINE_RUN_ID=$(gh run list --workflow=run-sweep.yml --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch $BASELINE_RUN_ID

# Download baseline results
mkdir -p baseline_results
cd baseline_results
gh run download $BASELINE_RUN_ID
cd ..

# Run 2 (new version)
echo "Running new version..."
gh workflow run run-sweep.yml --ref feature/optimization -f config_keys='["minimaxm2.5-fp8-mi355x-sglang"]'
NEW_RUN_ID=$(gh run list --workflow=run-sweep.yml --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch $NEW_RUN_ID

# Download new results
mkdir -p new_results
cd new_results
gh run download $NEW_RUN_ID
cd ..

# Compare results
python3 << 'PYTHON_SCRIPT'
import json
import glob

baseline_files = glob.glob("baseline_results/**/agg_*.json", recursive=True)
new_files = glob.glob("new_results/**/agg_*.json", recursive=True)

print("=== Regression Comparison ===\n")
print(f"{'Config':<40} {'Baseline':<15} {'New':<15} {'Change':<15}")
print("-" * 85)

for baseline_file in sorted(baseline_files):
    config_name = baseline_file.split("/")[-1]
    new_file = f"new_results/{config_name}"

    if new_file in new_files:
        with open(baseline_file) as f:
            baseline_data = json.load(f)
        with open(new_file) as f:
            new_data = json.load(f)

        baseline_tput = baseline_data.get('output_throughput', 0)
        new_tput = new_data.get('output_throughput', 0)
        change = ((new_tput - baseline_tput) / baseline_tput * 100) if baseline_tput > 0 else 0

        change_str = f"{change:+.1f}%"
        config_str = f"TP={baseline_data['tp']} CONC={baseline_data['conc']}"

        print(f"{config_str:<40} {baseline_tput:<15.0f} {new_tput:<15.0f} {change_str:<15}")
PYTHON_SCRIPT
```

### Scenario 3: Multi-Model Comparison

Test multiple models simultaneously.

```bash
cat >> perf-changelog.yaml << EOF
- date: $(date +%Y-%m-%d)
  description: "Multi-model comparison: MiniMax vs Qwen"
  config-keys:
    - minimaxm2.5-fp8-mi355x-sglang
    - qwen3.5-bf16-mi355x-vllm
EOF
```

---

## Summary Checklist

### Before Running Full Sweep

- [ ] GitHub runner is online and available
- [ ] Config exists in `amd-master.yaml`
- [ ] Benchmark script exists and is executable
- [ ] Docker image is accessible
- [ ] HuggingFace token is configured
- [ ] perf-changelog.yaml has valid syntax
- [ ] Local test passed (optional but recommended)

### During Execution

- [ ] check-newline job passes
- [ ] setup job generates correct matrix
- [ ] Monitor job progress (not all failing)
- [ ] Check for runner availability issues

### After Completion

- [ ] All sweep jobs completed successfully
- [ ] Artifacts uploaded correctly
- [ ] Results JSON files are valid
- [ ] Throughput values are reasonable
- [ ] Latency values are within expected range
- [ ] Server logs show no critical errors
- [ ] Summary table generated correctly

---

## Contact & Support

For issues with manual testing:
- **GitHub Issues**: [Open an issue](../../issues)
- **Maintainers**: @Rohan138, @ajith-sirra-amd, @seungrokj

---

**Last Updated**: 2026-02-24
**Version**: 1.0
