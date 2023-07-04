package com.potatotech.basebackend.config.migration;

import com.potatotech.basebackend.config.context.ConfigContextImpl;
import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

@Component
public class DBMigration {

    @Autowired
    ConfigContextImpl configContext;

    @Bean
    public void initializeFlyway(){
        var fly = Flyway.configure()
                .locations("filesystem:src/main/resources/db/migration")
                .dataSource(configContext.getUrl(),configContext.getUsername(),configContext.getPasswod())
                .createSchemas(true)
                .load();
        fly.migrate();
    }
}
