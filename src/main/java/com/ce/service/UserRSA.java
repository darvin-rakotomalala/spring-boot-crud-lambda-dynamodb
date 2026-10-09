package com.ce.service;

import com.ce.model.dto.UserDTO;
import com.ce.utils.HelpPage;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface UserRSA {

    List<UserDTO> findByNameContainingIgnoreCase(String name);

    UserDTO findById(String hashKey);

    UserDTO findByEmail(String email);

    List<UserDTO> findByNameContaining(String name);

    List<UserDTO> scanUserByStatus(String status);

    HelpPage<UserDTO> queryUserByStatus(String status, Pageable pageable);

    HelpPage<UserDTO> getAllUsers(Pageable pageable);
}
