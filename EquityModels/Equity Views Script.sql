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

SELECT s.UserKey
    ,s.StaffSectionKey
    ,s.SectionKey
    ,s.PersonalTitlePrefix
    ,CONCAT (
        s.StaffLastName
        ,', '
        ,s.StaffFirstName
        ) AS StaffName
    ,s.BirthDate
    ,CASE 
        WHEN s.HispanicLatinoEthnicity = 1
            THEN 'True'
        ELSE 'False'
        END AS HispanicLatinoEthnicity
	,s.Sex
	,s.Race
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

-- Student Demographics: Ethnicity/Race
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [BI].[equity.Ethnicity_Race]
AS 
SELECT
	StudentSchoolDemographicBridgeKey
	,StudentSchoolDemographicsBridge.StudentSchoolKey
	,StudentSchoolDim.SchoolKey
	,DemographicDim.DemographicKey
	,DemographicLabel
FROM
	analytics.StudentSchoolDemographicsBridge
INNER JOIN
	analytics.DemographicDim ON
		StudentSchoolDemographicsBridge.DemographicKey = DemographicDim.DemographicKey
INNER JOIN analytics.StudentSchoolDim 
ON StudentSchoolDemographicsBridge.StudentSchoolKey = StudentSchoolDim.StudentSchoolKey
WHERE
	DemographicParentKey = 'Race';
GO

-- Gender
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [BI].[equity.StudentGender]
AS
SELECT
	StudentSchoolKey
	,CONCAT(Sex, '-', StudentSchoolKey) AS StudentSchoolKeyGenderKey
	,StudentKey
	,SchoolKey
	,Sex AS Gender
FROM
	analytics.StudentSchoolDim;
GO

-- Residence Zip Code
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- For now we are returning the full address. 
-- Talked with David Clements, and we can add this individual field to ContactPersonDim, then change this to return it, instead of the ContactHomeAddress
CREATE OR ALTER VIEW [BI].[equity.ResidenceZipCode]
AS
SELECT
	CONCAT(Student.StudentUniqueId, '-', StudentSchoolAssociation.SchoolId) AS StudentSchoolKey
	,StudentSchoolAssociation.SchoolId AS SchoolKey
	,StudentKey
	,ContactHomeAddress
FROM
	analytics.ContactPersonDim
INNER JOIN
	edfi.Student ON
		ContactPersonDim.StudentKey = Student.StudentUniqueId
INNER JOIN
    edfi.StudentSchoolAssociation ON
		Student.StudentUSI = StudentSchoolAssociation.StudentUSI
INNER JOIN
	edfi.Descriptor ON
	    StudentSchoolAssociation.EntryGradeLevelDescriptorId = Descriptor.DescriptorId
INNER JOIN
    edfi.School ON
	    StudentSchoolAssociation.SchoolId = School.SchoolId
WHERE
	IsPrimaryContact = 1;
GO

-- Age
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- We currently don't have a field with the date of birth. 
-- We can include it in the StudentSchoolDim. Talked to David and this is fine.
-- Then we need to change this view to use this new field.
CREATE OR ALTER VIEW [BI].[equity.StudentAge]
AS
SELECT
	CONCAT(Student.StudentUniqueId, '-', StudentSchoolAssociation.SchoolId) AS StudentSchoolKey
	,Student.StudentUniqueId as StudentKey
	,StudentSchoolAssociation.SchoolId as SchoolKey
	,DATEDIFF(hour,Student.BirthDate,GETDATE())/8766 AS StudentAge
FROM
	edfi.Student
INNER JOIN
    edfi.StudentSchoolAssociation ON
		Student.StudentUSI = StudentSchoolAssociation.StudentUSI
INNER JOIN
	edfi.Descriptor ON
	    StudentSchoolAssociation.EntryGradeLevelDescriptorId = Descriptor.DescriptorId
INNER JOIN
    edfi.School ON
	    StudentSchoolAssociation.SchoolId = School.SchoolId
GO

-- Linch Status
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- This is data that we currently don't have in AMT. 
-- We will need to figure out what the best way in include this data is.
-- Looks like a new candidate to be included in the new Equity collection.
CREATE OR ALTER VIEW [BI].[equity.LunchStatus]
AS 
SELECT
	CONCAT(Student.StudentUniqueId, '-', StudentSchoolAssociation.SchoolId) AS StudentSchoolKey
	,StudentSchoolFoodServiceProgramAssociation.ProgramName
	,ProgramTypeDescriptor.CodeValue as ProgramTypeDescriptor
	,SchoolFoodServiceProgramServiceDescriptor.Description as SchoolFoodServiceProgramServiceDescriptor --This is the field we are interested in, for the lunch status filter.
FROM 
	edfi.StudentSchoolFoodServiceProgramAssociation
INNER JOIN	
	edfi.Descriptor ProgramTypeDescriptor ON
		StudentSchoolFoodServiceProgramAssociation.ProgramTypeDescriptorId = ProgramTypeDescriptor.DescriptorId
INNER JOIN
	edfi.StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService ON
		StudentSchoolFoodServiceProgramAssociation.BeginDate = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.BeginDate
		AND StudentSchoolFoodServiceProgramAssociation.EducationOrganizationId = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.EducationOrganizationId
		AND StudentSchoolFoodServiceProgramAssociation.ProgramEducationOrganizationId = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.ProgramEducationOrganizationId
		AND StudentSchoolFoodServiceProgramAssociation.ProgramName = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.ProgramName
		AND StudentSchoolFoodServiceProgramAssociation.ProgramTypeDescriptorId = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.ProgramTypeDescriptorId
		AND StudentSchoolFoodServiceProgramAssociation.StudentUSI = StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.StudentUSI
