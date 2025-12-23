# Vehicle Rental System - Database Design and SQL Queries

A comprehensive PostgreSQL database design for a vehicle rental management system with advanced SQL queries and business logic implementation.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Database Schema](#database-schema)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Features](#features)
- [Database Tables](#database-tables)
- [Setup Instructions](#setup-instructions)
- [SQL Queries](#sql-queries)
- [Business Logic](#business-logic)
- [Technologies Used](#technologies-used)
- [Author](#author)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Project Overview

This project demonstrates a complete database design for a vehicle rental system. It includes:

- **Normalized database schema** following best practices (3NF)
- **22+ SQL queries** covering basic to advanced operations
- **Automated triggers** for business logic
- **Sample data** for testing and demonstration
- **Performance indexes** for optimized queries
- **Data integrity constraints** to maintain consistency

The system manages customers, vehicles, rentals, and payments with proper referential integrity and business rules enforcement.

## 🗄️ Database Schema

The database consists of five main tables:

1. **VehicleTypes** - Categorizes vehicles (Sedan, SUV, Truck, etc.)
2. **Customers** - Stores customer information and credentials
3. **Vehicles** - Vehicle inventory with status tracking
4. **Rentals** - Rental transactions and history
5. **Payments** - Payment records for rentals

### Key Design Principles:

- **Normalization**: Database is normalized to 3NF to eliminate redundancy
- **Referential Integrity**: Foreign key constraints ensure data consistency
- **Check Constraints**: Business rules enforced at database level
- **Indexes**: Strategic indexing for query performance
- **Triggers**: Automatic status updates and calculations

## 📊 Entity Relationship Diagram

![Vehicle Rental System ERD](erd-diagram.png)

*Note: ERD diagram shows the relationships between all entities in the system.*

### Entity Relationships:

- **VehicleTypes** (1) → (M) **Vehicles**: One vehicle type can have many vehicles
- **Customers** (1) → (M) **Rentals**: One customer can make many rentals
- **Vehicles** (1) → (M) **Rentals**: One vehicle can be rented many times
- **Rentals** (1) → (M) **Payments**: One rental can have multiple payments

## ✨ Features

### Database Features:
- ✅ Complete CRUD operations
- ✅ Complex JOIN queries
- ✅ Aggregate functions and grouping
- ✅ Subqueries and CTEs (Common Table Expressions)
- ✅ Window functions for ranking and analytics
- ✅ Triggers for automated business logic
- ✅ Functions for calculations
- ✅ Transaction management
- ✅ Data validation constraints
- ✅ Performance optimization with indexes

### Business Features:
- Customer management with age validation (18+ years)
- Vehicle inventory tracking with status management
- Automated rental amount calculation
- Automatic vehicle status updates (available/rented/maintenance)
- Payment processing with multiple payment methods
- Overdue rental tracking
- Revenue analytics and reporting
- Customer lifetime value analysis
- Vehicle utilization tracking

## 📑 Database Tables

### 1. VehicleTypes
Stores different categories of vehicles available for rent.

**Columns:**
- `type_id` (PK): Unique identifier
- `type_name`: Name of vehicle type (Sedan, SUV, etc.)
- `description`: Description of the vehicle type
- `base_rate_per_day`: Base daily rental rate
- `created_at`: Timestamp of creation

### 2. Customers
Stores customer information and registration details.

**Columns:**
- `customer_id` (PK): Unique identifier
- `first_name`, `last_name`: Customer name
- `email`: Unique email address
- `phone`: Contact number
- `address`: Physical address
- `license_number`: Unique driver's license number
- `date_of_birth`: Birth date (must be 18+ years)
- `registration_date`: When customer registered

**Constraints:**
- Email must be unique
- License number must be unique
- Must be at least 18 years old

### 3. Vehicles
Stores vehicle inventory and current status.

**Columns:**
- `vehicle_id` (PK): Unique identifier
- `type_id` (FK): Reference to VehicleTypes
- `make`, `model`: Vehicle manufacturer and model
- `year`: Manufacturing year
- `license_plate`: Unique plate number
- `color`: Vehicle color
- `mileage`: Current odometer reading
- `status`: Current status (available/rented/maintenance/retired)
- `daily_rate`: Daily rental rate
- `purchase_date`: When vehicle was acquired
- `last_service_date`: Last maintenance date

**Constraints:**
- License plate must be unique
- Year must be between 1900 and current year + 1
- Daily rate must be positive
- Mileage cannot be negative

### 4. Rentals
Stores rental transactions and their status.

**Columns:**
- `rental_id` (PK): Unique identifier
- `customer_id` (FK): Reference to Customers
- `vehicle_id` (FK): Reference to Vehicles
- `rental_date`: Date rental started
- `return_date`: Actual return date (NULL if active)
- `expected_return_date`: Planned return date
- `total_amount`: Total rental cost
- `status`: Rental status (active/completed/cancelled)
- `created_at`: Timestamp of creation

**Constraints:**
- Expected return date must be after rental date
- Actual return date must be on or after rental date

### 5. Payments
Stores payment information for rentals.

**Columns:**
- `payment_id` (PK): Unique identifier
- `rental_id` (FK): Reference to Rentals
- `payment_date`: When payment was made
- `amount`: Payment amount
- `payment_method`: Method used (cash/credit_card/debit_card/online)
- `transaction_id`: External transaction reference
- `status`: Payment status (pending/completed/failed/refunded)

**Constraints:**
- Amount must be positive
- Payment method must be valid

## 🚀 Setup Instructions

### Prerequisites:
- PostgreSQL 12 or higher
- pgAdmin or any PostgreSQL client (Beekeeper Studio, DBeaver, etc.)
- Basic knowledge of SQL

### Installation Steps:

1. **Clone the repository:**
```bash
git clone https://github.com/nirobmondal/Vehicle-Rental-System-Database-Design-and-SQL-Queries.git
cd Vehicle-Rental-System-Database-Design-and-SQL-Queries
```

2. **Create a new database:**
```sql
CREATE DATABASE vehicle_rental_system;
```

3. **Connect to the database:**
```bash
psql -U your_username -d vehicle_rental_system
```

4. **Run the schema file:**
```bash
psql -U your_username -d vehicle_rental_system -f schema.sql
```

5. **Load sample data (optional):**
```bash
psql -U your_username -d vehicle_rental_system -f sample_data.sql
```

6. **Verify installation:**
```sql
-- Check tables
\dt

-- Verify data
SELECT COUNT(*) FROM Customers;
SELECT COUNT(*) FROM Vehicles;
```

### Using Beekeeper Studio:

1. Open Beekeeper Studio
2. Create new connection to PostgreSQL
3. Enter your database credentials
4. Connect to `vehicle_rental_system` database
5. Open and execute `schema.sql`
6. Open and execute `sample_data.sql`
7. Run queries from `queries.sql`

## 📝 SQL Queries

The `queries.sql` file contains 22 comprehensive queries organized into categories:

### Basic CRUD Operations (Queries 1-5)
- **Query 1**: Retrieve all available vehicles with pricing
- **Query 2**: Find customer by email
- **Query 3**: Insert new customer
- **Query 4**: Update vehicle mileage
- **Query 5**: Delete cancelled rental

### Intermediate Queries (Queries 6-10)
- **Query 6**: List active rentals with full details (JOIN query)
- **Query 7**: Calculate total revenue by vehicle type (Aggregation)
- **Query 8**: Find repeat customers (GROUP BY with HAVING)
- **Query 9**: Average rental duration by vehicle type
- **Query 10**: List vehicles needing maintenance

### Advanced Queries (Queries 11-15)
- **Query 11**: Most popular vehicle using CTE
- **Query 12**: Monthly revenue trend analysis
- **Query 13**: Inactive customers identification
- **Query 14**: Rank vehicles by revenue (Window Functions)
- **Query 15**: Overdue rentals tracking

### Business Intelligence (Queries 16-20)
- **Query 16**: Customer lifetime value analysis
- **Query 17**: Vehicle utilization rate calculation
- **Query 18**: Payment method analysis
- **Query 19**: Vehicle availability for date range
- **Query 20**: Complete rental history with payments

### Data Integrity (Queries 21-22)
- **Query 21**: Check for payment/rental mismatches
- **Query 22**: Database statistics summary

### Example Query Explanation:

**Query 6: Active Rentals Report**
```sql
SELECT 
    r.rental_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    v.make || ' ' || v.model AS vehicle,
    r.rental_date,
    r.expected_return_date,
    CURRENT_DATE - r.rental_date AS days_rented
FROM Rentals r
JOIN Customers c ON r.customer_id = c.customer_id
JOIN Vehicles v ON r.vehicle_id = v.vehicle_id
WHERE r.status = 'active';
```

**Purpose**: This query provides a comprehensive view of all currently active rentals. It combines data from three tables (Rentals, Customers, and Vehicles) to show:
- Who rented the vehicle (customer name and contact)
- What was rented (vehicle make and model)
- When it was rented and when it's due back
- How long it has been rented

**Business Use Case**: Daily operations dashboard to monitor active rentals and identify vehicles currently out on rent.

## ⚙️ Business Logic

### Automated Triggers:

1. **update_vehicle_status_on_rental**
   - Automatically sets vehicle status to 'rented' when a new rental starts
   - Sets vehicle status back to 'available' when rental is completed
   - Ensures vehicle availability is always accurate

2. **set_rental_amount**
   - Automatically calculates rental total amount before inserting
   - Uses daily rate × number of days
   - Eliminates manual calculation errors

### Functions:

1. **calculate_rental_amount()**
   - Input: vehicle_id, rental_date, expected_return_date
   - Output: Total rental amount
   - Used by triggers and can be called manually

### Indexes for Performance:

```sql
-- Quick lookups
idx_vehicles_status      -- Find available vehicles fast
idx_customers_email      -- Customer login/search
idx_rentals_status       -- Active/completed rental queries

-- Reporting queries
idx_rentals_dates        -- Date range searches
idx_vehicles_type        -- Vehicle type filtering
idx_payments_rental      -- Payment history lookup
```

## 🛠️ Technologies Used

- **Database**: PostgreSQL 12+
- **SQL Features**: 
  - DDL (Data Definition Language)
  - DML (Data Manipulation Language)
  - DCL (Data Control Language)
  - TCL (Transaction Control Language)
- **Advanced SQL**:
  - Common Table Expressions (CTEs)
  - Window Functions
  - Triggers
  - Functions
  - Indexes
- **Tools**: 
  - pgAdmin
  - Beekeeper Studio
  - DBeaver
  - psql CLI

## 👤 Author

**Nirob Mondal**

- GitHub: [@nirobmondal](https://github.com/nirobmondal)
- Email: nirobmondal@example.com

This project was created as a demonstration of advanced database design and SQL query techniques. It showcases best practices in relational database design, normalization, and complex query writing.

## 🤝 Contributing

Contributions are welcome! If you'd like to improve this project, please follow these steps:

1. **Fork the repository**
   ```bash
   # Click the 'Fork' button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/Vehicle-Rental-System-Database-Design-and-SQL-Queries.git
   cd Vehicle-Rental-System-Database-Design-and-SQL-Queries
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**
   - Add new queries
   - Improve existing schema
   - Fix bugs
   - Update documentation

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: description of your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your fork and branch
   - Describe your changes
   - Submit the pull request

### Contribution Guidelines:

- Follow SQL naming conventions (snake_case for tables and columns)
- Add comments to complex queries
- Test all queries before submitting
- Update README.md if adding new features
- Ensure backward compatibility
- Write clear commit messages

### Areas for Contribution:

- Additional complex queries
- Performance optimization tips
- Alternative database implementations (MySQL, Oracle)
- Data visualization scripts
- API integration examples
- Docker setup for easy deployment
- Additional test cases
- Documentation improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📚 Additional Resources

### Learning Resources:
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [SQL Tutorial - W3Schools](https://www.w3schools.com/sql/)
- [Database Normalization Guide](https://www.guru99.com/database-normalization.html)

### Related Projects:
- [Database Design Examples](https://github.com/topics/database-design)
- [SQL Query Examples](https://github.com/topics/sql-queries)

---

**Note**: This is a demonstration project for educational purposes. For production use, additional security measures, user authentication, and application layer logic should be implemented.

*Last Updated: December 2025*