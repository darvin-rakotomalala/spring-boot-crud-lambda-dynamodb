package com.ce.common.config;

import io.awspring.cloud.dynamodb.DynamoDbTableNameResolver;
import org.springframework.stereotype.Component;

@Component
public class CustomTableNameResolver implements DynamoDbTableNameResolver {

    @Override
    public <T> String resolve(Class<T> clazz) {
        if (clazz.isAnnotationPresent(TableName.class)) {
            return clazz.getAnnotation(TableName.class).name();
        }
        // Fallback or default behavior if annotation is missing
        return clazz.getSimpleName().toLowerCase();
    }
}
