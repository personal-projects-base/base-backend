package com.potatotech.basebackend.config.exceptions;

import lombok.Data;
import lombok.EqualsAndHashCode;
import org.springframework.http.HttpStatus;

@EqualsAndHashCode(callSuper = true)
@Data
public class ServiceException extends RuntimeException{

    private String message;
    private HttpStatus status;

    public ServiceException(HttpStatus status, String message){
        super(message);
        this.message = message;
        this.status = status;
    }

    public ServiceException(HttpStatus status, String message, Throwable throwable){
        super(message,throwable);
        this.message = message;
        this.status = status;
    }
}
