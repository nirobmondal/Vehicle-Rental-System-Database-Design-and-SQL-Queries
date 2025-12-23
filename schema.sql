-- Vehicle Rental System Database Schema
-- PostgreSQL Database Design

-- Drop existing tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS Payments CASCADE;
DROP TABLE IF EXISTS Rentals CASCADE;
DROP TABLE IF EXISTS Vehicles CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS VehicleTypes CASCADE;

-- Table: VehicleTypes
-- Stores different types of vehicles available for rent
CREATE TABLE VehicleTypes (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    base_rate_per_day DECIMAL(10, 2) NOT NULL CHECK (base_rate_per_day > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Customers
-- Stores customer information
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (date_of_birth < CURRENT_DATE - INTERVAL '18 years') -- Must be at least 18 years old
);

-- Table: Vehicles
-- Stores vehicle inventory
CREATE TABLE Vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    type_id INTEGER NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    color VARCHAR(30),
    mileage INTEGER DEFAULT 0 CHECK (mileage >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'rented', 'maintenance', 'retired')),
    daily_rate DECIMAL(10, 2) NOT NULL CHECK (daily_rate > 0),
    purchase_date DATE,
    last_service_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES VehicleTypes(type_id) ON DELETE RESTRICT
);

-- Table: Rentals
-- Stores rental transaction information
CREATE TABLE Rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    rental_date DATE NOT NULL DEFAULT CURRENT_DATE,
    return_date DATE,
    expected_return_date DATE NOT NULL,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE RESTRICT,
    CHECK (expected_return_date > rental_date),
    CHECK (return_date IS NULL OR return_date >= rental_date)
);

-- Table: Payments
-- Stores payment information for rentals
CREATE TABLE Payments (
    payment_id SERIAL PRIMARY KEY,
    rental_id INTEGER NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'credit_card', 'debit_card', 'online')),
    transaction_id VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT
);

-- Create indexes for better query performance
CREATE INDEX idx_vehicles_status ON Vehicles(status);
CREATE INDEX idx_vehicles_type ON Vehicles(type_id);
CREATE INDEX idx_rentals_customer ON Rentals(customer_id);
CREATE INDEX idx_rentals_vehicle ON Rentals(vehicle_id);
CREATE INDEX idx_rentals_status ON Rentals(status);
CREATE INDEX idx_rentals_dates ON Rentals(rental_date, expected_return_date);
CREATE INDEX idx_payments_rental ON Payments(rental_id);
CREATE INDEX idx_customers_email ON Customers(email);

-- Create a function to calculate rental total amount
CREATE OR REPLACE FUNCTION calculate_rental_amount(
    p_vehicle_id INTEGER,
    p_rental_date DATE,
    p_expected_return_date DATE
) RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_daily_rate DECIMAL(10, 2);
    v_days INTEGER;
BEGIN
    -- Get the daily rate for the vehicle
    SELECT daily_rate INTO v_daily_rate
    FROM Vehicles
    WHERE vehicle_id = p_vehicle_id;
    
    -- Calculate number of days
    v_days := p_expected_return_date - p_rental_date;
    
    -- Return total amount
    RETURN v_daily_rate * v_days;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update vehicle status when rented
CREATE OR REPLACE FUNCTION update_vehicle_status_on_rental()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' THEN
        UPDATE Vehicles SET status = 'rented' WHERE vehicle_id = NEW.vehicle_id;
    ELSIF NEW.status = 'completed' OR NEW.status = 'cancelled' THEN
        UPDATE Vehicles SET status = 'available' WHERE vehicle_id = NEW.vehicle_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_vehicle_status
AFTER INSERT OR UPDATE ON Rentals
FOR EACH ROW
EXECUTE FUNCTION update_vehicle_status_on_rental();

-- Create a trigger to automatically calculate rental amount
CREATE OR REPLACE FUNCTION set_rental_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_amount IS NULL THEN
        NEW.total_amount := calculate_rental_amount(
            NEW.vehicle_id,
            NEW.rental_date,
            NEW.expected_return_date
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_rental_amount
BEFORE INSERT ON Rentals
FOR EACH ROW
EXECUTE FUNCTION set_rental_amount();
