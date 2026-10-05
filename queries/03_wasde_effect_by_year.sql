-- 03_wasde_effect_by_year.sql — is the WASDE effect stable, growing, or fading?
WITH moves AS (
    SELECT
        symbol,
        date,
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
    SUBSTR(date, 1, 4) AS year,
    symbol,
    COUNT(CASE WHEN is_wasde_day = 1 THEN 1 END) AS wasde_days,
    ROUND(AVG(CASE WHEN is_wasde_day = 1 THEN abs_pct_move END), 3)
        AS avg_abs_move_wasde_pct,
    ROUND(AVG(CASE WHEN is_wasde_day = 0 THEN abs_pct_move END), 3)
        AS avg_abs_move_normal_pct
FROM flagged
WHERE abs_pct_move IS NOT NULL AND SUBSTR(date, 1, 4) >= '2020'
GROUP BY year, symbol
ORDER BY year, symbol;
