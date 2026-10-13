#!/bin/bash
# setup_repo.sh: creates the empty project skeleton for clickstream-snowflake-dbt
# Usage (from the repo root, after cloning): bash setup_repo.sh
# Safe to re-run.
set -e

echo "1. Creating folders..."
FOLDERS="snowflake scripts data/raw notebooks docs/images docs/diagrams"   # dbt folder is added later 
for d in $FOLDERS; do
  mkdir -p "$d"
  touch "$d/.gitkeep"   # Git does not track empty folders
done

echo "2. Adding project-specific rules to GitHub's Python .gitignore..."
if ! grep -q "Project-specific" .gitignore 2>/dev/null; then
cat >> .gitignore << 'EOF'

# ---- Project-specific ----
# Keys (never commit)
*.p8
*.pem
*.pub

# Raw data (too large for Git)
data/raw/*.csv

# dbt generated files
target/
dbt_packages/
logs/

# IDE
.vscode/

# Windows download metadata (WSL)
*Zone.Identifier
EOF
fi

echo "Done."