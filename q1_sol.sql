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

-- 1. List the name of the student with id equal to v1 (id).
EXPLAIN ANALYZE
SELECT name FROM Student WHERE id = @v1;

/* ORIGINAL
   -> Filter: (student.id = <cache>((@v1)))  (cost=41.00 rows=40) (actual time=0.049..0.170 rows=1 loops=1)
    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.015..0.146 rows=400 loops=1)

 */

-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

CREATE INDEX student_name_id_index
ON Student(id, name);

EXPLAIN ANALYZE
SELECT name FROM Student WHERE id = @v1;

/*
 MY SOLUTION
 -- Create index on student name and id with id column first. Without an index the query performs a full table scan on
 -- the students table. With the new index, with id coming first, the query only scans 1 row.
 -- I identified it with the EXPLAIN and EXPLAIN ANALYZE commands.

 */

/* WITH NEWLY CREATED INDEX
-> Index lookup on Student using student_name_id_index (id=(@v1))  (cost=0.35 rows=1) (actual time=0.011..0.013 rows=1 loops=1)
*/


