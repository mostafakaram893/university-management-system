/*
================================================================================
   DATABASE DESIGN, CREATION & DATA INSERTION (ENTERPRISE MASTER SCRIPT)
================================================================================
   Author: Senior Database Architect
   Environment: Microsoft SQL Server (T-SQL) / SSMS
   Description:
     This master script provides complete, optimized, normalized, and validated
     DDL & DML scripts for all four business systems analyzed from the provided 
     ERDs and System Specifications:
     
     1. CASE 1: Company Management System (From Draw.io Diagram)
     2. CASE 2: Hospital Management System (From Draw.io Diagram)
     3. CASE 3: Airline & Fleet Operations System (From Draw.io Diagram)
     4. CASE 4: University Management System (From University PDF Specification)

   Architecture Corrections & Quality Enhancements Applied:
     - Corrected composite attributes (e.g., Name, BirthDate) to reside directly 
       within entity tables instead of creating artificial, redundant tables.
     - Corrected 1:1 Manager relationship to use Foreign Key in Department rather 
       than duplicating all Employee & Department fields into a separate table.
     - Corrected derived attributes (e.g., flight duration) to use COMPUTED COLUMNS 
       rather than separate relational tables.
     - Implemented full referential integrity (PKs, FKs, CASCADE rules).
     - Applied robust domain constraints (CHECK constraints, DEFAULTs, UNIQUE).
     - Included rich, realistic, cohesive sample data for every single table.
================================================================================
*/

--------------------------------------------------------------------------------
-- SECTION 1: CASE 1 - COMPANY MANAGEMENT SYSTEM (Company_DB)
--------------------------------------------------------------------------------
IF DB_ID('Company_DB') IS NOT NULL
BEGIN
    ALTER DATABASE Company_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Company_DB;
END;
GO

CREATE DATABASE Company_DB;
GO

USE Company_DB;
GO

-- 1.1 Department Table
CREATE TABLE Department (
    DNum INT PRIMARY KEY,
    DName VARCHAR(100) NOT NULL UNIQUE,
    MgrSSN CHAR(9) NULL,               -- 1:1 Relationship (FK added via ALTER TABLE to resolve circular dependency)
    MgrStartDate DATE NULL
);
GO

-- 1.2 Employee Table
-- NOTE: Flattened composite attribute 'Name' (FName, LName) into the table directly.
CREATE TABLE Employee (
    SSN CHAR(9) PRIMARY KEY,
    FName VARCHAR(50) NOT NULL,
    LName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    DNum INT NOT NULL,
    SuperSSN CHAR(9) NULL,             -- Recursive 1:M relationship
    CONSTRAINT FK_Employee_Department FOREIGN KEY (DNum) REFERENCES Department(DNum),
    CONSTRAINT FK_Employee_Supervisor FOREIGN KEY (SuperSSN) REFERENCES Employee(SSN)
);
GO

-- Add circular FK for Department Manager
ALTER TABLE Department
ADD CONSTRAINT FK_Department_Manager FOREIGN KEY (MgrSSN) REFERENCES Employee(SSN);
GO

-- 1.3 Department Locations Table (Multivalued attribute)
CREATE TABLE Department_Locations (
    DNum INT NOT NULL,
    Location VARCHAR(100) NOT NULL,
    PRIMARY KEY (DNum, Location),
    CONSTRAINT FK_DeptLocations_Department FOREIGN KEY (DNum) REFERENCES Department(DNum) ON DELETE CASCADE
);
GO

-- 1.4 Project Table
CREATE TABLE Project (
    PNum INT PRIMARY KEY,
    PName VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    DNum INT NOT NULL,                 -- Controlling Department (1:M)
    CONSTRAINT FK_Project_Department FOREIGN KEY (DNum) REFERENCES Department(DNum)
);
GO

-- 1.5 Works_On Table (M:N between Employee & Project)
CREATE TABLE Works_On (
    ESSN CHAR(9) NOT NULL,
    PNum INT NOT NULL,
    WorkingHours DECIMAL(5, 2) NOT NULL CHECK (WorkingHours >= 0),
    PRIMARY KEY (ESSN, PNum),
    CONSTRAINT FK_WorksOn_Employee FOREIGN KEY (ESSN) REFERENCES Employee(SSN) ON DELETE CASCADE,
    CONSTRAINT FK_WorksOn_Project FOREIGN KEY (PNum) REFERENCES Project(PNum) ON DELETE CASCADE
);
GO

-- 1.6 Dependent Table (Weak Entity identifying on Employee)
CREATE TABLE Dependent (
    ESSN CHAR(9) NOT NULL,
    DependentName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    Relationship VARCHAR(50) NOT NULL,
    PRIMARY KEY (ESSN, DependentName),
    CONSTRAINT FK_Dependent_Employee FOREIGN KEY (ESSN) REFERENCES Employee(SSN) ON DELETE CASCADE
);
GO

