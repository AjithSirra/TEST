# Manually Cloned From
https://github.com/SemiAnalysisAI/InferenceX (02/18/2026)

- ⚠️  'main' branch is not compatible with self-hosted gh runners.
- ⚠️  use 'main_rocm' branch to use the self-hosted gh runners.

For assistance, reach out to: @Rohan138 @ajith-sirra-amd @seungrokj 

#  InferenceX™, Open Source Inference Frequent Benchmarking

InferenceX™ (formerly InferenceMAX) runs our suite of benchmarks every night, continually re-benchmarking the world’s most popular open-source inference frameworks used by major token factories and models to track real performance in real time. As these software stacks improve, InferenceX™ captures that progress in near real-time, providing a live indicator of inference performance progress. A live dashboard is available for free publicly at https://inferencex.com/. 

> [!IMPORTANT]
> Only [SemiAnalysisAI/InferenceX](https://github.com/SemiAnalysisAI/InferenceX) repo contains the Official InferenceX™ result, all other forks & repos are Unofficial. The benchmark setup & quality of machines/clouds in unofficial repos may be differ leading to subpar benchmarking. Unofficial must be explicitly labelled as Unofficial.
> Forks may not remove this disclaimer

[Full Article Write Up for InferenceXv2](https://newsletter.semianalysis.com/p/inferencex-v2-nvidia-blackwell-vs)
[Full Article Write Up for InferenceXv1](https://newsletter.semianalysis.com/p/inferencemax-open-source-inference)


<img width="1627" height="1022" alt="CleanShot 2026-02-04 at 15 26 09" src="https://github.com/user-attachments/assets/65110e16-7590-424f-884d-12876d9e8f3e" />


## Why?

InferenceX™, an open-source, under Apache2 license, automated benchmark designed to move at the same rapid speed as the software ecosystem itself, is built to address this challenge.

LLM Inference performance is driven by two pillars, hardware and software. While hardware innovation drives step jumps in performance every year through the release of new GPUs/XPUs and new systems, software evolves every single day, delivering continuous performance gains on top of these step jumps. Speed is the Moat 🚀
 
AI software like SGLang, vLLM, TensorRT-LLM, CUDA, ROCm and achieve this continuous improvement in performance through kernel-level optimizations, distributed inference strategies, and scheduling innovations that increase the pareto frontier of performance in incremental releases that can be just days apart.
 
This pace of software advancement creates a challenge: benchmarks conducted at a fixed point in time quickly go stale and do not represent the performance that can be achieved with the latest software packages.


## Acknowledgements & Supporters
Thank you to Lisa Su and Anush Elangovan for providing the MI355X and CDNA3 GPUs for this free and open-source project. We want to recognize the many AMD contributors for their responsiveness and for debugging, optimizing, and validating performance across AMD GPUs. 
We’re also grateful to Jensen Huang and Ian Buck for supporting this open source with access to a GB200 NVL72 rack (through OCI) and B200 GPUs. Thank you to the many NVIDIA contributors from the NVIDIA inference team, NVIDIA Dynamo team.

We also want to recognize the SGLang, vLLM, and TensorRT-LLM maintainers for building a world-class software stack and open sourcing it to the entire world.
Finally, we’re grateful to Crusoe, CoreWeave, Nebius, TensorWave, Oracle and TogetherAI for supporting open-source innovation through compute resources, enabling this.

"As we build systems at unprecedented scale, it's critical for the ML community to have open, transparent benchmarks that reflect how inference really performs across hardware and software. InferenceX™'s head-to-head benchmarks cut through the noise and provide a living picture of token throughput, performance per dollar, and tokens per Megawatt. This kind of open source effort strengthens the entire ecosystem and helps everyone, from researchers to operators of frontier datacenters, make smarter decisions." - Peter Hoeschele, VP of Infrastructure and Industrial Compute, OpenAI Stargate

"The gap between theoretical peak and real-world inference throughput is often determined by systems software: inference engine, distributed strategies, and low-level kernels. InferenceX™ is valuable because it benchmarks the latest software showing how optimizations actually play out across various hardware. Open, reproducible results like these help the whole community move faster.” - Tri Dao, Chief Scientist of Together AI & Inventor of Flash Attention

“The industry needs many public, reproducible benchmarks of inference performance. We’re excited to collaborate with InferenceX™ from the vLLM team. More diverse workloads and scenarios that everyone can trust and reference will help the ecosystem move forward. Fair, transparent measurements drive progress across every layer of the stack, from model architectures to inference engines to hardware.” – Simon Mo, vLLM Project Co-Lead

---

# Benchmarking System Architecture & Flow

This section provides a comprehensive guide to understanding how the InferenceX benchmarking system works internally.

## Table of Contents
- [System Architecture](#system-architecture)
- [Complete Execution Flow](#complete-execution-flow)
- [File Structure](#file-structure)
- [Configuration Guide](#configuration-guide)
- [Adding New Benchmarks](#adding-new-benchmarks)
- [Metrics Collected](#metrics-collected)
- [Troubleshooting](#troubleshooting)

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Workflow (Orchestrator)               │
│                     .github/workflows/run-sweep.yml              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ├─► Changelog Parser (utils/process_changelog.py)
                           │   └─► Config Generator (utils/matrix_logic/generate_sweep_configs.py)
                           │       └─► Master Configs (.github/configs/amd-master.yaml)
                           │
                           ├─► Parallel Sweep Jobs
                           │   ├─ sweep-single-node-1k1k
                           │   ├─ sweep-single-node-1k8k
                           │   ├─ sweep-single-node-8k1k
                           │   └─ sweep-multi-node-*
                           │
                           └─► Each Job Executes:
                               ├─► Runner (runners/launch_*.sh)
                               │   └─► Docker Container
                               │       └─► Benchmark Script (benchmarks/*.sh)
                               │           ├─► Server (vLLM/SGLang/ATOM)
                               │           └─► Client (utils/bench_serving/)
                               │
                               └─► Result Processing
                                   ├─ utils/process_result.py
                                   ├─ utils/collect_results.py
                                   └─ utils/summarize.py
```

### Server-Client Benchmark Architecture

```
┌────────────────────────────┐         ┌─────────────────────────────┐
│   Benchmark Script         │         │   Docker Container          │
│   (benchmarks/*.sh)        │         │                             │
│                            │         │   ┌──────────────────────┐  │
│  1. Download Model         │────────►│   │   Inference Server   │  │
│  2. Start Server           │         │   │   (vLLM/SGLang)      │  │
│  3. Wait for Health Check  │         │   │   Port: 8888         │  │
│  4. Run Client             │         │   │   API: OpenAI-compat │  │
│                            │         │   └──────────┬───────────┘  │
│  ┌──────────────────────┐  │         │              │              │
│  │  Benchmark Client    │  │         │              │              │
│  │  (benchmark_serving) │  │─────────┼──────────────┘              │
│  │                      │  │  HTTP   │                             │
│  │  - Generate Prompts  │  │  POST   │   GPU: MI355X / H100        │
│  │  - Async Requests    │  │  /v1/   │   Memory: HBM3/HBM3e        │
│  │  - Measure Latency   │  │  chat/  │   Parallelism: TP/EP        │
│  │  - Track Throughput  │  │  comp.. │                             │
│  └──────────────────────┘  │         └─────────────────────────────┘
└────────────────────────────┘
```

## Complete Execution Flow

### Example: Running MiniMax-M2.5 Full Sweep

#### 1. **Trigger** → Add Configuration to Changelog

Edit [perf-changelog.yaml](perf-changelog.yaml):
```yaml
- date: 2026-02-24
  description: “Benchmark MiniMax-M2.5 with FP8 on MI355X using SGLang”
  config-keys:
    - minimaxm2.5-fp8-mi355x-sglang
```

#### 2. **GitHub Workflow Activation**

File: [.github/workflows/run-sweep.yml](.github/workflows/run-sweep.yml)
- **Triggered by**: Push to `main`/`main_rocm` with changelog changes, or PR with `sweep-enabled` label
- **Jobs**:
  - `check-newline`: Validates YAML format
  - `setup`: Processes changelog and generates config matrix

#### 3. **Configuration Expansion Pipeline**

```
utils/process_changelog.py
  └─► Parses git diff to find new changelog entries
      └─► utils/matrix_logic/generate_sweep_configs.py
          └─► Reads .github/configs/amd-master.yaml
              └─► Finds: minimaxm2.5-fp8-mi355x-sglang
                  └─► Expands search space:
                      - Sequence lengths: 1k1k, 8k1k
                      - TP values: [4]
                      - Concurrency: [4, 8, 16, 32, 64]
                      └─► Outputs: Matrix JSON with all combinations
```

**Example config from** [.github/configs/amd-master.yaml](.github/configs/amd-master.yaml):
```yaml
minimaxm2.5-fp8-mi355x-sglang:
  image: rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218
  model: MiniMaxAI/MiniMax-M2.5
  model-prefix: minimaxm2.5
  runner: mi355x
  precision: fp8
  framework: sglang
  seq-len-configs:
    - isl: 1024
      osl: 1024
      search-space:
        - tp: [4]
          conc-start: 4
          conc-end: 64
    - isl: 8192
      osl: 1024
      search-space:
        - tp: [4]
          conc-start: 4
          conc-end: 64
```

#### 4. **Parallel Sweep Job Execution**

Multiple jobs run in parallel for different sequence length combinations:
- `sweep-single-node-1k1k` (ISL=1024, OSL=1024)
- `sweep-single-node-8k1k` (ISL=8192, OSL=1024)

Each job uses template: [.github/workflows/benchmark-tmpl.yml](.github/workflows/benchmark-tmpl.yml)

#### 5. **Individual Benchmark Execution** (Example: TP=4, CONC=16)

**Step A: Benchmark Template Workflow**

File: [.github/workflows/benchmark-tmpl.yml](.github/workflows/benchmark-tmpl.yml)
```yaml
- name: Run Benchmark
  run: bash ./runners/launch_mi355x-amd.sh
  env:
    MODEL: MiniMaxAI/MiniMax-M2.5
    TP: 4
    CONC: 16
    ISL: 1024
    OSL: 1024
    PRECISION: fp8
    FRAMEWORK: sglang
    RESULT_FILENAME: minimaxm2.5_fp8_tp4_conc16_mi355x
```

**Step B: Runner Script Launches Docker**

File: [runners/launch_mi355x-amd.sh](runners/launch_mi355x-amd.sh)
```bash
# Pull Docker image
docker pull rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218

# Run benchmark in container
docker run \
  --device=/dev/kfd --device=/dev/dri --device=/dev/mem \
  --shm-size=128g \
  --ipc=host --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -e MODEL=$MODEL -e TP=$TP -e CONC=$CONC \
  -e ISL=$ISL -e OSL=$OSL -e HF_TOKEN=$HF_TOKEN \
  -e RESULT_FILENAME=$RESULT_FILENAME \
  -v $(pwd):/workspace \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218 \
  bash /workspace/benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh
```

**Step C: Benchmark Script Execution** (Inside Container)

File: [benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh](benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh)
```bash
#!/usr/bin/env bash

# 1. Source shared utilities
source “$(dirname “$0”)/benchmark_lib.sh”

# 2. Validate required environment variables
check_env_vars MODEL TP CONC ISL OSL MAX_MODEL_LEN RESULT_FILENAME

# 3. Download model from HuggingFace
hf download “$MODEL”

# 4. Set GPU visibility for AMD
if [ -n “$ROCR_VISIBLE_DEVICES” ]; then
    export HIP_VISIBLE_DEVICES=”$ROCR_VISIBLE_DEVICES”
fi

# 5. Start SGLang inference server (background)
SERVER_LOG=/workspace/server.log
PORT=${PORT:-8888}

python3 -m sglang.launch_server \
    --attention-backend triton \
    --model-path $MODEL \
    --host=0.0.0.0 \
    --port $PORT \
    --tensor-parallel-size $TP \
    --trust-remote-code \
    --mem-fraction-static 0.8 \
    --kv-cache-dtype fp8_e4m3 \
    --max-model-len $MAX_MODEL_LEN > $SERVER_LOG 2>&1 &

SERVER_PID=$!

# 6. Wait for server to be ready (polls /health endpoint)
wait_for_server_ready --port “$PORT” --server-log “$SERVER_LOG” --server-pid “$SERVER_PID”

# 7. Run benchmark client
export PYTHONDONTWRITEBYTECODE=1
run_benchmark_serving \
    --model “$MODEL” \
    --port “$PORT” \
    --backend vllm \
    --input-len “$ISL” \
    --output-len “$OSL” \
    --random-range-ratio 0.8 \
    --num-prompts “$((CONC * 10))” \
    --max-concurrency “$CONC” \
    --result-filename “$RESULT_FILENAME” \
    --result-dir /workspace/ \
    --trust-remote-code

# 8. Optional: Run LM evaluation (if RUN_EVAL=true)
if [ “${RUN_EVAL}” = “true” ]; then
    run_eval --framework lm-eval --port “$PORT” --concurrent-requests $CONC
    append_lm_eval_summary
fi
```

**Step D: Benchmark Client Execution**

File: [utils/bench_serving/benchmark_serving.py](utils/bench_serving/benchmark_serving.py)
```python
# Generate random prompts with length variability
requests = sample_random_requests(
    prefix_len=0,
    input_len=1024,          # ISL
    output_len=1024,         # OSL
    num_prompts=160,         # CONC * 10 = 16 * 10
    range_ratio=0.8,         # ±20% length variation
    tokenizer=tokenizer
)

# Send async requests to inference server
results = []
for request in requests:
    result = await async_request_openai_completions(
        api_url=”http://localhost:8888/v1/chat/completions”,
        model=”MiniMaxAI/MiniMax-M2.5”,
        prompt=request.prompt,
        max_tokens=1024,
        ...
    )
    # Measure: TTFT, TPOT, ITL, E2EL
    results.append(result)

# Calculate and save metrics
metrics = {
    “request_throughput”: requests_per_second,
    “output_throughput”: output_tokens_per_second,
    “mean_ttft_ms”: mean_time_to_first_token,
    “mean_tpot_ms”: mean_time_per_output_token,
    “mean_e2el_ms”: mean_end_to_end_latency,
    “p99_ttft_ms”: percentile_99_ttft,
    ...
}

json.dump(metrics, f”{RESULT_FILENAME}.json”)
```

File: [utils/bench_serving/backend_request_func.py](utils/bench_serving/backend_request_func.py)
- Implements `async_request_openai_completions()` for vLLM/SGLang
- Handles streaming responses
- Tracks timestamps for latency calculation

#### 6. **Result Processing & Aggregation**

**Step A: Per-Job Result Processing**

File: [utils/process_result.py](utils/process_result.py)
```python
# Load raw benchmark result
with open(f”{RESULT_FILENAME}.json”) as f:
    result = json.load(f)

# Add metadata from environment
agg_result = {
    “hardware”: “mi355x”,
    “framework”: “sglang”,
    “precision”: “fp8”,
    “model”: “MiniMaxAI/MiniMax-M2.5”,
    “model_prefix”: “minimaxm2.5”,
    “tp”: 4,
    “conc”: 16,
    “isl”: 1024,
    “osl”: 1024,
    “spec_decoding”: “none”,
    **result  # Merge benchmark metrics
}

# Save aggregated result
with open(f”agg_{RESULT_FILENAME}.json”, “w”) as f:
    json.dump(agg_result, f, indent=2)
```

**Step B: Cross-Job Result Collection**

File: [.github/workflows/collect-results.yml](.github/workflows/collect-results.yml)
```yaml
- name: Download all benchmark artifacts
  uses: actions/download-artifact@v4
  with:
    pattern: bmk_*

- name: Collect results
  run: python3 utils/collect_results.py
```

File: [utils/collect_results.py](utils/collect_results.py)
```python
# Collect all aggregated results
all_results = []
for json_file in Path(“results”).rglob(“agg_*.json”):
    with open(json_file) as f:
        all_results.append(json.load(f))

# Save combined results
with open(“agg_all.json”, “w”) as f:
    json.dump(all_results, f, indent=2)
```

**Step C: Summary Generation**

File: [utils/summarize.py](utils/summarize.py)
```python
# Generate markdown summary table
table = “””
| Model | Hardware | Framework | Precision | TP | Concurrency | TTFT (ms) | TPOT (ms) | Throughput (tok/s) |
|-------|----------|-----------|-----------|----|-----------  |-----------|-----------|-------------------|
“””

for result in all_results:
    table += f”| {result[‘model_prefix’]} | {result[‘hardware’]} | {result[‘framework’]} | “
    table += f”{result[‘precision’]} | {result[‘tp’]} | {result[‘conc’]} | “
    table += f”{result[‘mean_ttft_ms’]:.1f} | {result[‘mean_tpot_ms’]:.1f} | “
    table += f”{result[‘output_throughput’]:.0f} |\n”

# Output to GitHub step summary
print(table)
```

#### 7. **Complete Execution Timeline**

```
USER: Adds minimaxm2.5-fp8-mi355x-sglang to perf-changelog.yaml
  ↓
PUSH: Commits to main_rocm branch
  ↓
GITHUB: Webhook triggers .github/workflows/run-sweep.yml
  ↓
JOB: check-newline ✓
  ↓
JOB: setup
  └─ utils/process_changelog.py
      └─ utils/matrix_logic/generate_sweep_configs.py
          └─ Reads .github/configs/amd-master.yaml
              └─ Generates matrix: 10 configs (5 concurrency levels × 2 seq lengths)
  ↓
PARALLEL JOBS: Launch (matrix strategy)
  ├─ sweep-single-node-1k1k
  │   ├─ [TP=4, CONC=4,  ISL=1024, OSL=1024]
  │   ├─ [TP=4, CONC=8,  ISL=1024, OSL=1024]
  │   ├─ [TP=4, CONC=16, ISL=1024, OSL=1024]  ← DETAILED EXAMPLE
  │   ├─ [TP=4, CONC=32, ISL=1024, OSL=1024]
  │   └─ [TP=4, CONC=64, ISL=1024, OSL=1024]
  │
  └─ sweep-single-node-8k1k
      └─ [Same concurrency sweep with ISL=8192, OSL=1024]

DETAILED: Job [TP=4, CONC=16, ISL=1024, OSL=1024]
  ↓
WORKFLOW: .github/workflows/benchmark-tmpl.yml
  └─ Sets env: MODEL, TP, CONC, ISL, OSL, PRECISION, FRAMEWORK, RESULT_FILENAME
  └─ Runs: bash ./runners/launch_mi355x-amd.sh
      ↓
RUNNER: runners/launch_mi355x-amd.sh
  └─ docker pull rocm/sgl-dev:v0.5.8.post1-rocm720-mi35x-20260218
  └─ docker run ... benchmarks/minimaxm2.5_fp8_mi355x_sglang.sh
      ↓
CONTAINER: Docker container on MI355X GPU
  ├─ Step 1: hf download MiniMaxAI/MiniMax-M2.5
  ├─ Step 2: python3 -m sglang.launch_server (background, port 8888)
  ├─ Step 3: wait_for_server_ready (polls /health endpoint)
  ├─ Step 4: run_benchmark_serving
  │   └─ utils/bench_serving/benchmark_serving.py
  │       ├─ Generate 160 random prompts (CONC × 10)
  │       ├─ Send async POST to http://localhost:8888/v1/chat/completions
  │       ├─ Stream responses, measure TTFT, TPOT, ITL, E2EL
  │       └─ Save: minimaxm2.5_fp8_tp4_conc16_mi355x.json
  └─ Step 5 (if RUN_EVAL=true): run_eval with lm-evaluation-harness
      ↓
PROCESS: utils/process_result.py
  └─ Load raw result, add metadata, save agg_*.json
      ↓
UPLOAD: GitHub artifact bmk_minimaxm2.5_fp8_tp4_conc16_mi355x.tar.gz
  ↓
... (9 other parallel jobs complete similarly) ...
  ↓
ALL JOBS: Complete
  ↓
JOB: collect-results
  ├─ Download all bmk_*.tar.gz artifacts
  ├─ utils/collect_results.py → agg_all.json (10 configs combined)
  └─ utils/summarize.py → markdown table
      ↓
JOB: collect-evals (if evaluations ran)
  ├─ Download all eval_*.tar.gz artifacts
  └─ utils/collect_eval_results.py → combined evaluation results
      ↓
JOB: trigger-vercel-deploy (if main branch)
  └─ Deploy results to https://inferencex.com/
      ↓
COMPLETE: Results visible on dashboard
```

## File Structure

```
InferenceMAX_rocm/
├── .github/
│   ├── workflows/
│   │   ├── run-sweep.yml              # Main orchestrator workflow
│   │   ├── benchmark-tmpl.yml         # Single-node benchmark template
│   │   ├── benchmark-multinode-tmpl.yml  # Multi-node (disaggregated) template
│   │   ├── collect-results.yml        # Result aggregation workflow
│   │   └── collect-evals.yml          # Evaluation aggregation workflow
│   └── configs/
│       ├── amd-master.yaml            # AMD hardware configurations
│       ├── nvidia-master.yaml         # NVIDIA hardware configurations
│       └── runners.yaml               # GitHub runner definitions
│
├── benchmarks/
│   ├── benchmark_lib.sh               # Shared utilities (wait_for_server, run_benchmark_serving, etc.)
│   ├── minimaxm2.5_fp8_mi355x_sglang.sh
│   ├── qwen3.5_bf16_mi355x_vllm.sh
│   └── ... (100+ model/hardware/framework combinations)
│
├── runners/
│   ├── launch_mi355x-amd.sh           # AMD MI355X docker runner
│   ├── launch_mi300x.sh               # AMD MI300X docker runner
│   ├── launch_h100.sh                 # NVIDIA H100 docker runner
│   └── launch_b200.sh                 # NVIDIA B200 docker runner
│
├── utils/
│   ├── process_changelog.py           # Parse changelog git diff
│   ├── process_result.py              # Per-job result processing
│   ├── collect_results.py             # Aggregate all benchmark results
│   ├── collect_eval_results.py        # Aggregate all evaluation results
│   ├── summarize.py                   # Generate markdown summary tables
│   ├── constants.py                   # Global constants and definitions
│   │
│   ├── bench_serving/
│   │   ├── benchmark_serving.py       # Main benchmark client
│   │   ├── backend_request_func.py    # Async request handlers (OpenAI, TGI, etc.)
│   │   └── benchmark_utils.py         # Helper functions
│   │
│   ├── matrix_logic/
│   │   ├── generate_sweep_configs.py  # Expand config into test matrix
│   │   └── validation.py              # Validate configurations
│   │
│   └── evals/
│       ├── gsm8k.yaml                 # GSM8K evaluation task config
│       └── gpqa_diamond.yaml          # GPQA Diamond evaluation task config
│
├── perf-changelog.yaml                # Trigger file for new benchmarks
└── README.md                          # This file
```

### Key File Descriptions

| File | Purpose | Key Functions/Sections |
|------|---------|----------------------|
| [perf-changelog.yaml](perf-changelog.yaml) | Triggers benchmarks when config-keys are added | `config-keys`: list of configs to run |
| [.github/workflows/run-sweep.yml](.github/workflows/run-sweep.yml) | Main orchestrator | Parses changelog, launches parallel jobs |
| [.github/configs/amd-master.yaml](.github/configs/amd-master.yaml) | AMD model/hardware configs | Defines image, model, framework, search-space |
| [utils/matrix_logic/generate_sweep_configs.py](utils/matrix_logic/generate_sweep_configs.py) | Expands configs into test matrix | Cartesian product of TP × concurrency × seq-len |
| [runners/launch_mi355x-amd.sh](runners/launch_mi355x-amd.sh) | Docker launcher for MI355X | `docker run` with GPU devices, mounts, env vars |
| [benchmarks/*.sh](benchmarks/) | Benchmark execution scripts | Start server, run client, optionally run eval |
| [benchmarks/benchmark_lib.sh](benchmarks/benchmark_lib.sh) | Shared utilities | `wait_for_server_ready`, `run_benchmark_serving`, `run_eval` |
| [utils/bench_serving/benchmark_serving.py](utils/bench_serving/benchmark_serving.py) | Benchmark client | Generate prompts, send requests, measure metrics |
| [utils/bench_serving/backend_request_func.py](utils/bench_serving/backend_request_func.py) | Request handlers | `async_request_openai_completions`, `async_request_tgi`, etc. |
| [utils/process_result.py](utils/process_result.py) | Result processing | Add metadata to raw benchmark JSON |
| [utils/collect_results.py](utils/collect_results.py) | Result aggregation | Combine all `agg_*.json` into `agg_all.json` |

## Configuration Guide

### Master Configuration Structure

File: [.github/configs/amd-master.yaml](.github/configs/amd-master.yaml)

```yaml
<config-key>:
  # Docker image with framework pre-installed
  image: <docker-registry>/<image-name>:<tag>

  # HuggingFace model identifier
  model: <organization>/<model-name>

  # Short name for result files
  model-prefix: <shortname>

  # Hardware type (must match runners.yaml)
  runner: <mi355x|mi300x|h100|b200|etc>

  # Precision mode
  precision: <fp4|fp8|bf16|int4>

  # Inference framework
  framework: <vllm|sglang|atom>

  # Sequence length configurations (creates separate sweep jobs)
  seq-len-configs:
    - isl: 1024                      # Input sequence length
      osl: 1024                      # Output sequence length
      search-space:
        - tp: [1, 2, 4, 8]           # Tensor parallelism values
          conc-start: 4              # Minimum concurrency
          conc-end: 64               # Maximum concurrency
          spec-decoding: [none, mtp] # Speculative decoding modes

    - isl: 8192                      # Different sequence length
      osl: 1024
      search-space:
        - tp: [4, 8]
          ep: [1, 8]                 # Expert parallelism (MoE models)
          conc-start: 4
          conc-end: 128

  # Optional: Multi-node disaggregated configuration
  multi-node-configs:
    - prefill-tp: [4, 8]
      prefill-ep: [1]
      decode-tp: [2, 4]
      decode-num-worker: [2, 4]
      dp-attn: [true, false]         # Distributed attention
      additional-prefill-settings: “--enable-chunked-prefill”
      additional-decode-settings: “--gpu-memory-utilization 0.9”
```

### Example Configuration: Llama 3.3 70B

```yaml
llama3.3-70b-fp8-mi355x-vllm:
  image: rocm/vllm-dev:v0.6.5-rocm620-mi35x-20260201
  model: meta-llama/Llama-3.3-70B-Instruct
  model-prefix: llama3.3-70b
  runner: mi355x
  precision: fp8
  framework: vllm
  seq-len-configs:
    - isl: 1024
      osl: 1024
      search-space:
        - tp: [4, 8]
          conc-start: 4
          conc-end: 128
    - isl: 8192
      osl: 1024
      search-space:
        - tp: [8]
          conc-start: 4
          conc-end: 64
```

### Configuration Parameters Reference

| Parameter | Values | Description |
|-----------|--------|-------------|
| **Hardware** |||
| `runner` | `mi355x`, `mi300x`, `h100`, `b200` | GPU hardware type |
| **Framework** |||
| `framework` | `vllm`, `sglang`, `atom` | Inference framework |
| **Precision** |||
| `precision` | `fp4`, `fp8`, `bf16`, `int4` | Model/KV-cache precision |
| **Parallelism** |||
| `tp` | `[1, 2, 4, 8, 16]` | Tensor parallelism (split model across GPUs) |
| `ep` | `[1, 8, 16]` | Expert parallelism (for MoE models) |
| **Workload** |||
| `isl` | `1024`, `8192`, etc. | Input sequence length (tokens) |
| `osl` | `1024`, `8192`, etc. | Output sequence length (tokens) |
| `conc` | `4`, `8`, `16`, `32`, `64`, `128`, `256` | Concurrent requests |
| **Optimization** |||
| `spec-decoding` | `none`, `mtp` | Speculative decoding mode |
| `dp-attn` | `true`, `false` | Distributed attention (multi-node) |

## Metrics Collected

### Latency Metrics

| Metric | Description | Unit | Formula | Target |
|--------|-------------|------|---------|--------|
| **TTFT** | Time To First Token - Prefill latency | ms | `first_token_time - request_start_time` | < 100ms |
| **TPOT** | Time Per Output Token - Decode latency | ms | `(request_end_time - first_token_time) / num_output_tokens` | < 20ms |
| **ITL** | Inter-Token Latency - Token-to-token time | ms | `token_timestamps[i+1] - token_timestamps[i]` | Low variance |
| **E2EL** | End-to-End Latency - Total request time | ms | `request_end_time - request_start_time` | Varies by OSL |

### Throughput Metrics

| Metric | Description | Unit | Formula | Target |
|--------|-------------|------|---------|--------|
| **Request Throughput** | Completed requests per second | req/s | `total_requests / total_duration` | > 10 req/s |
| **Output Throughput** | Output tokens generated per second | tok/s | `total_output_tokens / total_duration` | > 1000 tok/s |
| **Total Token Throughput** | All tokens (input + output) per second | tok/s | `(total_input_tokens + total_output_tokens) / total_duration` | > 5000 tok/s |

### Evaluation Metrics (Optional)

| Task | Metric | Description | Target |
|------|--------|-------------|--------|
| **GSM8K** | Accuracy (Exact Match) | Grade school math reasoning | > 80% |
| **GPQA Diamond** | Accuracy | Graduate-level science questions | > 40% |

### Result JSON Schema

```json
{
  // Metadata
  “hardware”: “mi355x”,
  “framework”: “sglang”,
  “precision”: “fp8”,
  “model”: “MiniMaxAI/MiniMax-M2.5”,
  “model_prefix”: “minimaxm2.5”,

  // Configuration
  “tp”: 4,
  “ep”: 1,
  “conc”: 16,
  “isl”: 1024,
  “osl”: 1024,
  “spec_decoding”: “none”,

  // Throughput
  “request_throughput”: 12.5,
  “output_throughput”: 1250.0,
  “total_token_throughput”: 5000.0,

  // TTFT (Time To First Token)
  “mean_ttft_ms”: 45.2,
  “median_ttft_ms”: 42.1,
  “p99_ttft_ms”: 89.5,
  “std_ttft_ms”: 12.3,

  // TPOT (Time Per Output Token)
  “mean_tpot_ms”: 12.3,
  “median_tpot_ms”: 11.8,
  “p99_tpot_ms”: 18.2,
  “std_tpot_ms”: 2.1,

  // E2EL (End-to-End Latency)
  “mean_e2el_ms”: 1280.5,
  “median_e2el_ms”: 1240.2,
  “p99_e2el_ms”: 1650.8,
  “std_e2el_ms”: 145.3,

  // ITL (Inter-Token Latency)
  “mean_itl_ms”: 11.9,
  “median_itl_ms”: 11.5,
  “p99_itl_ms”: 17.8,

  // Metadata
  “timestamp”: “2026-02-24T10:30:00Z”,
  “duration_s”: 120.5,
  “num_prompts”: 160,
  “total_input_tokens”: 163840,
  “total_output_tokens”: 163840
}
```

## Adding New Benchmarks

### 1. Quick Start: Benchmark Existing Configuration

If the model configuration already exists in [.github/configs/amd-master.yaml](.github/configs/amd-master.yaml):

```yaml
# Add to perf-changelog.yaml
- date: 2026-02-24
  description: “Benchmark existing config”
  config-keys:
    - qwen3.5-bf16-mi355x-vllm  # Already defined in amd-master.yaml
```

Then commit and push:
```bash
git add perf-changelog.yaml
git commit -m “Run Qwen3.5 benchmark”
git push origin main_rocm
```

### 2. Adding a New Model Configuration

#### Step 1: Add to Master Config

Edit [.github/configs/amd-master.yaml](.github/configs/amd-master.yaml):

```yaml
# Example: New Llama model
llama3.3-70b-fp8-mi355x-vllm:
  image: rocm/vllm-dev:v0.6.5-rocm620-mi35x-20260201
  model: meta-llama/Llama-3.3-70B-Instruct
  model-prefix: llama3.3-70b
  runner: mi355x
  precision: fp8
  framework: vllm
  seq-len-configs:
    - isl: 1024
      osl: 1024
      search-space:
        - tp: [4, 8]
          conc-start: 4
          conc-end: 128
```

#### Step 2: Create Benchmark Script

Create `benchmarks/llama3.3-70b_fp8_mi355x_vllm.sh`:

```bash
#!/usr/bin/env bash

# Source shared utilities
source “$(dirname “$0”)/benchmark_lib.sh”

# Validate required environment variables
check_env_vars \
    MODEL \
    TP \
    CONC \
    ISL \
    OSL \
    MAX_MODEL_LEN \
    RANDOM_RANGE_RATIO \
    RESULT_FILENAME

# Download model from HuggingFace
hf download “$MODEL”

# Set GPU visibility for AMD
if [ -n “$ROCR_VISIBLE_DEVICES” ]; then
    export HIP_VISIBLE_DEVICES=”$ROCR_VISIBLE_DEVICES”
fi

# Server configuration
SERVER_LOG=/workspace/server.log
PORT=${PORT:-8888}
MEM_UTIL=${MEM_UTIL:-0.9}

# Start vLLM server
set -x
python3 -m vllm.entrypoints.openai.api_server \
    --model $MODEL \
    --host 0.0.0.0 \
    --port $PORT \
    --tensor-parallel-size $TP \
    --trust-remote-code \
    --kv-cache-dtype fp8 \
    --gpu-memory-utilization $MEM_UTIL \
    --max-model-len $MAX_MODEL_LEN > $SERVER_LOG 2>&1 &

SERVER_PID=$!

# Wait for server readiness
wait_for_server_ready --port “$PORT” --server-log “$SERVER_LOG” --server-pid “$SERVER_PID”

# Run benchmark client
export PYTHONDONTWRITEBYTECODE=1
run_benchmark_serving \
    --model “$MODEL” \
    --port “$PORT” \
    --backend vllm \
    --input-len “$ISL” \
    --output-len “$OSL” \
    --random-range-ratio “$RANDOM_RANGE_RATIO” \
    --num-prompts “$((CONC * 10))” \
    --max-concurrency “$CONC” \
    --result-filename “$RESULT_FILENAME” \
    --result-dir /workspace/ \
    --trust-remote-code

# Optional: Run evaluation
if [ “${RUN_EVAL}” = “true” ]; then
    run_eval --framework lm-eval --port “$PORT” --concurrent-requests $CONC
    append_lm_eval_summary
fi
set +x
```

#### Step 3: Make Script Executable

```bash
chmod +x benchmarks/llama3.3-70b_fp8_mi355x_vllm.sh
```

#### Step 4: Trigger Benchmark

```yaml
# Add to perf-changelog.yaml
- date: 2026-02-24
  description: “Benchmark Llama 3.3 70B FP8 on MI355X”
  config-keys:
    - llama3.3-70b-fp8-mi355x-vllm
```

### 3. Framework-Specific Server Commands

#### vLLM
```bash
python3 -m vllm.entrypoints.openai.api_server \
    --model $MODEL \
    --host 0.0.0.0 \
    --port $PORT \
    --tensor-parallel-size $TP \
    --trust-remote-code \
    --kv-cache-dtype fp8 \
    --gpu-memory-utilization 0.9 \
    --max-model-len $MAX_MODEL_LEN
```

#### SGLang
```bash
python3 -m sglang.launch_server \
    --attention-backend triton \
    --model-path $MODEL \
    --host 0.0.0.0 \
    --port $PORT \
    --tensor-parallel-size $TP \
    --trust-remote-code \
    --mem-fraction-static 0.8 \
    --kv-cache-dtype fp8_e4m3 \
    --max-model-len $MAX_MODEL_LEN
```

#### ATOM (Multi-node Disaggregated)
```bash
# Prefill worker
python3 -m atom.launch_server \
    --prefill-only \
    --model-path $MODEL \
    --tensor-parallel-size $PREFILL_TP \
    --expert-parallel-size $PREFILL_EP \
    --distributed-attention $DP_ATTN \
    --port $PREFILL_PORT

# Decode worker(s)
python3 -m atom.launch_server \
    --decode-only \
    --model-path $MODEL \
    --tensor-parallel-size $DECODE_TP \
    --num-decode-workers $DECODE_NUM_WORKER \
    --prefill-url http://prefill-host:$PREFILL_PORT \
    --port $DECODE_PORT
```

## Troubleshooting

### Common Issues

#### 1. Server Fails to Start

**Symptoms**: Benchmark times out waiting for server health check

**Diagnosis**:
```bash
# Check server log
cat /workspace/server.log

# Common error patterns:
# - “OutOfMemoryError”: GPU memory exhausted
# - “ModuleNotFoundError”: Missing Python dependencies
# - “Address already in use”: Port conflict
# - “No such file or directory”: Model not downloaded
```

**Solutions**:
```bash
# Out of memory:
# Option A: Reduce MAX_MODEL_LEN
export MAX_MODEL_LEN=16384  # Instead of 32768

# Option B: Increase tensor parallelism
export TP=8  # Instead of 4

# Option C: Reduce memory fraction
export MEM_UTIL=0.8  # Instead of 0.9

# Port conflict:
export PORT=8889  # Use different port

# Model download issues:
# Check HuggingFace token
echo $HF_TOKEN
# Manually download
hf download meta-llama/Llama-3.3-70B-Instruct
```

#### 2. Benchmark Client Fails

**Symptoms**: Client crashes or reports connection errors

**Diagnosis**:
```bash
# Test server health endpoint
curl http://localhost:8888/health

# Test API endpoint
curl -X POST http://localhost:8888/v1/chat/completions \
  -H “Content-Type: application/json” \
  -d ‘{
    “model”: “meta-llama/Llama-3.3-70B-Instruct”,
    “messages”: [{“role”: “user”, “content”: “Hello”}],
    “max_tokens”: 10
  }’
```

**Solutions**:
```bash
# Server not ready:
# Increase wait timeout in benchmark_lib.sh
TIMEOUT=600  # 10 minutes instead of default

# Wrong backend:
# Ensure --backend matches framework
run_benchmark_serving --backend vllm  # For vLLM
run_benchmark_serving --backend vllm  # SGLang uses vLLM-compatible API

# API version mismatch:
# Check server logs for actual endpoint
grep “Uvicorn running” /workspace/server.log
```

#### 3. Low Throughput

**Symptoms**: Output throughput << expected tokens/second

**Diagnosis**:
```bash
# Check GPU utilization
rocm-smi  # AMD GPUs
nvidia-smi  # NVIDIA GPUs

# Expected: 90-100% GPU utilization
# If low (<50%):
#  - Client concurrency too low
#  - Server batching inefficient
#  - Bottleneck elsewhere (CPU, memory, network)
```

**Optimizations**:
```bash
# 1. Increase concurrency
export CONC=64  # Instead of 16
# Rule of thumb: Start at 4, double until throughput plateaus

# 2. Increase tensor parallelism (for large models)
export TP=8  # Instead of 4
# Trade-off: Higher TP = more GPUs used, better throughput, higher latency

# 3. Enable FP8 KV cache
--kv-cache-dtype fp8  # vLLM
--kv-cache-dtype fp8_e4m3  # SGLang

# 4. Adjust memory allocation
--gpu-memory-utilization 0.95  # More aggressive (vLLM)
--mem-fraction-static 0.9  # More aggressive (SGLang)

# 5. Enable chunked prefill (vLLM 0.6+)
--enable-chunked-prefill

# 6. Speculative decoding (if supported)
export SPEC_DECODING=mtp
```

#### 4. GitHub Workflow Fails

**Symptoms**: Workflow fails in GitHub Actions UI

**Common Errors**:

```yaml
# Error: “Config key not found”
# Cause: Typo in config-key or not defined in amd-master.yaml
# Solution: Verify key exists in .github/configs/amd-master.yaml

# Error: “Invalid YAML syntax”
# Cause: perf-changelog.yaml formatting error
# Solution: Validate YAML (yamllint, online validator)

# Error: “Runner offline”
# Cause: GitHub runner unavailable
# Solution: Check .github/configs/runners.yaml, ensure runner online

# Error: “Docker pull failed”
# Cause: Image doesn’t exist or authentication issue
# Solution: Verify image name, check registry credentials

# Error: “Permission denied”
# Cause: Benchmark script not executable
# Solution: chmod +x benchmarks/*.sh
```

### Debug Mode

Enable verbose logging:

```bash
# In benchmark script, add:
set -x  # Print all commands
export DEBUG=1
export VERBOSE=1

# In benchmark_serving.py, add:
--verbose  # Enable detailed logging

# In server launch:
--log-level debug  # More detailed server logs
```

### Performance Optimization Checklist

#### Hardware Selection
- **MI355X**: Best for 70B+ models (192GB HBM3e, high bandwidth)
- **MI300X**: Balanced (192GB HBM3)
- **H100**: Strong for 70B models (80GB HBM3)
- **B200**: Highest throughput (192GB HBM3e)

#### Parallelism Tuning
| Model Size | Recommended TP | Recommended EP | Recommended Concurrency |
|------------|---------------|---------------|------------------------|
| < 10B | 1 | 1 | 4-16 |
| 10-30B | 1-2 | 1 | 8-32 |
| 30-70B | 2-4 | 1 | 16-64 |
| 70B+ | 4-8 | 1 | 32-128 |
| MoE (Mixtral) | 2-4 | 8 | 16-64 |

#### Precision Selection
| Precision | Memory Usage | Quality Loss | Throughput Gain | Best For |
|-----------|-------------|--------------|----------------|----------|
| BF16 | Baseline | None | 1x | Quality baseline |
| FP8 | 0.5x | Minimal (<1% perplexity) | 1.8-2.2x | Production (recommended) |
| FP4 | 0.25x | Moderate (2-5% perplexity) | 2.5-3.5x | High throughput needs |
| INT4 | 0.25x | Variable | 2.0-3.0x | Experimental |

#### Memory Optimization
```bash
# vLLM
--gpu-memory-utilization 0.9  # Reserve 90% for KV cache
--max-model-len 32768         # Limit sequence length
--kv-cache-dtype fp8          # Compress KV cache
--enable-chunked-prefill      # Better memory efficiency

# SGLang
--mem-fraction-static 0.8     # Reserve 80% for KV cache
--max-model-len 32768
--kv-cache-dtype fp8_e4m3
--attention-backend triton    # Optimized attention kernels
```

### Contact & Support

For issues specific to this repository:
- **GitHub Issues**: [Open an issue](../../issues)
- **Maintainers**: @Rohan138, @ajith-sirra-amd, @seungrokj

For upstream InferenceX issues:
- **Official Repo**: [SemiAnalysisAI/InferenceX](https://github.com/SemiAnalysisAI/InferenceX)

---

**Documentation Version**: 1.0
**Last Updated**: 2026-02-24

