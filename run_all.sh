#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for f in $(find sql -name "*.sql" | sort -t/ -k3); do echo ">> $f"; duckdb home_credit.duckdb < "$f"; done
source .venv/bin/activate
python3 dashboard/build_dashboard.py
echo "Done. Open dashboard/index.html"
