SELECT COUNT(*)
FROM finance.bank_transactions;

SELECT *
FROM finance.bank_transactions  
LIMIT 10;

SELECT MIN(operation_date),
MAX(operation_date)
FROM finance.bank_transactions;

SELECT amount 
FROM finance.bank_transactions 
LIMIT 50;

SELECT count(*)
FROM finance.inflation;

SELECT MIN("period"),
MAX("period")
FROM finance.inflation;

SELECT inflation_rate,
key_rate
FROM finance.inflation;