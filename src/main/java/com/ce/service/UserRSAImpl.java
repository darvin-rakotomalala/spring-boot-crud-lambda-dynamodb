package com.ce.service;

import com.ce.exception.ErrorsEnum;
import com.ce.exception.FunctionalException;
import com.ce.mapper.UserMapper;
import com.ce.model.dto.UserDTO;
import com.ce.repository.UserRepository;
import com.ce.utils.HelpPage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@RequiredArgsConstructor
@Service
public class UserRSAImpl implements UserRSA {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Override
    public List<UserDTO> findByNameContainingIgnoreCase(String name) {
        return userMapper.toDTO(userRepository.findByNameContainingIgnoreCase(name));
    }

    @Override
    public UserDTO findById(String hashKey) {
        UserDTO userDTO = userMapper.toDTO(userRepository.findById(hashKey));
        if (userDTO != null) {
            return userDTO;
        }
        throw new FunctionalException(ErrorsEnum.ERR_MCS_USER_ID_NOT_FOUND.getErrorMessage());
    }

    @Override
    public UserDTO findByEmail(String email) {
        UserDTO userDTO = userMapper.toDTO(userRepository.findByEmail(email));
        if (userDTO != null) {
            return userDTO;
        }
        throw new FunctionalException(ErrorsEnum.ERR_MCS_USER_EMAIL_NOT_FOUND.getErrorMessage());
    }

    @Override
    public List<UserDTO> findByNameContaining(String name) {
        return userMapper.toDTO(userRepository.findByNameContaining(name));
    }

    @Override
    public List<UserDTO> scanUserByStatus(String status) {
        return userMapper.toDTO(userRepository.scanUserByStatus(status));
    }

    @Override
    public HelpPage<UserDTO> queryUserByStatus(String status, Pageable pageable) {
        return userMapper.toDTO(userRepository.queryUserByStatus(status, pageable), pageable);
    }

    @Override
    public HelpPage<UserDTO> getAllUsers(Pageable pageable) {
        return userMapper.toDTO(userRepository.getAllUsers(pageable), pageable);
    }
}
