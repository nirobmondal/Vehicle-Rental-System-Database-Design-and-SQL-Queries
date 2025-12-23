# Testing Guide - Vehicle Rental System Database

This guide provides step-by-step instructions to test and validate the database implementation.

## 🚀 Quick Start Testing

### 1. Database Setup
```bash
# Create database
createdb vehicle_rental_system

# Install schema
psql -d vehicle_rental_system -f schema.sql

# Load sample data
psql -d vehicle_rental_system -f sample_data.sql

# Apply improvements (recommended)
psql -d vehicle_rental_system -f improvements.sql
```

## ✅ Basic Functionality Tests

### Test 1: Verify Table Creation
```sql
-- Check all tables are created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Expected: 8 tables
-- AuditLog, Customers, Payments, Rentals, VehicleDamageReports, 
-- VehicleTypes, Vehicles
```

### Test 2: Verify Sample Data
```sql
-- Count records in each table
SELECT 
    (SELECT COUNT(*) FROM VehicleTypes) AS vehicle_types,
    (SELECT COUNT(*) FROM Customers) AS customers,
    (SELECT COUNT(*) FROM Vehicles) AS vehicles,
    (SELECT COUNT(*) FROM Rentals) AS rentals,
    (SELECT COUNT(*) FROM Payments) AS payments;

-- Expected: 6 types, 5 customers, 10 vehicles, 6 rentals, 5 payments
```

### Test 3: Check Indexes
```sql
-- List all indexes
SELECT 
    tablename, 
    indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;
```

## 🔬 Feature Testing

### Test 4: Automatic Rental Amount Calculation
```sql
-- Insert a new rental (amount should be calculated automatically)
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, expected_return_date)
VALUES (1, 8, '2024-12-25', '2024-12-28');

-- Check the calculated amount
SELECT 
    rental_id,
    vehicle_id,
    rental_date,
    expected_return_date,
    total_amount,
    expected_return_date - rental_date AS days,
    (SELECT daily_rate FROM Vehicles WHERE vehicle_id = 8) AS daily_rate
FROM Rentals
ORDER BY rental_id DESC
LIMIT 1;

-- Clean up
DELETE FROM Rentals WHERE rental_id = (SELECT MAX(rental_id) FROM Rentals);
```

### Test 5: Vehicle Status Update Trigger
```sql
-- Check initial status
SELECT vehicle_id, status FROM Vehicles WHERE vehicle_id = 6;

-- Create a rental (should change status to 'rented')
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, expected_return_date, status)
VALUES (2, 6, CURRENT_DATE, CURRENT_DATE + 3, 'active');

-- Check status changed to 'rented'
SELECT vehicle_id, status FROM Vehicles WHERE vehicle_id = 6;

-- Complete the rental (should change status back to 'available')
UPDATE Rentals 
SET status = 'completed', return_date = CURRENT_DATE
WHERE vehicle_id = 6 AND status = 'active';

-- Check status changed to 'available'
SELECT vehicle_id, status FROM Vehicles WHERE vehicle_id = 6;

-- Clean up
DELETE FROM Rentals WHERE vehicle_id = 6 AND rental_date = CURRENT_DATE;
```

## 🛡️ Constraint Testing (with improvements.sql)

### Test 6: Overlapping Rental Prevention
```sql
-- This should succeed
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, expected_return_date)
VALUES (1, 10, '2025-01-01', '2025-01-05');

-- This should FAIL with overlap error
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, expected_return_date)
VALUES (2, 10, '2025-01-03', '2025-01-07');

-- Expected: ERROR: Vehicle is already rented for overlapping dates

-- Clean up
DELETE FROM Rentals WHERE vehicle_id = 10 AND rental_date >= '2025-01-01';
```

### Test 7: Email Format Validation
```sql
-- This should succeed
INSERT INTO Customers (first_name, last_name, email, phone, license_number, date_of_birth)
VALUES ('Test', 'User', 'test.user@example.com', '555-9999', 'DL999999', '1990-01-01');

-- This should FAIL with email format error
INSERT INTO Customers (first_name, last_name, email, phone, license_number, date_of_birth)
VALUES ('Bad', 'Email', 'notanemail', '555-8888', 'DL888888', '1990-01-01');

-- Expected: ERROR: new row violates check constraint "check_email_format"

-- Clean up
DELETE FROM Customers WHERE license_number = 'DL999999';
```

