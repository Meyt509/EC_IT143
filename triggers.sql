/*****************************************************************************************************************
NAME:    triggers.sql
PURPOSE: EC IT143 6.3 - Fun with Triggers: last modified date and last modified by (all steps)

MODIFICATION LOG:
Ver      Date        Author        Description
-----   ----------   -----------   -------------------------------------------------------------------------------
1.0     10/13/2026   MMERISIER     1. Built this script for EC IT143


RUNTIME: 
0m 5s

NOTES: 
Steps 1 to 6 of the trigger method.
Prerequisite: the table dbo.t_w3_schools_customers must exist (see functions.sql, Part 0).
Step 3 (ALTER TABLE ADD) can only be run once.
 
******************************************************************************************************************/

USE EC_IT143_DA;
GO

/**************************************************************************************************************
  FUN WITH TRIGGERS
**************************************************************************************************************/

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s1_mm.sql
-- Fun with Triggers - Step 1: Start with a question
-- Simplest form of the questions.
-- ====================================================================================================

-- Q1: How do I keep track of WHEN a record was last modified?
-- Q2: How do I keep track of WHO last modified a record?

-- Q1 (SQL): Does the table already track when a record was modified?
-- Q2 (SQL): Does the table already track who modified a record?
-- A (SQL): List the columns of the table to find out (no tracking columns yet).
SELECT  COLUMN_NAME,
        DATA_TYPE
FROM    INFORMATION_SCHEMA.COLUMNS
WHERE   TABLE_SCHEMA = 'dbo'
  AND   TABLE_NAME   = 't_w3_schools_customers'
ORDER BY ORDINAL_POSITION;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s2_mm.sql
-- Fun with Triggers - Step 2: Begin creating an answer
-- Where I am in my journey and the next step.
-- ====================================================================================================

-- Q1: Where am I in my journey?
-- A1: I need two new columns: last_modified_date and last_modified_by.
--     A DEFAULT constraint only fires on INSERT, not on UPDATE,
--     so I need a trigger that fires AFTER UPDATE.

-- Q2: What is the next logical step?
-- A2: Add the columns, then create the trigger using GETDATE() and SUSER_NAME().

-- Q1 (SQL): Which triggers and default constraints exist on the table right now?
SELECT  name, type_desc, parent_class_desc
FROM    sys.triggers
WHERE   parent_id = OBJECT_ID('dbo.t_w3_schools_customers');

SELECT  name, definition
FROM    sys.default_constraints
WHERE   parent_object_id = OBJECT_ID('dbo.t_w3_schools_customers');

-- Q2 (SQL): What values will the trigger use?
SELECT  GETDATE()   AS last_modified_date_value,
        SUSER_NAME() AS last_modified_by_value;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s3_mm.sql
-- Fun with Triggers - Step 3: Research and test a solution
-- Sources:
-- 1) https://learn.microsoft.com/en-us/archive/msdn-magazine/2004/april/data-points-creating-audit-tables-invoking-com-objects-and-more (AFTER UPDATE trigger joined to inserted)
-- 2) Microsoft Docs: CREATE TRIGGER (Transact-SQL), SUSER_NAME (Transact-SQL), ALTER TABLE ADD column (course starting materials)
-- ====================================================================================================

-- Q1: How do I add the tracking columns?
-- A1: ALTER TABLE ... ADD, with defaults so inserts and existing rows get a value.

ALTER TABLE dbo.t_w3_schools_customers
    ADD last_modified_date DATETIME      NULL
            CONSTRAINT df_customers_last_modified_date DEFAULT (GETDATE()) WITH VALUES,
        last_modified_by   NVARCHAR(128) NULL
            CONSTRAINT df_customers_last_modified_by   DEFAULT (SUSER_NAME()) WITH VALUES;
GO

-- Q2: What do the two functions return?
SELECT GETDATE() AS now_value, SUSER_NAME() AS who_am_i;

SELECT TOP 5 CustomerID, ContactName, last_modified_date, last_modified_by
FROM   dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s4_mm.sql
-- Fun with Triggers - Step 4: Create after-update triggers
-- Two triggers: one for the last modified date and one for the last modified by.
-- ====================================================================================================

-- Q1: How do I update the last modified date automatically?
-- A1: AFTER UPDATE trigger that joins to the inserted pseudo-table.

CREATE OR ALTER TRIGGER dbo.trg_customers_last_modified_date
ON dbo.t_w3_schools_customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE  t
    SET     t.last_modified_date = GETDATE()
    FROM    dbo.t_w3_schools_customers AS t
            INNER JOIN inserted AS i ON i.CustomerID = t.CustomerID;
END;
GO

-- Q2: How do I record who made the change?
-- A2: Same pattern, using SUSER_NAME().

CREATE OR ALTER TRIGGER dbo.trg_customers_last_modified_by
ON dbo.t_w3_schools_customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE  t
    SET     t.last_modified_by = SUSER_NAME()
    FROM    dbo.t_w3_schools_customers AS t
            INNER JOIN inserted AS i ON i.CustomerID = t.CustomerID;
END;
GO

-- Q1 (SQL): Was the date trigger created?  Q2 (SQL): Was the user trigger created?
SELECT  name, type_desc, is_disabled
FROM    sys.triggers
WHERE   parent_id = OBJECT_ID('dbo.t_w3_schools_customers');
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s5_mm.sql
-- Fun with Triggers - Step 5: Test results
-- Check that the triggers worked as expected.
-- ====================================================================================================

-- Q1: Did the triggers work?
-- A1: Compare one row before and after an UPDATE.

-- Before
SELECT CustomerID, ContactName, last_modified_date, last_modified_by
FROM   dbo.t_w3_schools_customers
WHERE  CustomerID = 1;

-- Make a harmless change
UPDATE dbo.t_w3_schools_customers
SET    ContactName = ContactName + ' '
WHERE  CustomerID = 1;

-- After: date should be now and last_modified_by should be my login
SELECT CustomerID, ContactName, last_modified_date, last_modified_by
FROM   dbo.t_w3_schools_customers
WHERE  CustomerID = 1;

-- Clean up
UPDATE dbo.t_w3_schools_customers
SET    ContactName = RTRIM(ContactName)
WHERE  CustomerID = 1;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwt_s6_mm.sql
-- Fun with Triggers - Step 6: Ask the next question
-- Next question to explore.
-- ====================================================================================================

-- Q1: What am I curious about now?
-- A1: How do I set 'last modified by' to the server user (SUSER_NAME vs ORIGINAL_LOGIN)?

-- Q1 (SQL): Which login functions are available, and how do they differ?
SELECT  SUSER_NAME()     AS suser_name,       -- current login name
        SUSER_SNAME()    AS suser_sname,      -- login name (from SID)
        ORIGINAL_LOGIN() AS original_login,   -- login that connected (ignores EXECUTE AS)
        SYSTEM_USER      AS system_user_value,
        USER_NAME()      AS database_user;
GO

