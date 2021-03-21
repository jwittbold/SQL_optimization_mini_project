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

-- 6. List the names of students who have taken all courses offered by department v8 (deptId).

EXPLAIN
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) = 
			(SELECT COUNT(*) FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;


/* ORIGINAL
-> Nested loop inner join  (actual time=3.310..3.310 rows=0 loops=1)
    -> Filter: (student.id is not null)  (cost=41.00 rows=400) (actual time=0.015..0.229 rows=400 loops=1)
        -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.015..0.196 rows=400 loops=1)
    -> Index lookup on alias using <auto_key0> (studId=student.id)  (actual time=0.000..0.000 rows=0 loops=400)
        -> Materialize  (actual time=0.008..0.008 rows=0 loops=400)
            -> Filter: (count(0) = (select #5))  (actual time=2.903..2.903 rows=0 loops=1)
                -> Table scan on <temporary>  (actual time=0.000..0.001 rows=19 loops=1)
                    -> Aggregate using temporary table  (actual time=2.899..2.901 rows=19 loops=1)
                        -> Nested loop inner join  (cost=1020.25 rows=10000) (actual time=0.131..0.239 rows=19 loops=1)
                            -> Filter: (transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.003..0.053 rows=100 loops=1)
                                -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.003..0.044 rows=100 loops=1)
                            -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=transcript.crsCode)  (actual time=0.000..0.000 rows=0 loops=100)
                                -> Materialize with deduplication  (cost=110.52 rows=100) (actual time=0.002..0.002 rows=0 loops=100)
                                    -> Filter: (course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.064..0.116 rows=19 loops=1)
                                        -> Filter: (teaching.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.064..0.114 rows=19 loops=1)
                                            -> Inner hash join (<hash>(teaching.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.064..0.111 rows=19 loops=1)
                                                -> Table scan on Teaching  (cost=0.13 rows=100) (actual time=0.002..0.034 rows=100 loops=1)
                                                -> Hash
                                                    -> Filter: (course.deptId = <cache>((@v8)))  (cost=10.25 rows=10) (actual time=0.007..0.050 rows=19 loops=1)
                                                        -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.002..0.037 rows=100 loops=1)
                -> Select #5 (subquery in condition; uncacheable)
                    -> Aggregate: count(0)  (actual time=0.137..0.137 rows=1 loops=19)
                        -> Nested loop inner join  (cost=111.25 rows=1000) (actual time=0.074..0.136 rows=19 loops=19)
                            -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.002..0.050 rows=19 loops=19)
                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.001..0.038 rows=100 loops=19)
                            -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.000..0.000 rows=1 loops=361)
                                -> Materialize with deduplication  (cost=10.25 rows=100) (actual time=0.004..0.004 rows=1 loops=361)
                                    -> Filter: (teaching.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.001..0.043 rows=100 loops=19)
                                        -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.001..0.035 rows=100 loops=19)
            -> Select #5 (subquery in projection; uncacheable)
                -> Aggregate: count(0)  (actual time=0.137..0.137 rows=1 loops=19)
                    -> Nested loop inner join  (cost=111.25 rows=1000) (actual time=0.074..0.136 rows=19 loops=19)
                        -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.002..0.050 rows=19 loops=19)
                            -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.001..0.038 rows=100 loops=19)
                        -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.000..0.000 rows=1 loops=361)
                            -> Materialize with deduplication  (cost=10.25 rows=100) (actual time=0.004..0.004 rows=1 loops=361)
                                -> Filter: (teaching.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.001..0.043 rows=100 loops=19)
                                    -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.001..0.035 rows=100 loops=19)

 */

/*
MY SOLUTION
-- The original solution contains many full table scans, so I created index on Course(dept) to improve query performance of departments within courses.
-- The original solution also contains many sub-queries, so I eliminated most of them.
-- I filtered the course table to the count of records equal to @v8 (only 19)
-- I further filtered results using wildcard matching to records from Transcript table where crsCode LIKE 'MAT%' (also only 19)
-- Returned records having the same count of crsCode as the count of courses in @v8 - returns zero records since no students have taken 19 courses
-- I identified bottlenecks with the EXPLAIN and EXPLAIN ANALYZE commands.
*/

-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

CREATE INDEX course_dept
ON Course(deptId);


EXPLAIN ANALYZE
SELECT name
FROM Student s
INNER JOIN Transcript t
ON s.id = t.studId
WHERE t.crsCode LIKE 'MAT%'  -- reduces scanning 4000 rows to 400 rows
GROUP BY name
HAVING COUNT(crsCode) = (SELECT COUNT(deptId)
    FROM Course c
    WHERE deptId = @v8);

/* WITH INDEX course_dept
-> Filter: (count(t.crsCode) = (select #2))  (actual time=0.470..0.470 rows=0 loops=1)
    -> Table scan on <temporary>  (actual time=0.000..0.002 rows=19 loops=1)
        -> Aggregate using temporary table  (actual time=0.466..0.468 rows=19 loops=1)
            -> Inner hash join (s.id = t.studId)  (cost=455.69 rows=444) (actual time=0.068..0.244 rows=19 loops=1)
                -> Table scan on s  (cost=0.45 rows=400) (actual time=0.004..0.136 rows=400 loops=1)
                -> Hash
                    -> Filter: (t.crsCode like 'MAT%')  (cost=10.25 rows=11) (actual time=0.013..0.055 rows=19 loops=1)
                        -> Table scan on t  (cost=10.25 rows=100) (actual time=0.010..0.044 rows=100 loops=1)
    -> Select #2 (subquery in condition; uncacheable)
        -> Aggregate: count(c.deptId)  (actual time=0.010..0.010 rows=1 loops=19)
            -> Index lookup on c using course_dept (deptId=(@v8))  (cost=2.71 rows=19) (actual time=0.002..0.009 rows=19 loops=19)
-> Select #2 (subquery in projection; uncacheable)
    -> Aggregate: count(c.deptId)  (actual time=0.010..0.010 rows=1 loops=19)
        -> Index lookup on c using course_dept (deptId=(@v8))  (cost=2.71 rows=19) (actual time=0.002..0.009 rows=19 loops=19)

 */

