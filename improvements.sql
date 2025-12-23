-- Database Improvements and Critical Fixes
-- This file contains SQL statements to address the most critical logical issues
-- Run this after schema.sql and sample_data.sql to enhance the database

-- ============================================================================
-- CRITICAL FIX #1: Prevent Overlapping Rentals
-- ============================================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_check_rental_overlap ON Rentals;
DROP FUNCTION IF EXISTS check_rental_overlap();

-- Function to prevent double-booking of vehicles
CREATE OR REPLACE FUNCTION check_rental_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the vehicle is already rented during the requested period
    IF EXISTS (
        SELECT 1 
        FROM Rentals 
        WHERE vehicle_id = NEW.vehicle_id
          AND status = 'active'  -- Only check active rentals, not completed ones
          AND rental_id != COALESCE(NEW.rental_id, -1)
          AND (
              -- New rental overlaps with existing rental in any way
              NEW.rental_date <= expected_return_date
              AND NEW.expected_return_date >= rental_date
          )
    ) THEN
        RAISE EXCEPTION 'Vehicle is already rented for overlapping dates. Please choose different dates or another vehicle.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check for overlaps
CREATE TRIGGER trg_check_rental_overlap
BEFORE INSERT OR UPDATE ON Rentals
FOR EACH ROW
EXECUTE FUNCTION check_rental_overlap();

-- ============================================================================
-- CRITICAL FIX #2: Email Format Validation
-- ============================================================================

-- Add email format validation to ensure valid email addresses
ALTER TABLE Customers
ADD CONSTRAINT check_email_format 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- ============================================================================
-- IMPROVEMENT #1: Late Return Fee Calculation
-- ============================================================================

-- Add columns for late return tracking
ALTER TABLE Rentals 
ADD COLUMN IF NOT EXISTS late_fee DECIMAL(10, 2) DEFAULT 0 CHECK (late_fee >= 0),
ADD COLUMN IF NOT EXISTS late_days INTEGER DEFAULT 0 CHECK (late_days >= 0);

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_calculate_late_fee ON Rentals;
DROP FUNCTION IF EXISTS calculate_late_fee();

-- Function to calculate late fees (20% of daily rate per late day)
CREATE OR REPLACE FUNCTION calculate_late_fee()
RETURNS TRIGGER AS $$
DECLARE
    v_daily_rate DECIMAL(10, 2);
    v_rental_days INTEGER;
    v_original_amount DECIMAL(10, 2);
BEGIN
    -- Only calculate if return date is set and is after expected return date
    IF NEW.return_date IS NOT NULL AND NEW.return_date > NEW.expected_return_date THEN
        -- Store original amount if not already stored
        IF NEW.late_days = 0 THEN
            -- Calculate late days
            NEW.late_days := NEW.return_date - NEW.expected_return_date;
            
            -- Get vehicle daily rate
            SELECT daily_rate INTO v_daily_rate
            FROM Vehicles
            WHERE vehicle_id = NEW.vehicle_id;
            
            -- Calculate late fee (20% per day of the daily rate)
            NEW.late_fee := NEW.late_days * v_daily_rate * 0.20;
            
            -- Add late fee to total amount (only once)
            NEW.total_amount := NEW.total_amount + NEW.late_fee;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for late fee calculation
CREATE TRIGGER trg_calculate_late_fee
BEFORE UPDATE ON Rentals
FOR EACH ROW
WHEN (NEW.return_date IS NOT NULL AND OLD.return_date IS NULL)
EXECUTE FUNCTION calculate_late_fee();

-- ============================================================================
-- IMPROVEMENT #2: Enhanced Vehicle Status Management
-- ============================================================================

-- Drop and recreate the vehicle status trigger with better logic
DROP TRIGGER IF EXISTS trg_update_vehicle_status ON Rentals;
DROP FUNCTION IF EXISTS update_vehicle_status_on_rental();

