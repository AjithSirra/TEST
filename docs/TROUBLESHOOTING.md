# Troubleshooting Guide

Common issues and solutions when running InferenceMAX benchmarks on your local MI300X server.

## Runner Issues

### Runner Not Showing in GitHub

**Symptom:** Can't see `mi300x-local_0` in Settings → Actions → Runners

**Solutions:**

1. **Check runner service status**
   ```bash
   cd ~/actions-runner
   sudo ./svc.sh status
   ```

2. **Check runner configuration**
   ```bash
   cat ~/actions-runner/.runner
   ```
   Should show `"name": "mi300x-local_0"`

3. **Check runner logs**
   ```bash
   journalctl -u actions.runner.* -n 50
   ```

4. **Restart runner**
   ```bash
   cd ~/actions-runner
   sudo ./svc.sh stop
   sudo ./svc.sh start
   ```

5. **Reconfigure runner**
   ```bash
   cd ~/actions-runner
   sudo ./svc.sh stop
   ./config.sh remove --token YOUR_REMOVAL_TOKEN
   # Get new registration token from GitHub
   ./config.sh --url https://github.com/YOUR_ORG/InferenceMAX \
     --token NEW_TOKEN \
     --name mi300x-local_0 \
     --labels mi300x-local_0,mi300x
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

### Runner Shows "Offline"

**Symptom:** Runner appears in GitHub but shows as offline

**Solutions:**

1. **Check network connectivity**
   ```bash
   ping github.com
   curl -I https://github.com
   ```

2. **Check firewall**
   ```bash
   sudo ufw status
   # If active, ensure outbound HTTPS is allowed
   sudo ufw allow out 443/tcp
   ```

3. **Check runner process**
   ```bash
   ps aux | grep Runner.Listener
   ```
   Should show a running process

4. **Check system resources**
   ```bash
   df -h   # Disk space
   free -h # Memory
   ```

### Jobs Not Running on Your Runner

**Symptom:** Jobs queue but don't run on `mi300x-local_0`

**Solutions:**

1. **Check runner labels**
   ```bash
   cat ~/actions-runner/.runner | jq '.labels'
   ```
   Should include `"mi300x"` and `"mi300x-local_0"`

2. **Verify runners.yaml**
   - Check `.github/configs/runners.yaml` includes `mi300x-local_0`

3. **Check runner is idle**
   - Go to Settings → Actions → Runners
   - Status should be "Idle" not "Busy"

4. **Check job runner specification**
   - In workflow logs, verify `runs-on: mi300x-local_0`

---

## Docker Issues

### Docker Permission Denied

**Symptom:** `permission denied while trying to connect to the Docker daemon`

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit
ssh user@10.23.45.34

# Verify
docker ps
```

### Docker Container Fails to Start

**Symptom:** `Error response from daemon: could not select device driver`

**Solutions:**

1. **Check ROCm devices**
   ```bash
   ls -la /dev/kfd /dev/dri
   ```
   Should show character devices

2. **Check Docker daemon**
   ```bash
   sudo systemctl status docker
   ```

3. **Restart Docker**
   ```bash
   sudo systemctl restart docker
   ```

4. **Test Docker with ROCm**
   ```bash
   docker run --rm --device=/dev/kfd --device=/dev/dri \
     rocm/pytorch:latest rocm-smi
   ```

### Image Pull Failures

**Symptom:** `Error response from daemon: pull access denied`

**Solutions:**

1. **Check image name**
   - Verify image exists: `vllm/vllm-openai-rocm:v0.14.0`

2. **Login to Docker Hub (if private)**
   ```bash
   docker login
   ```

3. **Try manual pull**
   ```bash
   docker pull vllm/vllm-openai-rocm:v0.14.0
   ```

---

## HuggingFace Issues

### Model Download Failures

**Symptom:** `Repository not found` or `Access denied`

**Solutions:**

1. **Check HF_TOKEN secret**
   - Settings → Secrets and variables → Actions
   - Verify `HF_TOKEN` is set

2. **Test token on server**
   ```bash
   export HF_TOKEN=your_token_here
   pip install huggingface-hub
   huggingface-cli whoami
   ```

3. **Check model access**
   - Go to https://huggingface.co/openai/gpt-oss-120b
   - Verify you have access (may need to accept terms)

4. **Check cache directory**
   ```bash
   ls -la /data/hf_hub_cache/
   df -h /data  # Check disk space
   ```

### Slow Downloads

**Symptom:** Model download takes very long

**Solutions:**

1. **Check network speed**
   ```bash
   curl -o /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip
   ```

2. **Use local mirror** (if available)
   - Set HF_ENDPOINT environment variable

