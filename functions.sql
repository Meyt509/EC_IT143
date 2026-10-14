/*****************************************************************************************************************
NAME:    functions.sql
PURPOSE: EC IT143 6.3 - Fun with Functions: first name and last name scalar functions (all steps)

MODIFICATION LOG:
Ver      Date        Author        Description
-----   ----------   -----------   -------------------------------------------------------------------------------
1.0     10/13/2026   MMERISIER     1. Built this script for EC IT143


RUNTIME: 
0m 5s

NOTES: 
Part 0: Prep (materialize the view into a table)
Part 1: First name function (steps 1 to 8)
Part 2: Last name function (steps 1 to 7)
Prerequisite: run dbo.v_w3_schools_customers.sql first to create the view.
 
******************************************************************************************************************/

USE EC_IT143_DA;
GO

/**************************************************************************************************************
  PART 0 - PREP
**************************************************************************************************************/

-- ====================================================================================================
-- EC_IT143_6.3_prep_mm.sql
-- Materialize the W3Schools customers view into a table
-- Run dbo.v_w3_schools_customers.sql first. Then this script builds the table with SELECT INTO.
-- ====================================================================================================

-- Q1: How do I turn the view dbo.v_w3_schools_customers into a real table?
-- A1: Use SELECT INTO, which creates the table and fills it in one step.

IF OBJECT_ID('dbo.t_w3_schools_customers') IS NULL
    SELECT *
    INTO   dbo.t_w3_schools_customers
    FROM   dbo.v_w3_schools_customers;
GO

SELECT TOP 10 * FROM dbo.t_w3_schools_customers;
GO

/**************************************************************************************************************
  PART 1 - FIRST NAME FUNCTION
**************************************************************************************************************/

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s1_mm.sql
-- Fun with Functions - Step 1: Start with a question
-- Simplest form of the question: brief, precise, single focus.
-- ====================================================================================================

-- Q1: How do I extract the first name from the contact name?
-- A1: Example: 'Maria Anders' should return 'Maria'.

-- Q1 (SQL): What does the data I am working with look like?
SELECT  CustomerID,
        ContactName
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s2_mm.sql
-- Fun with Functions - Step 2: Begin creating an answer
-- Where I am in my journey and what the next logical step is.
-- ====================================================================================================

-- Q1: Where am I in my journey?
-- A1: ContactName holds 'FirstName LastName' separated by a space.
--     The first name is everything BEFORE the first space.

-- Q2: What is the next logical step?
-- A2: Use CHARINDEX to find the first space, then LEFT to keep the text before it.

-- Q1 (SQL): Where is the first space in each ContactName?
SELECT  ContactName,
        CHARINDEX(' ', ContactName) AS first_space_position
FROM    dbo.t_w3_schools_customers;

-- Q2 (SQL): What does the next step give me (text before the first space)?
SELECT  ContactName,
        LEFT(ContactName, CHARINDEX(' ', ContactName + ' ') - 1) AS first_name_preview
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s3_mm.sql
-- Fun with Functions - Step 3: Ad hoc SQL query (first name)
-- First attempt, focused on step 1 of the answer.
-- ====================================================================================================

-- Q1: What does a first attempt look like?
-- A1: LEFT up to the first space minus 1.

SELECT  ContactName,
        LEFT(ContactName, CHARINDEX(' ', ContactName) - 1) AS FirstName
FROM    dbo.t_w3_schools_customers;

-- Note: this fails if a ContactName has no space (CHARINDEX returns 0 -> length -1).
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s4_mm.sql
-- Fun with Functions - Step 4: Research and test a solution
-- Sources:
-- 1) https://learn.microsoft.com/en-us/answers/questions/378804/split-field-on-space-if-exists
-- 2) https://sqlservercentral.com/?p=295501 (trailing space trick: CHARINDEX(' ', fullname + ' '))
-- ====================================================================================================

-- Q1: How do I avoid the error when there is no space in the name?
-- A1: Append a space to the search string: CHARINDEX(' ', @Name + ' ').

DECLARE @ContactName NVARCHAR(200) = N'Maria Anders';
SELECT LEFT(@ContactName, CHARINDEX(' ', @ContactName + ' ') - 1) AS FirstName;

