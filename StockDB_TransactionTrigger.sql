/*
Name: Philip Seitz, Luis Reyes
Date: 5/9/24
Description:
Trigger used to process buy and sell transactions made by Customers for the transactional database.
*/

use hofstra_Phil_Luis_Stock_DB;

/*
AfterTransactionInsert:
Will handle new transactions inserted into the transactions table.  Triggers for each row
added to the transactions table.  If a buy transaction, a new row will be inserted into 
customer_portfolio_details corresponding to the transaction. If a sell transaction, first the
customer_portfoio_details table is checked to see if the given customer owns the stock listed
in the sell transaction. If so, the row is removed from customer_portfolio_details and moved
to customer_portfolio_sells, with the buy and sell transaction information.  If a none transaction,
the transaction is ignored.
*/
DROP TRIGGER IF EXISTS AfterTransactionInsert;
DELIMITER //
CREATE TRIGGER AfterTransactionInsert
-- For each transaction inserted into the transactions table
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
	-- Declare variables
    DECLARE cust_portfolio INT;
    DECLARE hasActive BIT;
    DECLARE old_price DECIMAL(12,2);
    DECLARE old_date DATETIME;
    DECLARE transaction_id INT;
    
	-- If the transaction type is 'buy'
    IF NEW.action_type = 'buy' THEN
    
		-- Retrieve the portfolio ID for the customer associated with this transaction.
        SELECT portfolio_id INTO cust_portfolio
        FROM customer_portfolio
        WHERE cust_id = NEW.cust_id;
        
		-- Insert new purchase into the customer_portfolio_details table
        INSERT INTO customer_portfolio_details (portfolio_id, symbol, cost, transactionDate)
        VALUES (cust_portfolio, NEW.symbol, NEW.price, NEW.action_date);
        
	-- If the transaction type is 'sell'
    ELSEIF NEW.action_type = 'sell' THEN
    
        -- Check if there are any active stocks of the given symbol for the customer
		SELECT COUNT(*) INTO hasActive
		FROM customer_portfolio_details
		WHERE portfolio_id IN (SELECT portfolio_id FROM customer_portfolio WHERE cust_id = NEW.cust_id)
		AND symbol = NEW.symbol;
		
        -- Get the portfolio_id (only 1 portfolio per customer)
		SELECT portfolio_id INTO cust_portfolio
		FROM customer_portfolio
		WHERE cust_id = NEW.cust_id;

        -- If there are active stocks available (hasActive >= 1), then process the sell transaction
		IF hasActive >= 1 THEN
        
			-- Get the entry_id from customer_portfolio_details for the associated buy (to be removed from table later)
			SELECT entry_id INTO transaction_id
            FROM customer_portfolio_details
            WHERE portfolio_id = cust_portfolio
            AND symbol = NEW.symbol
            LIMIT 1;
            
            -- Get the portfolio_id, buy price, and buy date from the associated buy of this stock
 			SELECT portfolio_id INTO cust_portfolio FROM customer_portfolio_details WHERE entry_id = transaction_id;
 			SELECT cost INTO old_price FROM customer_portfolio_details WHERE entry_id = transaction_id;
 			SELECT transactionDate INTO old_date FROM customer_portfolio_details WHERE entry_id = transaction_id;
             
			-- Insert complete transaction into customer_portfolio_sells
			INSERT INTO customer_portfolio_sells (portfolio_id, symbol, buyPrice, salePrice, buyDate, sellDate)
 			VALUES (cust_portfolio, NEW.symbol, old_price, NEW.price, old_date, NEW.action_date);
            
            -- Remove from customer_portfolio_details
			DELETE FROM customer_portfolio_details
 			WHERE entry_id = transaction_id;

          END IF;
    END IF;
END //

DELIMITER ;