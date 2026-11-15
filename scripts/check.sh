#!/usr/bin/env bash
# Checks hollr.space from outside. Prints one line per check; exits 1 if any failed.
# Each URL gets 3 tries, 20 s apart, so a single blip doesn't page anyone.
set -u
fails=0
report() { echo "$1"; [ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "- $1" >> "$GITHUB_STEP_SUMMARY"; }

check() { # url expected_status [must_contain]
  local url=$1 want=$2 needle=${3:-} code body
  for try in 1 2 3; do
    body=$(curl -sS -m 20 -o - -w '\n%{http_code}' -A 'hollr-uptime-check' "$url" 2>&1) || true
    code=${body##*$'\n'}; body=${body%$'\n'*}
    if [ "$code" = "$want" ] && { [ -z "$needle" ] || grep -q "$needle" <<<"$body"; }; then
      report "OK   $url ($code)"; return; fi
    [ $try -lt 3 ] && sleep 20
  done
  report "FAIL $url (got $code, want $want${needle:+ containing \"$needle\"})"; fails=$((fails+1))
}

check_cert() { # host min_days
  local host=$1 min=$2 end days
  end=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$end" ]; then report "FAIL TLS $host (could not read certificate)"; fails=$((fails+1)); return; fi
  days=$(( ( $(date -d "$end" +%s) - $(date +%s) ) / 86400 ))
  if [ "$days" -ge "$min" ]; then report "OK   TLS $host ($days days left)"
  else report "FAIL TLS $host (expires in $days days)"; fails=$((fails+1)); fi
}

check https://hollr.space/ 200 'Hollr'
check https://hollr.space/hollr.js 200
check https://hollr.space/status 200
check https://hollr.space/signin 200
check https://hollr.space/api/does-not-exist 404 'Not found'
check https://www.hollr.space/ 301
check_cert hollr.space 14

exit $(( fails > 0 ))
