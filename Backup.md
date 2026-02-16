```
# On your local machine, in the InferenceMAX repo
cat > .github/workflows/test-runner.yml <<'EOF'
name: Test Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: h100-local_0
    steps:
      - name: Test runner
        run: |
          echo "Runner is working!"
          hostname
          docker --version
          nvidia-smi
EOF

git add .github/workflows/test-runner.yml
git commit -m "Add runner test workflow"
git push
```