### Test 8: Late Fee Calculation
```sql
-- Create a rental that will be returned late
INSERT INTO Rentals (customer_id, vehicle_id, rental_date, expected_return_date, status)
VALUES (1, 8, '2024-12-01', '2024-12-05', 'active');

-- Get the rental_id
SELECT rental_id FROM Rentals ORDER BY rental_id DESC LIMIT 1;

-- Return it late (7 days late)
UPDATE Rentals 
SET return_date = '2024-12-12', status = 'completed'
WHERE rental_id = (SELECT MAX(rental_id) FROM Rentals);

-- Check late fee was calculated
SELECT 
    rental_id,
    rental_date,
    expected_return_date,
    return_date,
    late_days,
    late_fee,
    total_amount
FROM Rentals
WHERE rental_id = (SELECT MAX(rental_id) FROM Rentals);

-- Expected: late_days = 7, late_fee calculated as (7 * daily_rate * 0.20)

-- Clean up
DELETE FROM Rentals WHERE rental_id = (SELECT MAX(rental_id) FROM Rentals);
```

### Test 9: Payment Overpayment Prevention
```sql
-- Get an active rental
SELECT rental_id, total_amount FROM Rentals WHERE status = 'completed' LIMIT 1;

-- Try to pay more than the rental amount (should fail)
-- Replace 1 with an actual rental_id and adjust amounts
INSERT INTO Payments (rental_id, amount, payment_method)
VALUES (1, 999999.99, 'cash');

-- Expected: ERROR: Payment amount would exceed rental total

-- This should work (pay exact or less amount)
INSERT INTO Payments (rental_id, amount, payment_method)
VALUES (1, 50.00, 'cash');

-- Clean up
DELETE FROM Payments WHERE amount = 50.00;
```

### Test 10: Age Validation
```sql
-- This should FAIL - customer is under 18
INSERT INTO Customers (first_name, last_name, email, phone, license_number, date_of_birth)
VALUES ('Young', 'Person', 'young@example.com', '555-1111', 'DL111111', '2010-01-01');

-- Expected: ERROR: new row violates check constraint

-- This should succeed - customer is 18+
INSERT INTO Customers (first_name, last_name, email, phone, license_number, date_of_birth)
VALUES ('Adult', 'Person', 'adult@example.com', '555-2222', 'DL222222', '2000-01-01');

-- Clean up
DELETE FROM Customers WHERE license_number = 'DL222222';
```

## 📊 Query Testing

### Test 11: Available Vehicles Query
```sql
-- Run Query 1 from queries.sql
SELECT 
    v.vehicle_id,
    v.make,
    v.model,
    vt.type_name,
    v.daily_rate,
    v.mileage
FROM Vehicles v
JOIN VehicleTypes vt ON v.type_id = vt.type_id
WHERE v.status = 'available'
ORDER BY v.daily_rate;

-- Should return multiple vehicles
```

### Test 12: Active Rentals Dashboard
```sql
-- Test the view created by improvements.sql
SELECT * FROM active_rentals_dashboard;

-- Should show current active rentals with status flags
```

### Test 13: Vehicles Needing Service
```sql
-- Test maintenance tracking view
SELECT * FROM vehicles_needing_service;

-- Should show vehicles approaching or past service dates
```

### Test 14: Revenue Analysis
```sql
-- Run Query 7 from queries.sql
SELECT 
    vt.type_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_revenue,
    AVG(r.total_amount) AS avg_rental_amount
FROM VehicleTypes vt
LEFT JOIN Vehicles v ON vt.type_id = v.type_id
LEFT JOIN Rentals r ON v.vehicle_id = r.vehicle_id AND r.status = 'completed'
GROUP BY vt.type_name
ORDER BY total_revenue DESC NULLS LAST;
```

### Test 15: Audit Trail
```sql
-- Check if audit trail is working
-- Make a change
UPDATE Vehicles SET mileage = mileage + 100 WHERE vehicle_id = 1;

-- Check audit log
SELECT 
    audit_id,
    table_name,
    record_id,
    operation,
    old_values->>'mileage' AS old_mileage,
    new_values->>'mileage' AS new_mileage,
    changed_at
FROM AuditLog
WHERE table_name = 'Vehicles' AND record_id = 1
ORDER BY changed_at DESC
LIMIT 1;

-- Should show the mileage change
```

## 🔍 Performance Testing

### Test 16: Index Effectiveness
```sql
-- Check if indexes are being used
EXPLAIN ANALYZE
SELECT * FROM Rentals WHERE status = 'active';

-- Should show Index Scan, not Seq Scan

EXPLAIN ANALYZE
SELECT * FROM Vehicles WHERE status = 'available';

-- Should use idx_vehicles_status
```

