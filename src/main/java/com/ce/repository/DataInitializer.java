package com.ce.repository;

import com.ce.model.domain.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/**
 * Seeds the users table with example data on startup. Only active when
 * app.data-init.enabled=true (see application.yml, defaulted on for the
 * "local" and "dev" profiles).
 */
@RequiredArgsConstructor
@Slf4j
@Component
@Profile({"local", "dev"})
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;

    @Value("${app.data-init.enabled:true}")
    private boolean enabled;

    @Override
    public void run(String @NonNull ... args) {
        if (!enabled) {
            log.info("DataInitializer disabled, skipping seed data");
            return;
        }

        List<User> seedUsers = List.of(
                newUser("alice@example.com", "Alice Johnson", "ACTIVE"),
                newUser("bob@example.com", "Bob Smith", "ACTIVE"),
                newUser("carol@example.com", "Carol Martinez", "INACTIVE"),
                newUser("dave@example.com", "Dave O'Brien", "PENDING"),
                newUser("eve@example.com", "Eve Chen", "ACTIVE")
        );

        seedUsers.forEach(user -> {
            if (userRepository.findByEmail(user.getEmail()) == null) {
                userRepository.saveUser(user);
                log.info("Seeded user: {} <{}>", user.getName(), user.getEmail());
            } else {
                log.info("User with email {} already exists, skipping", user.getEmail());
            }
        });
    }

    private User newUser(String email, String name, String status) {
        User user = new User();
        user.setUserId(UUID.randomUUID().toString());
        user.setEmail(email);
        user.setName(name);
        user.setStatus(status);
        return user;
    }
}
