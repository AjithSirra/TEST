#!/bin/bash

# Environment setup script for local MI300X server
# Run this once on your server to prepare the environment

set -e

echo "================================"
echo "InferenceMAX Environment Setup"
echo "================================"

# Check if running on server
echo ""
echo "Server Information:"
echo "  Hostname: $(hostname)"
echo "  IP: $(hostname -I | awk '{print $1}')"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

# Check Docker
echo "Checking Docker..."
if command -v docker >/dev/null 2>&1; then
    echo "  ✓ Docker installed: $(docker --version)"

    # Check Docker permissions
    if docker ps >/dev/null 2>&1; then
        echo "  ✓ Docker permissions OK"
    else
        echo "  ⚠ Docker permissions issue - adding user to docker group"
        sudo usermod -aG docker $USER
        echo "  → Please log out and log back in for group changes to take effect"
    fi
else
    echo "  ✗ Docker not found - please install Docker"
    exit 1
fi

# Check ROCm
echo ""
echo "Checking ROCm..."
if command -v rocm-smi >/dev/null 2>&1; then
    echo "  ✓ ROCm installed"
    rocm-smi --showproductname 2>/dev/null || echo "  → Could not query GPUs"
else
    echo "  ⚠ ROCm not found - may need to install ROCm drivers"
fi

# Check Git
echo ""
echo "Checking Git..."
if command -v git >/dev/null 2>&1; then
    echo "  ✓ Git installed: $(git --version)"
else
    echo "  ⚠ Git not found - installing..."
    sudo apt-get update && sudo apt-get install -y git
fi

# Setup HuggingFace cache directory
echo ""
echo "Setting up HuggingFace cache..."
HF_CACHE="/data/hf_hub_cache"
if [ ! -d "$HF_CACHE" ]; then
    echo "  → Creating cache directory: $HF_CACHE"
    sudo mkdir -p "$HF_CACHE"
    sudo chown -R $USER:$USER "$HF_CACHE"
    sudo chmod -R 755 "$HF_CACHE"
else
    echo "  ✓ Cache directory exists: $HF_CACHE"
fi

# Check HuggingFace token
echo ""
echo "Checking HuggingFace token..."
if [ -n "$HF_TOKEN" ]; then
    echo "  ✓ HF_TOKEN is set"
else
    echo "  ⚠ HF_TOKEN not set"
    echo "  → Please set it: export HF_TOKEN=hf_xxxxxxxxxxxx"
    echo "  → Add to ~/.bashrc for persistence"
fi

# Check GitHub Actions runner
echo ""
echo "Checking GitHub Actions runner..."
if [ -d "$HOME/actions-runner" ]; then
    echo "  ✓ Runner directory exists"

    if [ -f "$HOME/actions-runner/.runner" ]; then
        echo "  ✓ Runner configured"
        RUNNER_NAME=$(grep -oP '(?<="name": ")[^"]*' "$HOME/actions-runner/.runner" 2>/dev/null || echo "unknown")
        echo "    Name: $RUNNER_NAME"
    else
        echo "  ⚠ Runner not configured yet"
        echo "  → Run ./config.sh in ~/actions-runner"
    fi

    if sudo systemctl is-active --quiet actions.runner.* 2>/dev/null; then
        echo "  ✓ Runner service is running"
    else
        echo "  ⚠ Runner service not active"
        echo "  → Run: cd ~/actions-runner && sudo ./svc.sh start"
    fi
else
    echo "  ⚠ Runner not installed"
    echo "  → See test/docs/SETUP_RUNNER.md for installation instructions"
fi

# Clone repository if not exists
echo ""
echo "Checking InferenceMAX repository..."
REPO_DIR="$HOME/InferenceMAX"
if [ -d "$REPO_DIR" ]; then
    echo "  ✓ Repository exists at: $REPO_DIR"

    cd "$REPO_DIR"
    CURRENT_BRANCH=$(git branch --show-current)
    echo "    Branch: $CURRENT_BRANCH"

    # Check for uncommitted changes
    if git diff-index --quiet HEAD --; then
        echo "    Status: Clean"
    else
        echo "    Status: Uncommitted changes"
    fi
else
    echo "  ⚠ Repository not found"
    read -p "  → Clone InferenceMAX repository to $REPO_DIR? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git clone https://github.com/InferenceMAX/InferenceMAX.git "$REPO_DIR"
        echo "  ✓ Repository cloned"
    fi
fi

echo ""
echo "================================"
echo "Setup Summary"
echo "================================"
echo ""
echo "Next steps:"
echo "1. If Docker permissions changed, log out and back in"
echo "2. Set HF_TOKEN if not already set"
echo "3. Install GitHub Actions runner if needed (see test/docs/SETUP_RUNNER.md)"
echo "4. Copy test files to repository:"
echo "   cd $REPO_DIR"
echo "   cp test/runners/launch_mi300x-local.sh runners/"
echo "5. Update .github/configs/runners.yaml with your runner"
echo ""
echo "Ready to run benchmarks!"
echo "================================"
