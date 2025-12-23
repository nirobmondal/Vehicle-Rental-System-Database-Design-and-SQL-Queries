# Vehicle Rental System - Database Design & SQL Queries

## 📋 Project Overview

This project demonstrates a comprehensive database design and implementation for a Vehicle Rental System. It showcases proficiency in relational database concepts, entity relationship modeling, and advanced SQL query operations. The system manages users, vehicles, and bookings with proper relationships and constraints to ensure data integrity.

### 🎯 Objectives

- Design an Entity Relationship Diagram (ERD) with proper relationships
- Implement database tables with primary and foreign key constraints
- Write advanced SQL queries using JOIN, EXISTS, WHERE, GROUP BY, and HAVING
- Handle real-world vehicle rental business logic

### 🛠️ Technologies Used

- **Database:** PostgreSQL
- **Database Tool:** Beekeeper Studio
- **ERD Design:** DrawSQL

---

## 🗺️ Entity Relationship Diagram (ERD)



**ERD LINK:** [https://drawsql.app/teams/alone-203/diagrams/vehicle-rental-system](https://drawsql.app/teams/alone-203/diagrams/vehicle-rental-system)

The ERD illustrates the complete database structure with:
- **Primary Keys (PK)** for unique identification
- **Foreign Keys (FK)** for maintaining referential integrity
- **Relationship Cardinality** showing one-to-many and many-to-one connections
- **Status Fields** for tracking entity states

---

## 🗄️ Database Schema

### Tables Structure

The database consists of three main tables that work together to manage the vehicle rental system:

#### 1. Users Table
Stores information about system users with role-based access.

**Columns:**
- `user_id` (INT, PRIMARY KEY) - Unique identifier for each user
- `name` (VARCHAR(100)) - User's full name
- `email` (VARCHAR(150), UNIQUE) - User's email address (must be unique)
- `password` (VARCHAR(255)) - User's hashed password
- `phone` (VARCHAR(20)) - Contact phone number
- `role` (VARCHAR(20)) - User role (Admin or Customer)

**Constraints:**
- Email must be unique to prevent duplicate accounts
- Role must be either 'Admin' or 'Customer'

#### 2. Vehicles Table
Maintains the inventory of vehicles available for rent.

**Columns:**
- `vehicle_id` (INT, PRIMARY KEY) - Unique identifier for each vehicle
- `name` (VARCHAR(100)) - Vehicle name/model
- `registration_number` (VARCHAR(100), UNIQUE) - Vehicle registration number
- `type` (VARCHAR(20)) - Type of vehicle (car, bike, truck)
- `model` (VARCHAR(50)) - Vehicle model year
- `rental_price` (DECIMAL(10,2)) - Daily rental price
- `status` (VARCHAR(50)) - Current status (available, rented, maintenance)

**Constraints:**
- Registration number must be unique
- Type must be one of: car, bike, or truck
- Status must be one of: available, rented, or maintenance

#### 3. Bookings Table
Records all rental bookings and their details.

**Columns:**
- `booking_id` (INT, PRIMARY KEY) - Unique identifier for each booking
- `user_id` (INT, FOREIGN KEY) - References Users table
- `vehicle_id` (INT, FOREIGN KEY) - References Vehicles table
- `start_date` (DATE) - Rental start date
- `end_date` (DATE) - Rental end date
- `status` (VARCHAR(50)) - Booking status (pending, confirmed, completed, cancelled)
- `total_cost` (DECIMAL(10,2)) - Total cost of the booking

**Constraints:**
- Status must be one of: pending, confirmed, completed, or cancelled
- Foreign key relationships ensure referential integrity

---

## 🔗 Entity Relationships

The database implements the following relationships:

### One-to-Many Relationship: Users → Bookings
- One user can make multiple bookings
- Each booking belongs to exactly one user
- Implemented via `user_id` foreign key in Bookings table

### Many-to-One Relationship: Bookings → Vehicles
- Multiple bookings can reference the same vehicle (at different times)
- Each booking references exactly one vehicle
- Implemented via `vehicle_id` foreign key in Bookings table

### Logical One-to-One: Booking Instance
- Each specific booking connects exactly one user with one vehicle for a specific time period
- This represents a unique rental transaction

---

## 📊 SQL Queries Explained

### Query 1: JOIN - Retrieve Booking Information with Customer and Vehicle Details

**Purpose:** This query combines data from three tables to provide a comprehensive view of all bookings along with customer names and vehicle names.

**Concepts Used:** INNER JOIN, table aliasing

**Query:**
```sql
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
```

**Explanation:** 
- Uses INNER JOIN to combine Users, Bookings, and Vehicles tables
- Retrieves customer and vehicle names instead of just IDs for better readability
- Shows all active bookings with complete information

**Expected Output:** 4 rows showing all bookings with customer names, vehicle names, dates, and status.

---

### Query 2: EXISTS - Find Vehicles That Have Never Been Booked

**Purpose:** Identifies vehicles in the inventory that have no booking history, which helps in inventory management and marketing strategies.

**Concepts Used:** NOT EXISTS, subquery, correlated subquery

**Query:**
```sql
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
    SELECT 1
    FROM Bookings AS b
    WHERE b.vehicle_id = v.vehicle_id
  )
ORDER BY
  v.vehicle_id ASC;
```

**Explanation:**
- Uses NOT EXISTS to check for absence of bookings
- The subquery checks if any booking exists for each vehicle
- Returns complete vehicle details for unbooked vehicles
- Useful for identifying underutilized inventory

**Expected Output:** 2 vehicles (Yamaha R15 and Ford F-150) that have never been booked.

---

### Query 3: WHERE - Retrieve Available Vehicles of Specific Type

**Purpose:** Filters vehicles by type and availability status to help customers find specific vehicles they're interested in renting.

**Concepts Used:** SELECT, WHERE clause, filtering

**Query:**
```sql
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
```

**Explanation:**
- Simple filtering using WHERE clause
- Searches for vehicles of type 'car' with 'available' status
- Can be modified to search for any vehicle type (bike, truck, etc.)
- Essential for customer vehicle search functionality

**Expected Output:** 1 vehicle (Toyota Corolla) that is a car and currently available.

---

### Query 4: GROUP BY and HAVING - Find Popular Vehicles with Multiple Bookings

**Purpose:** Analyzes booking patterns to identify the most popular vehicles, showing only those with more than 2 bookings.

**Concepts Used:** GROUP BY, HAVING, COUNT, aggregate functions, INNER JOIN

**Query:**
```sql
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
```

**Explanation:**
- Groups bookings by vehicle name
- Counts total bookings per vehicle using COUNT(*)
- HAVING clause filters groups to show only vehicles with more than 2 bookings
- Useful for identifying high-demand vehicles and optimizing fleet management

**Expected Output:** 1 vehicle (Honda Civic) with 3 bookings.

---

## 🚀 Setup Instructions

### Prerequisites
- PostgreSQL 12+ or any compatible SQL database
- Database management tool (Beekeeper Studio recommended)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nirobmondal/Vehicle-Rental-System-Database-Design-and-SQL-Queries.git
   cd Vehicle-Rental-System-Database-Design-and-SQL-Queries
   ```

2. **Setup Database:**
   - Open Beekeeper Studio
   - Connect to your PostgreSQL server
   - Execute the `queries.sql` file to create the database, tables, and sample data

3. **Verify Installation:**
   - Check that all three tables (Users, Vehicles, Bookings) are created
   - Verify that sample data is inserted
   - Run the provided queries to validate the setup

---

## 📁 Project Structure

```
Vehicle-Rental-System-Database-Design-and-SQL-Queries/
│
├── README.md           # Complete project documentation
├── queries.sql         # All SQL queries and database setup
└── LICENSE            # License information
```

---


## 📈 Sample Data

The database includes sample data for testing:

- **3 Users:** Alice (Customer), Bob (Admin), Charlie (Customer)
- **4 Vehicles:** Toyota Corolla, Honda Civic, Yamaha R15, Ford F-150
- **4 Bookings:** Various bookings with different statuses

This sample data demonstrates all relationship types and query scenarios.


## 📝 Query Results Summary

| Query | Purpose | Result Count |
|-------|---------|--------------|
| Query 1 (JOIN) | List all bookings with customer and vehicle details | 4 bookings |
| Query 2 (EXISTS) | Find vehicles never booked | 2 vehicles |
| Query 3 (WHERE) | Find available cars | 1 vehicle |
| Query 4 (GROUP BY) | Find popular vehicles (>2 bookings) | 1 vehicle |


## 🤝 Contributing

Contributions are welcome! If you'd like to improve this project:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/YourFeatureName
   ```
3. **Commit your changes**
   ```bash
   git commit -m "Add: Your feature description"
   ```
4. **Push to your branch**
   ```bash
   git push origin feature/YourFeatureName
   ```
5. **Open a Pull Request**

### Contribution Guidelines
- Follow SQL best practices and naming conventions
- Add comments to explain complex queries
- Update documentation for any schema changes
- Test all queries before submitting

---

## 👤 Author

**Nirob Mondal**

- GitHub: [@nirobmondal](https://github.com/nirobmondal)
- Project Repository: [Vehicle-Rental-System-Database-Design-and-SQL-Queries](https://github.com/nirobmondal/Vehicle-Rental-System-Database-Design-and-SQL-Queries)

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.


---

**⭐ If you find this project helpful, please consider giving it a star!**