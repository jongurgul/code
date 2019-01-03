--1st window
USE [tempdb]
IF EXISTS(SELECT * FROM sys.tables WHERE [Name] = 'J1')
DROP TABLE [J1];
IF EXISTS(SELECT * FROM sys.tables WHERE [Name] = 'J2')
DROP TABLE [J2];
CREATE TABLE [J1]([ID] INT);
CREATE TABLE [J2]([ID] INT);
INSERT INTO [J1]VALUES (1);
INSERT INTO [J2]VALUES(1);
GO
BEGIN TRAN
UPDATE [J1] SET [ID] = 1
--UPDATE [J2] SET [ID] = 1

--2nd window
USE [tempdb]
BEGIN TRAN
UPDATE [J2] SET [ID] = 1
UPDATE [J1] SET [ID] = 1


--now run commented code in 1st.

