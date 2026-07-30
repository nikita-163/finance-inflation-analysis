-- ============================================================
-- Исследовательский анализ данных
-- ============================================================

-- ============================================================
-- 1. Исследование структуры данных.
-- ============================================================

-- ==========================================
-- Таблица банковских операций
-- ==========================================

-- Вопрос:
-- Какие столбцы есть в таблице?

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'finance'
    AND table_name = 'bank_transactions'
ORDER BY ordinal_position;

-- Таблица содержит 17 столбцов с числовыми, строковыми и временными типами данных.

---------------------------------------------------------------

-- Вопрос:
-- Сколько операций содержится в таблице?

SELECT COUNT(*) AS total_transactions  
FROM finance.bank_transactions;

-- Таблица содержит 555 операций.

---------------------------------------------------------------

-- Вопрос:
-- За какой период собраны данные?

SELECT 
    MIN(operation_date) AS first_operation,
    MAX(operation_date) AS last_operation
FROM finance.bank_transactions;

-- Данные охватывают период с 24.06.2025 по 22.06.2026 (около 12 месяцев).

---------------------------------------------------------------

-- Вопрос: 
-- Есть ли операции без даты?

SELECT
    COUNT(*) AS missing_operation_date
FROM finance.bank_transactions
WHERE operation_date IS NULL;

-- Операций без даты не выявлено.

-- ==========================================
-- Таблица макроэкономических показателей
-- ==========================================

-- Вопрос:
-- Какие столбцы есть в таблице?

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'finance'
    AND table_name = 'inflation'
ORDER BY ordinal_position;

-- Таблица содержит 4 столбца с типами данных date и numeric.

---------------------------------------------------------------

-- Вопрос:
-- Сколько периодов содержится в таблице?

SELECT COUNT(*) AS total_periods
FROM finance.inflation;

-- Таблица содержит 12 периодов с макроэкономическими показателями.

---------------------------------------------------------------

-- Вопрос:
-- За какой период собраны данные?

SELECT 
    MIN("period") AS first_operation,
    MAX("period") AS last_operation
FROM finance.inflation; 

-- Данные охватывают период с 2025-06-01 по 2026-05-01 (12 месяцев).

---------------------------------------------------------------

-- Вопрос: 
-- Есть ли периоды без даты?

SELECT
    COUNT(*) AS missing_period
FROM finance.inflation
WHERE "period" IS NULL;

-- Периодов без даты не выявлено.

-- ============================================================
-- 2. Исследование полноты данных.
-- ============================================================

-- ==========================================
-- Таблица банковских операций
-- ==========================================

-- Вопрос:
-- Есть ли NULL-значения в критичных полях таблицы bank_transactions — а именно в operation_date и amount?

SELECT
    COUNT(*) FILTER (WHERE operation_date IS NULL) AS total_missing_date,
    COUNT(*) FILTER (WHERE amount IS NULL) AS total_missing_amount
FROM finance.bank_transactions;

-- NULL-значений в критичных полях таблицы bank_transactions не выявлено.

---------------------------------------------------------------

-- Вопрос:
-- Есть ли пропущенные месяцы во временном ряду?

WITH generate_months AS (
    SELECT generate_series(
        (SELECT DATE_TRUNC('month', MIN(operation_date)) FROM finance.bank_transactions)::date,
        (SELECT DATE_TRUNC('month', MAX(operation_date)) FROM finance.bank_transactions)::date,
        '1 month'::interval
    )::date AS month
)

SELECT
    gm.month,
    COUNT(bt.operation_date) AS month_total_operations
FROM generate_months gm 
    LEFT JOIN finance.bank_transactions bt 
        ON gm.month = DATE_TRUNC('month', bt.operation_date)
GROUP BY gm.month 
ORDER BY gm.month DESC;   

-- Пропущенных месяцев нет — каждый из 13 месяцев содержит хотя бы одну операцию. 
-- Обнаружен большой разброс активности по месяцам (от 5 до 118 операций) — требует проверки на этапе анализа аномалий (блок 4).

-- ==========================================
-- Таблица макроэкономических показателей
-- ==========================================

-- Вопрос:
-- Есть ли NULL-значения в критичных полях таблицы inflation  — а именно в "period", inflation_rate и key_rate?

SELECT
    COUNT(*) FILTER (WHERE "period" IS NULL) AS total_missing_period,
    COUNT(*) FILTER (WHERE inflation_rate IS NULL) AS total_missing_inflation_indicator, 
    COUNT(*) FILTER (WHERE key_rate IS NULL) AS total_missing_key_rate_indicator
