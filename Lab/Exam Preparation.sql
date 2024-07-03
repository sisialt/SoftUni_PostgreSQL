•	1.1. Database Design
CREATE TABLE owners(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15) NOT NULL,
	address VARCHAR(50)
);

CREATE TABLE animal_types(
	id SERIAL PRIMARY KEY,
	animal_type VARCHAR(30) NOT NULL
);

CREATE TABLE cages(
	id SERIAL PRIMARY KEY,
	animal_type_id INT NOT NULL,
	CONSTRAINT fk_cages_animal_types
	FOREIGN KEY (animal_type_id) REFERENCES animal_types(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE animals(
	id SERIAL PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	birthdate DATE NOT NULL,
	owner_id INT,
	animal_type_id INT NOT NULL,
	
	CONSTRAINT fk_animals_owners
	FOREIGN KEY (owner_id) REFERENCES owners(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_animals_animal_types
	FOREIGN KEY (animal_type_id) REFERENCES animal_types(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE volunteers_departments(
	id SERIAL PRIMARY KEY,
	department_name VARCHAR(30) NOT NULL
);

CREATE TABLE volunteers(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15) NOT NULL,
	address VARCHAR(50),
	animal_id INT,
	department_id INT NOT NULL,
	
	CONSTRAINT fk_volunteers_animals
	FOREIGN KEY (animal_id) REFERENCES animals(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_volunteers_volunteers_departments
	FOREIGN KEY (department_id) REFERENCES volunteers_departments(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE animals_cages(
	cage_id INT NOT NULL,
	animal_id INT NOT NULL,
	
	CONSTRAINT fk_animals_cages_cages
	FOREIGN KEY (cage_id) REFERENCES cages(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_animals_cages_animals
	FOREIGN KEY (animal_id) REFERENCES animals(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

•	2.2. Insert
INSERT INTO volunteers(id, name, phone_number, address, animal_id, department_id)
VALUES
	(25, 'Anita Kostova', '0896365412', 'Sofia, 5 Rosa str.', 15, 1),
	(26, 'Dimitur Stoev', '0877564223', NULL, 42, 4),
	(27, 'Kalina Evtimova', '0896321112', 'Silistra, 21 Breza str.', 9, 7),
	(28, 'Stoyan Tomov', '0898564100', 'Montana, 1 Bor str.', 18, 8),
	(29, 'Boryana Mileva', '0888112233', NULL, 31, 5)
;

INSERT INTO animals(id, name, birthdate, owner_id, animal_type_id)
VALUES	
	(47, 'Giraffe', '2018-09-21', 21, 1),
	(48, 'Harpy Eagle', '2015-04-17', 15, 3),
	(49, 'Hamadryas Baboon', '2017-11-02', NULL, 1),
	(50, 'Tuatara', '2021-06-30', 2, 4)
;

•	2.3. Update
UPDATE animals
SET owner_id = (SELECT id FROM owners WHERE name = 'Kaloqn Stoqnov')
WHERE owner_id IS NULL

•	2.4. Delete
DELETE FROM volunteers_departments
WHERE department_name = 'Education program assistant'

•	3.5. Volunteers
SELECT	
	name,
	phone_number,
	address,
	animal_id,
	department_id
FROM 
	volunteers
ORDER BY
	name ASC,
	animal_id ASC,
	department_id
	

•	3.6. Animals Data
SELECT	
	a.name,
	at.animal_type,
	TO_CHAR(a.birthdate, 'DD.MM.YYYY')
FROM
	animals AS a
JOIN
	animal_types AS at
ON a.animal_type_id = at.id
ORDER BY
	name ASC


•	3.7. Owners and Their Animals
SELECT	
	o.name AS "Owner",
	COUNT(*) AS "Count of animals" 
FROM
	owners AS o
JOIN animals AS a
	ON o.id = a.owner_id
GROUP BY
	o.name
ORDER BY
	"Count of animals" DESC,
	"Owner" ASC
LIMIT 5


•	3.8. Owners, Animals and Cages
SELECT	
	CONCAT(o.name, ' - ', a.name) AS "Owners - Animals", 
	o.phone_number AS "Phone Number",
	ac.cage_id AS "Cage ID"
FROM
	owners AS o
JOIN animals AS a
	ON o.id = a.owner_id
		JOIN animals_cages AS ac
			ON a.id = ac.animal_id
				JOIN animal_types AS at
					ON a.animal_type_id = at.id
WHERE 
	at.animal_type = 'Mammals'
ORDER BY
	o.name ASC,
	a.name DESC
	
•	3.9. Volunteers in Sofia
SELECT	
	v.name AS "Volunteers Name",
	v.phone_number AS "Phone Number",
	TRIM(RIGHT(TRIM(v.address), -7)) AS "Address"
FROM
	volunteers AS v
JOIN volunteers_departments AS vd
	ON v.department_id = vd.id
WHERE 
	vd.department_name = 'Education program assistant'
		AND
	v.address LIKE'%Sofia%'
ORDER BY
	v.name ASC

•	3.10. Animals for Adoption
SELECT	
	a.name AS "Animal Name",
	TO_CHAR(a.birthdate, 'YYYY') AS "Birth Year",
	at.animal_type AS "Animal Type"
FROM
	animals AS a
JOIN animal_types AS at
	ON a.animal_type_id = at.id
WHERE 
	a.owner_id IS NULL
		AND
	AGE('01/01/2022', a.birthdate) < INTERVAL '5 years'
		AND
	at.animal_type <> 'Birds'
ORDER BY
	a.name ASC

•	4.11. All Volunteers in a Department
CREATE OR REPLACE FUNCTION fn_get_volunteers_count_from_department(
	searched_volunteers_department VARCHAR(30)
)
RETURNS INT AS
$$
	DECLARE
		count_volunteers INT;
	BEGIN
		SELECT COUNT(*) INTO count_volunteers  # COUNT(v.id)
		FROM 
			volunteers AS v
			JOIN volunteers_departments AS vd
				ON v.department_id = vd.id
		WHERE
			vd.department_name = searched_volunteers_department;
			
		RETURN count_volunteers;
	END;
$$
LANGUAGE plpgsql;

•	4.12. Animals with Owner or Not
CREATE OR REPLACE PROCEDURE sp_animals_with_owners_or_not(
	IN animal_name VARCHAR(30),
	OUT owner_name VARCHAR(50)
)
AS
$$
	BEGIN
		SELECT 
			o.name INTO owner_name
		FROM
			owners AS o
			LEFT JOIN animals AS a
				ON o.id = a.owner_id
		WHERE
			a.name = animal_name;
		IF owner_name IS NULL THEN
			owner_name := 'For adoption';
		END IF;
		RETURN;
	END;
$$
LANGUAGE plpgsql;
