
-- Creating table for student scores in different subjects

CREATE TABLE students_performance 
(
student_id INT PRIMARY KEY,
student_name VARCHAR(255),
gender VARCHAR(10),
age INT,
grade_level INT,
subject VARCHAR(100),
score INT,
attendance_rate DECIMAL(3,2),
parent_income DECIMAL(10,2),
hours_studied_per_week INT
)
;



-- Creating table for teacher information

CREATE TABLE teacher_info 
(
teacher_id INT PRIMARY KEY,
teacher_name VARCHAR(255),
subject VARCHAR(100),
years_experience INT
)
;



-- Finding the average score for each subject

SELECT subject, AVG(score) AS average_score
FROM students_performance
GROUP BY subject
ORDER BY average_score DESC
;



-- Analysing the impact of attendance and hours studied on scores

SELECT subject, 
AVG(attendance_rate) AS avg_attendance_rate, 
AVG(hours_studied_per_week) AS avg_hours_studied,
AVG(score) AS avg_score
FROM students_performance
GROUP BY subject
ORDER BY avg_score DESC
;



-- Identifying students who are at risk based on low scores

SELECT student_id, student_name, subject, score, attendance_rate, hours_studied_per_week
FROM students_performance
WHERE score < 50
ORDER BY score ASC
;



-- Creating performance categories (Excellent, Average, At Risk)

SELECT student_id, student_name, subject, score,
CASE
	WHEN score >= 85 THEN 'Excellent'
	WHEN score BETWEEN 50 AND 84 THEN 'Average'
	ELSE 'At Risk'
END AS performance_category
FROM students_performance
ORDER BY performance_category, score DESC
;



-- Analysing how parent income impacts student performance

SELECT parent_income, AVG(score) AS avg_score
FROM students_performance
GROUP BY parent_income
ORDER BY parent_income DESC
;



-- Finding the top 5 performing students in each subject

WITH RankedStudents AS 
(
SELECT student_id, student_name, subject, score,
RANK() OVER (PARTITION BY subject ORDER BY score DESC) AS rank
FROM students_performance
)
SELECT student_id, student_name, subject, score
FROM RankedStudents
WHERE rank <= 5
;



-- Using JOIN to find student performance along with teacher experience

SELECT sp.student_name, sp.subject, sp.score, sp.hours_studied_per_week, ti.teacher_name, ti.years_experience
FROM students_performance sp
JOIN class_schedule cs ON sp.subject = cs.subject AND sp.grade_level = cs.grade_level
JOIN teacher_info ti ON cs.teacher_id = ti.teacher_id
WHERE ti.years_experience > 5
ORDER BY sp.score DESC
;



-- Using RANK() window function to rank students within each grade level

SELECT student_id, student_name, grade_level, subject, score, 
RANK() OVER (PARTITION BY grade_level ORDER BY score DESC) AS rank
FROM students_performance
;



-- Calculating rolling average of student scores over time (assuming data from different exams over time is available)

SELECT student_id, student_name, subject, score, 
AVG(score) OVER (PARTITION BY student_id ORDER BY student_id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_avg_score
FROM students_performance
;



-- Identifying students at risk based on attendance rate, score, and hours studied

SELECT student_id, student_name, attendance_rate, score, hours_studied_per_week,
CASE 
	WHEN attendance_rate < 0.80 AND score < 60 AND hours_studied_per_week < 10 THEN 'High Risk'
	WHEN attendance_rate < 0.85 OR score < 65 OR hours_studied_per_week < 12 THEN 'Moderate Risk'
	ELSE 'Low Risk'
END AS risk_level
FROM students_performance;
