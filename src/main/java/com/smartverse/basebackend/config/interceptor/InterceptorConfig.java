package com.smartverse.basebackend.config.interceptor;


import com.potatotech.authorization.tenant.TenantContext;
import com.smartverse.basebackend.config.migration.DBMigration;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class InterceptorConfig implements HandlerInterceptor, WebMvcConfigurer  {

    private final DBMigration dbMigration;
    private final InterceptorExclusions exclusions;
    private final TenantResolver tenantResolver;

    public InterceptorConfig(
            DBMigration dbMigration,
            InterceptorExclusions exclusions,
            TenantResolver tenantResolver) {
        this.dbMigration = dbMigration;
        this.exclusions = exclusions;
        this.tenantResolver = tenantResolver;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler){
        clearTenantContext();

        try {
            if(exclusions.shouldSkip(request)){
                return true;
            }

            var tenant = tenantResolver.resolve(request, handler);
            TenantContext.setCurrentTenant(tenant);
            dbMigration.loadMigrateTenants(tenant);
            return true;
        } catch (RuntimeException | Error exception) {
            clearTenantContext();
            throw exception;
        }
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler,
            Exception exception) {
        clearTenantContext();
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry){
        registry.addInterceptor(this);
    }

    private void clearTenantContext() {
        TenantContext.setCurrentTenant(null);
        TenantContext.setCurrentUser(null);
    }
}
