/*
Name: Philip Seitz, Luis Reyes
Date: 5/9/24
Description:
Creates the tables for the transactional database.
*/

DROP DATABASE IF EXISTS hofstra_Phil_Luis_Stock_DB;
CREATE DATABASE hofstra_Phil_Luis_Stock_DB;
USE hofstra_Phil_Luis_Stock_DB;

DROP TABLE IF EXISTS rec_table;
DROP TABLE IF EXISTS price_table;
DROP TABLE IF EXISTS watchlist;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customer_portfolio_details;
DROP TABLE IF EXISTS customer_portfolio_sells;
DROP TABLE IF EXISTS customer_portfolio;
DROP TABLE IF EXISTS customer_info;
DROP TABLE IF EXISTS stock_info;

-- Stock Info Table
CREATE TABLE stock_info (
    symbol VARCHAR(7) PRIMARY KEY,
    description VARCHAR(255)
);

-- Customer Info Table
CREATE TABLE customer_info (
    cust_id INT AUTO_INCREMENT PRIMARY KEY,
    firstName VARCHAR(250),
    lastName VARCHAR(250),
    streetNum INT,
    streetName VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    zip INT,
    phone VARCHAR(30)
);
-- Customer Portfolio Table
CREATE TABLE customer_portfolio (
    portfolio_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_id INT NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES customer_info(cust_id)
);
-- Customer Portfolio Details Table
DROP TABLE IF EXISTS customer_portfolio_details;
CREATE TABLE customer_portfolio_details (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id INT NOT NULL,
    symbol VARCHAR(7) NOT NULL,
    numShares INT,
    cost DECIMAL(12, 2) NOT NULL,
    transactionDate datetime,
    FOREIGN KEY (portfolio_id) REFERENCES customer_portfolio(portfolio_id),
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);

-- Recommendations Table
CREATE TABLE rec_table (
    rec_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(7) NOT NULL,
    period VARCHAR (10),
    strongBuy INT,
    buy INT,
    hold INT,
    sell INT,
    strongSell INT,
    recdate DATETIME,
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);

-- Price Information Table
CREATE TABLE price_table (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(7) NOT NULL,
    lastdate DATETIME,
    openprice FLOAT,
    highprice FLOAT,
    lowprice FLOAT,
    closeprice FLOAT,
    volume BIGINT,
    dividend FLOAT,
    split INT,
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);

-- Watchlist Table CONNECTED TO CUSTOMER INFO
CREATE TABLE watchlist (
    watchlist_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(7) NOT NULL,
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);
-- Transactions Table
dROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_id INT NOT NULL,
    symbol VARCHAR(7) NOT NULL,
    action_type VARCHAR(7) NOT NULL, 
    -- numShares INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    action_date DATETIME NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES customer_info(cust_id),
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);

-- Customer sells
DROP TABLE IF EXISTS customer_portfolio_sells;
CREATE TABLE customer_portfolio_sells (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id INT NOT NULL,
    symbol VARCHAR(7) NOT NULL,
    buyPrice DECIMAL(12,2) NOT NULL,
    salePrice DECIMAL(12, 2) NOT NULL,
    buyDate datetime,
    sellDate datetime,
    FOREIGN KEY (portfolio_id) REFERENCES customer_portfolio(portfolio_id),
    FOREIGN KEY (symbol) REFERENCES stock_info(symbol)
);