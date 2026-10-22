/*
================================================================================
   UNIVERSITY MANAGEMENT SYSTEM - ANALYTICAL EXAMPLE QUERIES
================================================================================
   Database : University_DB (see SQl.sql / university_database_setup.sql)
   Engine   : Microsoft SQL Server (T-SQL)
   Purpose  : Example analytical queries over the university schema, covering
              academic performance, faculty workload, research activity, and
              campus life. These mirror the KPIs shown in the Power BI report.
================================================================================
*/

USE University_DB;
GO

--------------------------------------------------------------------------------
-- 1. Average grade and enrollment count per department
--------------------------------------------------------------------------------
SELECT
    d.DeptName,
    COUNT(e.EnrollmentID)                              AS TotalEnrollments,
    COUNT(DISTINCT e.StudentID)                        AS UniqueStudents,
    CAST(AVG(e.Grade) AS DECIMAL(5, 2))                AS AvgGrade
FROM Department d
LEFT JOIN Student s            ON s.DeptID = d.DeptID
LEFT JOIN Course_Enrollment e  ON e.StudentID = s.StudentID
GROUP BY d.DeptName
ORDER BY AvgGrade DESC;
GO

--------------------------------------------------------------------------------
-- 2. Top 10 students by average grade (students with at least one graded course)
--------------------------------------------------------------------------------
SELECT TOP 10
    s.StudentID,
    s.FirstName + ' ' + s.LastName                     AS StudentName,
    d.DeptName,
    COUNT(e.EnrollmentID)                              AS CoursesTaken,
    CAST(AVG(e.Grade) AS DECIMAL(5, 2))                AS AvgGrade
FROM Student s
JOIN Course_Enrollment e ON e.StudentID = s.StudentID
JOIN Department d        ON d.DeptID = s.DeptID
WHERE e.Grade IS NOT NULL
GROUP BY s.StudentID, s.FirstName, s.LastName, d.DeptName
ORDER BY AvgGrade DESC;
GO

--------------------------------------------------------------------------------
-- 3. Most challenging courses (lowest average grade, minimum 3 enrollments)
--------------------------------------------------------------------------------
SELECT TOP 10
    c.CourseID,
    c.CourseName,
    d.DeptName,
    COUNT(e.EnrollmentID)                              AS Enrollments,
    CAST(AVG(e.Grade) AS DECIMAL(5, 2))                AS AvgGrade
FROM Course c
JOIN Course_Enrollment e ON e.CourseID = c.CourseID
JOIN Department d        ON d.DeptID = c.DeptID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.CourseName, d.DeptName
HAVING COUNT(e.EnrollmentID) >= 3
ORDER BY AvgGrade ASC;
GO

--------------------------------------------------------------------------------
-- 4. Grade trend by semester and academic year
--------------------------------------------------------------------------------
SELECT
    e.AcademicYear,
    e.Semester,
    COUNT(e.EnrollmentID)                              AS Enrollments,
    CAST(AVG(e.Grade) AS DECIMAL(5, 2))                AS AvgGrade
FROM Course_Enrollment e
WHERE e.Grade IS NOT NULL
GROUP BY e.AcademicYear, e.Semester
ORDER BY e.AcademicYear, e.Semester;
GO

--------------------------------------------------------------------------------
-- 5. Student-to-faculty ratio per department
--------------------------------------------------------------------------------
SELECT
    d.DeptName,
    COUNT(DISTINCT s.StudentID)                        AS Students,
    COUNT(DISTINCT p.ProfID)                           AS Faculty,
    CAST(COUNT(DISTINCT s.StudentID) * 1.0
         / NULLIF(COUNT(DISTINCT p.ProfID), 0)
         AS DECIMAL(6, 2))                             AS StudentFacultyRatio
FROM Department d
LEFT JOIN Student s   ON s.DeptID = d.DeptID
LEFT JOIN Professor p ON p.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY StudentFacultyRatio DESC;
GO

--------------------------------------------------------------------------------
-- 6. Faculty teaching load (courses per professor)
--------------------------------------------------------------------------------
SELECT
    p.ProfID,
    p.FirstName + ' ' + p.LastName                     AS ProfessorName,
    d.DeptName,
    COUNT(c.CourseID)                                  AS CoursesTaught,
    SUM(c.Credits)                                     AS TotalCredits
