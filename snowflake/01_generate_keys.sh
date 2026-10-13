#!/bin/bash
# 01_generate_keys.sh: generates the RSA key pair for dbt -> Snowflake key-pair authentication
# Usage (from the repo root): bash snowflake/01_generate_keys.sh
#
# - Passphrase is read from DBT_PRIVATE_KEY_PASSPHRASE in .env (git-ignored),
#   so the key and dbt always use the same passphrase
# - Private key (rsa_key.p8): encrypted, stays on this machine, NEVER committed
# - Public key  (rsa_key.pub): registered on DBT_USER in 02_setup_snowflake.sql
# - Keys live outside the repo (~/.ssh/snowflake/), so they cannot be committed by accident
set -e

KEY_DIR="$HOME/.ssh/snowflake"
PRIVATE_KEY="$KEY_DIR/rsa_key.p8"
PUBLIC_KEY="$KEY_DIR/rsa_key.pub"

# 1. Load the passphrase from .env
if [ -f .env ]; then
  set -a; source .env; set +a
fi
if [ -z "$DBT_PRIVATE_KEY_PASSPHRASE" ]; then
  echo "ERROR: DBT_PRIVATE_KEY_PASSPHRASE is not set. Add it to .env (see .env.example)."
  exit 1
fi

# 2. Don't overwrite existing keys (DBT_USER would lose access)
if [ -f "$PRIVATE_KEY" ]; then
  echo "Keys already exist in $KEY_DIR, nothing to do."
  echo "To regenerate: delete them first, then re-run this script AND 02_setup_snowflake.sql."
  exit 0
fi

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

# 3. Private key: 2048-bit RSA, PKCS#8, AES-256 encrypted with the passphrase
openssl genrsa 2048 2>/dev/null \
  | openssl pkcs8 -topk8 -v2 aes256 -inform PEM -out "$PRIVATE_KEY" -passout env:DBT_PRIVATE_KEY_PASSPHRASE

# 4. Public key
openssl rsa -in "$PRIVATE_KEY" -passin env:DBT_PRIVATE_KEY_PASSPHRASE -pubout -out "$PUBLIC_KEY" 2>/dev/null

# 5. Permissions: private key readable only by you
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

echo "Done:"
echo "  Private key: $PRIVATE_KEY"
echo "  Public key:  $PUBLIC_KEY"