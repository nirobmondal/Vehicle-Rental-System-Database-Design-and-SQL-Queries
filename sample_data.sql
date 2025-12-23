-- Vehicle Rental System - Sample Data
-- Insert sample data for testing and demonstration

-- Insert Vehicle Types
INSERT INTO VehicleTypes (type_name, description, base_rate_per_day) VALUES
('Sedan', 'Comfortable 4-door passenger car', 50.00),
('SUV', 'Sport Utility Vehicle for families and groups', 80.00),
('Truck', 'Pickup truck for hauling and towing', 75.00),
('Van', 'Spacious van for large groups', 90.00),
('Luxury', 'High-end luxury vehicles', 150.00),
('Economy', 'Budget-friendly compact cars', 35.00);

-- Insert Customers
INSERT INTO Customers (first_name, last_name, email, phone, address, license_number, date_of_birth) VALUES
('John', 'Doe', 'john.doe@email.com', '555-0101', '123 Main St, City, State 12345', 'DL123456', '1990-05-15'),
('Jane', 'Smith', 'jane.smith@email.com', '555-0102', '456 Oak Ave, City, State 12345', 'DL234567', '1985-08-22'),
('Robert', 'Johnson', 'robert.j@email.com', '555-0103', '789 Pine Rd, City, State 12345', 'DL345678', '1992-03-10'),
('Emily', 'Williams', 'emily.w@email.com', '555-0104', '321 Elm St, City, State 12345', 'DL456789', '1988-11-30'),
('Michael', 'Brown', 'michael.b@email.com', '555-0105', '654 Maple Dr, City, State 12345', 'DL567890', '1995-07-18');

-- Insert Vehicles
INSERT INTO Vehicles (type_id, make, model, year, license_plate, color, mileage, status, daily_rate, purchase_date, last_service_date) VALUES
(1, 'Toyota', 'Camry', 2022, 'ABC123', 'Silver', 15000, 'available', 55.00, '2022-01-15', '2024-11-01'),
(1, 'Honda', 'Accord', 2023, 'DEF456', 'Blue', 8000, 'available', 60.00, '2023-03-20', '2024-10-15'),
(2, 'Ford', 'Explorer', 2021, 'GHI789', 'Black', 25000, 'available', 85.00, '2021-06-10', '2024-09-20'),
(2, 'Chevrolet', 'Tahoe', 2023, 'JKL012', 'White', 12000, 'available', 95.00, '2023-02-05', '2024-11-10'),
(3, 'Ford', 'F-150', 2022, 'MNO345', 'Red', 18000, 'available', 80.00, '2022-08-12', '2024-10-01'),
(4, 'Chrysler', 'Pacifica', 2023, 'PQR678', 'Gray', 10000, 'available', 95.00, '2023-04-18', '2024-11-05'),
(5, 'BMW', '7 Series', 2024, 'STU901', 'Black', 3000, 'available', 175.00, '2024-01-10', '2024-10-25'),
(6, 'Hyundai', 'Elantra', 2022, 'VWX234', 'White', 20000, 'available', 40.00, '2022-05-22', '2024-09-15'),
(6, 'Kia', 'Rio', 2021, 'YZA567', 'Blue', 28000, 'maintenance', 38.00, '2021-09-30', '2024-08-20'),
(1, 'Nissan', 'Altima', 2023, 'BCD890', 'Silver', 9000, 'available', 58.00, '2023-07-14', '2024-11-12');

-- Insert Rentals
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, return_date, expected_return_date, status) VALUES
(1, 1, '2024-12-01', '2024-12-05', '2024-12-05', 'completed'),
(2, 3, '2024-12-10', '2024-12-15', '2024-12-15', 'completed'),
(3, 5, '2024-12-15', NULL, '2024-12-22', 'active'),
(4, 7, '2024-12-18', NULL, '2024-12-25', 'active'),
(5, 2, '2024-12-05', '2024-12-08', '2024-12-08', 'completed'),
(1, 4, '2024-12-20', NULL, '2024-12-27', 'active');

-- Insert Payments
INSERT INTO Payments (rental_id, amount, payment_method, transaction_id, status) VALUES
(1, 220.00, 'credit_card', 'TXN001234', 'completed'),
(2, 425.00, 'debit_card', 'TXN001235', 'completed'),
(3, 560.00, 'credit_card', 'TXN001236', 'completed'),
(4, 1225.00, 'credit_card', 'TXN001237', 'completed'),
(5, 180.00, 'cash', NULL, 'completed');