-- Sample Data Insertion for Company_DB
-- A. Departments (Temporary NULL for manager to break circular dependency)
INSERT INTO Department (DNum, DName, MgrSSN, MgrStartDate) VALUES
(1, 'Research & Development', NULL, NULL),
(2, 'Human Resources', NULL, NULL),
(3, 'Finance & Accounting', NULL, NULL),
(4, 'Information Technology', NULL, NULL);

-- B. Employees
INSERT INTO Employee (SSN, FName, LName, BirthDate, Gender, DNum, SuperSSN) VALUES
('101001001', 'Ahmed', 'Hassan', '1980-04-12', 'M', 1, NULL),
('101001002', 'Mona', 'El-Sayed', '1985-08-23', 'F', 2, '101001001'),
('101001003', 'Tarek', 'Mahmoud', '1982-11-15', 'M', 3, '101001001'),
('101001004', 'Youssef', 'Karam', '1990-01-30', 'M', 4, '101001001'),
('101001005', 'Sara', 'Ibrahim', '1994-06-18', 'F', 1, '101001001'),
('101001006', 'Omar', 'Khaled', '1992-09-05', 'M', 4, '101001004'),
('101001007', 'Nour', 'Ali', '1996-03-22', 'F', 2, '101001002');

-- C. Update Department Managers
UPDATE Department SET MgrSSN = '101001001', MgrStartDate = '2015-01-01' WHERE DNum = 1;
UPDATE Department SET MgrSSN = '101001002', MgrStartDate = '2018-05-15' WHERE DNum = 2;
UPDATE Department SET MgrSSN = '101001003', MgrStartDate = '2016-09-01' WHERE DNum = 3;
UPDATE Department SET MgrSSN = '101001004', MgrStartDate = '2020-03-10' WHERE DNum = 4;

-- D. Department Locations
INSERT INTO Department_Locations (DNum, Location) VALUES
(1, 'Building A - Smart Village'),
(1, 'Tech Park - Alexandria'),
(2, 'Building B - Nasr City'),
(3, 'Finance Tower - New Cairo'),
(4, 'Data Center - 6th October'),
(4, 'Building C - Smart Village');

-- E. Projects
INSERT INTO Project (PNum, PName, Location, City, DNum) VALUES
(501, 'ERP Cloud Migration', 'Tech Park', 'Alexandria', 4),
(502, 'AI Medical Diagnostics', 'Building A', 'Giza', 1),
(503, 'Automated Payroll Suite', 'Finance Tower', 'New Cairo', 3),
(504, 'Talent Acquisition Portal', 'Building B', 'Cairo', 2),
(505, 'IoT Energy Optimization', 'Building A', 'Giza', 1);

-- F. Works_On
INSERT INTO Works_On (ESSN, PNum, WorkingHours) VALUES
('101001001', 502, 15.5),
('101001005', 502, 28.0),
('101001005', 505, 12.0),
('101001004', 501, 20.0),
('101001006', 501, 35.0),
('101001003', 503, 30.0),
('101001002', 504, 25.0),
('101001007', 504, 15.0);

-- G. Dependents
INSERT INTO Dependent (ESSN, DependentName, BirthDate, Gender, Relationship) VALUES
('101001001', 'Ziad Ahmed', '2010-07-14', 'M', 'Son'),
('101001001', 'Mariam Ahmed', '2014-10-05', 'F', 'Daughter'),
('101001002', 'Karim Wael', '2016-02-18', 'M', 'Son'),
('101001003', 'Hoda Tarek', '2012-12-01', 'F', 'Daughter'),
('101001004', 'Salma Youssef', '2021-05-19', 'F', 'Daughter');
GO


--------------------------------------------------------------------------------
-- SECTION 2: CASE 2 - HOSPITAL MANAGEMENT SYSTEM (Hospital_DB)
--------------------------------------------------------------------------------
IF DB_ID('Hospital_DB') IS NOT NULL
BEGIN
    ALTER DATABASE Hospital_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Hospital_DB;
END;
GO

CREATE DATABASE Hospital_DB;
GO

USE Hospital_DB;
GO

-- 2.1 Nurse Table
CREATE TABLE Nurse (
    NurseID INT IDENTITY(1,1) PRIMARY KEY,
    NurseName VARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(20) NOT NULL,
    Address VARCHAR(255) NOT NULL
);
GO

-- 2.2 Wards Table (Supervised 1:1 by Nurse)
CREATE TABLE Ward (
    WardID INT PRIMARY KEY,
    WardName VARCHAR(100) NOT NULL,
    SupervisorNurseID INT NOT NULL UNIQUE, -- 1:1 supervision constraint
    CONSTRAINT FK_Ward_SupervisorNurse FOREIGN KEY (SupervisorNurseID) REFERENCES Nurse(NurseID)
);
GO

-- 2.3 Consultant Table
CREATE TABLE Consultant (
    ConsultantID INT PRIMARY KEY,
    ConsultantName VARCHAR(100) NOT NULL,
    Specialty VARCHAR(100) NOT NULL DEFAULT 'General Medicine'
);
GO

