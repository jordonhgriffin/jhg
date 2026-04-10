#!/bin/bash

ACCOUNT_ID="0f80d9753adb7da50e017ed2301f6849"
DOMAIN=${1:-"jordonhgriffin.com"}
DATE=${2:-$(date +%Y-%m-%d)}
FILTER=${3:-"all"}
THIRTY_DAYS_AGO=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)

echo ""
echo "  Usage: ./analytics.sh [domain] [date] [filter]"
echo ""
echo "  Available filters:"
echo "    all          - run everything (default)"
echo "    paths        - 1. page views by path"
echo "    countries    - 2. top countries"
echo "    devices      - 3. device types"
echo "    browsers     - 4. top browsers"
echo "    cache        - 5. cache hit rate"
echo "    statuses     - 6. HTTP response statuses"
echo "    totals       - 7. 30-day daily totals"
echo ""
echo "  Examples:"
echo "    ./analytics.sh                                       # jordonhgriffin.com, today, all"
echo "    ./analytics.sh jordonhgriffin.com 2026-04-08        # specific date, all"
echo "    ./analytics.sh jordonhgriffin.com today referrers   # today, referrers only"
echo "    ./analytics.sh dabirisdesserts.com today paths      # different domain, paths only"
echo ""

# allow 'today' as a date alias
if [ "$DATE" = "today" ]; then
  DATE=$(date +%Y-%m-%d)
fi

if [ -z "$CF_API_TOKEN" ]; then
  echo "Error: CF_API_TOKEN is not set. Run: export CF_API_TOKEN=\"your_token\""
  exit 1
fi

echo "Looking up zone for $DOMAIN..."
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  | python3 -c "import json,sys; z=json.load(sys.stdin)['result']; print(z[0]['id'] if z else '')")

if [ -z "$ZONE_ID" ]; then
  echo "Error: Could not find a Cloudflare zone for $DOMAIN"
  echo "Make sure the domain is on your Cloudflare account and your token has Analytics:Read"
  exit 1
fi

echo ""
echo "========================================================"
echo " Analytics: $DOMAIN"
echo " Date:      $DATE"
echo "========================================================"
echo ""
echo "LEGEND"
echo "  Page views by path  - sampled, good for relative popularity (not exact)"
echo "  Countries           - where visitors are coming from"
echo "  Devices             - desktop vs mobile vs other"
echo "  Cache hit rate      - % of requests served by Cloudflare vs your Worker"
echo "  Response statuses   - 200 OK, 404 not found, etc."
echo "  Daily totals        - 30-day view, includes bots"
echo ""

gql() {
  curl -s -X POST "https://api.cloudflare.com/client/v4/graphql" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$1"
}

run_section() { [ "$FILTER" = "all" ] || [ "$FILTER" = "$1" ]; }

