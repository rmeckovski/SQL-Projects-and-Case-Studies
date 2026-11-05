SELECT
	e.first_name,
	d.location AS region,
	e.salary
FROM employees AS e
INNER JOIN departments AS d
	ON e.department_id = d.id
WHERE e.is_active = 1 
  AND e.salary > 85000 
  AND d.location = 'New York'

UNION

SELECT
	e.first_name,
	d.location AS region,
	e.salary
FROM employees AS e
INNER JOIN departments AS d
	ON e.department_id = d.id
WHERE e.is_active = 1 
  AND e.salary > 80000 
  AND d.location = 'London'

ORDER BY salary DESC;
