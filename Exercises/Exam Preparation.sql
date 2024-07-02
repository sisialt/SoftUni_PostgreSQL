•	1.1. Database Design
DROP TABLE IF EXISTS addresses CASCADE;
CREATE TABLE addresses(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL
);

CREATE TABLE categories(
	id SERIAL PRIMARY KEY,
	name VARCHAR(10) NOT NULL
);

CREATE TABLE clients(
	id SERIAL PRIMARY KEY,
	full_name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(20) NOT NULL
);

CREATE TABLE drivers(
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	age INT NOT NULL,
	rating NUMERIC(10,2) DEFAULT 5.5,
	CONSTRAINT ck_drivers_age CHECK (age > 0)
);

CREATE TABLE cars(
	id SERIAL PRIMARY KEY,
	make VARCHAR(20) NOT NULL,
	model VARCHAR(20),
	year INT DEFAULT 0 CHECK (year > 0) NOT NULL,
	mileage INT DEFAULT 0 CHECK(mileage > 0),
	condition CHAR(1) NOT NULL,
	category_id INT NOT NULL,
	CONSTRAINT fk_cars_categories
	FOREIGN KEY (category_id)
	REFERENCES categories(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE courses(
	id SERIAL PRIMARY KEY,
	from_address_id INT NOT NULL,
	start TIMESTAMP NOT NULL,
	bill NUMERIC(10,2) DEFAULT 10 CHECK (bill > 0),
	car_id INT NOT NULL,
	client_id INT NOT NULL,
	
	CONSTRAINT fk_courses_addresses
	FOREIGN KEY (from_address_id)
	REFERENCES addresses(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_courses_cars
	FOREIGN KEY (car_id)
	REFERENCES cars(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE, 
	
	CONSTRAINT fk_courses_clients
	FOREIGN KEY (client_id)
	REFERENCES clients(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE cars_drivers(
	car_id INT NOT NULL,
	driver_id INT NOT NULL,
	
	CONSTRAINT fk_cars_drivers_cars
	FOREIGN KEY (car_id)
	REFERENCES cars(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_cars_drivers_drivers
	FOREIGN KEY (driver_id)
	REFERENCES drivers(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

•	2.2. Insert
INSERT INTO clients(full_name, phone_number)
SELECT
	CONCAT(first_name, ' ', last_name),
	 CONCAT('(088) 9999', id * 2 )
FROM
	 drivers
WHERE
	 id BETWEEN 10 AND 20

•	2.3. Update
UPDATE cars
SET condition = 'C'
WHERE
	(mileage >= 800000
	OR mileage IS NULL)
	AND year <= 2010
	AND make <> 'Mercedes-Benz'

•	2.4. Delete
DELETE FROM clients
WHERE
	id NOT IN (SELECT client_id FROM courses)
		AND
	LENGTH(full_name) > 3

•	3.5. Cars
SELECT
	make,
	model,
	condition
FROM
	cars
ORDER BY
	id ASC

•	3.6. Drivers and Cars
SELECT
	d.first_name,
	d.last_name,
	c.make,
	c.model,
	c.mileage
FROM
	drivers AS d
	JOIN cars_drivers AS cd
		ON d.id = cd.driver_id
		JOIN cars AS c
			ON c.id = cd.car_id
WHERE
	mileage <> 0
ORDER BY
	mileage DESC,
	first_name ASC

•	3.7. Number of Courses for Each Car
SELECT
	c.id,
	c.make,
	c.mileage,
	COUNT(co.id) AS count_of_courses,
	ROUND(AVG(co.bill),2) AS average_bill
FROM
	cars AS c
	LEFT JOIN courses AS co
		ON c.id = co.car_id
GROUP BY
	c.id
HAVING
	COUNT(co.id) <> 2
ORDER BY
	count_of_courses DESC,
	c.id ASC

•	3.8. Regular Clients
SELECT
	cl.full_name,
	COUNT(co.car_id) AS count_of_cars,
	SUM(co.bill) AS total_sum
FROM
	clients AS cl
	JOIN courses AS co
		ON cl.id = co.client_id
WHERE 
	SUBSTRING(cl.full_name, 2,1) = 'a'
GROUP BY
	cl.id
HAVING
	COUNT(co.car_id) > 1
ORDER BY
	full_name

•	3.9. Full Information of Courses
SELECT
	a.name AS address,
	CASE 
		WHEN extract('hour' from start)::int BETWEEN 6 and 20 THEN 'Day'
		WHEN extract('hour' from start)::int < 6 OR extract('hour' from start)::int > 20 THEN 'Night'
	END AS day_time,
	co.bill,
	cl.full_name,
	c.make,
	c.model,
	cat.name AS category_name
FROM
	courses AS co
	JOIN clients AS cl
		ON cl.id = co.client_id
		JOIN addresses AS a
			ON co.from_address_id = a.id
			JOIN cars AS c
				ON co.car_id = c.id
				JOIN categories AS cat
					ON cat.id = c.category_id
ORDER BY
	co.id


•	4.10. Find all Courses by Client’s Phone Number
CREATE OR REPLACE FUNCTION fn_courses_by_client(phone_num VARCHAR(20))
RETURNS INT AS
$$
	DECLARE
		count_courses INT;
	BEGIN
		SELECT 
			COUNT(*) INTO count_courses
		FROM 
			courses AS co 
				JOIN clients AS cl
				ON co.client_id = cl.id
		WHERE cl.phone_number = phone_num;
		RETURN count_courses;
	END;
$$
LANGUAGE plpgsql;

•	4.11. Full Info for Address
CREATE TABLE search_results (
    id SERIAL PRIMARY KEY,
    address_name VARCHAR(50),
    full_name VARCHAR(100),
    level_of_bill VARCHAR(20),
    make VARCHAR(30),
    condition CHAR(1),
    category_name VARCHAR(50)
);

CREATE OR REPLACE PROCEDURE sp_courses_by_address(address_name VARCHAR(100))
AS
$$
	BEGIN
		TRUNCATE TABLE search_results;
		INSERT INTO 
			search_results(address_name, full_name, level_of_bill, make, condition, category_name)
		SELECT 
			a.name,
			cl.full_name,
			CASE
				WHEN co.bill <= 20 THEN 'Low'
				WHEN co.bill <= 30 THEN 'Medium'
				WHEN co.bill > 30 THEN 'High'
			END,
			c.make,
			c.condition,
			cat.name
		FROM
			addresses AS a
				JOIN courses AS co
				ON a.id = co.from_address_id
					JOIN clients AS cl
					ON cl.id = co.client_id
						JOIN cars AS c
						ON co.car_id = c.id
							JOIN categories AS cat
							ON cat.id = c.category_id
		WHERE 
			a.name = address_name
		ORDER BY
			c.make,
			cl.full_name
		;
		RETURN;
	END;
$$
LANGUAGE plpgsql;
