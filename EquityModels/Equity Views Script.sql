-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.
IF NOT EXISTS (
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name = 'BI'
        )
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA [BI] AUTHORIZATION [dbo]'
END
GO

CREATE OR ALTER VIEW [BI].[equity.School]
AS
SELECT SchoolKey
    ,SchoolName
    ,LocalEducationAgencyKey
    ,LocalEducationAgencyName
FROM analytics.SchoolDim;
GO

CREATE OR ALTER VIEW [BI].[equity.Section]
AS
SELECT DISTINCT SchoolKey
    ,SectionKey
    ,SectionName
    ,SessionName
    ,LocalCourseCode
    ,SchoolYear
    ,EducationalEnvironmentDescriptor
    ,LocalEducationAgencyId
FROM analytics.SectionDim;
GO

CREATE OR ALTER VIEW [BI].[equity.Student]
AS
SELECT StudentSchoolDim.GradeLevel AS [CurrentGradeLevel]
    ,StudentSchoolDim.SchoolKey AS [CurrentSchoolKey]
    ,CASE 
        WHEN StudentSchoolDim.IsHispanic = 1
            THEN 'True'
        ELSE 'False'
        END AS HispanicLatinoEthnicity
    ,CONCAT (
        StudentSchoolDim.StudentLastName
        ,', '
        ,StudentSchoolDim.StudentFirstName
        ) as StudentName
    ,StudentSchoolDim.Sex AS SexType
    ,StudentSchoolDim.StudentSchoolKey
    ,StudentSchoolDim.StudentKey
    ,CAST(StudentSchoolDim.[EnrollmentDateKey] AS DATE) AS EntryDate
    ,StudentSchoolDim.[SchoolKey]
FROM [analytics].[StudentSchoolDim];

GO

CREATE OR ALTER VIEW [BI].[equity.StudentSectionAssociation]
AS
SELECT CONCAT (
        StudentSectionDim.[StudentKey]
        ,'-'
        ,StudentSectionDim.[SchoolKey]
        ) AS StudentSchoolKey
    ,StudentSectionDim.StudentSectionKey
    ,StudentSectionDim.SchoolKey
    ,StudentSectionDim.SectionKey
    ,StudentSectionDim.SchoolYear
    ,CAST(StudentSectionDim.StudentSectionStartDateKey AS DATE) AS BeginDate
    ,CAST(StudentSectionDim.StudentSectionEndDateKey AS DATE) AS EndDate
FROM analytics.StudentSectionDim
INNER JOIN analytics.SchoolDim ON StudentSectionDim.SchoolKey = SchoolDim.SchoolKey;
GO

CREATE OR ALTER VIEW [BI].[equity.StaffSection]
AS

SELECT s.StaffUSI
    ,s.UserKey
    ,s.StaffSectionKey
    ,s.SectionKey
    ,s.PersonalTitlePrefix
    ,CONCAT (
        s.LastSurname
        ,', '
        ,s.FirstName
        ) AS StaffName
    ,s.BirthDate
    ,CASE 
        WHEN s.HispanicLatinoEthnicity = 1
            THEN 'True'
        ELSE 'False'
        END AS HispanicLatinoEthnicity
    ,s.YearsOfPriorProfessionalExperience
    ,s.YearsOfPriorTeachingExperience
    ,CASE 
        WHEN s.HighlyQualifiedTeacher = 1
            THEN 'True'
        ELSE 'False'
        END AS HighlyQualifiedTeacher
    ,HighestCompletedLevelOfEducation
    ,s.LoginId
FROM analytics.StaffSectionDim s;

GO

CREATE OR ALTER VIEW [BI].[equity.Assessment]
AS
SELECT DISTINCT [AssessmentKey]
    ,CONCAT_WS('-', [AssessmentKey], IdentificationCode, LearningStandard) AS [AssessmentIdentificationCodeKey]
    ,[AssessmentIdentifier]
    ,[Namespace]
    ,[Title]
    ,[Version]
    ,[Category]
    ,[AssessedGradeLevel]
    ,[AcademicSubject]
    ,LearningStandard
FROM [analytics].[asmt_AssessmentFact];
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [BI].[equity.StudentAssessmentScoreResult]
AS
SELECT DISTINCT aaf.AssessmentKey
    ,CONCAT_WS('-', aaf.[AssessmentKey], aaf.IdentificationCode, aaf.LearningStandard) AS [AssessmentIdentificationCodeKey]
    ,aaf.AssessmentIdentifier
    ,sa.StudentAssessmentKey
    ,sa.StudentAssessmentIdentifier
    ,sa.StudentSchoolKey
    ,CAST(sa.AdministrationDate AS DATE) AS AdministrationDate
    ,aaf.AssessedGradeLevel AS GradeLevel
    ,sa.ReportingMethod AS ReportingMethod
    ,sa.StudentScore AS Result
    ,sa.Namespace AS Namespace
    ,aaf.Version AS Version
    ,sa.PerformanceResult
FROM analytics.asmt_StudentAssessmentFact sa
INNER JOIN analytics.asmt_AssessmentFact aaf ON sa.AssessmentKey = aaf.AssessmentKey
    AND sa.ObjectiveAssessmentKey = aaf.ObjectiveAssessmentKey
    AND sa.AssessedGradeLevel = aaf.AssessedGradeLevel
    AND sa.ReportingMethod = aaf.ReportingMethod
WHERE sa.ReportingMethod IN ('Raw Score');
GO


