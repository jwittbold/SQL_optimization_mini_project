USE springboardopt;

-- -------------------------------------
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 4. List the names of students who have taken a course taught by professor v5 (name).
EXPLAIN
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

/*

 -> Inner hash join (student.id = transcript.studId)  (cost=1313.72 rows=160) (actual time=0.157..0.157 rows=0 loops=1)
    -> Table scan on Student  (cost=0.03 rows=400) (never executed)
    -> Hash
        -> Inner hash join (professor.id = teaching.profId)  (cost=1144.90 rows=4) (actual time=0.151..0.151 rows=0 loops=1)
            -> Filter: (professor.`name` = <cache>((@v5)))  (cost=0.95 rows=4) (never executed)
                -> Table scan on Professor  (cost=0.95 rows=400) (never executed)
            -> Hash
                -> Filter: ((teaching.semester = transcript.semester) and (teaching.crsCode = transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.146..0.146 rows=0 loops=1)
                    -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.145..0.145 rows=0 loops=1)
                        -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.005..0.039 rows=100 loops=1)
 */


-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

/*
MY SOLUTION
-- I created two temporary tables, one to join student and transcript to retrieve name and course code together, and t
-- the other to join professor and teaching to retrieve professor name and course code toether. Otherwise there were many costly joins occuring.
-- I then created indexes on each of the temp tables to turn them into ref type scans rather than all type scans.
-- changing the order to name, crsCode on the professor_courses index changed it from an index scan to a ref scan.
-- I identified bottlenecks with the EXPLAIN and EXPLAIN ANALYZE commands.
 */


CREATE TEMPORARY TABLE stud_crsCode AS
    SELECT name, crsCode
        FROM Student
        JOIN Transcript
        ON Student.id = Transcript.studId;

CREATE INDEX student_courses
ON stud_crsCode(crsCode, name);

CREATE TEMPORARY TABLE prof_crsCode AS
    SELECT name, crsCode
        FROM Teaching
        JOIN Professor
        ON Professor.id = Teaching.profId;

CREATE INDEX professor_courses_3
ON prof_crsCode(name, crsCode);


EXPLAIN
SELECT stud_crsCode.name AS Student_Name, prof_crsCode.name AS Professor_Name
FROM stud_crsCode
INNER JOIN prof_crsCode
ON stud_crsCode.crsCode = prof_crsCode.crsCode
WHERE prof_crsCode.name = @v5;


/*

WITH INDEXES professor_courses_3 (name, crsCode) ordered
-> Nested loop inner join  (cost=2.20 rows=1) (actual time=0.019..0.023 rows=2 loops=1)
    -> Filter: (prof_crscode.crsCode is not null)  (cost=1.10 rows=1) (actual time=0.013..0.014 rows=1 loops=1)
        -> Index lookup on prof_crsCode using professor_courses_3 (name=(@v5))  (cost=1.10 rows=1) (actual time=0.013..0.013 rows=1 loops=1)
    -> Index lookup on stud_crsCode using student_courses (crsCode=prof_crscode.crsCode)  (cost=1.10 rows=1) (actual time=0.005..0.007 rows=2 loops=1)





WITHOUT INDEXES
-> Filter: (stud_crscode.crsCode = prof_crscode.crsCode)  (cost=110.52 rows=100) (actual time=0.122..0.184 rows=2 loops=1)
    -> Inner hash join (<hash>(stud_crscode.crsCode)=<hash>(prof_crscode.crsCode))  (cost=110.52 rows=100) (actual time=0.122..0.183 rows=2 loops=1)
        -> Table scan on stud_crsCode  (cost=0.13 rows=100) (actual time=0.003..0.056 rows=100 loops=1)
        -> Hash
            -> Filter: (prof_crscode.`name` = <cache>((@v5)))  (cost=10.25 rows=10) (actual time=0.045..0.095 rows=1 loops=1)
                -> Table scan on prof_crsCode  (cost=10.25 rows=100) (actual time=0.021..0.076 rows=100 loops=1)

WITH INDEXES, professor_courses (crsCode, name) ordered.
-> Nested loop inner join  (cost=21.25 rows=10) (actual time=0.068..0.080 rows=2 loops=1)
    -> Filter: ((prof_crscode.`name` = <cache>((@v5))) and (prof_crscode.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.058..0.067 rows=1 loops=1)
        -> Index scan on prof_crsCode using professor_courses  (cost=10.25 rows=100) (actual time=0.016..0.052 rows=100 loops=1)
    -> Index lookup on stud_crsCode using student_courses (crsCode=prof_crscode.crsCode)  (cost=1.01 rows=1) (actual time=0.009..0.011 rows=2 loops=1)



 */






# EXPLAIN ANALYZE
# SELECT Student.name
# FROM Student
# INNER JOIN Transcript trans
# ON Student.id = trans.studId
# INNER JOIN Teaching
# ON Teaching.crsCode = trans.crsCode
# INNER JOIN Professor
# ON Professor.id = Teaching.profId
# WHERE Professor.name = @v5;


# EXPLAIN ANALYZE
# WITH v5_courses AS (
#     SELECT crsCode
#     FROM Teaching t
#     INNER JOIN Professor p
#     ON p.id = t.profId
#     WHERE p.name = @v5
# )
# SELECT name
# FROM Student s
# INNER JOIN Transcript trans
# ON s.id = trans.studId
# INNER JOIN v5_courses
# ON trans.crsCode = v5_courses.crsCode






