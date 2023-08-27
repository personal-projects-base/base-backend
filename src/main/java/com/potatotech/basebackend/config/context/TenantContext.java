package com.potatotech.basebackend.config.context;

import com.potatotech.authenticate.security.UserSupplier;
import org.springframework.stereotype.Component;

@Component
public class TenantContext {

    private static final ThreadLocal<String> currentTenant = new ThreadLocal<>();

    private static final ThreadLocal<UserSupplier> currentUser = new ThreadLocal<>();

    public static void setCurrentTenant(String tenant){
        currentTenant.set(tenant);
    }

    public static String getCurrentTenant(){
        return currentTenant.get();
    }

    public static UserSupplier getCurrentUser(){
        return currentUser.get();
    }

    public static void setCurrentUser(UserSupplier user) {
        currentUser.set(user);
    }
}
