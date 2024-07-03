
•	01. Count Employees by Town
CREATE OR REPLACE FUNCTION fn_count_employees_by_town(town_name VARCHAR)
RETURNS INT AS
$$
	DECLARE
		count_towns INT;
	BEGIN
		SELECT COUNT(*) INTO count_towns 
		FROM employees AS e JOIN addresses AS a USING(address_id) JOIN towns AS t USING(town_id) 
		WHERE name = town_name;
		RETURN count_towns;
	END;
$$
LANGUAGE plpgsql;

•	02. Employees Promotion
CREATE OR REPLACE PROCEDURE sp_increase_salaries(department_name VARCHAR)
AS
$$
	BEGIN
		UPDATE employees
		SET salary = salary + salary * 0.05
		WHERE department_id = (SELECT department_id FROM departments WHERE name = department_name);
	END;
$$
LANGUAGE plpgsql;

•	03. Employees Promotion By ID
CREATE OR REPLACE PROCEDURE sp_increase_salary_by_id(id INT) 
AS
$$
	BEGIN
		IF (SELECT employee_id FROM employees WHERE employee_id = id) IS NULL THEN
			RETURN;
		ELSE
			UPDATE employees SET salary = salary + 0.05 * salary WHERE employee_id = id;
		END IF;
	END;
$$
LANGUAGE plpgsql;

•	04. Triggered
CREATE TABLE deleted_employees(
	employee_id SERIAL PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	middle_name VARCHAR(20),
	job_title VARCHAR(50),
	department_id INT,
	salary NUMERIC(19,4)
); 

CREATE OR REPLACE FUNCTION backup_fired_employees() 
RETURNS TRIGGER AS
$$
	BEGIN
		INSERT INTO deleted_employees(first_name, last_name, middle_name, job_title, department_id, salary)
		VALUES (old.first_name, old.last_name, old.middle_name, old.job_title, old.department_id, old.salary);
		RETURN new;
	END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER backup_trigger
AFTER DELETE ON employees
FOR EACH ROW
EXECUTE PROCEDURE backup_fired_employees();


