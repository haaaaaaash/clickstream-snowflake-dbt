#!/bin/bash
# setup_dbt.sh: prepares the environment for the dbt project in dbt/ and tests the connection
# Usage (from the repo root): bash scripts/setup_dbt.sh
# Prerequisite: the dbt config files are already in dbt/
#   (dbt_project.yml, profiles.yml, packages.yml, macros/generate_schema_name.sql)
# Safe to re-run.
set -e

if [ ! -f .env ]; then
  echo "ERROR: .env not found. Run from the repo root (see .env.example)."
  exit 1
fi
if [ ! -f dbt/dbt_project.yml ]; then
  echo "ERROR: dbt/dbt_project.yml not found. Copy the dbt config files into dbt/ first."
  exit 1
fi

echo "1. Creating model folders..."
mkdir -p dbt/models/bronze dbt/models/silver dbt/models/gold dbt/tests

echo "2. Adding dbt paths to .env and .env.example..."
for f in .env .env.example; do
  touch "$f"
  [ -s "$f" ] && [ -n "$(tail -c1 "$f")" ] && echo >> "$f"   # make sure the file ends with a newline
  grep -q "^DBT_PROJECT_DIR="  "$f" || echo "DBT_PROJECT_DIR=dbt"  >> "$f"
  grep -q "^DBT_PROFILES_DIR=" "$f" || echo "DBT_PROFILES_DIR=dbt" >> "$f"
done

echo "3. Setting up direnv (auto-loads .env when you cd into the repo)..."
if ! command -v direnv > /dev/null; then
  echo "   direnv not installed -> installing (may ask for your sudo password)"
  sudo apt-get install -y direnv
fi
grep -q 'direnv hook bash' ~/.bashrc || echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
[ -f .envrc ] || echo "dotenv" > .envrc
direnv allow .

echo "4. Installing dbt packages + testing the connection..."
set -a; source .env; set +a          # load .env for this script
dbt deps
dbt debug

echo
echo "Done. Open a NEW terminal (or run: source ~/.bashrc) so direnv loads .env automatically."