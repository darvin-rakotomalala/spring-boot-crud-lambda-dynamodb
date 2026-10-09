package com.ce.model.domain;

import com.ce.common.config.TableName;
import com.ce.model.common.AuditModel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

@DynamoDbBean
@TableName(name = "users")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class User extends AuditModel {

    private String userId;
    private String email;
    private String name;
    private String status;

    // Partition key
    @DynamoDbPartitionKey
    public String getUserId() {
        return userId;
    }

    // GSI partition key for querying by email
    @DynamoDbSecondaryPartitionKey(indexNames = "email-index")
    public String getEmail() {
        return email;
    }

    @DynamoDbAttribute("name")
    public String getName() {
        return name;
    }

    // GSI partition key for querying by status
    @DynamoDbSecondaryPartitionKey(indexNames = "status-index")
    public String getStatus() {
        return status;
    }
}