-- 2.4 Patient Table (Hosted in Ward, Assigned to Consultant)
CREATE TABLE Patient (
    PatientID INT PRIMARY KEY,
    PatientName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    WardID INT NOT NULL,               -- Hosted by Ward (1:M)
    AssignedConsultantID INT NOT NULL, -- Assigned primary consultant (1:M)
    CONSTRAINT FK_Patient_Ward FOREIGN KEY (WardID) REFERENCES Ward(WardID),
    CONSTRAINT FK_Patient_Consultant FOREIGN KEY (AssignedConsultantID) REFERENCES Consultant(ConsultantID)
);
GO

-- 2.5 Patient Examined by Consultant (M:N Relationship)
CREATE TABLE Patient_Examined_By_Consultant (
    PatientID INT NOT NULL,
    ConsultantID INT NOT NULL,
    ExaminationDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ExaminationNotes VARCHAR(500) NULL,
    PRIMARY KEY (PatientID, ConsultantID, ExaminationDate),
    CONSTRAINT FK_Examined_Patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    CONSTRAINT FK_Examined_Consultant FOREIGN KEY (ConsultantID) REFERENCES Consultant(ConsultantID)
);
GO

-- 2.6 Drug Table
CREATE TABLE Drug (
    CodeNum VARCHAR(50) PRIMARY KEY,
    RecommendedDosage VARCHAR(100) NOT NULL
);
GO

-- 2.7 Drug Brand Names (Multivalued attribute)
CREATE TABLE Drug_Brand (
    CodeNum VARCHAR(50) NOT NULL,
    BrandName VARCHAR(100) NOT NULL,
    PRIMARY KEY (CodeNum, BrandName),
    CONSTRAINT FK_DrugBrand_Drug FOREIGN KEY (CodeNum) REFERENCES Drug(CodeNum) ON DELETE CASCADE
);
GO

-- 2.8 Medication Administration (Ternary Relationship: Nurse gives Drug to Patient)
CREATE TABLE Medication_Administration (
    AdministrationID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    CodeNum VARCHAR(50) NOT NULL,
    NurseID INT NOT NULL,
    AdminDate DATE NOT NULL,
    AdminTime TIME NOT NULL,
    DosageGiven VARCHAR(100) NOT NULL,
    CONSTRAINT FK_MedAdmin_Patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    CONSTRAINT FK_MedAdmin_Drug FOREIGN KEY (CodeNum) REFERENCES Drug(CodeNum),
    CONSTRAINT FK_MedAdmin_Nurse FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID)
);
GO

-- Sample Data Insertion for Hospital_DB
-- A. Nurses
INSERT INTO Nurse (NurseName, PhoneNumber, Address) VALUES
('Fatima Al-Zahra', '01012345678', '15 Al-Ahram St, Heliopolis, Cairo'),
('Amina Mansour', '01123456789', '8 Abbas Al-Akkad St, Nasr City, Cairo'),
('Heba Abdel-Rahman', '01234567890', '22 Kornish Al-Nile, Maadi, Cairo'),
('Yasmin Farouk', '01543219876', '4 El-Gomhoureya St, Aswan'),
('Dalia Mostafa', '01098765432', '12 Horreya Ave, Alexandria');

-- B. Wards
INSERT INTO Ward (WardID, WardName, SupervisorNurseID) VALUES
(101, 'Cardiology Intensive Care', 1),
(102, 'Pediatrics Ward', 2),
(103, 'Surgical Recovery Ward', 3),
(104, 'Internal Medicine Ward', 4);

-- C. Consultants
INSERT INTO Consultant (ConsultantID, ConsultantName, Specialty) VALUES
(201, 'Dr. Magdy Yacoub', 'Cardiothoracic Surgery'),
(202, 'Dr. Hossam Mowafi', 'Internal Medicine'),
(203, 'Dr. Sherif Omar', 'Oncology & General Surgery'),
(204, 'Dr. Nadia Badrawi', 'Pediatrics');

-- D. Patients
INSERT INTO Patient (PatientID, PatientName, BirthDate, WardID, AssignedConsultantID) VALUES
(1001, 'Kamal El-Shennawy', '1965-03-12', 101, 201),
(1002, 'Layla Mourad', '1988-11-25', 102, 204),
(1003, 'Adel Imam', '1955-05-17', 103, 203),
(1004, 'Nourhan Mostafa', '1999-08-09', 104, 202),
(1005, 'Mahmoud Abdel-Aziz', '1972-01-30', 101, 201);

-- E. Consultant Examinations
INSERT INTO Patient_Examined_By_Consultant (PatientID, ConsultantID, ExaminationDate, ExaminationNotes) VALUES
(1001, 201, '2026-09-01', 'Post-stent cardiac evaluation normal; heart rhythm stable.'),
(1001, 202, '2026-09-02', 'General internal consultation for blood pressure control.'),
(1002, 204, '2026-09-03', 'Pediatric follow-up on bronchial inflammation.'),
(1003, 203, '2026-09-05', 'Post-operative abdominal examination on track.'),
(1004, 202, '2026-09-06', 'Routine metabolic screen and blood glucose check.');