SET @ContactName = N'Madonna';   -- test with no space
SELECT LEFT(@ContactName, CHARINDEX(' ', @ContactName + ' ') - 1) AS FirstName;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s5_mm.sql
-- Fun with Functions - Step 5: Create user-defined scalar function (first name)
-- Function dbo.udf_get_first_name returns the text before the first space.
-- ====================================================================================================

-- Q1: How do I make the logic reusable?
-- A1: Wrap it in a scalar user-defined function.

CREATE OR ALTER FUNCTION dbo.udf_get_first_name
(
    @ContactName NVARCHAR(200)   -- full contact name, e.g. 'Maria Anders'
)
RETURNS NVARCHAR(100)
AS
BEGIN
    -- Remove leading/trailing spaces
    DECLARE @Name NVARCHAR(200) = LTRIM(RTRIM(@ContactName));

    -- Everything before the first space (the extra ' ' protects single-word names)
    RETURN LEFT(@Name, CHARINDEX(' ', @Name + ' ') - 1);
END;
GO
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s6_mm.sql
-- Fun with Functions - Step 6: Compare UDF results to ad hoc query results
-- Side-by-side comparison.
-- ====================================================================================================

-- Q1: Does the UDF return the same thing as my ad hoc query?
-- A1: Show both results side by side.

SELECT  ContactName,
        LEFT(ContactName, CHARINDEX(' ', ContactName + ' ') - 1) AS FirstName_AdHoc,
        dbo.udf_get_first_name(ContactName)                      AS FirstName_UDF
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s7_mm.sql
-- Fun with Functions - Step 7: '0 results expected' test (first name)
-- Uses a Common Table Expression. Expected result: 0 rows.
-- ====================================================================================================

-- Q1: How do I prove the UDF matches the ad hoc query for every row?
-- A1: Return only the rows where they differ. If the function works, nothing comes back.

WITH cte AS
(
    SELECT  CustomerID,
            ContactName,
            LEFT(LTRIM(RTRIM(ContactName)),
                 CHARINDEX(' ', LTRIM(RTRIM(ContactName)) + ' ') - 1) AS FirstName_AdHoc,
            dbo.udf_get_first_name(ContactName)                        AS FirstName_UDF
    FROM    dbo.t_w3_schools_customers
)
SELECT  *
FROM    cte
WHERE   ISNULL(FirstName_AdHoc, '') <> ISNULL(FirstName_UDF, '');
-- Expected: 0 rows
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_s8_mm.sql
-- Fun with Functions - Step 8: Ask the next question
-- Restart the process for the last name.
-- ====================================================================================================

-- Q1: What am I curious about now?
-- A1: How do I extract the last name from the contact name?
--     See the *_ln_* scripts, which repeat steps 1 to 7.

-- Q1 (SQL): Preview of the next answer (last name = text after the first space)
SELECT  ContactName,
        SUBSTRING(ContactName, CHARINDEX(' ', ContactName + ' ') + 1, LEN(ContactName)) AS last_name_preview
FROM    dbo.t_w3_schools_customers;

-- Edge cases to think about: names with no space or with more than one space
SELECT  ContactName
FROM    dbo.t_w3_schools_customers
WHERE   CHARINDEX(' ', LTRIM(RTRIM(ContactName))) = 0
   OR   LEN(LTRIM(RTRIM(ContactName))) - LEN(REPLACE(LTRIM(RTRIM(ContactName)), ' ', '')) > 1;
GO

/**************************************************************************************************************
  PART 2 - LAST NAME FUNCTION
**************************************************************************************************************/

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s1_mm.sql
-- Last name - Step 1: Start with a question
-- Restart of the process for the last name.
-- ====================================================================================================

-- Q1: How do I extract the last name from the contact name?
-- A1: Example: 'Maria Anders' should return 'Anders'.

-- Q1 (SQL): What does the data I am working with look like?
SELECT  CustomerID,
        ContactName
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s2_mm.sql
-- Last name - Step 2: Begin creating an answer
-- Where I am and the next step.
-- ====================================================================================================

-- Q1: Where am I in my journey?
-- A1: The last name is everything AFTER the first space.

