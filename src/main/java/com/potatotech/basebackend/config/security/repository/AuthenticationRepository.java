package com.potatotech.basebackend.config.security.repository;


import com.potatotech.basebackend.config.security.model.UserSupplierEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AuthenticationRepository extends JpaRepository<UserSupplierEntity, UUID>  {

    Optional<UserSupplierEntity> findOneByEmail(String email);

    boolean existsByEmail(String email);

    int countAllBy();
}
