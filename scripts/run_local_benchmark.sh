#!/bin/bash

# Single GPTOSS FP4 Benchmark Runner for Local MI300X
# This script runs a single benchmark configuration locally (not via GitHub Actions)

set -e

# ========================
# CONFIGURATION PARAMETERS
# ========================

# Model Configuration (from amd-master.yaml line 139-168)
export IMAGE="vllm/vllm-openai-rocm:v0.14.0"
export MODEL="openai/gpt-oss-120b"
export MODEL_PREFIX="gptoss"
export EXP_NAME="gptoss"
export PRECISION="fp4"
export FRAMEWORK="vllm"

# Hardware Configuration
export RUNNER_TYPE="mi300x"
export TP="${TP:-8}"  # Tensor Parallelism (1, 2, 4, or 8)

# Workload Configuration
export ISL="${ISL:-1024}"  # Input Sequence Length
export OSL="${OSL:-1024}"  # Output Sequence Length
export CONC="${CONC:-16}"  # Concurrency
export MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
export RANDOM_RANGE_RATIO="${RANDOM_RANGE_RATIO:-0.8}"

# Expert Parallelism & Data Parallel Attention (not used for GPTOSS)
export EP_SIZE=1
export DP_ATTENTION=false

# Speculative Decoding & Disaggregation (not used for GPTOSS)
export SPEC_DECODING="none"
export DISAGG="false"

# Evaluation
export RUN_EVAL="${RUN_EVAL:-false}"  # Set to "true" to run accuracy evals

# HuggingFace Configuration
export HF_TOKEN="${HF_TOKEN:-}"
export HF_HUB_CACHE="${HF_HUB_CACHE:-/data/hf_hub_cache/}"

# Result Configuration
export RESULT_FILENAME="${EXP_NAME}_${PRECISION}_${FRAMEWORK}_tp${TP}_ep${EP_SIZE}_dpa_${DP_ATTENTION}_conc${CONC}_mi300x-local"

# Workspace (current directory)
export GITHUB_WORKSPACE=$(pwd)

# Port
export PORT=8888

# ========================
# VALIDATION
# ========================

if [ -z "$HF_TOKEN" ]; then
    echo "ERROR: Please set HF_TOKEN environment variable"
    echo "Example: export HF_TOKEN=hf_xxxxxxxxxxxx"
    exit 1
fi

if [ ! -d "$HF_HUB_CACHE" ]; then
    echo "Creating HF cache directory: $HF_HUB_CACHE"
    sudo mkdir -p "$HF_HUB_CACHE"
    sudo chmod 777 "$HF_HUB_CACHE"
fi

# ========================
# PRINT CONFIGURATION
# ========================

echo "================================"
echo "InferenceMAX GPTOSS Benchmark"
echo "================================"
echo "Server: $(hostname)"
echo "Model: $MODEL"
echo "Framework: $FRAMEWORK"
echo "Precision: $PRECISION"
echo "TP: $TP | Concurrency: $CONC"
echo "ISL: $ISL | OSL: $OSL"
echo "Result: $RESULT_FILENAME.json"
echo "================================"

# ========================
# RUN BENCHMARK
# ========================

# Check if we're in the repo root
if [ ! -f "benchmarks/benchmark_lib.sh" ]; then
    echo "ERROR: Must run from InferenceMAX repository root"
    exit 1
fi

# Run the benchmark using the benchmark script
bash benchmarks/gptoss_fp4_mi300x.sh

echo ""
echo "Benchmark complete!"
echo "Results saved to: $GITHUB_WORKSPACE/$RESULT_FILENAME.json"

# Display summary if jq is available
if command -v jq >/dev/null 2>&1; then
    echo ""
    echo "================================"
    echo "SUMMARY"
    echo "================================"
    jq '{
        throughput: .throughput,
        ttft_p50: .ttft.p50,
        tpot_p50: .tpot.p50,
        e2el_p50: .e2el.p50
    }' "$RESULT_FILENAME.json" 2>/dev/null || echo "Could not parse results"
fi
