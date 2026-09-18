package com.smartverse.basebackend.config.interceptor;

import com.potatotech.authorization.tenant.TenantConfiguration;
import com.smartverse.basebackend.config.context.EnumConfigContext;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class InterceptorExclusions {

    private static final List<String> ADMIN_TENANT_PATHS = List.of();

    private final TenantConfiguration tenantConfiguration = new TenantConfiguration();

    public boolean shouldSkip(HttpServletRequest request) {
        var uri = request.getRequestURI();
        return isSwagger(uri)
                || isError(uri)
                || (HttpMethod.OPTIONS.matches(request.getMethod()) && !requiresAdminTenant(uri));
    }

    public boolean requiresAdminTenant(String uri) {
        return ADMIN_TENANT_PATHS.stream().anyMatch(path -> matches(uri, path));
    }

    public boolean isAnonymous(Object handler) {
        return tenantConfiguration.validAnonymous(handler);
    }

    private boolean isSwagger(String uri) {
        return matches(uri, "/swagger-ui/") || matches(uri, "/v3/");
    }

    private boolean isError(String uri) {
        return matches(uri, "/error");
    }

    private boolean matches(String uri, String path) {
        return uri.startsWith(serviceContextPath() + path);
    }

    private String serviceContextPath() {
        return "/" + System.getenv(EnumConfigContext.SERVICE_NAME.name());
    }
}
