#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 COR Holdings, LLC
#
# CI only (F-0017-T4, @ac-6): vrai up --native, a user, a device-flow login approved by curl
# as the browser (vrai-cli's install-check does the same), then vrai status, which must exit 0.
#
#   scripts/ci/up-login-status.sh <label>
set -eu
label="$1"
log="${RUNNER_TEMP:-/tmp}/$label.txt"
pass="orbit $(date +%s) quiet river lantern"
vrai up --native 2>&1 | tee -a "$log"
url="$(sed -n 's/^listen *= *"\(.*\)"/http:\/\/\1/p' "$HOME/.vrai/host.toml" 2>/dev/null | head -n 1)"
url="${url:-http://127.0.0.1:8777}"
printf '%s\n' "$pass" | vrai user add "tryout-$label" --password-stdin 2>&1 | tee -a "$log"
t="$(mktemp -d)"
vrai login "$url" > "$t/login.log" 2>&1 &
pid=$!
code=""
for _ in $(seq 100); do
  code="$(sed -n 's/.*enter the code \([A-Za-z0-9-]*\).*/\1/p' "$t/login.log" | head -n 1)"
  [ -n "$code" ] && break
  sleep 0.1
done
[ -n "$code" ] || { tee -a "$log" < "$t/login.log"; echo "refused: vrai login printed no code" | tee -a "$log"; exit 1; }
curl -fsS -o /dev/null -c "$t/jar" -b "$t/jar" --data-urlencode "name=tryout-$label" --data-urlencode "password=$pass" \
  --data-urlencode return_to=/auth/device/verify "$url/auth/login"
curl -fsS -c "$t/jar" -b "$t/jar" --data-urlencode "user_code=$code" --data-urlencode action=approve \
  "$url/auth/device/verify" | grep -q Approved || { echo "refused: the device code was not approved" | tee -a "$log"; exit 1; }
wait "$pid"
tee -a "$log" < "$t/login.log"
vrai status 2>&1 | tee -a "$log"
echo "vrai status exit 0 ($label)" | tee -a "$log"
