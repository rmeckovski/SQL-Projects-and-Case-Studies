SELECT
	UPPER(d.location) AS location_name,
	TRIM(d.department_name) AS department_name,
	SUM(CASE WHEN e.is_active = 1 THEN 1 ELSE 0 END) AS active_employee_count,
	ROUND(SUM(e.salary), 2) AS total_department_payroll,
	ROUND(AVG(e.salary + (e.salary * e.bonus_percentage)), 2) AS avg_total_compensation
FROM employees AS e
INNER JOIN departments AS d
	ON e.department_id = d.id
WHERE e.is_active = 1
GROUP BY d.location, d.department_name
HAVING SUM(CASE WHEN e.is_active = 1 THEN 1 ELSE 0 END) >= 2
ORDER BY total_department_payroll DESC, location_name ASC;