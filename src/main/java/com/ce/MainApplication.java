package com.ce;

import com.ce.controller.HealthController;
import com.ce.controller.UserController;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NonNull;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;

@Slf4j
@SpringBootApplication
@RequiredArgsConstructor
@Import({UserController.class, HealthController.class})
public class MainApplication implements CommandLineRunner {

    public static void main(String[] args) {
        SpringApplication.run(MainApplication.class, args);
    }

    @Override
    public void run(String @NonNull ... args) {
        log.info("############################   RUN   ############################");
    }
}
