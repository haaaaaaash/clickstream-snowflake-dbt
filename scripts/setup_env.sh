#!/bin/bash
# setup_env.sh: creates the Python environment + installs the Snowflake CLI
# Usage (from the repo root): bash scripts/setup_env.sh
# Then activate: source .venv/bin/activate
set -e

echo "1. Checking uv..."
uv --version

echo "2. Creating venv (Python 3.11)..."
uv venv --python 3.11

echo "3. Installing packages from requirements.txt..."
uv pip install --python .venv -r requirements.txt

echo "4. Locking exact versions to requirements.lock..."
uv pip freeze --python .venv > requirements.lock

echo "5. Installing Snowflake CLI (isolated, outside the venv)..."
uv tool install snowflake-cli || uv tool upgrade snowflake-cli

echo "6. Verifying..."
.venv/bin/dbt --version
snow --version

echo "Done. Activate with: source .venv/bin/activate"