-- Q2: What is the next logical step?
-- A2: Use SUBSTRING starting at CHARINDEX(' ') + 1.

-- Q1 (SQL): Where does the last name start (position after the first space)?
SELECT  ContactName,
        CHARINDEX(' ', ContactName + ' ') + 1 AS last_name_start_position
FROM    dbo.t_w3_schools_customers;

-- Q2 (SQL): What does the next step give me (text after the first space)?
SELECT  ContactName,
        SUBSTRING(ContactName, CHARINDEX(' ', ContactName + ' ') + 1, LEN(ContactName)) AS last_name_preview
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s3_mm.sql
-- Last name - Step 3: Ad hoc SQL query
-- First query for the last name.
-- ====================================================================================================

-- Q1: What does a first attempt look like?
-- A1: SUBSTRING from the character after the first space to the end.

SELECT  ContactName,
        SUBSTRING(ContactName, CHARINDEX(' ', ContactName + ' ') + 1, LEN(ContactName)) AS LastName
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s4_mm.sql
-- Last name - Step 4: Research and test a solution
-- Sources:
-- 1) https://learn.microsoft.com/en-us/answers/questions/378804/split-field-on-space-if-exists
-- 2) https://sqlservercentral.com/?p=295501 (LastName = SUBSTRING(fullname, CHARINDEX(' ', fullname) + 1, 8000))
-- ====================================================================================================

-- Q1: Does it work on a single value and on a single-word name?
-- A1: Test with variables.

DECLARE @n NVARCHAR(200) = N'Ana Trujillo';
SELECT SUBSTRING(@n, CHARINDEX(' ', @n + ' ') + 1, LEN(@n)) AS LastName;

SET @n = N'Madonna';   -- no space: returns an empty string
SELECT SUBSTRING(@n, CHARINDEX(' ', @n + ' ') + 1, LEN(@n)) AS LastName;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s5_mm.sql
-- Last name - Step 5: Create user-defined scalar function
-- Function dbo.udf_get_last_name returns the text after the first space.
-- ====================================================================================================

-- Q1: How do I make the last name logic reusable?
-- A1: Wrap it in a scalar user-defined function.

CREATE OR ALTER FUNCTION dbo.udf_get_last_name
(
    @ContactName NVARCHAR(200)   -- full contact name, e.g. 'Maria Anders'
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @Name NVARCHAR(200) = LTRIM(RTRIM(@ContactName));

    -- Everything after the first space (empty string if there is only one word)
    RETURN SUBSTRING(@Name, CHARINDEX(' ', @Name + ' ') + 1, LEN(@Name));
END;
GO
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s6_mm.sql
-- Last name - Step 6: Compare UDF results to ad hoc query results
-- Side-by-side comparison.
-- ====================================================================================================

-- Q1: Does the UDF return the same thing as my ad hoc query?
-- A1: Show both results side by side.

SELECT  ContactName,
        SUBSTRING(ContactName, CHARINDEX(' ', ContactName + ' ') + 1, LEN(ContactName)) AS LastName_AdHoc,
        dbo.udf_get_last_name(ContactName)                                              AS LastName_UDF
FROM    dbo.t_w3_schools_customers;
GO

-- ====================================================================================================
-- EC_IT143_6.3_fwf_ln_s7_mm.sql
-- Last name - Step 7: '0 results expected' test
-- Uses a Common Table Expression. Expected result: 0 rows.
-- ====================================================================================================

-- Q1: How do I prove the last name UDF matches the ad hoc query for every row?
-- A1: Return only the rows where they differ.

WITH cte AS
(
    SELECT  CustomerID,
            ContactName,
            SUBSTRING(LTRIM(RTRIM(ContactName)),
                      CHARINDEX(' ', LTRIM(RTRIM(ContactName)) + ' ') + 1,
                      LEN(ContactName))                  AS LastName_AdHoc,
            dbo.udf_get_last_name(ContactName)           AS LastName_UDF
    FROM    dbo.t_w3_schools_customers
)
SELECT  *
FROM    cte
WHERE   ISNULL(LastName_AdHoc, '') <> ISNULL(LastName_UDF, '');
-- Expected: 0 rows
GO

