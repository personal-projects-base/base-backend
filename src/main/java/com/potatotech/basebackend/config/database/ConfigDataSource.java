package com.potatotech.basebackend.config.database;

import org.hibernate.cfg.AvailableSettings;
import org.hibernate.context.spi.CurrentTenantIdentifierResolver;
import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.stereotype.Component;

import java.util.Map;


@Component
public class ConfigDataSource implements CurrentTenantIdentifierResolver, HibernatePropertiesCustomizer {


    private String currentTenant = "public";

    @Override
    public String resolveCurrentTenantIdentifier() {
        return TenantContext.getCurrentTenant() == null ? currentTenant : TenantContext.getCurrentTenant();
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return false;
    }

    @Override
    public void customize(Map<String, Object> hibernateProperties) {
        hibernateProperties.put(AvailableSettings.MULTI_TENANT_IDENTIFIER_RESOLVER, this);
    }
}