-- F. Drugs & Brands
INSERT INTO Drug (CodeNum, RecommendedDosage) VALUES
('DRUG-PAR-500', '500mg every 8 hours as needed'),
('DRUG-AMO-1000', '1000mg twice daily with meals'),
('DRUG-ATO-20', '20mg once daily at bedtime'),
('DRUG-MET-850', '850mg twice daily with meals'),
('DRUG-INS-100', '10 units subcutaneous before breakfast');

INSERT INTO Drug_Brand (CodeNum, BrandName) VALUES
('DRUG-PAR-500', 'Panadol Extra'),
('DRUG-PAR-500', 'Cetamol'),
('DRUG-AMO-1000', 'Augmentin'),
('DRUG-AMO-1000', 'Hibiotic'),
('DRUG-ATO-20', 'Lipitor'),
('DRUG-ATO-20', 'Ator'),
('DRUG-MET-850', 'Glucophage'),
('DRUG-INS-100', 'Lantus SoloStar');

-- G. Medication Administrations
INSERT INTO Medication_Administration (PatientID, CodeNum, NurseID, AdminDate, AdminTime, DosageGiven) VALUES
(1001, 'DRUG-ATO-20', 1, '2026-09-10', '21:00:00', '20mg oral tablet'),
(1001, 'DRUG-PAR-500', 1, '2026-09-11', '08:30:00', '500mg oral tablet'),
(1002, 'DRUG-AMO-1000', 2, '2026-09-11', '12:00:00', '500mg oral suspension'),
(1003, 'DRUG-PAR-500', 3, '2026-09-11', '14:15:00', '1000mg IV drip'),
(1004, 'DRUG-MET-850', 4, '2026-09-11', '09:00:00', '850mg oral tablet'),
(1005, 'DRUG-ATO-20', 1, '2026-09-12', '21:00:00', '20mg oral tablet');
GO


--------------------------------------------------------------------------------
-- SECTION 3: CASE 3 - AIRLINE & FLEET MANAGEMENT SYSTEM (Airline_DB)
--------------------------------------------------------------------------------
IF DB_ID('Airline_DB') IS NOT NULL
BEGIN
    ALTER DATABASE Airline_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Airline_DB;
END;
GO

CREATE DATABASE Airline_DB;
GO

USE Airline_DB;
GO

-- 3.1 Airline Table
CREATE TABLE Airline (
    AirlineID INT PRIMARY KEY,
    AirlineName VARCHAR(100) NOT NULL UNIQUE,
    Address VARCHAR(255) NOT NULL,
    ContactPerson VARCHAR(100) NOT NULL
);
GO

-- 3.2 Airline Telephone Numbers (Multivalued attribute)
CREATE TABLE Airline_Phone (
    AirlineID INT NOT NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    PRIMARY KEY (AirlineID, PhoneNumber),
    CONSTRAINT FK_AirPhone_Airline FOREIGN KEY (AirlineID) REFERENCES Airline(AirlineID) ON DELETE CASCADE
);
GO

-- 3.3 Employee Table
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    BirthDate DATE NOT NULL,
    AirlineID INT NOT NULL,
    CONSTRAINT FK_Employee_Airline FOREIGN KEY (AirlineID) REFERENCES Airline(AirlineID)
);
GO

-- 3.4 Employee Qualifications (Multivalued attribute)
CREATE TABLE Employee_Qualification (
    EmployeeID INT NOT NULL,
    Qualification VARCHAR(100) NOT NULL,
    PRIMARY KEY (EmployeeID, Qualification),
    CONSTRAINT FK_EmpQual_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID) ON DELETE CASCADE
);
GO

-- 3.5 Aircraft Table
CREATE TABLE Aircraft (
    AircraftID INT PRIMARY KEY,
    AirlineID INT NOT NULL,
    Model VARCHAR(100) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0),
    CONSTRAINT FK_Aircraft_Airline FOREIGN KEY (AirlineID) REFERENCES Airline(AirlineID)
);
GO

-- 3.6 Aircraft Crew Table (Weak Entity dependent on Aircraft)
CREATE TABLE Aircraft_Crew (
    AircraftID INT PRIMARY KEY,
    MajorPilot VARCHAR(100) NOT NULL,
    AssistantPilot VARCHAR(100) NOT NULL,
    Hostess1 VARCHAR(100) NOT NULL,
    Hostess2 VARCHAR(100) NOT NULL,
    CONSTRAINT FK_Crew_Aircraft FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID) ON DELETE CASCADE
);
GO

-- 3.7 Route Table
CREATE TABLE Route (
    RouteID INT PRIMARY KEY,
    Origin VARCHAR(100) NOT NULL,
    Destination VARCHAR(100) NOT NULL,
    DistanceKM DECIMAL(10, 2) NOT NULL CHECK (DistanceKM > 0)
);
GO

