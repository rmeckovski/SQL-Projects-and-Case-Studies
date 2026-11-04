SELECT
	UPPER(TRIM(department)) AS department_name, 
	LOWER(LEFT(department, 3)) AS dept_prefix,  
	SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_staff_count,     
	ROUND(SUM(CAST(salary AS DECIMAL(12,2))), 2) AS total_annual_payroll, 
	ROUND(AVG(salary + (salary * bonus_percentage)), 2) AS avg_total_compensation, 
	MAX(LEN(TRIM(corporate_email))) AS longest_email_len, -- DONE	
	SUM(CASE
			WHEN DATENAME(month, hire_date) = 'January' 
			OR DATENAME(month, hire_date) = 'December'
			THEN 1
			ELSE 0
		END) AS senior_hire_count,
	
	CASE 
		WHEN AVG(salary + (salary * bonus_percentage)) > 100000 THEN 'Elite Tier'
		WHEN AVG(salary + (salary * bonus_percentage)) BETWEEN 70000 AND 100000 THEN 'Growth Tier'
		ELSE 'Standard Tier'
	END AS department_tier

FROM employees
WHERE	is_active = 1 
	AND phone_number IS NOT NULL 
	AND department IN ('Engineering', 'Product', 'Data Science', 'Finance')
	AND corporate_email LIKE '%@%'
	AND corporate_email NOT LIKE '%test%'
	AND hire_date BETWEEN '2015-01-01' AND '2024-12-31'
GROUP BY department
HAVING SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) >= 3
ORDER BY total_annual_payroll DESC, department_name ASC;