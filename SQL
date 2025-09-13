-- ===========================
-- Travel Booking System Database Schema
-- ===========================

-- Customers Table
CREATE TABLE public.customers (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Destinations Table
CREATE TABLE public.destinations (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hotels Table
CREATE TABLE public.hotels (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    hotel_name VARCHAR(255) NOT NULL,
    destination_id UUID NOT NULL,
    rating NUMERIC(3,2) DEFAULT 0.0,
    room_type VARCHAR(100),
    price_per_night NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_hotels_destination FOREIGN KEY (destination_id)
        REFERENCES public.destinations(id) ON DELETE CASCADE
);

-- Transports Table
CREATE TABLE public.transports (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    transport_type VARCHAR(50) NOT NULL,
    seat_capacity INTEGER NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    arrival_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trips Table
CREATE TABLE public.trips (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    destination_id UUID NOT NULL,
    hotel_id UUID NOT NULL,
    transport_id UUID NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_trips_destination FOREIGN KEY (destination_id)
        REFERENCES public.destinations(id) ON DELETE CASCADE,
    CONSTRAINT fk_trips_hotel FOREIGN KEY (hotel_id)
        REFERENCES public.hotels(id) ON DELETE CASCADE,
    CONSTRAINT fk_trips_transport FOREIGN KEY (transport_id)
        REFERENCES public.transports(id) ON DELETE CASCADE
);

-- Bookings Table
CREATE TABLE public.bookings (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL,
    trip_id UUID NOT NULL,
    booking_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    num_people INTEGER NOT NULL,
    total_cost NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id)
        REFERENCES public.customers(id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_trip FOREIGN KEY (trip_id)
        REFERENCES public.trips(id) ON DELETE CASCADE
);

-- Payments Table
CREATE TABLE public.payments (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    amount NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id)
        REFERENCES public.bookings(id) ON DELETE CASCADE
);

-- Reviews Table
CREATE TABLE public.reviews (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL,
    trip_id UUID NOT NULL,
    rating NUMERIC(3,2) NOT NULL,
    comments TEXT,
    review_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
        REFERENCES public.customers(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_trip FOREIGN KEY (trip_id)
        REFERENCES public.trips(id) ON DELETE CASCADE
);

-- Enable Row Level Security for all tables
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public data (destinations, hotels, transports, trips)
CREATE POLICY "Public read access for destinations" ON public.destinations FOR SELECT USING (true);
CREATE POLICY "Public read access for hotels" ON public.hotels FOR SELECT USING (true);
CREATE POLICY "Public read access for transports" ON public.transports FOR SELECT USING (true);
CREATE POLICY "Public read access for trips" ON public.trips FOR SELECT USING (true);

-- RLS Policies for user-specific data
CREATE POLICY "Users can view their own customer record" ON public.customers FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "Users can update their own customer record" ON public.customers FOR UPDATE USING (auth.uid()::text = id::text);
CREATE POLICY "Users can insert their own customer record" ON public.customers FOR INSERT WITH CHECK (auth.uid()::text = id::text);

CREATE POLICY "Users can view their own bookings" ON public.bookings FOR SELECT USING (auth.uid()::text = customer_id::text);
CREATE POLICY "Users can create their own bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid()::text = customer_id::text);
CREATE POLICY "Users can update their own bookings" ON public.bookings FOR UPDATE USING (auth.uid()::text = customer_id::text);

CREATE POLICY "Users can view their own payments" ON public.payments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE bookings.id = payments.booking_id 
        AND bookings.customer_id::text = auth.uid()::text
    )
);

CREATE POLICY "Users can view their own reviews" ON public.reviews FOR SELECT USING (auth.uid()::text = customer_id::text);
CREATE POLICY "Users can create their own reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid()::text = customer_id::text);
CREATE POLICY "Users can update their own reviews" ON public.reviews FOR UPDATE USING (auth.uid()::text = customer_id::text);

-- Admin policies (for authenticated admin users)
CREATE POLICY "Admins can manage all data" ON public.customers FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

-- Apply admin policies to all tables
CREATE POLICY "Admins can manage destinations" ON public.destinations FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage hotels" ON public.hotels FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage transports" ON public.transports FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage trips" ON public.trips FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage bookings" ON public.bookings FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage payments" ON public.payments FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

CREATE POLICY "Admins can manage reviews" ON public.reviews FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

-- Create indexes for better performance
CREATE INDEX idx_hotels_destination_id ON public.hotels(destination_id);
CREATE INDEX idx_trips_destination_id ON public.trips(destination_id);
CREATE INDEX idx_trips_hotel_id ON public.trips(hotel_id);
CREATE INDEX idx_trips_transport_id ON public.trips(transport_id);
CREATE INDEX idx_bookings_customer_id ON public.bookings(customer_id);
CREATE INDEX idx_bookings_trip_id ON public.bookings(trip_id);
CREATE INDEX idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX idx_reviews_customer_id ON public.reviews(customer_id);
CREATE INDEX idx_reviews_trip_id ON public.reviews(trip_id);
CREATE INDEX idx_customers_email ON public.customers(email); 
