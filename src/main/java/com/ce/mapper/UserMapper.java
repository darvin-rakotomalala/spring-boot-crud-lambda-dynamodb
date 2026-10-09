package com.ce.mapper;

import com.ce.common.mapper.DtoMapper;
import com.ce.model.domain.User;
import com.ce.model.dto.UserDTO;
import org.mapstruct.Mapper;

@Mapper
public interface UserMapper extends DtoMapper<UserDTO, User> {

}
