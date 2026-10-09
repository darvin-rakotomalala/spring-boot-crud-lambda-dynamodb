package com.ce.exception;

import lombok.Getter;

@Getter
public enum ErrorsEnum {

    /**
     * ERR_MCS_POC
     */

    ERR_MCS_USER_EMAIL_EMPTY("Error occurred - User email shouldn't be NULL or EMPTY"),
    ERR_MCS_USER_NAME_EMPTY("Error occurred - User name shouldn't be NULL or EMPTY"),
    ERR_MCS_USER_STATUS_EMPTY("Error occurred - User status shouldn't be NULL or EMPTY"),
    ERR_MCS_USER_OBJECT_EMPTY("Error occurred - object User shouldn't be NULL or EMPTY"),
    ERR_MCS_USER_ID_NOT_FOUND("Error occurred - no User found with this id"),
    ERR_MCS_USER_EMAIL_NOT_FOUND("Error occurred - no User found with this email");

    private final String errorMessage;

    private ErrorsEnum(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    @Override
    public String toString() {
        return " errorMessage : " + errorMessage;
    }

}