3. **Pre-download models**
   ```bash
   export HF_TOKEN=your_token
   huggingface-cli download openai/gpt-oss-120b \
     --cache-dir /data/hf_hub_cache/
   ```

---

## Benchmark Issues

### Benchmark Starts but Fails Quickly

**Symptom:** Benchmark job starts but fails within minutes

**Solutions:**

1. **Check GPU availability**
   ```bash
   rocm-smi
   ```
   Should show 8 GPUs

2. **Check GPU memory**
   ```bash
   rocm-smi --showmeminfo vram
   ```

3. **Check vLLM server logs**
   - In job logs, look for server startup section
   - Common errors:
     - Out of memory → Reduce `--max-model-len` or TP
     - Model load error → Check model format
     - CUDA/ROCm error → Check driver version

4. **Reduce configuration**
   - Try smaller TP (e.g., TP=2 instead of TP=8)
   - Try lower concurrency
   - Try shorter sequence lengths

### Benchmark Hangs

**Symptom:** Benchmark runs but never completes

**Solutions:**

1. **Check timeout**
   - Workflow timeout is 180 minutes
   - Long benchmarks may need more time

2. **Check server log**
   ```bash
   # On server, check recent Docker logs
   docker logs $(docker ps -q) --tail 100
   ```

3. **Check if server is responding**
   ```bash
   # From inside the job
   curl http://localhost:8888/health
   ```

4. **Kill hanging jobs**
   ```bash
   # On server
   docker ps -q | xargs docker kill
   ```

### Results Missing

**Symptom:** Benchmark completes but no results artifact

**Solutions:**

1. **Check result file was created**
   - In job logs, look for "Upload result artifact" step
   - Should show file path

2. **Check file permissions**
   ```bash
   ls -la $GITHUB_WORKSPACE/*.json
   ```

3. **Check GitHub Actions artifact limits**
   - Free tier: 500 MB per artifact
   - Results should be < 1 MB each

---

## Performance Issues

### Low Throughput

**Symptom:** Throughput much lower than expected

**Solutions:**

1. **Check GPU utilization**
   ```bash
   watch -n 1 rocm-smi
   ```
   Should show high GPU utilization during benchmark

2. **Check for thermal throttling**
   ```bash
   rocm-smi --showtemp
   ```

3. **Check CPU utilization**
   ```bash
   htop
   ```

4. **Disable NUMA balancing** (done by launch script)
   ```bash
   cat /proc/sys/kernel/numa_balancing
   ```
   Should be 0

5. **Check for other processes**
   ```bash
   docker ps -a
   nvidia-smi  # or rocm-smi
   ```

### High Latency

**Symptom:** TTFT or TPOT higher than expected

**Solutions:**

1. **Increase TP** - More GPUs for model
2. **Reduce concurrency** - Less queueing
3. **Check batch size** - May be too large
4. **Check network latency** - If remote

---

## Workflow Issues

### "No matrix entries generated"

**Symptom:** Workflow completes immediately with no jobs

**Solutions:**

1. **Check CLI command syntax**
   ```bash
   # Must specify --single-node or --multi-node
   full-sweep --single-node ...
   ```

2. **Check filter parameters**
   - Make sure model-prefix, runner-type match config
   - Example: `gptoss` not `gpt-oss`

3. **Verify config files exist**
   ```bash
   ls .github/configs/amd-master.yaml
   ```

4. **Test locally**
   ```bash
   pip install pydantic
   python3 utils/matrix_logic/generate_sweep_configs.py \
     full-sweep --single-node --model-prefix gptoss \
     --runner-type mi300x --config-files .github/configs/amd-master.yaml
   ```

### Secrets Not Available

**Symptom:** `HF_TOKEN` or other secrets are empty

**Solutions:**

1. **Check secret names** (case-sensitive)
   - Must be exactly: `HF_TOKEN`, `REPO_PAT`

2. **Check secret is in repository**
   - Settings → Secrets and variables → Actions
   - Not in Organization or Environment secrets

3. **Check workflow permissions**
   ```yaml
   secrets: inherit  # In workflow_call
   ```

---

## Getting Help

If you're still stuck:

1. **Check job logs**
   - Go to failed job
   - Expand all steps
   - Look for error messages

2. **Check runner logs**
   ```bash
   journalctl -u actions.runner.* -n 200
   ```

3. **Check server logs**
   ```bash
   docker logs $(docker ps -q) --tail 200
   ```

4. **Create minimal reproduction**
   - Run simplest possible config
   - Isolate the issue

5. **Collect diagnostics**
   ```bash
   # On server
   rocm-smi
   docker version
   df -h
   free -h
   cat ~/actions-runner/.runner
   ```

6. **Ask for help**
   - Include error messages
   - Include configuration used
   - Include diagnostics output