FROM finance.inflation;

-- NULL-значений в критичных полях таблицы inflation не выявлено. 

---------------------------------------------------------------

-- Вопрос:
-- Есть ли пропущенные периоды во временном ряду?

WITH generate_months AS (
    SELECT generate_series(
        (SELECT DATE_TRUNC('month', MIN("period")) FROM finance.inflation)::date,
        (SELECT DATE_TRUNC('month', MAX("period")) FROM finance.inflation)::date,
        '1 month'::interval
    )::date AS month
)

SELECT
    gm.month,
    COUNT(i."period") AS period_total_indicators
FROM generate_months gm 
    LEFT JOIN finance.inflation i 
        ON gm.month = DATE_TRUNC('month', i."period")
GROUP BY gm.month 
ORDER BY gm.month DESC;   

-- Пропущенных периодов нет — каждый из 12 периодов содержит макроэкономические показатели.

-- ============================================================
-- 3. Исследование уникальности данных.
-- ============================================================

-- ==========================================
-- Таблица банковских операций
-- ==========================================

-- Вопрос:
-- Есть ли полные дубликаты строк в таблице bank_transactions?

SELECT
    operation_date,
    amount,
    category,
    bonus_value,
    merchant, 
    COUNT(*) AS total_count_duplicate_operations
FROM finance.bank_transactions
GROUP BY operation_date, amount, category, bonus_value, merchant
HAVING COUNT(*) > 1;

-- Запрос выявил строки с полным совпадением по дате, сумме, категории, кешбэку и продавцу.
-- Данные строки нужно проверить через вывод полной строки со свеми столбцами таблицы.

SELECT
    *,
    COUNT(*) OVER (PARTITION BY operation_date, amount, category, bonus_value, merchant) AS total_count_duplicate_operations_2
FROM finance.bank_transactions
WHERE category IN ('Фастфуд', 'Продукты', 'Переводы')
ORDER BY total_count_duplicate_operations_2 DESC, operation_date DESC; 

-- Дополнительная проверка не дала новой информации, так как данные объективно одинаковые.
-- Но вспомнив по памяти о данных операциях, можно сделать вывод:
-- все совпадения соответствуют реальным повторным событиям.
-- Полных дубликатов строк не выявлено.

---------------------------------------------------------------

-- Вопрос:
-- Cогласованы ли в таблице справочные значения?

SELECT
    'raw' AS metric_type,
    COUNT(DISTINCT category) AS total_unique_category,
    COUNT(DISTINCT merchant) AS total_unique_merchant,
    COUNT(DISTINCT status) AS total_unique_status     
FROM finance.bank_transactions

UNION ALL

SELECT
    'normalized' AS metric_type,
    COUNT(DISTINCT LOWER(TRIM(category))) AS total_normalized_unique_category,
    COUNT(DISTINCT LOWER(TRIM(merchant))) AS total_normalized_unique_merchant,
    COUNT(DISTINCT LOWER(TRIM(status))) AS total_normalized_unique_status
FROM finance.bank_transactions;

-- Количество уникальных категорий(25), продавцов(139), статусов(3) совпадает с количеством нормализованных уникальных категорий(25), продавцов(139), статусов(3). 
-- Все справочные значения согласованы.

-- ==========================================
-- Таблица макроэкономических показателей
-- ==========================================

-- Вопрос:
-- Есть ли полные дубликаты строк в таблице inflation?

SELECT
    "period",
    COUNT(*) AS total_count_unique_periods
FROM finance.inflation
GROUP BY "period"
HAVING COUNT(*) > 1;

-- Полных дубликатов строк не выявлено.

-- ============================================================
-- 4. Исследование распределений и аномалий.
-- ============================================================

-- ==========================================
-- Таблица банковских операций
-- ==========================================

-- Вопрос:
-- Как распределены суммы операций в таблице bank_transactions?

SELECT
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount) AS percentile_95,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS percentile_75,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS percentile_50,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS percentile_25,
    ROUND(MAX(amount), 2) AS max_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(MIN(amount), 2) AS min_amount
FROM finance.bank_transactions
WHERE transaction_type = 'Списание' AND merchant NOT IN ('Между своими счетами', 'Никита Сергеевич Р'); 

