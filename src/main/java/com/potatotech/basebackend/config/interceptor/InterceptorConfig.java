package com.potatotech.basebackend.config.interceptor;

import com.potatotech.basebackend.config.security.SecurityService;
import feign.Request;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class InterceptorConfig implements HandlerInterceptor, WebMvcConfigurer {


    private static final String AUTHORIZATION = "Authorization";

    @Autowired
    private SecurityService securityService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler){
        if(isOptions(request)){
            return true;
        }
        var auth = request.getHeader(AUTHORIZATION);

        securityService.isAuthenticated(auth);
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