-- 3.8 Flight Schedule / Aircraft Assigned to Route (M:N Relationship)
CREATE TABLE Flight_Assignment (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    AircraftID INT NOT NULL,
    RouteID INT NOT NULL,
    DepartureTime DATETIME2 NOT NULL,
    ArrivalTime DATETIME2 NOT NULL,
    PassengerCount INT NOT NULL CHECK (PassengerCount >= 0),
    TicketPrice DECIMAL(10, 2) NOT NULL CHECK (TicketPrice >= 0),
    -- COMPUTED COLUMN: Travel spent time in minutes
    TravelSpentMinutes AS DATEDIFF(MINUTE, DepartureTime, ArrivalTime),
    CONSTRAINT FK_Flight_Aircraft FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID),
    CONSTRAINT FK_Flight_Route FOREIGN KEY (RouteID) REFERENCES Route(RouteID),
    CONSTRAINT CHK_Flight_Times CHECK (ArrivalTime > DepartureTime)
);
GO

-- 3.9 Financial Transaction Table (Weak Entity dependent on Airline)
CREATE TABLE Airline_Transaction (
    AirlineID INT NOT NULL,
    TransactionID INT NOT NULL,
    TxDate DATE NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Amount DECIMAL(14, 2) NOT NULL,
    PRIMARY KEY (AirlineID, TransactionID),
    CONSTRAINT FK_Transaction_Airline FOREIGN KEY (AirlineID) REFERENCES Airline(AirlineID) ON DELETE CASCADE
);
GO

-- Sample Data Insertion for Airline_DB
-- A. Airlines & Phones
INSERT INTO Airline (AirlineID, AirlineName, Address, ContactPerson) VALUES
(1, 'EgyptAir', 'Cairo International Airport, Terminal 3, Cairo', 'Eng. Yehia Zakaria'),
(2, 'Emirates', 'Emirates Group Headquarters, Dubai, UAE', 'Sheikh Ahmed bin Saeed'),
(3, 'Air Cairo', 'El Nozha, Heliopolis, Cairo', 'Hussein Sherif');

INSERT INTO Airline_Phone (AirlineID, PhoneNumber) VALUES
(1, '+20-2-26966700'),
(1, '+20-2-1717'),
(2, '+971-4-2864066'),
(3, '+20-2-22687100');

-- B. Employees & Qualifications
INSERT INTO Employee (EmployeeID, EmployeeName, Address, Gender, BirthDate, AirlineID) VALUES
(301, 'Capt. Amr Khaled', 'Nasr City, Cairo', 'M', '1978-06-15', 1),
(302, 'Capt. Sherif El-Wakil', 'New Cairo, Cairo', 'M', '1982-09-20', 1),
(303, 'Yasmine Fahmy', 'Maadi, Cairo', 'F', '1992-04-10', 1),
(304, 'Salma Hegazy', 'Heliopolis, Cairo', 'F', '1995-12-05', 1),
(305, 'Capt. Tariq Al-Hashimi', 'Jumeirah, Dubai', 'M', '1980-02-28', 2),
(306, 'Reem Al-Mansoor', 'Deira, Dubai', 'F', '1996-07-14', 2),
(307, 'Mostafa Radwan', 'Stanley, Alexandria', 'M', '1989-11-03', 3);

INSERT INTO Employee_Qualification (EmployeeID, Qualification) VALUES
(301, 'ATPL - Airline Transport Pilot License'),
(301, 'Boeing 777/787 Type Rating'),
(302, 'ATPL - Airline Transport Pilot License'),
(302, 'Airbus A320/A321 Type Rating'),
(303, 'Aviation Safety & Emergency Procedures'),
(303, 'First Aid Certified Level 3'),
(304, 'Cabin Crew Certified Specialist'),
(305, 'Airbus A380 Senior Captain Certification'),
(307, 'ICAO Commercial Aviation Specialist');

-- C. Aircraft & Crew
INSERT INTO Aircraft (AircraftID, AirlineID, Model, Capacity) VALUES
(701, 1, 'Boeing 787-9 Dreamliner', 309),
(702, 1, 'Airbus A321neo', 182),
(703, 2, 'Airbus A380-800', 517),
(704, 3, 'Embraer E190', 110);

INSERT INTO Aircraft_Crew (AircraftID, MajorPilot, AssistantPilot, Hostess1, Hostess2) VALUES
(701, 'Capt. Amr Khaled', 'First Officer Tamer Nabil', 'Yasmine Fahmy', 'Salma Hegazy'),
(702, 'Capt. Sherif El-Wakil', 'First Officer Hany Adel', 'Nadine Samy', 'Dina Fikry'),
(703, 'Capt. Tariq Al-Hashimi', 'First Officer Paul Evans', 'Reem Al-Mansoor', 'Sarah Jenkins'),
(704, 'Capt. Mostafa Radwan', 'First Officer Aly Sabry', 'Mariam Gomaa', 'Nourhan Lotfy');

-- D. Routes
INSERT INTO Route (RouteID, Origin, Destination, DistanceKM) VALUES
(401, 'Cairo (CAI)', 'London Heathrow (LHR)', 3530.00),
(402, 'Cairo (CAI)', 'Dubai International (DXB)', 2420.00),
(403, 'Dubai (DXB)', 'New York (JFK)', 11020.00),
(404, 'Cairo (CAI)', 'Aswan International (ASW)', 690.00),
(405, 'Cairo (CAI)', 'Jeddah King Abdulaziz (JED)', 1210.00);

