package ru.sfedu.psyapp;

import lombok.extern.slf4j.Slf4j;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@Slf4j
public class MainApplication {
    private static final String URL = "jdbc:postgresql://postgres:5432/psych_service";
    private static final String USER = "postgres";
    private static final String PASSWORD = "password";

    public static Connection getConnection() throws SQLException {
         try {
             Class.forName("org.postgresql.Driver");
         } catch (ClassNotFoundException e) {
             e.printStackTrace();
         }
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    // Пример запроса для извлечения назначений из соответствующего шарда
    public static void getAppointmentsByClientId(int clientId) {
        String tableName = clientId % 2 == 0 ? "appointments.appointments_shard1" : "appointments.appointments_shard2";
        String query = "SELECT * FROM " + tableName + " WHERE client_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(query)) {
            stmt.setInt(1, clientId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                log.info("Appointment ID: " + rs.getInt("appointment_id"));
                log.info("Client ID: " + rs.getInt("client_id"));
                log.info("Psychologist ID: " + rs.getInt("psychologist_id"));
                log.info("Date: " + rs.getTimestamp("appointment_date"));
                log.info("Status: " + rs.getString("status"));
                log.info("Notes: " + rs.getString("notes"));
                log.info("---");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            log.error("Error executing query: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        // Пример использования
        getAppointmentsByClientId(1);
    }
}