CREATE OR REPLACE FUNCTION update_vehicle_status_on_rental()
RETURNS TRIGGER AS $$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    -- Get current vehicle status
    SELECT status INTO v_current_status
    FROM Vehicles
    WHERE vehicle_id = NEW.vehicle_id;
    
    IF NEW.status = 'active' THEN
        -- Only update to rented if vehicle is currently available
        IF v_current_status = 'available' THEN
            UPDATE Vehicles 
            SET status = 'rented' 
            WHERE vehicle_id = NEW.vehicle_id;
        ELSIF v_current_status != 'rented' THEN
            RAISE EXCEPTION 'Vehicle % is not available (current status: %)', NEW.vehicle_id, v_current_status;
        END IF;
        
    ELSIF NEW.status IN ('completed', 'cancelled') THEN
        -- Check if there are other active rentals for this vehicle
        IF NOT EXISTS (
            SELECT 1 
            FROM Rentals 
            WHERE vehicle_id = NEW.vehicle_id 
              AND status = 'active' 
              AND rental_id != NEW.rental_id
        ) THEN
            -- No other active rentals, set back to available
            UPDATE Vehicles 
            SET status = 'available' 
            WHERE vehicle_id = NEW.vehicle_id
              AND status = 'rented';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create improved trigger
CREATE TRIGGER trg_update_vehicle_status
AFTER INSERT OR UPDATE ON Rentals
FOR EACH ROW
EXECUTE FUNCTION update_vehicle_status_on_rental();

-- ============================================================================
-- IMPROVEMENT #3: Vehicle Maintenance Tracking
-- ============================================================================

-- Add maintenance scheduling columns
ALTER TABLE Vehicles
ADD COLUMN IF NOT EXISTS next_service_due_date DATE,
ADD COLUMN IF NOT EXISTS next_service_due_mileage INTEGER CHECK (next_service_due_mileage > 0);

-- Update existing vehicles with next service dates
UPDATE Vehicles
SET 
    next_service_due_date = COALESCE(last_service_date, purchase_date) + INTERVAL '6 months',
    next_service_due_mileage = mileage + 5000
WHERE next_service_due_date IS NULL;

-- Create view for vehicles needing service
CREATE OR REPLACE VIEW vehicles_needing_service AS
SELECT 
    v.vehicle_id,
    v.make,
    v.model,
    v.license_plate,
    v.status,
    v.mileage,
    v.next_service_due_mileage,
    v.last_service_date,
    v.next_service_due_date,
    CASE
        WHEN v.mileage >= v.next_service_due_mileage THEN 'URGENT: Mileage Limit Reached'
        WHEN CURRENT_DATE >= v.next_service_due_date THEN 'URGENT: Service Date Passed'
        WHEN v.mileage >= v.next_service_due_mileage - 500 THEN 'WARNING: Approaching Mileage Limit'
        WHEN CURRENT_DATE >= v.next_service_due_date - INTERVAL '7 days' THEN 'WARNING: Service Due Soon'
        ELSE 'OK'
    END AS service_status,
    v.next_service_due_mileage - v.mileage AS miles_until_service,
    v.next_service_due_date - CURRENT_DATE AS days_until_service
FROM Vehicles v
WHERE v.status != 'retired'
  AND v.next_service_due_mileage IS NOT NULL
  AND v.next_service_due_date IS NOT NULL
  AND (
      v.mileage >= v.next_service_due_mileage - 500 
      OR CURRENT_DATE >= v.next_service_due_date - INTERVAL '7 days'
  )
ORDER BY 
    CASE 
        WHEN v.mileage >= v.next_service_due_mileage THEN 1
        WHEN CURRENT_DATE >= v.next_service_due_date THEN 2
        WHEN v.mileage >= v.next_service_due_mileage - 500 THEN 3
        WHEN CURRENT_DATE >= v.next_service_due_date - INTERVAL '7 days' THEN 4
        ELSE 5
    END;

-- ============================================================================
-- IMPROVEMENT #4: Payment Validation
-- ============================================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_validate_payment_total ON Payments;
DROP FUNCTION IF EXISTS validate_payment_total();

