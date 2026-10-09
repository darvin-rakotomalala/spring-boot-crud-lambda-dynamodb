package com.ce.repository;

import com.ce.model.domain.User;
import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.PageIterable;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryEnhancedRequest;
import software.amazon.awssdk.enhanced.dynamodb.model.ScanEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import org.springframework.data.domain.Pageable;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Repository
public class UserRepository {

    private final DynamoDbTemplate dynamoDbTemplate;

    public User saveUser(User user) {
        if (user.getUserId() == null || user.getUserId().isBlank()) {
            user.setUserId(UUID.randomUUID().toString());
        }
        return dynamoDbTemplate.save(user);
    }

    public List<User> findByNameContainingIgnoreCase(String name) {
        // Option 1: In-Memory Filtering (Best for smaller datasets or pre-filtered queries)
        return dynamoDbTemplate.scanAll(User.class)
                .stream()
                .flatMap(page -> page.items().stream())
                .filter(note -> note.getName() != null &&
                        note.getName().toLowerCase().contains(name.toLowerCase()))
                .collect(Collectors.toList());
    }

    public User findById(String hashKey) {
        Key key = Key.builder().partitionValue(hashKey).build();
        return dynamoDbTemplate.load(key, User.class);
    }

    public User findByEmail(String email) {
        QueryConditional queryConditional = QueryConditional
                .keyEqualTo(Key.builder()
                        .partitionValue(email)
                        .build());

        QueryEnhancedRequest queryRequest = QueryEnhancedRequest.builder()
                .queryConditional(queryConditional)
                .build();

        return dynamoDbTemplate.query(queryRequest, User.class, "email-index")
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst()
                .orElse(null);
    }

    /**
     * Standard DynamoDB Scan with filter expression (exact case match at DB level).
     */
    public List<User> findByNameContaining(String name) {
        Expression filterExpression = Expression.builder()
                .expression("contains(#nm, :nameVal)")
                .putExpressionName("#nm", "name")
                .putExpressionValue(":nameVal", AttributeValue.builder().s(name).build())
                .build();

        ScanEnhancedRequest scanRequest = ScanEnhancedRequest.builder()
                .filterExpression(filterExpression)
                .build();

        return dynamoDbTemplate.scan(scanRequest, User.class)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    public List<User> scanUserByStatus(String status) {
        Map<String, AttributeValue> expressionValues = new HashMap<>();
        expressionValues.put(":val1", AttributeValue.fromS(status));

        Map<String, String> expressionNames = new HashMap<>();
        expressionNames.put("#st", "status");

        Expression filterExpression = Expression.builder()
                .expression("#st = :val1")
                .expressionValues(expressionValues)
                .expressionNames(expressionNames)
                .build();

        ScanEnhancedRequest scanEnhancedRequest = ScanEnhancedRequest.builder()
                .filterExpression(filterExpression)
                .build();

        PageIterable<User> returnedList = dynamoDbTemplate.scan(scanEnhancedRequest, User.class);

        return returnedList.items().stream().collect(Collectors.toList());
    }

    public User updateUser(User user) {
        return dynamoDbTemplate.update(user);
    }

    public void deleteById(String id) {
        Key key = Key.builder().partitionValue(id).build();
        dynamoDbTemplate.delete(key, User.class);
    }

    public Page<User> queryUserByStatus(String status, Pageable pageable) {

        QueryConditional queryConditional = QueryConditional
                .keyEqualTo(
                        Key.builder()
                                .partitionValue(status)
                                .build());

        QueryEnhancedRequest queryRequest = QueryEnhancedRequest.builder()
                .queryConditional(queryConditional)
                .limit(pageable.getPageSize())
                .build();

        PageIterable<User> pageIterable =
                dynamoDbTemplate.query(queryRequest, User.class, "status-index");

        List<User> users = pageIterable.items().stream()
                .collect(Collectors.toList());

        return new PageImpl<>(users, pageable, users.size());
    }

    public Page<User> getAllUsers(Pageable pageable) {
        ScanEnhancedRequest scanRequest = ScanEnhancedRequest.builder()
                .limit(pageable.getPageSize())
                .build();

        List<User> content = dynamoDbTemplate.scan(scanRequest, User.class)
                .stream()
                .flatMap(page -> page.items().stream())
                .limit(pageable.getPageSize())
                .collect(Collectors.toList());

        long total = dynamoDbTemplate.scanAll(User.class)
                .stream()
                .mapToLong(page -> page.items().size())
                .sum();

        return new PageImpl<>(content, pageable, total);
    }
}