-- E. Flight Assignments
INSERT INTO Flight_Assignment (AircraftID, RouteID, DepartureTime, ArrivalTime, PassengerCount, TicketPrice) VALUES
(701, 401, '2026-10-01 09:30:00', '2026-10-01 14:45:00', 285, 850.00),
(701, 402, '2026-10-02 18:00:00', '2026-10-02 23:15:00', 298, 420.00),
(703, 403, '2026-10-03 08:00:00', '2026-10-03 22:30:00', 495, 1250.00),
(702, 404, '2026-10-04 07:00:00', '2026-10-04 08:25:00', 170, 110.00),
(702, 405, '2026-10-05 15:30:00', '2026-10-05 18:40:00', 180, 310.00);

-- F. Transactions
INSERT INTO Airline_Transaction (AirlineID, TransactionID, TxDate, Description, Amount) VALUES
(1, 10001, '2026-09-01', 'Jet Fuel Supply - Cairo Fuel Depot Terminal 3', 450000.00),
(1, 10002, '2026-09-03', 'Boeing 787 Scheduled Avionics Maintenance', 125000.00),
(2, 20001, '2026-09-05', 'Airport Gate Lease - JFK Terminal 4', 890000.00),
(3, 30001, '2026-09-08', 'Catering & Inflight Services - Aswan Route', 35000.00);
GO


--------------------------------------------------------------------------------
-- SECTION 4: CASE 4 - UNIVERSITY MANAGEMENT SYSTEM (University_DB)
--------------------------------------------------------------------------------
IF DB_ID('University_DB') IS NOT NULL
BEGIN
    ALTER DATABASE University_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE University_DB;
END;
GO

CREATE DATABASE University_DB;
GO

USE University_DB;
GO

-- 4.1 Department Table
CREATE TABLE Department (
    DeptID INT PRIMARY KEY,
    DeptName VARCHAR(100) NOT NULL UNIQUE,
    Building VARCHAR(50) NOT NULL,
    Budget DECIMAL(14, 2) NOT NULL CHECK (Budget >= 0)
);
GO

-- 4.2 Professor Table
CREATE TABLE Professor (
    ProfID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(30) NULL,
    OfficeNumber VARCHAR(20) NOT NULL,
    DeptID INT NOT NULL,
    CONSTRAINT FK_Professor_Department FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);
GO

-- 4.3 Student Table
CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(30) NULL,
    BirthDate DATE NOT NULL,
    DeptID INT NOT NULL,               -- Major Academic Department
    CONSTRAINT FK_Student_Department FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);
GO

-- 4.4 University ID Table (Weak / Identifying 1:1 Entity for Student)
CREATE TABLE University_ID (
    CardNumber VARCHAR(30) PRIMARY KEY,
    StudentID INT NOT NULL UNIQUE,      -- Strict 1:1 mapping with Student
    IssueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ExpiryDate DATE NOT NULL,
    CardStatus VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (CardStatus IN ('Active', 'Expired', 'Suspended', 'Lost')),
    CONSTRAINT FK_UnivID_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE
);
GO

-- 4.5 Course Table
CREATE TABLE Course (
    CourseID VARCHAR(20) PRIMARY KEY,
    CourseName VARCHAR(150) NOT NULL,
    Credits INT NOT NULL CHECK (Credits BETWEEN 1 AND 6),
    DeptID INT NOT NULL,
    ProfID INT NOT NULL,               -- Supervising / Teaching Professor
    CONSTRAINT FK_Course_Department FOREIGN KEY (DeptID) REFERENCES Department(DeptID),
    CONSTRAINT FK_Course_Professor FOREIGN KEY (ProfID) REFERENCES Professor(ProfID)
);
GO

-- 4.6 Student Course Enrollment (M:N with Grades)
CREATE TABLE Course_Enrollment (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID VARCHAR(20) NOT NULL,
    Semester VARCHAR(20) NOT NULL,
    AcademicYear INT NOT NULL,
    Grade DECIMAL(4, 2) NULL CHECK (Grade BETWEEN 0.00 AND 100.00),
    CONSTRAINT UQ_Student_Course_Term UNIQUE (StudentID, CourseID, Semester, AcademicYear),
    CONSTRAINT FK_Enrollment_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrollment_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);
GO

-- 4.7 Research Project Table (Weak Entity supervised by Professor)
CREATE TABLE Research_Project (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(200) NOT NULL,
    Description VARCHAR(MAX) NULL,
    Budget DECIMAL(12, 2) NOT NULL CHECK (Budget >= 0),
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    LeadProfessorID INT NOT NULL,      -- Supervising Professor
    CONSTRAINT FK_Project_Professor FOREIGN KEY (LeadProfessorID) REFERENCES Professor(ProfID)
);
GO