-- Из запроса можно сделать вывод, что распределение сумм операций скошено в сторону крупных сумм.
-- Среднее значение превышает медианное значение примерно в 1.74 раза, что указывает на наличие
-- небольшого числа крупных операций, утягивающих среднее вверх. 
-- 95% операций укладываются в границу, которая более чем в 3 раза ниже максимального значения суммы операции.
-- То есть основная масса трат сосредоточена в невысоком диапазоне, а хвост из 5% операций 
-- требует отдельного разбора на предмет реальных крупных покупок или потенциальных аномалий.

---------------------------------------------------------------

-- Вопрос:
-- Какие конкретно операции превышают порог 95-ого перцентиля?

SELECT
    *
FROM finance.bank_transactions
WHERE amount > (    
    SELECT 
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount) 
    FROM finance.bank_transactions 
    WHERE transaction_type = 'Списание' 
        AND merchant NOT IN ('Между своими счетами', 'Никита Сергеевич Р')
    ) 
    AND transaction_type = 'Списание' 
    AND merchant NOT IN ('Между своими счетами', 'Никита Сергеевич Р')
ORDER BY amount DESC, operation_date DESC;

-- Порог 95-ого перцентиля превышают реальные операции в категориях: 
-- медицинские услуги, переводы другим людям, активный отдых, фастфуд и продукты.
-- Ручная проверка отдельных случаев подтвердила реальность крупных сумм:
-- операция в категории "Фастфуд" — разовый крупный заказ доставки еды,
-- операция в категории "Продукты" — закупка продуктов на месяц вперёд.
-- Аномалий не выявлено.

-- ==========================================
-- Таблица макроэкономических показателей
-- ==========================================

-- Вопрос:
-- Требуется ли анализ распределения/выбросов для показателей inflation_rate и key_rate в таблице inflation?

-- Перцентильный анализ и поиск выбросов, применённый к bank_transactions, 
-- неприменим к этой таблице, так как данные представляют собой непрерывный временной ряд, 
-- где резкое отклонение от соседних месяцев логичнее анализировать как изменение тренда.
-- Решение: анализ распределения для этой таблицы пропущен осознанно.

-- ============================================================
-- 5. Исследование согласованности бизнес-логики.
-- ============================================================

-- ==========================================
-- Таблица банковских операций
-- ==========================================

-- Вопрос:
-- Есть ли операции с суммой 0 или отрицательным значением?

SELECT
    COUNT(*) FILTER (WHERE amount < 0) AS total_count_negative_amount,
    COUNT(*) FILTER (WHERE amount = 0) AS total_count_zero_amount
FROM finance.bank_transactions;

-- Операций с суммой 0 или отрицательным значением не обнаружено. Все суммы операций положительные.

---------------------------------------------------------------

-- Вопрос:
-- Есть ли операции с датой в будущем относительно момента выгрузки данных? 

SELECT
    CASE 
        WHEN MAX(operation_date) < '2026-06-28' THEN 'ok' ELSE 'logic_mistake'
    END AS future_date_check
FROM finance.bank_transactions;

-- Дата выгрузки данных из банка: 28.06.2026.
-- Логическая целостность временных данных сохранена. 
-- Операций с датой позже даты выгрузки не выявлено.

---------------------------------------------------------------

-- Вопрос:
-- Логически ли связаны между собой поля amount и bonus_value?

SELECT
    COUNT(*) FILTER (WHERE bonus_value >= amount) AS bonus_value_high_amount,
    COUNT(bonus_value) FILTER (WHERE category = 'Переводы') AS bonus_value_in_transfer,
    COUNT(bonus_value) FILTER (WHERE transaction_type = 'Пополнение') AS bonus_value_in_refill 
FROM finance.bank_transactions;

-- Запрос не выявил операции с кешбэком, который превышает сумму,
-- а также не выявил операции с кешбэком в категории "Переводы" и в типе транзакции "Пополнение".
-- Поля логически связаны между собой.

-- ==========================================
-- Таблица макроэкономических показателей
-- ==========================================

-- Вопрос:
-- Есть ли в таблице inflation периоды с датой позже момента выгрузки данных ЦБ?

SELECT
    CASE 
        WHEN MAX("period") < '2026-06-28' THEN 'ok' ELSE 'logic_mistake'
    END AS inflation_future_date_check
FROM finance.inflation;

-- Дата выгрузки данных с официального сайта ЦБ: 28.06.2026.
-- Логическая целостность временных данных сохранена. 
-- Периодов с датой позже даты выгрузки не выявлено.