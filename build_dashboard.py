#!/usr/bin/env python3
"""Reads mart.driver_bands and mart.headline from DuckDB and writes dashboard/index.html.

Run from the project root:  python3 dashboard/build_dashboard.py
"""
import json
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "home_credit.duckdb"
TEMPLATE = ROOT / "dashboard" / "template.html"
OUT = ROOT / "dashboard" / "index.html"


def fetch(con, sql):
    cur = con.execute(sql)
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def main():
    if not DB.exists():
        sys.exit(f"Database not found: {DB}")
    con = duckdb.connect(str(DB), read_only=True)
    data = {
        "bands": fetch(con, "SELECT driver, band, customers, defaulters, default_pct, lift FROM mart.driver_bands ORDER BY driver, band"),
        "head": fetch(con, "SELECT * FROM mart.headline")[0],
    }
    con.close()

    payload = json.dumps(data, default=float).replace("</", "<\\/")
    html = TEMPLATE.read_text(encoding="utf-8").replace("__DATA__", payload)
    OUT.write_text(html, encoding="utf-8")
    print(f"Wrote {OUT} ({len(data['bands'])} band rows)")


if __name__ == "__main__":
    main()
