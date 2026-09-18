package com.smartverse.basebackend.config.interceptor;

import com.potatotech.authorization.security.Authenticate;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

@Component
public class TenantResolver extends Authenticate {

    private static final String ADMIN_TENANT = "admin";
    private static final String DEFAULT_TENANT = "public";
    private static final String AUTHORIZATION_HEADER = "Authorization";

    private final InterceptorExclusions exclusions;

    public TenantResolver(InterceptorExclusions exclusions) {
        this.exclusions = exclusions;
    }

    public String resolve(HttpServletRequest request, Object handler) {
        if (exclusions.requiresAdminTenant(request.getRequestURI())) {
            return ADMIN_TENANT;
        }

        if (!exclusions.isAnonymous(handler)) {
            var authorization = request.getHeader(AUTHORIZATION_HEADER);
            return isAuthenticated(authorization).getTenant();
        }

        return DEFAULT_TENANT;
    }
}
