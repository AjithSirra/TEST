# Setting Up GitHub Actions Self-Hosted Runner

This guide walks you through setting up your MI300X server (10.23.45.34) as a GitHub Actions self-hosted runner.

## Prerequisites

- Server with 8x MI300 GPUs at 10.23.45.34
- SSH access to the server
- Docker with ROCm support installed
- GitHub repository admin access

## Step 1: Connect to Your Server

```bash
ssh user@10.23.45.34
```

## Step 2: Install Prerequisites

```bash
# Update system
sudo apt-get update

# Install required packages
sudo apt-get install -y curl git jq

# Verify Docker is installed and accessible
docker --version
docker ps

# If Docker permission error, add user to docker group
sudo usermod -aG docker $USER
# Then log out and log back in
```

## Step 3: Download GitHub Actions Runner

```bash
# Create a folder for the runner
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download the latest runner package (check GitHub for latest version)
RUNNER_VERSION="2.321.0"
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
  -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
```

## Step 4: Get Runner Registration Token

On your **local machine**, navigate to your GitHub repository:

1. Go to: `Settings` → `Actions` → `Runners`
2. Click: **"New self-hosted runner"**
3. Select: **Linux** as the OS
4. Copy the **registration token** (starts with `A...`)

## Step 5: Configure the Runner

Back on your **server**:

```bash
cd ~/actions-runner

# Configure the runner
./config.sh \
  --url https://github.com/YOUR_ORG/InferenceMAX \
  --token YOUR_REGISTRATION_TOKEN_HERE \
  --name mi300x-local_0 \
  --labels mi300x-local_0,mi300x \
  --work _work \
  --replace
```

**Important:**
- Replace `YOUR_ORG/InferenceMAX` with your actual repo path
- Replace `YOUR_REGISTRATION_TOKEN_HERE` with the token from Step 4
- The `--name mi300x-local_0` must match what's in `runners.yaml`
- The `--labels mi300x-local_0,mi300x` allows the runner to pick up `mi300x` jobs

You'll be prompted with:
- **Enter the name of the runner group**: Press Enter (uses default)
- **Enter any additional labels**: Press Enter (we already set labels)
- **Enter name of work folder**: Press Enter (uses `_work`)

## Step 6: Install Runner as a Service

```bash
cd ~/actions-runner

# Install the service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

Expected output:
```
● actions.runner.YOUR_ORG-InferenceMAX.mi300x-local_0.service - GitHub Actions Runner (YOUR_ORG-InferenceMAX.mi300x-local_0)
   Loaded: loaded
   Active: active (running)
```

## Step 7: Verify Runner is Online

On your **local machine**, check GitHub:

1. Go to: `Settings` → `Actions` → `Runners`
2. You should see **mi300x-local_0** with:
   - Status: **Idle** (green dot)
   - Labels: `self-hosted`, `Linux`, `X64`, `mi300x-local_0`, `mi300x`

## Step 8: Configure GitHub Secrets

Your runner needs access to secrets:

1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Click: **"New repository secret"**
3. Add these secrets:

   - **Name:** `HF_TOKEN`
     **Value:** Your HuggingFace token (e.g., `hf_xxxxxxxxxxxx`)

   - **Name:** `REPO_PAT`
     **Value:** GitHub Personal Access Token (for checkout)

To create a GitHub PAT:
- Go to: GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
- Click: Generate new token (classic)
- Select scopes: `repo` (all), `workflow`
- Copy the token

## Step 9: Test the Runner

Create a simple test workflow to verify the runner works:

```bash
# On your local machine, in the InferenceMAX repo
cat > .github/workflows/test-runner.yml <<'EOF'
name: Test Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: mi300x-local_0
    steps:
      - name: Test runner
        run: |
          echo "Runner is working!"
          hostname
          docker --version
          rocm-smi --showproductname || echo "ROCm check"
EOF

git add .github/workflows/test-runner.yml
git commit -m "Add runner test workflow"
git push
```

Then:
1. Go to: `Actions` → `Test Runner`
2. Click: **"Run workflow"**
3. Watch the job execute on your runner

## Step 10: Update Repository Configuration

Now that the runner is working, update the repository:

```bash
# On your local machine, in the InferenceMAX repo

# 1. Update runners.yaml
# Edit .github/configs/runners.yaml and add 'mi300x-local_0' to the mi300x list

# 2. Copy runner launch script
cp test/runners/launch_mi300x-local.sh runners/

# 3. Make it executable
chmod +x runners/launch_mi300x-local.sh

# 4. Commit changes
git add .github/configs/runners.yaml runners/launch_mi300x-local.sh
git commit -m "Add mi300x-local_0 runner configuration"
git push
```

## Troubleshooting

### Runner Not Showing Up

```bash
# On server, check runner status
cd ~/actions-runner
sudo ./svc.sh status

# Check logs
journalctl -u actions.runner.* -f
```

### Runner Offline

```bash
# Restart the service
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Docker Permission Errors

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
exit
ssh user@10.23.45.34

# Verify
docker ps
```

### Runner Taking Jobs but Failing

Check the HF_HUB_CACHE path in the launch script:
```bash
# On server, verify cache directory exists
ls -la /data/hf_hub_cache/

# If not, create it
sudo mkdir -p /data/hf_hub_cache/
sudo chown -R $USER:$USER /data/hf_hub_cache/
sudo chmod -R 755 /data/hf_hub_cache/
```

### Reconfigure Runner

If you need to reconfigure:

```bash
cd ~/actions-runner
sudo ./svc.sh stop
./config.sh remove --token YOUR_REMOVAL_TOKEN
# Then repeat Step 5 with a new registration token
```

## Managing the Runner

### Stop Runner
```bash
cd ~/actions-runner
sudo ./svc.sh stop
```

### Start Runner
```bash
cd ~/actions-runner
sudo ./svc.sh start
```

### Check Status
```bash
cd ~/actions-runner
sudo ./svc.sh status
```

### View Logs
```bash
# Live logs
journalctl -u actions.runner.* -f

# Recent logs
journalctl -u actions.runner.* -n 100
```

### Remove Runner

To completely remove the runner:

```bash
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove --token YOUR_REMOVAL_TOKEN
cd ~
rm -rf actions-runner
```

## Next Steps

Once your runner is set up and verified:

1. See [TRIGGER_BENCHMARKS.md](TRIGGER_BENCHMARKS.md) for how to run benchmarks
2. See [../perf-changelog-examples/](../perf-changelog-examples/) for example configurations
3. Try the manual workflow dispatch method first for quick tests

Your runner is now ready to execute InferenceMAX benchmarks! 🚀
