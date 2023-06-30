package com.potatotech.basebackend;

import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@EnableRabbit
@SpringBootApplication
public class BaseBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BaseBackendApplication.class, args);
	}

}
