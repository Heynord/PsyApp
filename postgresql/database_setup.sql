-- Создание схем для вертикального шардирования
CREATE SCHEMA IF NOT EXISTS clients;
CREATE SCHEMA IF NOT EXISTS appointments;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Домен пользователей (без горизонтального шардирования)
CREATE TABLE clients.psychologists (
                                       psychologist_id SERIAL PRIMARY KEY,
                                       name VARCHAR(100) NOT NULL,
                                       email VARCHAR(100) UNIQUE NOT NULL,
                                       license_number VARCHAR(50) UNIQUE,
                                       specialization VARCHAR(100),
                                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clients.clients (
                                 client_id SERIAL PRIMARY KEY,
                                 name VARCHAR(100) NOT NULL,
                                 email VARCHAR(100) UNIQUE NOT NULL,
                                 phone VARCHAR(20),
                                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clients.client_details (
                                        client_id INT PRIMARY KEY REFERENCES clients.clients(client_id),
                                        date_of_birth DATE,
                                        address TEXT,
                                        emergency_contact TEXT
);

-- Домен записей (горизонтальное шардирование по client_id)
-- Шард 1: client_id % 2 = 0
CREATE TABLE appointments.appointments_shard1 (
                                                  appointment_id SERIAL PRIMARY KEY,
                                                  client_id INT NOT NULL,
                                                  psychologist_id INT REFERENCES clients.psychologists(psychologist_id),
                                                  appointment_date TIMESTAMP NOT NULL,
                                                  status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'completed', 'canceled')),
                                                  notes TEXT,
                                                  CHECK (client_id % 2 = 0)
);

-- Шард 2: client_id % 2 = 1
CREATE TABLE appointments.appointments_shard2 (
                                                  appointment_id SERIAL PRIMARY KEY,
                                                  client_id INT NOT NULL,
                                                  psychologist_id INT REFERENCES clients.psychologists(psychologist_id),
                                                  appointment_date TIMESTAMP NOT NULL,
                                                  status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'completed', 'canceled')),
                                                  notes TEXT,
                                                  CHECK (client_id % 2 = 1)
);

-- Домен аналитики (горизонтальное шардирование по session_date)
-- Шард 1: сессии до 2025 года
CREATE TABLE analytics.session_logs_shard1 (
                                               log_id SERIAL PRIMARY KEY,
                                               appointment_id INT,
                                               session_date DATE NOT NULL,
                                               duration_minutes INT,
                                               session_notes TEXT,
                                               CHECK (session_date < '2025-01-01')
);

-- Шард 2: сессии с 2025 года и позже
CREATE TABLE analytics.session_logs_shard2 (
                                               log_id SERIAL PRIMARY KEY,
                                               appointment_id INT,
                                               session_date DATE NOT NULL,
                                               duration_minutes INT,
                                               session_notes TEXT,
                                               CHECK (session_date >= '2025-01-01')
);

CREATE TABLE analytics.feedback (
                                    feedback_id SERIAL PRIMARY KEY,
                                    appointment_id INT,
                                    client_id INT REFERENCES clients.clients(client_id),
                                    rating INT CHECK (rating BETWEEN 1 AND 5),
                                    comment TEXT,
                                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE analytics.payment_logs (
                                        payment_id SERIAL PRIMARY KEY,
                                        appointment_id INT,
                                        client_id INT REFERENCES clients.clients(client_id),
                                        amount DECIMAL(10,2),
                                        payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Тестовые данные
INSERT INTO clients.psychologists (name, email, license_number, specialization)
VALUES
    ('Др. Иван Петров', 'ivan.petrov@psych.com', 'PSY123', 'Когнитивная терапия'),
    ('Др. Анна Смирнова', 'anna.smirnova@psych.com', 'PSY456', 'Семейная терапия');

INSERT INTO clients.clients (name, email, phone)
VALUES
    ('Алиса Кузнецова', 'alisa.k@client.com', '555-0101'),
    ('Борис Иванов', 'boris.i@client.com', '555-0102');

INSERT INTO clients.client_details (client_id, date_of_birth, address, emergency_contact)
VALUES
    (1, '1990-05-15', 'ул. Ленина, 123', 'Мария Кузнецова'),
    (2, '1985-08-22', 'ул. Мира, 456', 'Том Иванов');

INSERT INTO appointments.appointments_shard1 (client_id, psychologist_id, appointment_date, status, notes)
VALUES
    (2, 1, '2025-06-22 20:00:00', 'completed', 'Первичная консультация'),
    (2, 1, '2025-06-25 10:00:00', 'completed', 'Повторная сессия');

INSERT INTO appointments.appointments_shard2 (client_id, psychologist_id, appointment_date, status, notes)
VALUES
    (1, 2, '2025-06-26 14:00:00', 'completed', 'Повторная сессия');

INSERT INTO analytics.session_logs_shard2 (appointment_id, session_date, duration_minutes, session_notes)
VALUES
    (1, '2025-06-25', 60, 'Обсуждение техник управления тревогой');

INSERT INTO analytics.feedback (appointment_id, client_id, rating, comment)
VALUES
    (1, 2, 4, 'Очень полезная сессия');

INSERT INTO analytics.payment_logs (appointment_id, client_id, amount, payment_date)
VALUES
    (1, 2, 150.00, '2025-06-25 11:00:00');