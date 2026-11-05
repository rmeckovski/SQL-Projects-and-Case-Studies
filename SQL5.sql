WITH CleanedEmployees AS (
	SELECT
		e.first_name,
		e.last_name,
		UPPER(TRIM(d.location)) AS clean_location,
		TRIM(REPLACE(d.department_name, 'Group', 'Team')) AS clean_dept,
		e.salary + (e.salary * e.bonus_percentage) AS total_comp
	FROM employees AS e
	INNER JOIN departments AS d
		ON e.department_id = d.id
	WHERE e.is_active = 1
),

RegionalPipeline AS (
	SELECT 
		first_name,
		last_name,
		clean_location,
		clean_dept,
		total_comp
	FROM CleanedEmployees
	WHERE clean_location = 'NEW YORK' AND total_comp > 90000

	UNION ALL

	SELECT
		first_name,
		last_name,
		clean_location,
		clean_dept,
		total_comp
	FROM CleanedEmployees
	WHERE clean_location = 'LONDON' AND total_comp > 80000
),

AdvancedAnalytics AS (
	SELECT
		first_name,
		last_name,
		clean_location,
		clean_dept,
		total_comp,
		DENSE_RANK() OVER (PARTITION BY clean_dept ORDER BY total_comp DESC) AS regional_rank,
		SUM(total_comp) OVER (PARTITION BY clean_dept) AS dept_total_comp
	FROM RegionalPipeline
)

SELECT
	clean_location,
	clean_dept,
	first_name,
	last_name,
	ROUND(total_comp, 2) AS total_comp,
	ROUND(dept_total_comp, 2) AS dept_total_comp,
	regional_rank
FROM AdvancedAnalytics
WHERE regional_rank <= 3
ORDER BY clean_dept ASC, total_comp DESC;
