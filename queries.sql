 -- creating a new database for the assignment
CREATE DATABASE
  Rental_System;

-- creating Users table
CREATE TABLE
  Users (
    user_id INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('Admin', 'Customer')) NOT NULL
  );

-- creating Vehicles table 
CREATE TABLE
  Vehicles (
    vehicle_id INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('car', 'bike', 'truck')) NOT NULL,
    model VARCHAR(50) NOT NULL,
    rental_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) CHECK (status IN ('available', 'rented', 'maintenance')) NOT NULL
  );

-- creating Bookings table
CREATE TABLE
  Bookings (
    booking_id INT PRIMARY KEY NOT NULL,
    user_id INT NOT NULL REFERENCES users (user_id),
    vehicle_id INT NOT NULL REFERENCES vehicles (vehicle_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) CHECK (
      status IN ('pending', 'confirmed', 'completed', 'cancelled')
    ) NOT NULL,
    total_cost DECIMAL(10, 2) NOT NULL
  );

-- inserting values into Users table
INSERT INTO
  Users (user_id, name, email, password, phone, role)
VALUES
  (
    1,
    'Alice',
    'alice@example.com',
    'alice123',
    '1234567890',
    'Customer'
  ),
  (
    2,
    'Bob',
    'bob@example.com',
    'bob123',
    '0987654321',
    'Admin'
  ),
  (
    3,
    'Charlie',
    'charlie@example.com',
    'charlie123',
    '1122334455',
    'Customer'
  );

-- inserting values into Vechiles tables
INSERT INTO
  Vehicles (
    vehicle_id,
    name,
    registration_number,
    type
,
      model,
      rental_price,
      status
  )
VALUES
  (
    1,
    'Toyota Corolla',
    'ABC-123',
    'car',
    '2022',
    50.00,
    'available'
  ),
  (
    2,
    'Honda Civic',
    'DEF-456',
    'car',
    '2021',
    60.00,
    'rented'
  ),
  (
    3,
    'Yamaha R15',
    'GHI-789',
    'bike',
    '2023',
    30.00,
    'available'
  ),
  (
    4,
    'Ford F-150',
    'JKL-012',
    'truck',
    '2020',
    100.00,
    'maintenance'
  );

-- inserting values into Bookings table
INSERT INTO
  Bookings (
    booking_id,
    user_id,
    vehicle_id,
    start_date,
    end_date,
    status,
    total_cost
  )
VALUES
  (
    1,
    1,
    2,
    '2023-10-01',
    '2023-10-05',
    'completed',
    240.00
  ),
  (
    2,
    1,
    2,
    '2023-11-01',
    '2023-11-03',
    'completed',
    120.00
  ),
  (
    3,
    3,
    2,
    '2023-12-01',
    '2023-12-02',
    'confirmed',
    60.00
  ),
  (
    4,
    1,
    1,
    '2023-12-10',
    '2023-12-12',
    'pending',
    100.00
  );

-- Query 1: Retrieve booking information along with Customer name and Vehicle name.
SELECT
  booking_id,
  u.name AS customer_name,
  v.name AS vehicle_name,
  start_date,
  end_date,
  b.status
FROM
  Users AS u
  INNER JOIN Bookings AS b ON u.user_id = b.user_id
  INNER JOIN Vehicles AS v ON b.vehicle_id = v.vehicle_id;

-- Query 2: Find all vehicles that have never been booked.
SELECT
  v.vehicle_id,
  v.name,
  v.type,
  v.model,
  v.registration_number,
  v.rental_price,
  v.status
FROM
  Vehicles AS v
WHERE
  NOT EXISTS (
    SELECT
      1
    FROM
      Bookings AS b
    WHERE
      b.vehicle_id = v.vehicle_id
  )
ORDER BY
  v.vehicle_id ASC;

-- Query 3: Retrieve all available vehicles of a specific type (e.g. cars).
SELECT
  vehicle_id,
  name,
  type,
  model,
  registration_number,
  rental_price,
  status
FROM
  Vehicles
WHERE
  type = 'car'
  AND status = 'available';

-- Query 4:Find the total number of bookings for each vehicle and display only those vehicles that have more than 2 bookings.
SELECT
  v.name AS vehicle_name,
  COUNT(*) AS total_bookings
FROM
  Bookings AS b
  INNER JOIN Vehicles AS v ON b.vehicle_id = v.vehicle_id
GROUP BY
  v.name
HAVING
  COUNT(*) > 2;