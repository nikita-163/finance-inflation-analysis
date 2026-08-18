-- ================================================================
-- Аналитические запросы и ответы на бизнес-задачи
-- ================================================================

-- Вопрос:
-- Как менялись личные расходы в течение года?

SELECT
  DATE_TRUNC('month', transaction_date) AS month,
  SUM(amount) AS month_expenses
FROM finance.v_real_expenses
GROUP BY DATE_TRUNC ('month', transaction_date)
ORDER BY month;

WITH monthly AS (
  SELECT
  DATE_TRUNC('month', transaction_date) AS month,
  SUM(amount) AS month_expenses
FROM finance.v_real_expenses
GROUP BY DATE_TRUNC ('month', transaction_date)
)

SELECT
  ROUND(MAX(month_expenses) / AVG(month_expenses), 2) AS max_to_avg_ratio,
  ROUND(MIN(month_expenses) / AVG(month_expenses), 2) AS min_to_avg_ratio
FROM monthly;  

-- Общая сумма расходов по месяцам колеблется в диапазоне от 0.83 до 1.15 от среднего уровня.
-- Отклонение минимальной месячной суммы расходов не превышает 17% от средней
-- и отклонение максимальной суммы расходов не превышает 15% от средней.

---------------------------------------------------------------

-- Вопрос:
-- Какие категории расходов занимают наибольшую долю бюджета?

SELECT
  category,
  SUM(amount) AS total_sum,
  ROUND(SUM(amount) / (SELECT SUM(amount) FROM finance.v_real_expenses) * 100, 1) AS percentage_share
FROM finance.v_real_expenses
GROUP BY category
ORDER BY SUM(amount) DESC
LIMIT 5; 

-- Топ 5 категорий по расходам: продукты (42%), фастфуд (24%), переводы другим людям (15%), 
-- прочие расходы (7%), медицинские услуги (5%).

---------------------------------------------------------------

-- Вопрос:
-- Изменялся ли средний чек со временем?

SELECT
  DATE_TRUNC('month', transaction_date) AS month,
  AVG(amount) AS average_cheque
FROM finance.v_real_expenses
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY month;

WITH avg_by_month AS (
  SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    AVG(amount) AS avg_amount
  FROM finance.v_real_expenses
  GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
  month,
  ROUND(avg_amount / AVG(avg_amount) OVER(), 2) AS diff_avg_value
FROM avg_by_month;

-- Диапазон разброса значений среднего чека по месяцам от 0.76 до 1.97, 
-- в одном месяце средний чек меньше на 24%, а в двух месяцах средний чек больше на 97%.

---------------------------------------------------------------

-- Вопрос:
-- Наблюдается ли сезонность в расходах?

WITH quarters AS (
  SELECT
    amount,
    transaction_date,
    CASE
      WHEN DATE_PART('month', transaction_date) IN (1, 2, 3) THEN 'first_quarter'
      WHEN DATE_PART('month', transaction_date) IN (4, 5, 6) THEN 'two_quarter'
      WHEN DATE_PART('month', transaction_date) IN (7, 8, 9) THEN 'three_quarter'
      ELSE 'four_quarter'
    END AS year_quarters
  FROM finance.v_real_expenses
)

SELECT
  year_quarters,
  ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 1) AS share_pct
FROM quarters
GROUP BY year_quarters
ORDER BY share_pct; 

SELECT
    year_quarters,
    SUM(amount) AS total_expenses,
    COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) AS months_in_quarter,
    ROUND(SUM(amount) / COUNT(DISTINCT DATE_TRUNC('month', transaction_date)), 2) AS avg_monthly_expenses
FROM quarters
GROUP BY year_quarters
ORDER BY avg_monthly_expenses DESC;

-- Расчёт через среднемесячные расходы (с учётом фактического числа месяцев в каждом квартале, 
-- так как диапазон данных не совпадает с календарным годом) подтвердил ту же картину, что и первоначальный расчёт по доле:
-- 8,4% трат приходится на первый квартал, 15,3% на второй, 24,7% на четвёртый и 51,7% на третий квартал.
-- Больше 50% трат приходится на 4 квартал, сезонность в расходах наблюдается.