-- Function to prevent overpayment
CREATE OR REPLACE FUNCTION validate_payment_total()
RETURNS TRIGGER AS $$
DECLARE
    v_rental_amount DECIMAL(10, 2);
    v_total_payments DECIMAL(10, 2);
BEGIN
    -- Get the total rental amount including any late fees
    SELECT total_amount INTO v_rental_amount
    FROM Rentals
    WHERE rental_id = NEW.rental_id;
    
    -- Calculate total payments including this new one
    SELECT COALESCE(SUM(amount), 0) + NEW.amount INTO v_total_payments
    FROM Payments
    WHERE rental_id = NEW.rental_id
      AND status = 'completed'
      AND payment_id != COALESCE(NEW.payment_id, -1);
    
    -- Prevent overpayment
    IF v_total_payments > v_rental_amount THEN
        RAISE EXCEPTION 'Payment amount $% would exceed rental total of $%. Maximum payment allowed: $%', 
            NEW.amount, v_rental_amount, (v_rental_amount - (v_total_payments - NEW.amount));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate payments
CREATE TRIGGER trg_validate_payment_total
BEFORE INSERT OR UPDATE ON Payments
FOR EACH ROW
WHEN (NEW.status = 'completed')
EXECUTE FUNCTION validate_payment_total();

-- ============================================================================
-- IMPROVEMENT #5: Damage Tracking System
-- ============================================================================

-- Create table for vehicle damage reports
CREATE TABLE IF NOT EXISTS VehicleDamageReports (
    damage_id SERIAL PRIMARY KEY,
    rental_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reported_by VARCHAR(50) CHECK (reported_by IN ('customer', 'staff', 'inspection')),
    damage_description TEXT NOT NULL,
    damage_severity VARCHAR(20) NOT NULL CHECK (damage_severity IN ('minor', 'moderate', 'severe', 'total_loss')),
    estimated_repair_cost DECIMAL(10, 2) CHECK (estimated_repair_cost >= 0),
    actual_repair_cost DECIMAL(10, 2) CHECK (actual_repair_cost >= 0),
    insurance_claim_id VARCHAR(50),
    repair_date DATE,
    status VARCHAR(20) DEFAULT 'reported' CHECK (status IN ('reported', 'under_review', 'approved', 'repaired', 'disputed', 'closed')),
    notes TEXT,
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE RESTRICT
);

