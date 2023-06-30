package com.potatotech.basebackend.config.security;

import com.potatotech.basebackend.config.exceptions.ServiceException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import static io.micrometer.common.util.StringUtils.isEmpty;

@Service
public class SecurityService {

    private static final String BEARER = "Bearer";

    @Value("${app-config.secret.api-secret}")
    private String secret;


    public void isAuthenticated(String token){
        try{
            var accessToken = extractToken(token);
            var claims = Jwts
                    .parserBuilder()
                    .setSigningKey(Keys.hmacShaKeyFor(secret.getBytes()))
                    .build()
                    .parseClaimsJws(accessToken)
                    .getBody();
            var user = UserSupplier.getUser(claims);
            if(user == null || isEmpty(user.getEmail())){
                throw new ServiceException(HttpStatus.UNAUTHORIZED,"Access not authorized");
            }
        }catch (Exception ex){
            ex.printStackTrace();
            throw new ServiceException(HttpStatus.UNAUTHORIZED,"Access not authorized");
        }
    }

    private String extractToken(String token){
        if(isEmpty(token)){
            throw new ServiceException(HttpStatus.UNAUTHORIZED,"Access not authorized");
        }
        if(token.contains(BEARER)){
            token = token.replace(BEARER,"");
        }
        return token;
    }
}