FROM Professor p
LEFT JOIN Course c    ON c.ProfID = p.ProfID
LEFT JOIN Department d ON d.DeptID = p.DeptID
GROUP BY p.ProfID, p.FirstName, p.LastName, d.DeptName
ORDER BY CoursesTaught DESC;
GO

--------------------------------------------------------------------------------
-- 7. Research activity: projects, budgets, and student researchers per professor
--------------------------------------------------------------------------------
SELECT
    p.FirstName + ' ' + p.LastName                     AS LeadProfessor,
    COUNT(DISTINCT rp.ProjectID)                       AS Projects,
    SUM(rp.Budget)                                     AS TotalBudget,
    COUNT(DISTINCT spc.StudentID)                      AS StudentResearchers,
    SUM(spc.WeeklyHours)                               AS TotalWeeklyHours
FROM Research_Project rp
JOIN Professor p                    ON p.ProfID = rp.LeadProfessorID
LEFT JOIN Student_Project_Collaboration spc
       ON spc.ProjectID = rp.ProjectID
GROUP BY p.FirstName, p.LastName
ORDER BY TotalBudget DESC;
GO

--------------------------------------------------------------------------------
-- 8. Club participation: members and leadership roles per club
--------------------------------------------------------------------------------
SELECT
    c.ClubName,
    c.Category,
    COUNT(cm.StudentID)                                AS Members,
    SUM(CASE WHEN cm.MemberRole <> 'Member'
             THEN 1 ELSE 0 END)                        AS LeadershipRoles
FROM Club c
LEFT JOIN Club_Membership cm ON cm.ClubID = c.ClubID
GROUP BY c.ClubName, c.Category
ORDER BY Members DESC;
GO

--------------------------------------------------------------------------------
-- 9. Students with no club membership (NOT EXISTS pattern)
--------------------------------------------------------------------------------
SELECT
    s.StudentID,
    s.FirstName + ' ' + s.LastName AS StudentName,
    d.DeptName
FROM Student s
JOIN Department d ON d.DeptID = s.DeptID
WHERE NOT EXISTS (
    SELECT 1
    FROM Club_Membership cm
    WHERE cm.StudentID = s.StudentID
);
GO

--------------------------------------------------------------------------------
-- 10. Library usage: most borrowed books and outstanding late fees
--------------------------------------------------------------------------------
SELECT TOP 10
    b.Title,
    b.Author,
    l.LibraryName,
    COUNT(bb.BorrowID)                                 AS TimesBorrowed,
    SUM(bb.LateFee)                                    AS TotalLateFees
FROM Book b
JOIN Library l        ON l.LibraryID = b.LibraryID
LEFT JOIN Book_Borrowing bb ON bb.BookID = b.BookID
GROUP BY b.Title, b.Author, l.LibraryName
ORDER BY TimesBorrowed DESC;
GO

--------------------------------------------------------------------------------
-- 11. Overdue borrowings not yet returned
--------------------------------------------------------------------------------
SELECT
    s.FirstName + ' ' + s.LastName AS StudentName,
    b.Title,
    bb.BorrowDate,
    bb.DueDate,
    DATEDIFF(DAY, bb.DueDate, CAST(GETDATE() AS DATE)) AS DaysOverdue
FROM Book_Borrowing bb
JOIN Student s ON s.StudentID = bb.StudentID
JOIN Book b    ON b.BookID = bb.BookID
WHERE bb.ReturnDate IS NULL
  AND bb.DueDate < CAST(GETDATE() AS DATE)
ORDER BY DaysOverdue DESC;
GO

--------------------------------------------------------------------------------
-- 12. University ID cards expiring within 90 days
--------------------------------------------------------------------------------
SELECT
    s.FirstName + ' ' + s.LastName AS StudentName,
    u.CardNumber,
    u.CardStatus,
    u.ExpiryDate
FROM University_ID u
JOIN Student s ON s.StudentID = u.StudentID
WHERE u.CardStatus = 'Active'
  AND u.ExpiryDate <= DATEADD(DAY, 90, CAST(GETDATE() AS DATE))
ORDER BY u.ExpiryDate;
GO
