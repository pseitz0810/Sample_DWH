/*
Name: Philip Seitz, Luis Reyes
Date: 5/9/24
Description:
This SQL script contains the code used to update the fact tables of the data warehouse.
*/
use hofstra_Phil_Luis_Stock_DB;

/*
DailyStockUpdate Trigger:
Updates the PortfolioValue_Fact and Watchlist_Fact tables each time stock prices are added to the
price table (each day).  Triggers for each row added to the price table.
	PortfolioValue_Fact update:
		For each stock (row added to price table):
			For each row in customer_portfolio_details where stock = stock:
				Add row to PortfolioValue_Fact with customer_id, portfolio_id, date, stock's daily return
	Watchlist_Fact update:
		For each stock (row added to price table):
			If stock is in the watchlist table:
				Add row to Watchlist_Fact with date, stock's daily return
*/
DROP TRIGGER IF EXISTS DailyStockUpdate;
DELIMITER //
CREATE TRIGGER DailyStockUpdate
-- For each row inserted into the price table
AFTER INSERT ON price_table
FOR EACH ROW
BEGIN
    
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur_cust_id INT;
    DECLARE cur_p_id INT;
	-- Used to loop for each row in the customer_portfolio_details table for the given stock
    DECLARE cur CURSOR FOR SELECT cp.cust_id, cpd.portfolio_id 
							FROM customer_portfolio_details cpd 
                            JOIN customer_portfolio cp ON cpd.portfolio_id = cp.portfolio_id WHERE cpd.symbol=NEW.symbol;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	
    OPEN cur;
 	daily_performance_update: LOOP
		FETCH cur INTO cur_cust_id,cur_p_id;
        
        IF done THEN
			LEAVE daily_performance_update;
		END IF;
        
        INSERT INTO PortfolioValue_Fact (PortfolioID, CustomerID, Symbol, NumShares, OpenPrice, CurrentPrice, DateKey, DailyReturn)
        VALUES(cur_p_id,cur_cust_id,NEW.symbol,100,NEW.openprice,NEW.closeprice,YEAR(NEW.lastdate)*10000+MONTH(NEW.lastdate)*100 + DAY(NEW.lastdate),(NEW.closeprice-NEW.openprice)/NEW.openprice);
	
    END LOOP;
	CLOSE cur;
    
    -- Add the Watchlist_Fact table if in watchlist
    IF NEW.symbol IN (SELECT symbol FROM watchlist) THEN
		INSERT INTO Watchlist_Fact (DateKey, Symbol, OpenPrice, CurrentPrice, DailyReturn)
		VALUES(YEAR(NEW.lastdate)*10000+MONTH(NEW.lastdate)*100 + DAY(NEW.lastdate),NEW.symbol,NEW.openprice,NEW.closeprice,(NEW.closeprice-NEW.openprice)/NEW.openprice);
	END IF;
	
END //
DELIMITER ;

/*
PortfolioBalance_Fact Insert:
Updates the PortfolioBalance_Fact table.  This gets the most recent prices from the price table
(using the max date) and joins with the customer_portfolio_details table, the groups by portfolio_id
to get each portfolio's balance.
*/
INSERT INTO PortfolioBalance_Fact (PortfolioID,CustomerID,Balance)
SELECT t1.cust_id,t1.portfolio_id,SUM(t1.balance)
FROM (SELECT cp.cust_id, cpd.portfolio_id, cpd.symbol, p.closeprice*100 AS balance
		FROM customer_portfolio_details cpd
		JOIN customer_portfolio cp ON cp.portfolio_id = cpd.portfolio_id
		JOIN (SELECT symbol,closeprice FROM price_table WHERE lastdate = (SELECT MAX(lastdate) from price_table)) p ON p.symbol = cpd.symbol ) t1
GROUP BY t1.portfolio_id;

/*
Recommendation_Fact Insert:
Updates the Recommendation_Fact table. This table is used to show the average recommendation for each
portfolio.  A row is added for each row in the customer_portfolio_details table, with an average
recommendation for each row (stock), using the most recent recommendations in the recommendation table.
*/
INSERT INTO Recommendation_Fact (PortfolioID,CustomerID,datekey,Symbol,num_ratings,avg_rating)
SELECT 
	cp.portfolio_id,
    cp.cust_id,
    YEAR(r.period)*10000+MONTH(r.period)*100 + DAY(r.period) as datekey,
	r.symbol,
    (r.strongBuy +r.buy + r.hold + r.sell + r.strongSell) as num_ratings,
    -- If there are no recommendations available, return -1
    CASE 
		WHEN (r.strongBuy +r.buy + r.hold + r.sell + r.strongSell) = 0 THEN
			-1
		ELSE
			((r.strongBuy*5)+(r.buy*4)+(r.hold*3)+(r.sell*2)+(r.strongSell*1)) / (r.strongBuy +r.buy + r.hold + r.sell + r.strongSell) 
	END as avg_rating
FROM rec_table r
JOIN (SELECT 
	symbol, 
	MAX(period) as max_date
	from rec_table r group by symbol) maxrec ON maxrec.symbol = r.symbol AND maxrec.max_date = r.period
JOIN customer_portfolio_details cpd ON r.symbol = cpd.symbol
JOIN customer_portfolio cp ON cp.portfolio_id = cpd.portfolio_id;