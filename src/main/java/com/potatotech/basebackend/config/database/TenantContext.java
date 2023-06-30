package com.potatotech.basebackend.config.database;

public class TenantContext {

    private static ThreadLocal<String> currentTenant = new ThreadLocal<>();
}
