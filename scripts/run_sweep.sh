#!/bin/bash

# GPTOSS FP4 Full Sweep Runner for Local MI300X
# Runs multiple TP and concurrency configurations

set -e

# Export HF_TOKEN if not already set
if [ -z "$HF_TOKEN" ]; then
    echo "ERROR: Please export HF_TOKEN before running"
    echo "Example: export HF_TOKEN=hf_xxxxxxxxxxxx"
    exit 1
fi

# Configuration arrays based on amd-master.yaml lines 139-168
declare -a TP_VALUES=(1 2 4 8)
declare -a CONC_VALUES_TP1=(64)
declare -a CONC_VALUES_TP2=(4 8 16 32 64)
declare -a CONC_VALUES_TP4=(4 8 16 32 64)
declare -a CONC_VALUES_TP8=(4 8 16)

# Sequence length configurations
SEQUENCE_CONFIGS=(
    "1024:1024"
    "1024:8192"
    "8192:1024"
)

echo "Starting GPTOSS FP4 Benchmark Sweep on MI300X"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to repo root (assuming script is in test/scripts/)
cd "$SCRIPT_DIR/../.."

TOTAL_RUNS=0

# Count total runs
for SEQ in "${SEQUENCE_CONFIGS[@]}"; do
    IFS=':' read -r ISL OSL <<< "$SEQ"

    for TP in "${TP_VALUES[@]}"; do
        case $TP in
            1)
                CONC_VALUES=("${CONC_VALUES_TP1[@]}")
                ;;
            2)
                CONC_VALUES=("${CONC_VALUES_TP2[@]}")
                ;;
            4)
                CONC_VALUES=("${CONC_VALUES_TP4[@]}")
                ;;
            8)
                CONC_VALUES=("${CONC_VALUES_TP8[@]}")
                ;;
        esac

        TOTAL_RUNS=$((TOTAL_RUNS + ${#CONC_VALUES[@]}))
    done
done

echo "Total benchmark runs: $TOTAL_RUNS"
echo ""

CURRENT_RUN=0

# Run benchmarks
for SEQ in "${SEQUENCE_CONFIGS[@]}"; do
    IFS=':' read -r ISL OSL <<< "$SEQ"

    echo ""
    echo "=============================================="
    echo "Sequence Length: ISL=$ISL, OSL=$OSL"
    echo "=============================================="

    for TP in "${TP_VALUES[@]}"; do
        case $TP in
            1)
                CONC_VALUES=("${CONC_VALUES_TP1[@]}")
                ;;
            2)
                CONC_VALUES=("${CONC_VALUES_TP2[@]}")
                ;;
            4)
                CONC_VALUES=("${CONC_VALUES_TP4[@]}")
                ;;
            8)
                CONC_VALUES=("${CONC_VALUES_TP8[@]}")
                ;;
        esac

        echo ""
        echo "Running TP=$TP configurations..."

        for CONC in "${CONC_VALUES[@]}"; do
            CURRENT_RUN=$((CURRENT_RUN + 1))
            export TP=$TP
            export CONC=$CONC
            export ISL=$ISL
            export OSL=$OSL

            echo ""
            echo "[$CURRENT_RUN/$TOTAL_RUNS] TP=$TP, CONC=$CONC, ISL=$ISL, OSL=$OSL"

            # Run the benchmark
            bash test/scripts/run_local_benchmark.sh

            # Wait a bit between runs
            sleep 5
        done
    done
done

echo ""
echo "=============================================="
echo "Sweep complete!"
echo "Results saved to: *.json files"
echo "=============================================="

# Create summary if jq is available
if command -v jq >/dev/null 2>&1; then
    echo ""
    echo "Creating summary..."

    echo "Configuration,Throughput,TTFT_P50,TPOT_P50,E2EL_P50" > sweep_summary.csv

    for f in gptoss_fp4_vllm_*.json; do
        if [ -f "$f" ]; then
            CONFIG=$(basename "$f" .json)
            THROUGHPUT=$(jq -r '.throughput // "N/A"' "$f")
            TTFT_P50=$(jq -r '.ttft.p50 // "N/A"' "$f")
            TPOT_P50=$(jq -r '.tpot.p50 // "N/A"' "$f")
            E2EL_P50=$(jq -r '.e2el.p50 // "N/A"' "$f")

            echo "$CONFIG,$THROUGHPUT,$TTFT_P50,$TPOT_P50,$E2EL_P50" >> sweep_summary.csv
        fi
    done

    echo "Summary saved to: sweep_summary.csv"
fi