INNER JOIN 
	edfi.GeneralStudentProgramAssociation ON
		StudentSchoolFoodServiceProgramAssociation.BeginDate = GeneralStudentProgramAssociation.BeginDate
		AND StudentSchoolFoodServiceProgramAssociation.EducationOrganizationId = GeneralStudentProgramAssociation.EducationOrganizationId
		AND StudentSchoolFoodServiceProgramAssociation.ProgramEducationOrganizationId = GeneralStudentProgramAssociation.ProgramEducationOrganizationId
		AND StudentSchoolFoodServiceProgramAssociation.ProgramName = GeneralStudentProgramAssociation.ProgramName
		AND StudentSchoolFoodServiceProgramAssociation.ProgramTypeDescriptorId = GeneralStudentProgramAssociation.ProgramTypeDescriptorId
		AND StudentSchoolFoodServiceProgramAssociation.StudentUSI = GeneralStudentProgramAssociation.StudentUSI
INNER JOIN
	edfi.Descriptor SchoolFoodServiceProgramServiceDescriptor ON
		StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.SchoolFoodServiceProgramServiceDescriptorId = SchoolFoodServiceProgramServiceDescriptor.DescriptorId
INNER JOIN
	edfi.Student ON
		GeneralStudentProgramAssociation.StudentUSI = Student.StudentUSI
INNER JOIN
    edfi.StudentSchoolAssociation ON
        Student.StudentUSI = StudentSchoolAssociation.StudentUSI
INNER JOIN
    edfi.Descriptor ON
        StudentSchoolAssociation.EntryGradeLevelDescriptorId = Descriptor.DescriptorId;
GO

-- Program Types.
-- Based on a conversation with David Clements, we are removing 'ESE and 504 Status' filter and 'ELL Status' filter.
-- And instead of those, we are adding a Program Type filter.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [BI].[equity.ProgramTypes]
AS
SELECT
	CONCAT(Student.StudentUniqueId, '-', StudentSchoolAssociation.SchoolId) AS StudentSchoolKey
	,Student.StudentUniqueId as StudentKey
	,StudentSchoolAssociation.SchoolId as SchoolKey
	,Program.ProgramName
	,Descriptor.Description as ProgramType --This is the field we need for the filter.
FROM
	edfi.Program
INNER JOIN
    edfi.ProgramTypeDescriptor ON
		Program.ProgramTypeDescriptorId = ProgramTypeDescriptor.ProgramTypeDescriptorId
INNER JOIN
	edfi.Descriptor ON
		ProgramTypeDescriptor.ProgramTypeDescriptorId = Descriptor.DescriptorId
INNER JOIN
    [edfi].[StudentProgramAssociation] StudentProgram ON 
		StudentProgram.ProgramName = Program.ProgramName
		AND StudentProgram.ProgramTypeDescriptorId = Program.ProgramTypeDescriptorId
		AND StudentProgram.ProgramEducationOrganizationId = Program.EducationOrganizationId
INNER JOIN 
    edfi.Student ON 
		StudentProgram.StudentUSI = Student.StudentUSI
INNER JOIN 
    edfi.StudentSchoolAssociation ON 
		Student.StudentUSI = edfi.StudentSchoolAssociation.StudentUSI
GO

-- Feeder School
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- This is data that we currently don't have in AMT. 
-- We will need to figure out what the best way in include this data is.
-- Looks like a new candidate to be included in the new Equity collection.
CREATE OR ALTER VIEW [BI].[equity.FeederSchool]
AS
SELECT
	SchoolKey
	,FeederSchoolKey
	,FeederSchoolName
FROM
    analytics.equity_FeederSchoolDim
GO

-- Student Programs
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [BI].[equity.StudentPrograms]
AS
SELECT
	BeginDate
	,EducationOrganizationId
	,ProgramName
	,StudentUSI
	,StudentSchoolKey
FROM
	[analytics].[StudentProgramDim]
GO

-- Cohort
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- This is data that we currently don't have in AMT. 
-- We will need to figure out what the best way in include this data is.
-- Looks like a new candidate to be included in the new Equity collection.
CREATE OR ALTER VIEW [BI].[equity.Cohort]
AS
SELECT
	StudentSchoolKey
	,CohortDescription
	,ProgramName
FROM
	analytics.equity_StudentProgramCohortDim
GO

-- Discipline Actions
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- This is data that we currently don't have in AMT. 
-- We will need to figure out what the best way in include this data is.
-- Looks like a candidate to be included in the new Equity collection.
CREATE OR ALTER VIEW [BI].[equity.DisciplineAction]
AS
SELECT StudentDisciplineActionKey
    ,StudentSchoolKey
    ,DisciplineDateKey
    ,StudentKey
    ,SchoolKey
    ,DisciplineActionDescription
    ,UserKey
    ,LastModifiedDate
FROM analytics.equity_StudentDisciplineActionDim;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [BI].[equity.StudentHistory]
AS
SELECT 
    StudentKey,
    StudentSchoolKey,
    GradeSummary,
    CurrentSchoolKey,
    AttendanceRate,
    ReferralsAndSuspensions,
    EnrollmentHistory
FROM 
    analytics.equity_StudentHistoryDim

