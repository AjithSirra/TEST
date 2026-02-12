# InferenceMAX Local Testing Configuration

This folder contains all the configuration files needed to run GPTOSS benchmarks on your local MI300X server (10.23.45.34) using GitHub Actions.

## Contents

- `runners/` - Runner launch scripts for your local server
- `configs/` - Configuration files for benchmarks
- `workflows/` - GitHub Actions workflow files
- `perf-changelog-examples/` - Example perf changelog entries
- `scripts/` - Helper scripts for running benchmarks

## Quick Start

### 1. Setup Self-Hosted Runner

Follow the instructions in `docs/SETUP_RUNNER.md`

### 2. Update Repository Configuration

Copy files to the main repository:

```bash
# Copy runner script
cp test/runners/launch_mi300x-local.sh ../runners/

# Copy workflow (optional)
cp test/workflows/test-local-mi300x.yml ../.github/workflows/

# Add runner to runners.yaml
# Follow instructions in test/configs/runners-update.yaml
```

### 3. Trigger Benchmarks

See `docs/TRIGGER_BENCHMARKS.md` for various methods to run benchmarks.

## File Structure

```
test/
├── README.md                           # This file
├── docs/
│   ├── SETUP_RUNNER.md                # Self-hosted runner setup guide
│   ├── TRIGGER_BENCHMARKS.md          # How to trigger benchmarks
│   └── TROUBLESHOOTING.md             # Common issues and solutions
├── runners/
│   └── launch_mi300x-local.sh         # Launch script for local MI300X
├── configs/
│   ├── runners-update.yaml            # Update to add to main runners.yaml
│   └── local-mi300x-config.yaml       # Local server configuration
├── workflows/
│   └── test-local-mi300x.yml          # Custom workflow for local testing
├── perf-changelog-examples/
│   ├── gptoss-fp4-full.yaml           # Full sweep example
│   ├── gptoss-fp4-quick.yaml          # Quick test example
│   └── gptoss-fp4-specific.yaml       # Specific configuration example
└── scripts/
    ├── run_local_benchmark.sh         # Single benchmark runner
    ├── run_sweep.sh                   # Full sweep runner
    └── setup_environment.sh           # Environment setup script
```
