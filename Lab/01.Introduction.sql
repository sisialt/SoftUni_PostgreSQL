
1.
CREATE TABLE 
	employees(
		id SERIAL PRIMARY KEY NOT NULL,
		first_name VARCHAR(30),
		last_name VARCHAR(50),
		hiring_date DATE DEFAULT '2023-01-01',
		salary NUMERIC(10, 2),
		devices_number INTEGER
	);
CREATE TABLE 
	departments(
		id SERIAL PRIMARY KEY NOT NULL,
		name VARCHAR(50),
		code CHAR(3),
		description TEXT
	);
CREATE TABLE 
	issues(
		id SERIAL PRIMARY KEY UNIQUE,
		description VARCHAR(150),
		date DATE,
		start TIMESTAMP
	);

3.
ALTER TABLE employees
ADD COLUMN middle_name VARCHAR(50)

4.
ALTER TABLE employees
ALTER COLUMN salary SET NOT NULL,
ALTER COLUMN salary SET DEFAULT 0,
ALTER COLUMN hiring_date SET NOT NULL;

5.
ALTER TABLE employees
ALTER COLUMN middle_name TYPE VARCHAR(100)

6.
TRUNCATE TABLE issues

7.
DROP TABLE departments

