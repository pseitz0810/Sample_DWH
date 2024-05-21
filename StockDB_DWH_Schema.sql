/*
Name: Philip Seitz, Luis Reyes
Date: 5/9/24
Description:
Creates the tables for the transactional database and populates the dimension tables.
*/
use hofstra_Phil_Luis_Stock_DB;
DROP PROCEDURE IF EXISTS fill_date_dim;
DROP TABLE IF EXISTS PortfolioValue_Fact;
DROP TABLE IF EXISTS Watchlist_Fact;
DROP TABLE IF EXISTS Recommendation_Fact;
DROP TABLE IF EXISTS PortfolioBalance_Fact;
DROP TABLE IF EXISTS Stock_Dim;
DROP TABLE IF EXISTS Customer_Dim;
DROP TABLE IF EXISTS Portfolio_Dim;
DROP TABLE IF EXISTS Date_Dim;

-- Date dimension
CREATE TABLE Date_Dim (
    DateKey INT PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    Weekday VARCHAR(10)
);

-- Portfolio dimension
CREATE TABLE Portfolio_Dim (
    PortfolioID INT PRIMARY KEY,
    CustomerID INT,
    custName VARCHAR(250),
    custLastName VARCHAR(250),
    custCity VARCHAR(50),
	custState VARCHAR(50)
);

-- Customer dimension
CREATE TABLE Customer_Dim (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(250),
    LastName VARCHAR(250),
    City VARCHAR(50),
    State VARCHAR(50),
    Zip INT,
    Phone VARCHAR(30),
    InGoodStanding BIT
);

-- Stock dimension
CREATE TABLE Stock_Dim (
    Symbol VARCHAR(7) PRIMARY KEY,
    Description VARCHAR(255)
);

CREATE TABLE PortfolioValue_Fact (
    FactID INT AUTO_INCREMENT PRIMARY KEY,
    DateKey INT NOT NULL,  -- This refers to the DateDimension table
    PortfolioID INT NOT NULL,
    CustomerID INT NOT NULL,
    Symbol VARCHAR(7) NOT NULL,
    NumShares INT NOT NULL,
    OpenPrice DECIMAL (12,2),
    CurrentPrice DECIMAL(12, 2),
    DailyReturn DECIMAL(12, 2), -- Calculated as (CurrentPrice - OpenPrice) * NumShares
    FOREIGN KEY (DateKey) REFERENCES Date_Dim(DateKey),
    FOREIGN KEY (PortfolioID) REFERENCES Portfolio_Dim(PortfolioID),
    FOREIGN KEY (CustomerID) REFERENCES Customer_Dim(CustomerID),
    FOREIGN KEY (Symbol) REFERENCES Stock_Dim(Symbol)
);


CREATE TABLE Recommendation_Fact (
	entry_id INT AUTO_INCREMENT PRIMARY KEY,
    PortfolioID INT NOT NULL,
    CustomerID INT NOT NULL,
    datekey INT,
    Symbol VARCHAR(7),
    num_ratings INT,
    avg_rating FLOAT,
    FOREIGN KEY (PortfolioID) REFERENCES Portfolio_Dim(PortfolioID),
    FOREIGN KEY (CustomerID) REFERENCES Customer_Dim(CustomerID),
    FOREIGN KEY (datekey) REFERENCES Date_Dim(DateKey),
    FOREIGN KEY (Symbol) REFERENCES Stock_Dim(Symbol)
);

CREATE TABLE Watchlist_Fact (
    FactID INT AUTO_INCREMENT PRIMARY KEY,
    DateKey INT NOT NULL,  -- This refers to the DateDimension table
    Symbol VARCHAR(7) NOT NULL,
    OpenPrice DECIMAL (12,2),
    CurrentPrice DECIMAL(12, 2),
    DailyReturn DECIMAL(12, 2), -- Calculated as (CurrentPrice - OpenPrice) * NumShares
    FOREIGN KEY (DateKey) REFERENCES Date_Dim(DateKey),
    FOREIGN KEY (Symbol) REFERENCES Stock_Dim(Symbol)
);

CREATE TABLE PortfolioBalance_Fact (
	FactID INT AUTO_INCREMENT PRIMARY KEY,
    PortfolioID INT NOT NULL,
    CustomerID INT NOT NULL,
    Balance Decimal(12,2),
    FOREIGN KEY (PortfolioID) REFERENCES Portfolio_Dim(PortfolioID),
    FOREIGN KEY (CustomerID) REFERENCES Customer_Dim(CustomerID)
);
    

-- Script to populate Date_Dim table
DELIMITER //
CREATE PROCEDURE fill_date_dim(IN startdate DATE,IN stopdate DATE)
BEGIN
    DECLARE currentdate DATE;
    SET currentdate = startdate;
    WHILE currentdate <= stopdate DO
        INSERT INTO Date_Dim VALUES (
            YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),-- Datekey
            currentdate, -- Date
            YEAR(currentdate), -- Year
            QUARTER(currentdate), -- Quarter            
            MONTH(currentdate), -- Month
            DAY(currentdate),-- Day
            DATE_FORMAT(currentdate,'%W')
            );
        SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
    END WHILE;
END
//
DELIMITER ;

-- TRUNCATE TABLE date_dim;
CALL fill_date_dim('2020-01-01','2025-01-01');

-- Script to populate Portfolio_Dim table
INSERT INTO Portfolio_Dim (PortfolioID, CustomerID, custName, custLastName, custCity, custState)
SELECT cp.portfolio_id, ci.cust_id, ci.firstName, ci.lastName, ci.city, ci.state
FROM customer_portfolio cp
JOIN customer_info ci ON cp.cust_id = ci.cust_id;

-- Script to populate Customer_Dim table
INSERT INTO Customer_Dim (CustomerID, FirstName, LastName, City, State, Zip, Phone)
SELECT cust_id, firstName, lastName, city, state, zip, phone
FROM customer_info;

-- Script to populate Stock_Dim table
INSERT INTO Stock_Dim (Symbol, Description)
SELECT symbol, description
FROM stock_info;