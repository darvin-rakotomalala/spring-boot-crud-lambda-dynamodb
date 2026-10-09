package com.ce.service;

import com.ce.exception.ErrorsEnum;
import com.ce.exception.FunctionalException;
import com.ce.mapper.UserMapper;
import com.ce.model.domain.User;
import com.ce.model.dto.UserDTO;
import com.ce.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Slf4j
@RequiredArgsConstructor
@Service
public class UserCUDSAImpl implements UserCUDSA {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Override
    public UserDTO saveUser(UserDTO userDTO) {
        if (userDTO == null) {
            throw new FunctionalException(ErrorsEnum.ERR_MCS_USER_OBJECT_EMPTY.getErrorMessage());
        }
        User savedUser = userRepository.saveUser(userMapper.toDO(userDTO));
        return userMapper.toDTO(savedUser);
    }

    @Override
    public UserDTO updateUser(UserDTO userDTO) {
        if (userDTO == null || userDTO.getUserId() == null) {
            throw new FunctionalException(ErrorsEnum.ERR_MCS_USER_OBJECT_EMPTY.getErrorMessage());
        }
        User userFound = userRepository.findById(userDTO.getUserId());
        userFound.setEmail(userDTO.getEmail());
        userFound.setName(userDTO.getName());
        userFound.setStatus(userDTO.getStatus());
        userFound.setUpdatedAt(Instant.now());
        return userMapper.toDTO(userRepository.updateUser(userFound));
    }

    @Override
    public void deleteById(String id) {
        userRepository.deleteById(id);
    }
}