### Test 17: Complex Query Performance
```sql
-- Test a complex query with timing
\timing on

SELECT 
    vt.type_name,
    v.make || ' ' || v.model AS vehicle,
    COALESCE(SUM(r.total_amount), 0) AS total_revenue,
    RANK() OVER (PARTITION BY vt.type_name ORDER BY COALESCE(SUM(r.total_amount), 0) DESC) AS rank_in_type
FROM VehicleTypes vt
JOIN Vehicles v ON vt.type_id = v.type_id
LEFT JOIN Rentals r ON v.vehicle_id = r.vehicle_id AND r.status = 'completed'
GROUP BY vt.type_name, v.vehicle_id, v.make, v.model
ORDER BY vt.type_name, rank_in_type;

\timing off
```

## 📝 Data Integrity Testing

### Test 18: Referential Integrity
```sql
-- Try to delete a customer with rentals (should fail)
DELETE FROM Customers WHERE customer_id = 1;

-- Expected: ERROR: update or delete on table violates foreign key constraint

-- Try to delete a vehicle type with vehicles (should fail)
DELETE FROM VehicleTypes WHERE type_id = 1;

-- Expected: ERROR: update or delete on table violates foreign key constraint
```

### Test 19: Check Constraints
```sql
-- Try invalid vehicle year (should fail)
INSERT INTO Vehicles (type_id, make, model, year, license_plate, daily_rate)
VALUES (1, 'Test', 'Model', 1800, 'TEST123', 50.00);

-- Expected: ERROR: new row violates check constraint "vehicles_year_check"

-- Try negative daily rate (should fail)
INSERT INTO Vehicles (type_id, make, model, year, license_plate, daily_rate)
VALUES (1, 'Test', 'Model', 2024, 'TEST456', -10.00);

-- Expected: ERROR: new row violates check constraint
```

### Test 20: Transaction Testing
```sql
-- Test rollback
BEGIN;
    UPDATE Vehicles SET status = 'maintenance' WHERE vehicle_id = 1;
    SELECT status FROM Vehicles WHERE vehicle_id = 1;
    -- Should show 'maintenance'
ROLLBACK;

-- Check status reverted
SELECT status FROM Vehicles WHERE vehicle_id = 1;
-- Should show original status
```

## 📈 Reporting Tests

### Test 21: Customer Lifetime Value
```sql
-- Run Query 16 from queries.sql
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS lifetime_value
FROM Customers c
LEFT JOIN Rentals r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC NULLS LAST;
```

### Test 22: Database Statistics
```sql
-- Run Query 22 from queries.sql
SELECT 
    (SELECT COUNT(*) FROM Customers) AS total_customers,
    (SELECT COUNT(*) FROM Vehicles) AS total_vehicles,
    (SELECT COUNT(*) FROM Vehicles WHERE status = 'available') AS available_vehicles,
    (SELECT COUNT(*) FROM Rentals WHERE status = 'active') AS active_rentals,
    (SELECT COALESCE(SUM(total_amount), 0) FROM Rentals WHERE status = 'completed') AS total_revenue;
```

## ✅ Test Results Checklist

After running all tests, verify:

- [ ] All tables created successfully
- [ ] Sample data loaded correctly
- [ ] Automatic calculations work (rental amount)
- [ ] Triggers function properly (status updates)
- [ ] Constraints prevent invalid data
  - [ ] Overlapping rentals blocked
  - [ ] Invalid email format rejected
  - [ ] Overpayment prevented
  - [ ] Age validation works
  - [ ] Date constraints enforced
- [ ] Queries return expected results
- [ ] Views are accessible and accurate
- [ ] Indexes improve query performance
- [ ] Audit trail captures changes
- [ ] Referential integrity maintained
- [ ] Late fee calculation accurate
- [ ] Maintenance tracking functional

## 🐛 Common Issues and Solutions

### Issue: Trigger not firing
**Solution**: Check trigger was created after table:
```sql
SELECT * FROM pg_trigger WHERE tgname LIKE 'trg_%';
```

### Issue: Constraint violation
**Solution**: Check constraint details:
```sql
SELECT conname, contype, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'rentals'::regclass;
```

### Issue: Poor query performance
**Solution**: Analyze and create missing indexes:
```sql
EXPLAIN ANALYZE your_query_here;
```

## 📚 Additional Testing

For production use, consider:
- Load testing with larger datasets (10,000+ records)
- Concurrent transaction testing
- Backup and restore procedures
- Data migration scenarios
- Security penetration testing

---

**Tip**: Run these tests in a development environment before deploying to production!