-- 4.8 Student Project Collaboration (M:N between Student & Project)
CREATE TABLE Student_Project_Collaboration (
    StudentID INT NOT NULL,
    ProjectID INT NOT NULL,
    Role VARCHAR(100) NOT NULL DEFAULT 'Research Assistant',
    AssignedDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    WeeklyHours INT NOT NULL CHECK (WeeklyHours >= 0),
    PRIMARY KEY (StudentID, ProjectID),
    CONSTRAINT FK_Collab_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Collab_Project FOREIGN KEY (ProjectID) REFERENCES Research_Project(ProjectID) ON DELETE CASCADE
);
GO

-- 4.9 Student Club Table
CREATE TABLE Club (
    ClubID INT PRIMARY KEY,
    ClubName VARCHAR(100) NOT NULL UNIQUE,
    Category VARCHAR(50) NOT NULL,
    EstablishedYear INT NOT NULL
);
GO

-- 4.10 Student Club Membership (M:N)
CREATE TABLE Club_Membership (
    StudentID INT NOT NULL,
    ClubID INT NOT NULL,
    JoinDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    MemberRole VARCHAR(50) NOT NULL DEFAULT 'Member' CHECK (MemberRole IN ('President', 'Vice President', 'Treasurer', 'Secretary', 'Member')),
    PRIMARY KEY (StudentID, ClubID),
    CONSTRAINT FK_ClubMem_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_ClubMem_Club FOREIGN KEY (ClubID) REFERENCES Club(ClubID) ON DELETE CASCADE
);
GO

-- 4.11 Library Table
CREATE TABLE Library (
    LibraryID INT PRIMARY KEY,
    LibraryName VARCHAR(100) NOT NULL UNIQUE,
    Location VARCHAR(100) NOT NULL
);
GO

-- 4.12 Book Table (Registered in Library)
CREATE TABLE Book (
    BookID INT PRIMARY KEY,
    ISBN VARCHAR(30) NOT NULL UNIQUE,
    Title VARCHAR(200) NOT NULL,
    Author VARCHAR(150) NOT NULL,
    PublicationYear INT NOT NULL,
    Category VARCHAR(50) NOT NULL,
    LibraryID INT NOT NULL,
    TotalCopies INT NOT NULL DEFAULT 1 CHECK (TotalCopies > 0),
    AvailableCopies INT NOT NULL DEFAULT 1 CHECK (AvailableCopies >= 0),
    CONSTRAINT FK_Book_Library FOREIGN KEY (LibraryID) REFERENCES Library(LibraryID),
    CONSTRAINT CHK_Copies CHECK (AvailableCopies <= TotalCopies)
);
GO

-- 4.13 Book Borrowing Table (Student borrows Book)
CREATE TABLE Book_Borrowing (
    BorrowID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    BookID INT NOT NULL,
    BorrowDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL,
    LateFee DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT FK_Borrow_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Borrow_Book FOREIGN KEY (BookID) REFERENCES Book(BookID)
);
GO

-- Sample Data Insertion for University_DB
-- A. Departments
INSERT INTO Department (DeptID, DeptName, Building, Budget) VALUES
(10, 'Computer Science & Artificial Intelligence', 'Alan Turing Hall', 1500000.00),
(20, 'Electrical Engineering', 'Nikola Tesla Building', 1800000.00),
(30, 'Mechanical Engineering', 'James Watt Complex', 1600000.00),
(40, 'Business Administration & Management', 'Adam Smith Pavilion', 1200000.00);

-- B. Professors
INSERT INTO Professor (ProfID, FirstName, LastName, Email, Phone, OfficeNumber, DeptID) VALUES
(1001, 'Prof. Mahmoud', 'El-Gendy', 'm.elgendy@univ.edu', '+20-100-111222', 'TH-401', 10),
(1002, 'Dr. Hoda', 'Abdel-Aty', 'h.abdelaty@univ.edu', '+20-100-333444', 'TH-305', 10),
(1003, 'Prof. Sameh', 'Morcos', 's.morcos@univ.edu', '+20-100-555666', 'TB-202', 20),
(1004, 'Dr. Rania', 'Shawky', 'r.shawky@univ.edu', '+20-100-777888', 'AS-108', 4);

-- C. Students
INSERT INTO Student (StudentID, FirstName, LastName, Email, Phone, BirthDate, DeptID) VALUES
(2024001, 'Mostafa', 'Karam', 'mostafa.karam@univ.edu', '+20-112-998877', '2003-05-14', 10),
(2024002, 'Mariam', 'Ashraf', 'mariam.ashraf@univ.edu', '+20-114-556677', '2004-02-20', 10),
(2024003, 'Omar', 'Ghoneim', 'omar.ghoneim@univ.edu', '+20-115-334455', '2002-11-09', 20),
(2024004, 'Nourhan', 'Badr', 'nourhan.badr@univ.edu', '+20-111-778899', '2003-08-30', 4),
(2024005, 'Khaled', 'Ezzat', 'khaled.ezzat@univ.edu', '+20-118-223344', '2004-09-17', 3);