# ── 1. Page views by path ────────────────────────────────────────────────────
if run_section paths; then
echo "--------------------------------------------------------"
echo "1. Page views by path (human traffic, sampled):"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 50, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\", clientRequestPath_like: \\\"%.html\\\"}) { count dimensions { clientRequestPath } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
human = [g for g in groups if 'swagger' not in g['dimensions']['clientRequestPath'] and 'webjars' not in g['dimensions']['clientRequestPath'] and '%3A' not in g['dimensions']['clientRequestPath']]
bot   = [g for g in groups if 'swagger' in g['dimensions']['clientRequestPath'] or 'webjars' in g['dimensions']['clientRequestPath']]
if human:
    for g in human:
        print(f\"  {g['count']:>4}  {g['dimensions']['clientRequestPath']}\")
else:
    print('  No human page views recorded.')
print('')
print('  Bot/scanner paths filtered out:')
if bot:
    for g in bot:
        print(f\"  {g['count']:>4}  {g['dimensions']['clientRequestPath']}\")
else:
    print('  None detected.')
"
fi

# ── 2. Countries ─────────────────────────────────────────────────────────────
if run_section countries; then
echo ""
echo "--------------------------------------------------------"
echo "2. Top countries:"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 20, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\"}) { count dimensions { clientCountryName } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
for g in groups:
    country = g['dimensions']['clientCountryName'] or 'Unknown'
    print(f\"  {g['count']:>4}  {country}\")
"
fi

# ── 3. Devices ───────────────────────────────────────────────────────────────
if run_section devices; then
echo ""
echo "--------------------------------------------------------"
echo "3. Device types:"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 10, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\"}) { count dimensions { clientDeviceType } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
total = sum(g['count'] for g in groups)
for g in groups:
    device = g['dimensions']['clientDeviceType'] or 'Unknown'
    pct = g['count'] / total * 100 if total else 0
    print(f\"  {g['count']:>4}  {pct:>5.1f}%  {device}\")
"
fi

# ── 4. Browsers ──────────────────────────────────────────────────────────────
if run_section browsers; then
echo ""
echo "--------------------------------------------------------"
echo "4. Top browsers:"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 10, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\"}) { count dimensions { userAgentBrowser } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
for g in groups:
    browser = g['dimensions']['userAgentBrowser'] or 'Unknown'
    print(f\"  {g['count']:>4}  {browser}\")
"
fi


# ── 6. Cache hit rate ────────────────────────────────────────────────────────
if run_section cache; then
echo ""
echo "--------------------------------------------------------"
echo "5. Cache status:"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 10, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\"}) { count dimensions { cacheStatus } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
total = sum(g['count'] for g in groups)
for g in groups:
    status = g['dimensions']['cacheStatus'] or 'unknown'
    pct = g['count'] / total * 100 if total else 0
    print(f\"  {g['count']:>4}  {pct:>5.1f}%  {status}\")
print('')
print('  Tip: hit = served by Cloudflare cache, miss/dynamic = hit your Worker')
"
fi

# ── 7. Response statuses ─────────────────────────────────────────────────────
if run_section statuses; then
echo ""
echo "--------------------------------------------------------"
echo "6. HTTP response statuses:"
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequestsAdaptiveGroups(limit: 15, orderBy: [count_DESC], filter: {date: \\\"$DATE\\\"}) { count dimensions { edgeResponseStatus } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequestsAdaptiveGroups']
labels = {'200':'OK','301':'Redirect','302':'Redirect','304':'Not Modified','400':'Bad Request','403':'Forbidden','404':'Not Found','500':'Server Error','503':'Unavailable'}
for g in groups:
    code = str(g['dimensions']['edgeResponseStatus'])
    label = labels.get(code, '')
    print(f\"  {g['count']:>4}  {code}  {label}\")
"
fi


# ── 9. Daily totals ──────────────────────────────────────────────────────────
if run_section totals; then
echo ""
echo "--------------------------------------------------------"
echo "7. Daily totals - last 30 days (includes bots):"
echo "   page views = HTML loads | requests = all assets"
echo ""
gql "{\"query\":\"{ viewer { zones(filter: {zoneTag: \\\"$ZONE_ID\\\"}) { httpRequests1dGroups(limit: 30, orderBy: [date_DESC], filter: {date_geq: \\\"$THIRTY_DAYS_AGO\\\"}) { sum { requests pageViews } dimensions { date } } } } }\"}" \
| python3 -c "
import json, sys
raw = json.load(sys.stdin)
if not raw.get('data'):
    print('  No data returned:', raw.get('errors', ''))
    sys.exit(0)
groups = raw['data']['viewer']['zones'][0]['httpRequests1dGroups']
groups.sort(key=lambda x: x['dimensions']['date'], reverse=True)
for g in groups:
    print(f\"  {g['dimensions']['date']}  page views: {g['sum']['pageViews']:>5}  requests: {g['sum']['requests']:>6}\")
"
fi

echo ""
echo "========================================================"
echo " Done"
echo "========================================================"
