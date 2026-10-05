"""Build the WASDE study database.

Reads:  data/wasde_dates.csv (80 USDA release dates, 2020-01-10 → 2026-09-11,
          collected from the USDA WASDE archive; note: no October 2025 release)
        ../corn-soy-futures-sql/data/futures.db (daily CBOT corn/soy prices)
Writes: data/wasde.db -> wasde_dates(release_date), daily_prices(...)

WASDE is released at 12:00 ET, mid-session, so the release day's close
captures the market reaction.
"""
import csv
import sqlite3

SRC = "../corn-soy-futures-sql/data/futures.db"
DB = "data/wasde.db"

src = sqlite3.connect(SRC)
rows = src.execute("SELECT symbol, date, open, high, low, close, volume FROM daily_prices").fetchall()
src.close()

conn = sqlite3.connect(DB)
cur = conn.cursor()
cur.execute("DROP TABLE IF EXISTS daily_prices")
cur.execute(
    "CREATE TABLE daily_prices (symbol TEXT, date TEXT, open REAL, high REAL,"
    " low REAL, close REAL, volume INTEGER, PRIMARY KEY (symbol, date))"
)
cur.executemany("INSERT OR REPLACE INTO daily_prices VALUES (?,?,?,?,?,?,?)", rows)

cur.execute("DROP TABLE IF EXISTS wasde_dates")
cur.execute("CREATE TABLE wasde_dates (release_date TEXT PRIMARY KEY)")
with open("data/wasde_dates.csv", newline="") as f:
    dates = [(r["release_date"],) for r in csv.DictReader(f)]
cur.executemany("INSERT OR REPLACE INTO wasde_dates VALUES (?)", dates)
conn.commit()

n = cur.execute("SELECT COUNT(*) FROM wasde_dates").fetchone()[0]
m = cur.execute(
    "SELECT COUNT(*) FROM wasde_dates w JOIN daily_prices d ON d.date = w.release_date"
).fetchone()[0]
print(f"{n} WASDE dates, {m} fall on trading days with price data")
conn.close()
