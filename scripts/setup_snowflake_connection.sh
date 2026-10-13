#!/bin/bash
# setup_snowflake_connection.sh: creates the 'admin' Snowflake CLI connection (one-time)
# Usage (from the repo root): bash scripts/setup_snowflake_connection.sh
#
# - Reads SNOWFLAKE_ACCOUNT / SNOWFLAKE_USER from .env (git-ignored) if present,
#   otherwise asks for them. Template: .env.example
# - Password is always typed (hidden), never stored in files or shell history
# - Connection is saved in ~/.snowflake/config.toml (outside the repo)
set -e

# 1. Load .env if it exists
if [ -f .env ]; then
  set -a; source .env; set +a
  echo "Loaded settings from .env"
fi

# 2. Ask for anything missing
[ -z "$SNOWFLAKE_ACCOUNT" ] && read -p "Account identifier (ORG-ACCOUNT): " SNOWFLAKE_ACCOUNT
[ -z "$SNOWFLAKE_USER" ]    && read -p "User: " SNOWFLAKE_USER
read -sp "Password for $SNOWFLAKE_USER: " SF_PASSWORD; echo

SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT/./-}"   # accept ORG.ACCOUNT as well

# 3. Create the connection
snow connection add \
  --connection-name admin \
  --account "$SNOWFLAKE_ACCOUNT" \
  --user "$SNOWFLAKE_USER" \
  --password "$SF_PASSWORD" \
  --role ACCOUNTADMIN \
  --warehouse COMPUTE_WH \
  --no-interactive

unset SF_PASSWORD
chmod 0600 ~/.snowflake/config.toml 2>/dev/null || true

# 4. Test
echo "Testing connection..."
snow connection test -c admin