package com.ce.controller;

import com.ce.constraint.validation.UserValidator;
import com.ce.model.dto.UserDTO;
import com.ce.service.UserCUDSA;
import com.ce.service.UserRSA;
import com.ce.utils.HelpPage;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping(path = "users")
public class UserController {

    private final UserCUDSA userCUDSA;
    private final UserRSA userRSA;
    private final UserValidator userValidator;

    @InitBinder("userDTO")
    protected void initUserDTOBinder(WebDataBinder webDataBinder) {
        webDataBinder.setValidator(userValidator);
    }

    @Operation(summary = "WS used to create user")
    @PostMapping
    public UserDTO saveUser(@RequestBody @Validated UserDTO userDTO) {
        return userCUDSA.saveUser(userDTO);
    }

    @Operation(summary = "WS used to get user by id")
    @GetMapping("/{userId}")
    public UserDTO findById(@PathVariable("userId") String userId) {
        return userRSA.findById(userId);
    }

    @Operation(summary = "WS used to get user by email")
    @GetMapping("/by-email")
    public UserDTO findByEmail(@RequestParam(name = "email") String email) {
        return userRSA.findByEmail(email);
    }

    @Operation(summary = "WS used to update user")
    @PutMapping
    public UserDTO updateUser(@RequestBody @Validated UserDTO userDTO) {
        return userCUDSA.updateUser(userDTO);
    }

    @Operation(summary = "WS used to get user by name containing")
    @GetMapping("/by-name")
    public List<UserDTO> findByNameContaining(@RequestParam(name = "name") String name) {
        return userRSA.findByNameContaining(name);
    }

    @Operation(summary = "WS used to scan user by status")
    @GetMapping("/by-status")
    public List<UserDTO> scanUserByStatus(@RequestParam(name = "status") String status) {
        return userRSA.scanUserByStatus(status);
    }

    @Operation(summary = "WS used to query user by status with page")
    @GetMapping("/query-by-status")
    public HelpPage<UserDTO> queryUserByStatus(
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(defaultValue = "0", required = false) int page,
            @RequestParam(defaultValue = "15", required = false) int size) {
        Pageable pageable = PageRequest.of(page, size);
        return userRSA.queryUserByStatus(status, pageable);
    }

    @Operation(summary = "WS used to get all users with page")
    @GetMapping
    public HelpPage<UserDTO> getAllUsers(
            @RequestParam(defaultValue = "0", required = false) int page,
            @RequestParam(defaultValue = "15", required = false) int size) {
        Pageable pageable = PageRequest.of(page, size);
        return userRSA.getAllUsers(pageable);
    }

    @Operation(summary = "WS used to delete user by id")
    @DeleteMapping(value = "/{userId}", produces = MediaType.TEXT_PLAIN_VALUE + ";charset=UTF-8")
    public String deleteById(@PathVariable("userId") String userId) {
        userCUDSA.deleteById(userId);
        return "User with id " + userId + " deleted successfully!";
    }
}
