-- ==========================================
-- Создание таблицы банковских операций
-- ==========================================

CREATE TABLE finance.bank_transactions (
  
  transactions_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  
  operation_date DATE NOT NULL,
  transaction_date DATE NOT NULL, 
  
  account_name VARCHAR(100),
  account_number VARCHAR(30),

  card_name VARCHAR(100),
  card_number VARCHAR(30),

  merchant VARCHAR(255),

  amount NUMERIC(10,2) NOT NULL,
  
  currency CHAR(3) DEFAULT 'RUB',

  status VARCHAR(30),

  category VARCHAR(100),

  mcc INTEGER,

  transactions_type VARCHAR(50),

  comment TEXT,

  bonus_value NUMERIC(10,2),
  bonus_title VARCHAR(100)

);

-- ==========================================
-- Создание таблицы макроэкономических показателей
-- ==========================================

CREATE TABLE finance.inflation (

  period DATE PRIMARY KEY, 

  key_rate NUMERIC(4,2) NOT NULL,

  inflation_rate NUMERIC(4,2) NOT NULL,

  inflation_target NUMERIC(4,2) NOT NULL

);