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

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
EXPLAIN
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;

/*
 -> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=5.44 rows=44) (actual time=0.303..0.303 rows=0 loops=1)
    -> Table scan on Student  (cost=5.44 rows=400) (actual time=0.020..0.265 rows=400 loops=1)
 */

-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

/*
MY SOLUTION
-- I created an index to reduce from a full table scan to an index scan.
-- I used the same index created in the first question but reversed the order of the columns. This changed it from a range scan to an index scan.
-- This resulted in a lower 'cost' but higher number of rows scanned and slightly longer Runtime.
-- I also changed the BETWEEN clause to use <= and >= operators. It runtime was seemingly reduced ever so slightly. That could be coincidence?
-- I identified bottlenecks with the EXPLAIN and EXPLAIN ANALYZE commands.
 */

CREATE INDEX student_name_id_index
ON Student(name, id);

EXPLAIN
SELECT name FROM Student WHERE id >= @v2 AND id <= @v3;


/*
 WITH
CREATE INDEX student_name_id_index
ON Student(name, id);

-> Filter: ((<cache>((@v2)) <= student.id) and (student.id <= <cache>((@v3))))  (cost=5.44 rows=44) (actual time=0.019..0.185 rows=278 loops=1)
    -> Index scan on Student using student_name_id_index  (cost=5.44 rows=400) (actual time=0.017..0.146 rows=400 loops=1)


-- WITH
CREATE INDEX student_name_id_index
ON Student(id, name);

-> Filter: ((<cache>((@v2)) <= student.id) and (student.id <= <cache>((@v3))))  (cost=64.52 rows=278) (actual time=0.015..0.140 rows=278 loops=1)
    -> Index range scan on Student using student_name_id_index  (cost=64.52 rows=278) (actual time=0.013..0.110 rows=278 loops=1)

 */