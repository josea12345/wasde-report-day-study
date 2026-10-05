-- 02_biggest_report_day_moves.sql — the 15 most violent WASDE-day reactions
WITH moves AS (
    SELECT
        symbol,
        date,
        close,
        100.0 * (close - LAG(close) OVER (PARTITION BY symbol ORDER BY date))
            / LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS pct_move
    FROM daily_prices
)
SELECT
    m.symbol,
    m.date AS wasde_release,
    ROUND(m.close / 100.0, 2) AS close_usd_bu,
    ROUND(m.pct_move, 2)      AS pct_move
FROM moves m
JOIN wasde_dates w ON w.release_date = m.date
WHERE m.pct_move IS NOT NULL
ORDER BY ABS(m.pct_move) DESC
LIMIT 15;
