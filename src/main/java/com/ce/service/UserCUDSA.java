package com.ce.service;

import com.ce.model.dto.UserDTO;

public interface UserCUDSA {

    UserDTO saveUser(UserDTO userDTO);

    UserDTO updateUser(UserDTO userDTO);

    void deleteById(String id);
}