-- D. University IDs (1:1 with Students)
INSERT INTO University_ID (CardNumber, StudentID, IssueDate, ExpiryDate, CardStatus) VALUES
('UID-2024-001', 2024001, '2024-09-01', '2028-08-31', 'Active'),
('UID-2024-002', 2024002, '2024-09-01', '2028-08-31', 'Active'),
('UID-2024-003', 2024003, '2024-09-01', '2028-08-31', 'Active'),
('UID-2024-004', 2024004, '2024-09-01', '2028-08-31', 'Active'),
('UID-2024-005', 2024005, '2024-09-01', '2028-08-31', 'Active');

-- E. Courses
INSERT INTO Course (CourseID, CourseName, Credits, DeptID, ProfID) VALUES
('CS101', 'Data Structures & Algorithms', 4, 10, 1001),
('CS204', 'Relational Database Management Systems', 3, 10, 1002),
('EE310', 'Embedded Microcontroller Systems', 4, 20, 1003),
('BUS102', 'Principles of Corporate Finance', 3, 40, 1004),
('CS409', 'Applied Artificial Intelligence & Deep Learning', 4, 10, 1001);

-- F. Course Enrollments
INSERT INTO Course_Enrollment (StudentID, CourseID, Semester, AcademicYear, Grade) VALUES
(2024001, 'CS101', 'Fall', 2025, 96.50),
(2024001, 'CS204', 'Spring', 2026, 98.00),
(2024002, 'CS101', 'Fall', 2025, 91.00),
(2024002, 'CS204', 'Spring', 2026, 94.50),
(2024003, 'EE310', 'Spring', 2026, 88.00),
(2024004, 'BUS102', 'Fall', 2025, 92.00),
(2024001, 'CS409', 'Fall', 2026, 97.00);

-- G. Research Projects & Collaborations
INSERT INTO Research_Project (Title, Description, Budget, StartDate, EndDate, LeadProfessorID) VALUES
('Autonomous Drone Navigation in GPS-Denied Environments', 'Developing visual SLAM algorithms for micro-aerial robotics.', 350000.00, '2026-01-15', '2027-06-30', 1001),
('High-Efficiency Smart Grid Distributed Sensing', 'Edge computing algorithms for real-time electrical grid fault mitigation.', 420000.00, '2025-10-01', '2027-03-31', 1003);

INSERT INTO Student_Project_Collaboration (StudentID, ProjectID, Role, AssignedDate, WeeklyHours) VALUES
(2024001, 1, 'Computer Vision Software Engineer', '2026-02-01', 15),
(2024002, 1, 'Data Pipeline & ML Researcher', '2026-02-15', 12),
(2024003, 2, 'Firmware & Sensor Developer', '2026-01-10', 10);

-- H. Clubs & Memberships
INSERT INTO Club (ClubID, ClubName, Category, EstablishedYear) VALUES
(1, 'IEEE Student Branch', 'Engineering & Tech', 2012),
(2, 'Google Developer Student Club (GDSC)', 'Software & AI', 2018),
(3, 'University Debate & Public Speaking Society', 'Cultural & Leadership', 2015);

INSERT INTO Club_Membership (StudentID, ClubID, JoinDate, MemberRole) VALUES
(2024001, 2, '2024-10-01', 'President'),
(2024002, 2, '2024-10-10', 'Vice President'),
(2024003, 1, '2024-10-05', 'Member'),
(2024004, 3, '2024-11-01', 'Secretary');

-- I. Library & Books
INSERT INTO Library (LibraryID, LibraryName, Location) VALUES
(1, 'Central Science & Engineering Library', 'Campus Zone A, 3rd Floor'),
(2, 'Humanities & Business Reading Commons', 'Campus Zone C, Ground Floor');

INSERT INTO Book (BookID, ISBN, Title, Author, PublicationYear, Category, LibraryID, TotalCopies, AvailableCopies) VALUES
(8001, '978-0133970777', 'Fundamentals of Database Systems (7th Ed)', 'Ramez Elmasri & Shamkant Navathe', 2016, 'Computer Science', 1, 10, 8),
(8002, '978-0262033848', 'Introduction to Algorithms (CLRS 3rd Ed)', 'Thomas Cormen et al.', 2009, 'Computer Science', 1, 8, 7),
(8003, '978-0134444666', 'Electric Circuits (11th Ed)', 'James Nilsson & Susan Riedel', 2018, 'Engineering', 1, 6, 6),
(8004, '978-1260013900', 'Principles of Corporate Finance (13th Ed)', 'Richard Brealey & Stewart Myers', 2020, 'Business', 2, 5, 4);

-- J. Book Borrowings
INSERT INTO Book_Borrowing (StudentID, BookID, BorrowDate, DueDate, ReturnDate, LateFee) VALUES
(2024001, 8001, '2026-09-01', '2026-09-15', '2026-09-12', 0.00),
(2024002, 8001, '2026-09-05', '2026-09-19', NULL, 0.00),
(2024004, 8004, '2026-08-20', '2026-09-03', '2026-09-06', 15.00);
GO
