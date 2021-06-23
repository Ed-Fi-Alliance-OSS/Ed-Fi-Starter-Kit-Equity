# Equity Metrics and Measures

## Student

### Student Age

To calculate the StudentAge in years, you can use this query.

```sql
SELECT
    DATEDIFF(hour,StudentSchoolDim.BirthDate,GETDATE())/8766 AS StudentAge
    , StudentSchoolKey
FROM
    analytics.StudentSchoolDim
```

## Student History

### Attendance History

To calculate the Attendance Rate, the Equity Starter Kit queries DaysEnrolled
and DaysAbsent from analytics.chrab_ChronicAbsenteeismAttendanceFact. Chronic
Absenteeism assumes the Texas model of counting attendance by home room, and it
assumes that attendance is being handle "negatively": that is, a student is
assumed present unless marked as absent.

```sql
SELECT StudentKey
        ,SchoolKey
        ,COUNT(1) AS DaysEnrolled
        ,SUM(ReportedAsAbsentFromHomeRoom) AS DaysAbsent
    FROM analytics.chrab_ChronicAbsenteeismAttendanceFact
    GROUP BY StudentKey
            ,SchoolKey;
```

#### Attendance Rate

With the values of DaysEnrolled and DaysAbsent, the calculation is performed to
obtain the AttendanceRate of each student.

```math
AttendanceRate = 100*((DaysEnrolled - DaysAbsent) / DaysEnrolled)
```

SQL Query

```sql
WITH AttendanceHist
AS (
    SELECT StudentKey
        ,SchoolKey
        ,COUNT(1) AS DaysEnrolled
        ,SUM(ReportedAsAbsentFromHomeRoom) AS DaysAbsent
    FROM analytics.chrab_ChronicAbsenteeismAttendanceFact
    GROUP BY StudentKey
        ,SchoolKey
    )
SELECT DISTINCT studentSchoolDim.StudentKey
    ,CAST((DaysEnrolled - DaysAbsent) AS DECIMAL) 
      / CAST(DaysEnrolled AS DECIMAL) * 100 AS AttendanceRate
FROM analytics.StudentSchoolDim studentSchoolDim
LEFT OUTER JOIN AttendanceHist ah 
    ON ah.StudentKey = studentSectionDim.StudentKey 
        AND ah.SchoolKey = studentSectionDim.SchoolKey;
```

### Referrals and Suspensions

To calculate total referrals and suspensions, you can use the
analytics.equity_StudentDisciplineActionDim view and filter on the
StudentSchoolKey to get the value for a specific user. 

```sql
SELECT COUNT(1) AS ReferralsAndSuspensions
        ,StudentSchoolKey
FROM analytics.equity_StudentDisciplineActionDim
Group By StudentSchoolKey;
```

