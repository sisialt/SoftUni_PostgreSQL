1.1.	Database Design
CREATE TABLE towns(
	id SERIAL PRIMARY KEY,
	name VARCHAR(45) NOT NULL
);

CREATE TABLE stadiums(
	id SERIAL PRIMARY KEY,
	name VARCHAR(45) NOT NULL,
	capacity INT NOT NULL CHECK (capacity > 0),
	town_id INT NOT NULL,
	
	CONSTRAINT fk_stadiums_towns
	FOREIGN KEY (town_id)
	REFERENCES towns(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
	
);

CREATE TABLE teams(
	id SERIAL PRIMARY KEY,
	name VARCHAR(45) NOT NULL,
	established DATE NOT NULL,
	fan_base INT DEFAULT 0 CHECK (fan_base >= 0) NOT NULL,
	stadium_id INT NOT NULL,
	
	CONSTRAINT fk_teams_stadiums
	FOREIGN KEY (stadium_id)
	REFERENCES stadiums(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE coaches(
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(10) NOT NULL,
	last_name VARCHAR(20) NOT NULL,
	salary NUMERIC(10,2) DEFAULT 0 CHECK (salary >= 0) NOT NULL,
	coach_level INT DEFAULT 0 CHECK (coach_level >= 0) NOT NULL
);

CREATE TABLE skills_data(
	id SERIAL PRIMARY KEY,
	dribbling INT DEFAULT 0 CHECK (dribbling >= 0),
	pace INT DEFAULT 0 CHECK (pace >= 0),
	"passing" INT DEFAULT 0 CHECK ("passing" >= 0),
	shooting INT DEFAULT 0 CHECK (shooting >= 0),
	speed INT DEFAULT 0 CHECK (speed >= 0),
	strength INT DEFAULT 0 CHECK (strength >= 0)
);

CREATE TABLE players(
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(10) NOT NULL,
	last_name VARCHAR(20) NOT NULL,
	age INT DEFAULT 0 CHECK (age >= 0) NOT NULL,
	"position" CHAR(1) NOT NULL,
	salary NUMERIC(10,2) DEFAULT 0 CHECK (salary >= 0) NOT NULL,
	hire_date TIMESTAMP,
	skills_data_id INT NOT NULL,
	team_id INT,
	
	CONSTRAINT fk_players_skills_data
	FOREIGN KEY (skills_data_id)
	REFERENCES skills_data(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_players_teams
	FOREIGN KEY (team_id)
	REFERENCES teams(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE players_coaches(
	player_id INT,
	coach_id INT,
	
	CONSTRAINT fk_players_coaches_players
	FOREIGN KEY (player_id)
	REFERENCES players(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	
	CONSTRAINT fk_players_coaches_coaches
	FOREIGN KEY (coach_id)
	REFERENCES coaches(id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);




2.2. Insert

INSERT INTO coaches(first_name, last_name, salary, coach_level)
SELECT
	first_name,
	last_name,
	salary * 2,
	LENGTH(first_name)
FROM
	players
WHERE
	hire_date < '2013-12-13 07:18:46'

2.3. Update

UPDATE coaches
SET salary = salary * coach_level
WHERE 
	id = 
	(
	SELECT
		c.id
	FROM
		coaches AS c
		JOIN players_coaches AS pc
		ON c.id = pc.coach_id
	WHERE
		pc.player_id IS NOT NULL
		AND LEFT(c.first_name,1) = 'C'
	GROUP BY
		c.id
		)

2.4. Delete

DELETE FROM
	players CASCADE
WHERE
	hire_date < '2013-12-13 07:18:46'

3.5. Players

SELECT
	CONCAT(first_name, ' ', last_name) AS full_name,
	age,
	hire_date
FROM
	players
WHERE
	first_name LIKE('M%')
ORDER BY
	age DESC,
	full_name ASC

3.6. Offensive Players without Team

SELECT
	p.id,
	CONCAT(p.first_name, ' ', p.last_name) AS full_name,
	p.age,
	p.position,
	p.salary,
	sd.pace,
	sd.shooting
FROM
	players AS p
		JOIN skills_data AS sd
		ON p.skills_data_id = sd.id
WHERE
	p.position = 'A'
		AND
	p.team_id IS NULL
		AND
	sd.pace + sd.shooting > 130

3.7. Teams with Player Count and Fan Base

SELECT
	t.id AS team_id,
	t.name AS team_name,
	COUNT(p.id) AS player_count,
	fan_base
FROM
	teams AS t
		LEFT JOIN players AS p
		ON t.id = p.team_id
WHERE
	t.fan_base > 30000
GROUP BY
	t.id
ORDER BY
	player_count DESC,
	fan_base DESC


3.8. Coaches, Players Skills and Teams Overview

SELECT
	CONCAT(c.first_name, ' ', c.last_name) AS coach_full_name,
	CONCAT(p.first_name, ' ', p.last_name) AS player_full_name,
	t.name AS team_name,
	sd.passing,
	sd.shooting,
	sd.speed
FROM
	players AS p
		JOIN players_coaches AS pc
		ON p.id = pc.player_id
			JOIN coaches AS c
			ON c.id = pc.coach_id
				JOIN skills_data AS sd
				ON p.skills_data_id = sd.id
					JOIN teams AS t
					ON p.team_id = t.id
ORDER BY
	coach_full_name,
	player_full_name DESC


4.9. Stadium Teams Information

CREATE OR REPLACE FUNCTION fn_stadium_team_name(stadium_name VARCHAR(30))
RETURNS TABLE(
	team_name VARCHAR
) AS
$$
	BEGIN
		RETURN QUERY
			SELECT
				t.name
			FROM
				teams AS t
					JOIN stadiums AS s
					ON t.stadium_id = s.id
			WHERE
				s.name = stadium_name
			ORDER BY
				t.name
		;
	END;
$$
LANGUAGE plpgsql;

4.10. Player Team Finder

CREATE OR REPLACE PROCEDURE sp_players_team_name(
	IN player_name VARCHAR(50),
	OUT team_name VARCHAR
) AS
$$
	BEGIN
		SELECT
			t.name INTO team_name
		FROM
			teams AS t
				JOIN players AS p
				ON t.id = p.team_id
		WHERE
			CONCAT(p.first_name, ' ', p.last_name) = player_name;
		IF team_name IS NULL THEN
			team_name := 'The player currently has no team';
		END IF;
		RETURN;
	END;
$$
LANGUAGE plpgsql;



