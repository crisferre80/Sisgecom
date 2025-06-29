/*
  # Insert Sample Data

  1. Sample Products
    - Various categories of products for testing
    - Different stock levels to demonstrate low stock alerts

  2. Sample User (Admin)
    - Create an admin user profile for testing
*/

-- Insert sample products
INSERT INTO products (barcode, name, price, quantity, min_stock, category, supplier, description) VALUES
('1234567890123', 'Smartphone Samsung Galaxy A54', 299.99, 25, 5, 'Electrónicos', 'Samsung Electronics', 'Smartphone con pantalla de 6.4 pulgadas y cámara de 50MP'),
('2345678901234', 'Laptop HP Pavilion 15', 599.99, 15, 3, 'Electrónicos', 'HP Inc.', 'Laptop con procesador Intel Core i5 y 8GB RAM'),
('3456789012345', 'Camiseta Nike Dri-FIT', 29.99, 50, 10, 'Ropa', 'Nike', 'Camiseta deportiva de secado rápido'),
('4567890123456', 'Pantalón Jeans Levi\'s 501', 79.99, 30, 8, 'Ropa', 'Levi Strauss & Co.', 'Pantalón jeans clásico de corte recto'),
('5678901234567', 'Cafetera Nespresso Essenza', 89.99, 12, 5, 'Hogar', 'Nespresso', 'Cafetera de cápsulas compacta'),
('6789012345678', 'Aspiradora Dyson V8', 349.99, 8, 3, 'Hogar', 'Dyson', 'Aspiradora inalámbrica con tecnología ciclónica'),
('7890123456789', 'Balón de Fútbol Adidas', 24.99, 40, 15, 'Deportes', 'Adidas', 'Balón oficial de fútbol FIFA Quality'),
('8901234567890', 'Raqueta de Tenis Wilson', 129.99, 20, 5, 'Deportes', 'Wilson Sporting Goods', 'Raqueta profesional de tenis'),
('9012345678901', 'Libro "Cien Años de Soledad"', 15.99, 35, 10, 'Libros', 'Editorial Sudamericana', 'Novela de Gabriel García Márquez'),
('0123456789012', 'Audífonos Sony WH-1000XM4', 199.99, 18, 5, 'Electrónicos', 'Sony Corporation', 'Audífonos inalámbricos con cancelación de ruido'),
('1357924680135', 'Tablet iPad Air', 449.99, 10, 3, 'Electrónicos', 'Apple Inc.', 'Tablet con pantalla de 10.9 pulgadas'),
('2468135792468', 'Zapatillas Adidas Ultraboost', 149.99, 2, 5, 'Ropa', 'Adidas', 'Zapatillas deportivas para running'),
('3691472583691', 'Microondas LG NeoChef', 129.99, 6, 4, 'Hogar', 'LG Electronics', 'Microondas con tecnología Smart Inverter'),
('4815926374815', 'Bicicleta Trek FX 3', 599.99, 1, 3, 'Deportes', 'Trek Bicycle Corporation', 'Bicicleta híbrida para ciudad'),
('5927384615927', 'Novela "El Quijote"', 12.99, 25, 8, 'Libros', 'Editorial Planeta', 'Clásico de la literatura española');

-- Note: User profiles will be created automatically when users sign up
-- The trigger will handle profile creation based on auth.users data