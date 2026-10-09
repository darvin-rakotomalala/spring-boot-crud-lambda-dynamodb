package com.ce.constraint.validation;

import com.ce.exception.ErrorsEnum;
import com.ce.model.dto.UserDTO;
import org.apache.commons.lang3.StringUtils;
import org.jspecify.annotations.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.validation.Errors;
import org.springframework.validation.Validator;

@Component
public class UserValidator implements Validator {

    @Override
    public boolean supports(@NonNull Class<?> clazz) {
        return UserDTO.class.equals(clazz);
    }

    @Override
    public void validate(@NonNull Object target, @NonNull Errors errors) {
        UserDTO noteDTO = (UserDTO) target;
        if (StringUtils.isEmpty(noteDTO.getEmail())) {
            errors.rejectValue("email", "email.value.empty", ErrorsEnum.ERR_MCS_USER_EMAIL_EMPTY.getErrorMessage());
        }
        if (StringUtils.isEmpty(noteDTO.getName())) {
            errors.rejectValue("name", "name.value.empty", ErrorsEnum.ERR_MCS_USER_NAME_EMPTY.getErrorMessage());
        }
        if (StringUtils.isEmpty(noteDTO.getStatus())) {
            errors.rejectValue("status", "status.value.empty", ErrorsEnum.ERR_MCS_USER_STATUS_EMPTY.getErrorMessage());
        }
    }
}
