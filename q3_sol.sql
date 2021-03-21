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

-- 3. List the names of students who have taken course v4 (crsCode).
EXPLAIN
SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);

/*  ORIGINAL

-> Inner hash join (student.id = `<subquery2>`.studId)  (cost=411.29 rows=400) (actual time=0.090..0.245 rows=2 loops=1)
    -> Table scan on Student  (cost=5.04 rows=400) (actual time=0.004..0.135 rows=400 loops=1)
    -> Hash
        -> Table scan on <subquery2>  (cost=0.05 rows=10) (actual time=0.000..0.001 rows=2 loops=1)
            -> Materialize with deduplication  (cost=10.25 rows=10) (actual time=0.067..0.068 rows=2 loops=1)
                -> Filter: (transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.031..0.063 rows=2 loops=1)
                    -> Filter: (transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.030..0.062 rows=2 loops=1)
                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.015..0.050 rows=100 loops=1)
 */

-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

/*
MY SOLUTION
-- I decided to create an index for crsCode on the Transcript table to go from full table scan to ref scan.
-- Utilizes previously created student_name_id_index.
-- I changed the order of within the student_name_id_index to list ID first to change it from an index scan to a ref scan.
-- I then filtered for the crsCode in my WHERE clause and inner joined the students names from the Students
-- table with matching IDs to reduce steps.
-- Querying with the newly created 'crsCode_index' and INNER JOIN results in far fewer steps, fewer table scans,
-- reduced cost, and reduced query time.
-- I identified bottlenecks with the EXPLAIN and EXPLAIN ANALYZE commands.
*/

CREATE INDEX crsCode_index
ON Transcript(crsCode);


EXPLAIN ANALYZE
SELECT name
FROM Student s
INNER JOIN Transcript t
ON s.id = t.studId
WHERE t.crsCode = @v4;


/*  THIS IS WITH 'crsCode_index' and student_name_id_index (with order of id, name)

-> Nested loop inner join  (cost=1.40 rows=2) (actual time=0.020..0.026 rows=2 loops=1)
    -> Filter: (t.studId is not null)  (cost=0.70 rows=2) (actual time=0.015..0.017 rows=2 loops=1)
        -> Index lookup on t using crsCode_index (crsCode=(@v4))  (cost=0.70 rows=2) (actual time=0.014..0.016 rows=2 loops=1)
    -> Index lookup on s using student_name_id_index (id=t.studId)  (cost=0.30 rows=1) (actual time=0.003..0.004 rows=1 loops=2)



    THIS IS WITH 'crsCode_index' and student_name_id_index (with order of name, id)
-> Inner hash join (s.id = t.studId)  (cost=81.71 rows=80) (actual time=0.050..0.194 rows=2 loops=1)
    -> Index scan on s using student_name_id_index  (cost=2.50 rows=400) (actual time=0.004..0.132 rows=400 loops=1)
    -> Hash
        -> Index lookup on t using crsCode_index (crsCode=(@v4))  (cost=0.70 rows=2) (actual time=0.016..0.019 rows=2 loops=1)


-----------------------------------------------------------------------------------------------------------------------------

    THIS IS WITHOUT 'crsCode_index'

-> Inner hash join (s.id = t.studId)  (cost=411.29 rows=400) (actual time=0.086..0.241 rows=2 loops=1)
    -> Table scan on s  (cost=0.50 rows=400) (actual time=0.003..0.136 rows=400 loops=1)
    -> Hash
        -> Filter: (t.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.031..0.064 rows=2 loops=1)
            -> Table scan on t  (cost=10.25 rows=100) (actual time=0.014..0.051 rows=100 loops=1)

 */

-- no more efficient
# EXPLAIN ANALYZE
# WITH cte AS (
#     SELECT studId FROM Transcript WHERE crsCode = @v4
# )
# SELECT name FROM Student
# INNER JOIN cte
# ON cte.studId = Student.id;

