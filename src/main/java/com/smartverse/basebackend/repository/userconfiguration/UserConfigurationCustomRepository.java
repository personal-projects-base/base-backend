package com.smartverse.basebackend.repository.userconfiguration;


import com.smartverse.basebackend_gen.UserConfigurationEntity;
import com.smartverse.basebackend_gen.UserConfigurationRepository;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
@Primary
public interface UserConfigurationCustomRepository extends UserConfigurationRepository {

    Optional<UserConfigurationEntity> findByHash(UUID hash);
}
