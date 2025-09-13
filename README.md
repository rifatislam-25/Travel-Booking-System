# 🛫 Travel Booking System (Supabase + RLS Security)

A **secure, full-stack travel booking platform** built with **Supabase (PostgreSQL + Auth + RLS)**.  
This project demonstrates how to design a **normalized schema**, implement **Row Level Security (RLS)**, and enforce **role-based access control** while supporting real-world booking workflows.

---

## 📌 Features
- 🔐 **Authentication & Profiles** – Users can sign up, log in, and manage their profile.  
- 🏨 **Destinations, Hotels & Transport** – Browse travel options before booking.  
- 📅 **Bookings Management** – Customers can book trips securely.  
- 💳 **Payments** – Linked to bookings for secure transactions.  
- ⭐ **Reviews** – Customers leave feedback on trips.  
- 🔑 **RLS Policies** – Fine-grained access control per role (anon, authenticated, admin).  
- 📊 **ERD & Schema Visualization** – Clear representation of the database structure.

---

## 🗂️ Database Schema

All tables use:
- **UUID Primary Keys** (`gen_random_uuid()`)
- **Timestamps** (`created_at`, `booking_date`, etc.)
- **Foreign Keys with ON DELETE CASCADE**
- **Indexes on FKs & common query fields**

### Main Entities
- **customers** – user profiles  
- **destinations** – travel locations  
- **hotels** – linked to destinations  
- **transports** – flight, bus, train options  
- **trips** – bundles destinations + hotels + transports  
- **bookings** – reservations by customers  
- **payments** – transactions linked to bookings  
- **reviews** – customer feedback  

📌 Example SQL migration (`supabase/migrations/...sql`):
```sql
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    booking_date TIMESTAMP DEFAULT now(),
    status VARCHAR(50) DEFAULT 'pending'
);
````

---

## 📊 ERD (Entity Relationship Diagram)

The schema is normalized and connected as follows:

* `customers → bookings → trips`
* `trips → destinations, hotels, transports`
* `payments → bookings`
* `reviews → customers + trips`

📸 **Visualization:**
## 🎥 Database Travel Schema

![Database Schema](assets/images/schema_sql.png)

---

## 🔐 Row Level Security (RLS)

RLS is **enabled on all tables** to ensure **role-based access**.

### Roles

* **Anon (unauthenticated)**

  * Can read public data: `destinations`, `hotels`, `trips`, `transports`.
  * Cannot insert or modify records.

* **Authenticated Users**

  * Can manage their **own data only**:

    * Profile (`customers`)
    * Bookings (`bookings`)
    * Payments (`payments`)
    * Reviews (`reviews`)
  * Cannot access other users’ data.

* **Admins**

  * Defined via `auth.users.raw_user_meta_data->>'role' = 'admin'`.
  * Have `ALL` access to every table.

📌 Example RLS Policy:

```sql
-- Allow users to read only their own bookings
CREATE POLICY "Users can view their own bookings"
ON public.bookings
FOR SELECT
TO authenticated
USING (customer_id = auth.uid());
```

---

## ⚙️ Workflow

1. **Visitor (Anon)** → browse trips, hotels, transports.
2. **User (after login)** → create profile, book trips, make payments, write reviews.
3. **Admin** → manage users, bookings, payments, reviews (full access).

---

## 📸 Policy Graph

* **Solid lines** → foreign key relationships
* **Dashed lines** → RLS controlled access
* **Dotted lines** → Admin unrestricted access

## 📊 ERD & RLS Policy Visualization

![ERD + RLS Policy](https://github.com/rifatislam-25/Travel-Booking-System/blob/main/travel_booking_system_erd_rls.png?raw=true)




---


## 📸 Screenshots

* ERD Diagram
* Policy Graph
* Website screenshots (profile, booking, payment, review)

*(Insert images here)*

---

## 🎯 Why This Project Matters

* **Security-first design** with Supabase RLS.
* **Scalable schema** suitable for real travel booking apps.
* **Extensible** for agents, coupons, or multi-currency support.
* **Professional case study** for database-driven applications.

---

## 📬 Connect

👤 **Md Shafiqul Islam Rifat**

* 🌐 [Portfolio](#)
* 💼 [LinkedIn](#)
* 💻 [GitHub](#)

---

```

---