-- Create index for quick damage lookups
CREATE INDEX IF NOT EXISTS idx_damage_reports_rental ON VehicleDamageReports(rental_id);
CREATE INDEX IF NOT EXISTS idx_damage_reports_vehicle ON VehicleDamageReports(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_damage_reports_status ON VehicleDamageReports(status);

-- ============================================================================
-- IMPROVEMENT #6: Audit Trail System
-- ============================================================================

-- Create audit log table
CREATE TABLE IF NOT EXISTS AuditLog (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Create index for audit queries
CREATE INDEX IF NOT EXISTS idx_audit_table ON AuditLog(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_record ON AuditLog(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_date ON AuditLog(changed_at);

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id INTEGER;
BEGIN
    -- Determine record ID based on table
    CASE TG_TABLE_NAME
        WHEN 'Rentals' THEN
            v_record_id := COALESCE(NEW.rental_id, OLD.rental_id);
        WHEN 'Vehicles' THEN
            v_record_id := COALESCE(NEW.vehicle_id, OLD.vehicle_id);
        WHEN 'Customers' THEN
            v_record_id := COALESCE(NEW.customer_id, OLD.customer_id);
        WHEN 'Payments' THEN
            v_record_id := COALESCE(NEW.payment_id, OLD.payment_id);
        ELSE
            v_record_id := 0;
    END CASE;
    
    IF TG_OP = 'DELETE' THEN
        INSERT INTO AuditLog (table_name, record_id, operation, old_values)
        VALUES (TG_TABLE_NAME, v_record_id, 'DELETE', row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO AuditLog (table_name, record_id, operation, old_values, new_values)
        VALUES (TG_TABLE_NAME, v_record_id, 'UPDATE', row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO AuditLog (table_name, record_id, operation, new_values)
        VALUES (TG_TABLE_NAME, v_record_id, 'INSERT', row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers for critical tables
CREATE TRIGGER trg_audit_rentals
AFTER INSERT OR UPDATE OR DELETE ON Rentals
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER trg_audit_vehicles
AFTER INSERT OR UPDATE OR DELETE ON Vehicles
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER trg_audit_customers
AFTER INSERT OR UPDATE OR DELETE ON Customers
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER trg_audit_payments
AFTER INSERT OR UPDATE OR DELETE ON Payments
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ============================================================================
-- USEFUL VIEWS FOR BUSINESS OPERATIONS
-- ============================================================================

-- View: Complete Rental Information
CREATE OR REPLACE VIEW rental_details AS
SELECT 
    r.rental_id,
    r.rental_date,
    r.expected_return_date,
    r.return_date,
    r.status AS rental_status,
    r.total_amount,
    r.late_days,
    r.late_fee,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email AS customer_email,
    c.phone AS customer_phone,
    v.vehicle_id,
    v.make || ' ' || v.model || ' (' || v.year || ')' AS vehicle,
    v.license_plate,
    v.daily_rate,
    vt.type_name AS vehicle_type,
    COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS total_paid,
    r.total_amount - COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS balance_due
FROM Rentals r
JOIN Customers c ON r.customer_id = c.customer_id
JOIN Vehicles v ON r.vehicle_id = v.vehicle_id
JOIN VehicleTypes vt ON v.type_id = vt.type_id
LEFT JOIN Payments p ON r.rental_id = p.rental_id
GROUP BY r.rental_id, c.customer_id, c.first_name, c.last_name, c.email, c.phone,
         v.vehicle_id, v.make, v.model, v.year, v.license_plate, v.daily_rate, vt.type_name;

-- View: Current Active Rentals Dashboard
CREATE OR REPLACE VIEW active_rentals_dashboard AS
SELECT 
    rental_id,
    customer_name,
    customer_phone,
    vehicle,
    license_plate,
    rental_date,
    expected_return_date,
    CURRENT_DATE - rental_date AS days_out,
    CASE 
        WHEN CURRENT_DATE > expected_return_date THEN 'OVERDUE'
        WHEN CURRENT_DATE = expected_return_date THEN 'DUE TODAY'
        WHEN expected_return_date - CURRENT_DATE <= 2 THEN 'DUE SOON'
        ELSE 'ON TIME'
    END AS status_flag,
    total_amount,
    balance_due
FROM rental_details
WHERE rental_status = 'active'
ORDER BY expected_return_date;

-- View: Vehicle Fleet Summary
CREATE OR REPLACE VIEW fleet_summary AS
SELECT 
    v.status,
    vt.type_name,
    COUNT(*) AS vehicle_count,
    AVG(v.mileage) AS avg_mileage,
    AVG(v.daily_rate) AS avg_daily_rate
FROM Vehicles v
JOIN VehicleTypes vt ON v.type_id = vt.type_id
GROUP BY v.status, vt.type_name
ORDER BY v.status, vt.type_name;

-- ============================================================================
-- Verification Query
-- ============================================================================

-- Run this to verify all improvements are applied
SELECT 
    'Improvements Applied Successfully!' AS status,
    (SELECT COUNT(*) FROM pg_trigger WHERE tgname LIKE 'trg_%') AS triggers_created,
    (SELECT COUNT(*) FROM pg_proc WHERE proname LIKE '%rental%' OR proname LIKE '%vehicle%') AS functions_created,
    (SELECT COUNT(*) FROM pg_views WHERE viewname IN ('rental_details', 'active_rentals_dashboard', 'fleet_summary', 'vehicles_needing_service')) AS views_created,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('vehicledamagereports', 'auditlog')) AS new_tables_created;
