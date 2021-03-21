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

-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
EXPLAIN ANALYZE
SELECT * FROM Student,
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;

/*
-> Filter: <in_optimizer>(transcript.studId,<exists>(select #3) is false)  (cost=4112.69 rows=4000) (actual time=0.317..4.055 rows=30 loops=1)
    -> Inner hash join (student.id = transcript.studId)  (cost=4112.69 rows=4000) (actual time=0.152..0.355 rows=30 loops=1)
        -> Table scan on Student  (cost=0.06 rows=400) (actual time=0.003..0.156 rows=400 loops=1)
        -> Hash
            -> Filter: (transcript.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.083..0.138 rows=30 loops=1)
                -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.083..0.133 rows=30 loops=1)
                    -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.003..0.037 rows=100 loops=1)
                    -> Hash
                        -> Filter: (course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.017..0.066 rows=26 loops=1)
                            -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.013..0.050 rows=100 loops=1)
    -> Select #3 (subquery in condition; dependent)
        -> Limit: 1 row(s)  (actual time=0.121..0.121 rows=0 loops=30)
            -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(transcript.studId), true)  (actual time=0.121..0.121 rows=0 loops=30)
                -> Filter: (<if>(outer_field_is_not_null, ((<cache>(transcript.studId) = transcript.studId) or (transcript.studId is null)), true) and (transcript.crsCode = course.crsCode))  (cost=110.52 rows=100) (actual time=0.120..0.120 rows=0 loops=30)
                    -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.063..0.117 rows=34 loops=30)
                        -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.001..0.039 rows=100 loops=30)
                        -> Hash
                            -> Filter: (course.deptId = <cache>((@v7)))  (cost=10.25 rows=10) (actual time=0.004..0.051 rows=32 loops=30)
                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.001..0.039 rows=100 loops=30)


 */


/*
-- Original solution returns duplicate rows, additional columns, problem statement only asks for names

MY SOLUTION
-- Re-declare v6 & v7 variables with wildcard matching to use an index range scan.
-- Not sure if that is a valid move within this exercise, but it does increase performance.
-- Avoids the costly inner hash join of student.id to transcript.studId in original query, that is a major performance bottleneck
-- Query is utilizing previously created student_name_id_index for an index lookup.
-- Filter for desired and undesired courses
-- INNER JOIN Transcript table matching on student IDs

 */
-- ------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------- MY SOLUTION ----------------------------------------------------------

SET @v6 = 'MGT%';
SET @v7 = 'EE%';


EXPLAIN
SELECT name
FROM Student s
INNER JOIN Transcript t
ON s.id = t.studId
WHERE t.crsCode LIKE @v6 AND t.crsCode NOT LIKE @v7;


/*

 -> Nested loop inner join  (cost=21.06 rows=26) (actual time=0.041..0.113 rows=26 loops=1)
    -> Filter: (t.studId is not null)  (cost=11.96 rows=26) (actual time=0.032..0.066 rows=26 loops=1)
        -> Index range scan on t using crsCode_index, with index condition: ((t.crsCode like <cache>((@v6))) and (not((t.crsCode like <cache>((@v7))))))  (cost=11.96 rows=26) (actual time=0.031..0.063 rows=26 loops=1)
    -> Index lookup on s using student_name_id_index (id=t.studId)  (cost=0.25 rows=1) (actual time=0.001..0.002 rows=1 loops=26)

 */


/* WITHOUT TWO NEWLY CREATED INDEXES
-> Inner hash join (s.id = t.studId)  (cost=397.30 rows=395) (actual time=0.078..0.248 rows=26 loops=1)
    -> Table scan on s  (cost=0.51 rows=400) (actual time=0.003..0.132 rows=400 loops=1)
    -> Hash
        -> Filter: ((t.crsCode like <cache>((@v6))) and (not((t.crsCode like <cache>((@v7))))))  (cost=1.24 rows=10) (actual time=0.017..0.063 rows=26 loops=1)
            -> Table scan on t  (cost=1.24 rows=100) (actual time=0.013..0.048 rows=100 loops=1)
 */


/*  WITH TWO NEWLY CREATED INDEXES
-> Inner hash join (s.id = t.studId)  (cost=1053.06 rows=1040) (actual time=0.064..0.231 rows=26 loops=1)
    -> Index scan on s using student_name_id_index  (cost=0.20 rows=400) (actual time=0.004..0.132 rows=400 loops=1)
    -> Hash
        -> Index range scan on t using crsCode_index, with index condition: ((t.crsCode like <cache>((@v6))) and (not((t.crsCode like <cache>((@v7))))))  (cost=11.96 rows=26) (actual time=0.017..0.046 rows=26 loops=1)

*/
