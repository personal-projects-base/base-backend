package com.potatotech.basebackend.config.database;

import com.potatotech.authorization.exception.ServiceException;
import com.potatotech.authorization.tenant.TenantContext;

import com.potatotech.basebackend.config.context.ConfigContextImpl;
import jakarta.persistence.EntityManager;
import org.hibernate.Session;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.sql.SQLException;

@Component
public class TenantSchemaInterceptor {


    @Autowired
    EntityManager entityManager;

    @Autowired
    ConfigContextImpl configContext;

    public void switchSchema() {
        Session session = entityManager.unwrap(Session.class);
        session.doWork(connection -> {
            try {
                connection.createStatement().execute(String.format("SET SCHEMA '%s_%s'",configContext.getDatabase().toUpperCase(), TenantContext.getCurrentTenant().toUpperCase()));

            } catch (SQLException e) {
                throw new ServiceException(HttpStatus.BAD_GATEWAY,e.getMessage());
            }
        });
    }

}
