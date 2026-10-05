-- 01_report_day_vs_normal.sql — the core question: do prices move more on
-- WASDE release days than on ordinary trading days?
WITH moves AS (
    SELECT
        symbol,
        date,
        close,
        ABS(100.0 * (close - LAG(close) OVER (PARTITION BY symbol ORDER BY date))
            / LAG(close) OVER (PARTITION BY symbol ORDER BY date)) AS abs_pct_move
    FROM daily_prices
),
flagged AS (
    SELECT
        m.*,
        CASE WHEN w.release_date IS NOT NULL THEN 1 ELSE 0 END AS is_wasde_day
    FROM moves m
    LEFT JOIN wasde_dates w ON w.release_date = m.date
)
SELECT
    symbol,
    SUM(is_wasde_day)     AS wasde_days,
    SUM(1 - is_wasde_day) AS normal_days,
    ROUND(AVG(CASE WHEN is_wasde_day = 1 THEN abs_pct_move END), 3)
        AS avg_abs_move_wasde_pct,
    ROUND(AVG(CASE WHEN is_wasde_day = 0 THEN abs_pct_move END), 3)
        AS avg_abs_move_normal_pct,
    ROUND(AVG(CASE WHEN is_wasde_day = 1 THEN abs_pct_move END)
        / AVG(CASE WHEN is_wasde_day = 0 THEN abs_pct_move END), 2)
        AS wasde_vs_normal_ratio,
    ROUND(100.0 * SUM(CASE WHEN is_wasde_day = 1 AND abs_pct_move > 2 THEN 1 ELSE 0 END)
        / SUM(is_wasde_day), 1) AS pct_big_moves_on_wasde_days,
    ROUND(100.0 * SUM(CASE WHEN is_wasde_day = 0 AND abs_pct_move > 2 THEN 1 ELSE 0 END)
        / SUM(1 - is_wasde_day), 1) AS pct_big_moves_on_normal_days
FROM flagged
WHERE abs_pct_move IS NOT NULL
GROUP BY symbol;
