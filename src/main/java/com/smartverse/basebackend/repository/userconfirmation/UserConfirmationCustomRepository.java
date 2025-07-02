package com.smartverse.basebackend.repository.userconfirmation;


import com.smartverse.basebackend_gen.UserConfirmationEntity;
import com.smartverse.basebackend_gen.UserConfirmationRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserConfirmationCustomRepository extends UserConfirmationRepository {
    Optional<UserConfirmationEntity> findByHash(String hash);
}
