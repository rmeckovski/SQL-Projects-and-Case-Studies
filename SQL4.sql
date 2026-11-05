WITH EmployeeComp AS (
	SELECT
		e.first_name,
		e.last_name,
		d.department_name,
		d.location, 
		e.salary + (e.salary * e.bonus_percentage) AS total_comp
	FROM employees AS e
	INNER JOIN departments AS d
		ON e.department_id = d.id
	WHERE e.is_active = 1
),

DepartmentRanking AS (
	SELECT 
		first_name,
		last_name,
		department_name,
		location,
		total_comp,
		DENSE_RANK() OVER (PARTITION BY department_name ORDER BY total_comp DESC) AS comp_rank,
		AVG(total_comp) OVER (PARTITION BY department_name) AS dept_avg_comp
	FROM EmployeeComp
)

SELECT
	department_name,
	first_name,
	last_name,
	ROUND(total_comp, 2) AS total_comp,
	ROUND(dept_avg_comp, 2) AS dept_avg_comp
FROM DepartmentRanking
WHERE comp_rank <= 3
ORDER BY department_name ASC, total_comp DESC;
