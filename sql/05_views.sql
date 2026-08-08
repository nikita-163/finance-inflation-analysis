-- v_real_expenses: представление для анализа реальных расходов.

CREATE VIEW finance.v_real_expenses AS 
SELECT 
  transaction_id, 
  transaction_date, 
  merchant, 
  amount, 
  category, 
  mcc, 
  bonus_value
FROM finance.bank_transactions
WHERE status = 'Выполнен'
  AND transaction_type = 'Списание'
  AND merchant != 'Между своими счетами';

-- Фильтрует: только списания, без переводов между своими счетами, только завершённые операции.
-- Столбец transaction_type не включил в итоговое представление
-- так как после фильтрации по этому полю оно перестало нести аналитический смысл  

SELECT
  COUNT(*)
FROM finance.v_real_expenses; 
