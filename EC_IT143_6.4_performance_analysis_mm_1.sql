/*****************************************************************************************************************
NAME:    EC_IT143_6.4_performance_analysis_mm.sql
PURPOSE: Performance analysis: execution plans, missing index recommendations and index creation
         (AdventureWorks). Two required queries on two different tables + one optional bonus query.

MODIFICATION LOG:
Ver      Date        Author        Description
-----   ----------   -----------   -------------------------------------------------------------------------------
1.0     10/13/2026   MMERISIER     1. Built this script for EC IT143


RUNTIME: 
0m 10s

NOTES: 
HOW TO USE (repeat for each part):
  1. Turn on "Include Actual Execution Plan" (Ctrl+M) - or use the Estimated plan (Ctrl+L, no need to run the query).
  2. Run the BEFORE query. Open the Execution Plan tab.
  3. Note the Estimated Subtree Cost (hover over the SELECT operator) and the green "Missing Index" text.
  4. Right-click the missing index text > "Missing Index Details..." and compare with the CREATE INDEX below.
     If your recommendation is different, use YOUR recommendation (SQL Server's text is the reference).
  5. Name the index and run the CREATE INDEX statement.
  6. Run the AFTER query. Compare the plan (Index Seek vs Scan), subtree cost, reads and elapsed time.

Change the database name below if yours is not AdventureWorks2019 (this script needs the full AdventureWorks,
not AdventureWorksLT).
 
******************************************************************************************************************/

USE AdventureWorks2019;   -- <-- change to your AdventureWorks database name
GO

SET STATISTICS IO ON;     -- shows logical reads in the Messages tab
SET STATISTICS TIME ON;   -- shows CPU time and elapsed time in the Messages tab
GO


/*****************************************************************************************************************
  PART 1 - Person.Address filtered on City (character column that is not indexed on its own)
******************************************************************************************************************/

-- Q1: Which addresses are in the city of Bothell?
-- A1: Filter Person.Address on City. City is not the leading column of any index, so SQL Server must scan the table.

-- ---- BEFORE (include the actual execution plan: Ctrl+M) ----
SELECT  pa.AddressID,
        pa.AddressLine1,
        pa.City,
        pa.PostalCode
FROM    Person.Address AS pa
WHERE   pa.City = 'Bothell';
GO

-- Q2: What index does SQL Server recommend for this query?
-- A2: Right-click "Missing Index" in the plan > Missing Index Details. Expected recommendation (roughly):
--       CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
--       ON [Person].[Address] ([City])
--       INCLUDE ([AddressLine1],[PostalCode])

-- ---- CREATE THE INDEX (named) ----
CREATE NONCLUSTERED INDEX IX_Address_City
ON Person.Address (City)
INCLUDE (AddressLine1, PostalCode);
GO

-- ---- AFTER (run again and compare estimated subtree cost, reads, elapsed time) ----
SELECT  pa.AddressID,
        pa.AddressLine1,
        pa.City,
        pa.PostalCode
FROM    Person.Address AS pa
WHERE   pa.City = 'Bothell';
GO


/*****************************************************************************************************************
  PART 2 - Sales.SalesOrderDetail filtered on CarrierTrackingNumber (character column that is not indexed)
******************************************************************************************************************/

-- Q1: Which order lines shipped with the carrier tracking number '4911-403C-98'?
-- A1: Filter Sales.SalesOrderDetail on CarrierTrackingNumber. No index starts with this column, so SQL Server scans.

-- ---- BEFORE (include the actual execution plan: Ctrl+M) ----
SELECT  sod.SalesOrderID,
        sod.SalesOrderDetailID,
        sod.CarrierTrackingNumber,
        sod.OrderQty,
        sod.UnitPrice
FROM    Sales.SalesOrderDetail AS sod
WHERE   sod.CarrierTrackingNumber = '4911-403C-98';
GO

-- Q2: What index does SQL Server recommend for this query?
-- A2: Expected recommendation (roughly):
--       CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
--       ON [Sales].[SalesOrderDetail] ([CarrierTrackingNumber])
--       INCLUDE ([OrderQty],[UnitPrice])

-- ---- CREATE THE INDEX (named) ----
CREATE NONCLUSTERED INDEX IX_SalesOrderDetail_CarrierTrackingNumber
ON Sales.SalesOrderDetail (CarrierTrackingNumber)
INCLUDE (OrderQty, UnitPrice);
GO

-- ---- AFTER (run again and compare estimated subtree cost, reads, elapsed time) ----
SELECT  sod.SalesOrderID,
        sod.SalesOrderDetailID,
        sod.CarrierTrackingNumber,
        sod.OrderQty,
        sod.UnitPrice
FROM    Sales.SalesOrderDetail AS sod
WHERE   sod.CarrierTrackingNumber = '4911-403C-98';
GO


/*****************************************************************************************************************
  PART 3 (OPTIONAL BONUS) - Sales.SalesOrderHeader filtered on PurchaseOrderNumber
******************************************************************************************************************/

-- Q1: Which sales order has the purchase order number 'PO522145787'?
-- A1: PurchaseOrderNumber is a character column with no index on it.

-- ---- BEFORE ----
SELECT  soh.SalesOrderID,
        soh.PurchaseOrderNumber,
        soh.OrderDate,
        soh.TotalDue
FROM    Sales.SalesOrderHeader AS soh
WHERE   soh.PurchaseOrderNumber = 'PO522145787';
GO

-- ---- CREATE THE INDEX (use the exact recommendation from your plan if it differs) ----
CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_PurchaseOrderNumber
ON Sales.SalesOrderHeader (PurchaseOrderNumber)
INCLUDE (OrderDate, TotalDue);
GO

-- ---- AFTER ----
SELECT  soh.SalesOrderID,
        soh.PurchaseOrderNumber,
        soh.OrderDate,
        soh.TotalDue
FROM    Sales.SalesOrderHeader AS soh
WHERE   soh.PurchaseOrderNumber = 'PO522145787';
GO


/*****************************************************************************************************************
  CLEAN UP (optional): remove the indexes to run the demo again from the start.
  Remember: over-indexing also hurts performance (slower INSERT/UPDATE/DELETE, more storage).
******************************************************************************************************************/

-- DROP INDEX IX_Address_City                           ON Person.Address;
-- DROP INDEX IX_SalesOrderDetail_CarrierTrackingNumber ON Sales.SalesOrderDetail;
-- DROP INDEX IX_SalesOrderHeader_PurchaseOrderNumber   ON Sales.SalesOrderHeader;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
