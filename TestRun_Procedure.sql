/*
Name: Philip Seitz, Luis Reyes
Date: 5/9/24
Description:
Steps to take in order to process a few weeks of transactions succesfully.
*/

-- 1. Run StockDB_Transact_Schema.sql
-- 2. Import customer_table_split.csv into the customer_info table
-- 3. Import stock_list.csv into stock_info table
-- 4. Import all_recs_hist.csv into rec_table table
-- 5. Import price_hist_march.csv into price_table table
-- 6. Run queries:
INSERT INTO customer_portfolio (cust_id)
SELECT cust_id FROM customer_info;
INSERT INTO watchlist (symbol)
SELECT symbol from stock_info;
-- 7. Run StockDB_TransactionTrigger.sql
-- 8. Run StockDB_DWH_Schema
-- 9. From StockDB_DWH_ETL.sql, create the DailyStockUpdate trigger
-- 10. Import transactions_04_01_2024.csv into the transactions table
-- 11. Import price_hist_april1.csv into the price table
-- (Repeat steps 10 and 11 for the consecutive transactions_04_XX_2024.csv and price_hist_aprilX.csv files)
-- After each iteration of steps 10 and 11, the following steps can update the remaining fact tables:
	-- 1. Truncate PortfolioBalance_Fact table.  From StockDB_DWH_ETL.sql, run PortfolioBalance_Fact Insert
    -- 2. Truncate Recommendation_Fact table.  From StockDB_DWH_ETL.sql, run Recommendation_Fact Insert
