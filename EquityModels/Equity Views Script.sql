-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.
IF NOT EXISTS (
SELECT  schema_name
FROM    information_schema.schemata
WHERE   schema_name = 'bi' )
 
BEGIN
EXEC sp_executesql N'CREATE SCHEMA [bi] AUTHORIZATION [dbo]'
END
GO

--View name [bi].[equity.<view name>]