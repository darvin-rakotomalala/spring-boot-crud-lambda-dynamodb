package com.ce.model.common;

import lombok.Getter;
import lombok.Setter;

import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;

import java.io.Serializable;
import java.time.Instant;

@Getter
@Setter
public abstract class AuditModel implements Serializable {

    private Instant createdAt;
    private Instant updatedAt;

    @DynamoDbAttribute("created_at")
    public Instant getCreatedAt() {
        return createdAt;
    }

    @DynamoDbAttribute("updated_at")
    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
