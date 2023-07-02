package com.potatotech.basebackend.config.interceptor;

import com.potatotech.authenticate.exception.ServiceException;
import com.potatotech.authenticate.security.Authenticate;
import com.potatotech.authenticate.tenant.TenantConfiguration;
import com.potatotech.basebackend.config.database.TenantContext;
import feign.Request;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class InterceptorConfig extends Authenticate implements HandlerInterceptor, WebMvcConfigurer  {


    private static final String AUTHORIZATION = "Authorization";
    private static final String TENANT = "tenant";


    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler){
        var tenantConfiguration = new TenantConfiguration();
        if(isOptions(request)){
            return true;
        }
        var auth = request.getHeader(AUTHORIZATION);
        var tenant = request.getHeader(TENANT);


        if(!tenantConfiguration.validAnonymous(handler)){
            this.isAuthenticated(auth);
        } else {
            if(tenant == null){
                throw new ServiceException(HttpStatus.FORBIDDEN,"tenant is required");
            }
            TenantContext.setCurrentTenant(tenant);
        }
        return true;
    }


    private boolean isOptions(HttpServletRequest request){
        return Request.HttpMethod.OPTIONS.equals(request.getMethod());
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry){
        registry.addInterceptor(this);
    }
}
