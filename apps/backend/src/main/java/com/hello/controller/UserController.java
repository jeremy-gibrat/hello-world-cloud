package com.hello.controller;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.IndexRequest;
import com.hello.model.User;
import com.hello.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;
    
    @Autowired(required = false)
    private ElasticsearchClient elasticsearchClient;

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        try {
            List<User> users = userRepository.findAll();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        try {
            return userRepository.findById(id)
                    .map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<?> createUser(@RequestBody User user) {
        try {
            if (userRepository.existsByEmail(user.getEmail())) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(Map.of("error", "Email already exists"));
            }
            User savedUser = userRepository.save(user);
            
            // Index dans Elasticsearch
            indexUserInElasticsearch(savedUser);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    private void indexUserInElasticsearch(User user) {
        if (elasticsearchClient != null) {
            try {
                Map<String, Object> doc = new HashMap<>();
                doc.put("id", user.getId());
                doc.put("name", user.getName());
                doc.put("email", user.getEmail());
                doc.put("@timestamp", java.time.LocalDateTime.now().toString());
                
                IndexRequest<Map<String, Object>> request = IndexRequest.of(i -> i
                        .index("users")
                        .id(String.valueOf(user.getId()))
                        .document(doc)
                );
                
                elasticsearchClient.index(request);
            } catch (Exception e) {
                System.err.println("Failed to index user in Elasticsearch: " + e.getMessage());
            }
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User userDetails) {
        try {
            return userRepository.findById(id)
                    .map(user -> {
                        user.setName(userDetails.getName());
                        if (!user.getEmail().equals(userDetails.getEmail()) 
                            && userRepository.existsByEmail(userDetails.getEmail())) {
                            return ResponseEntity.status(HttpStatus.CONFLICT)
                                    .body(Map.of("error", "Email already exists"));
                        }
                        user.setEmail(userDetails.getEmail());
                        User updatedUser = userRepository.save(user);
                        return ResponseEntity.ok((Object) updatedUser);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            if (!userRepository.existsById(id)) {
                return ResponseEntity.notFound().build();
            }
            userRepository.deleteById(id);
            return ResponseEntity.ok(Map.of("message", "User deleted successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/count")
    public ResponseEntity<?> getUserCount() {
        try {
            long count = userRepository.count();
            return ResponseEntity.ok(Map.of("count", count));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/init")
    public ResponseEntity<?> initializeData() {
        try {
            if (userRepository.count() == 0) {
                User user1 = userRepository.save(new User("Alice Dupont", "alice@example.com"));
                User user2 = userRepository.save(new User("Bob Martin", "bob@example.com"));
                User user3 = userRepository.save(new User("Charlie Durand", "charlie@example.com"));
                
                // Index les utilisateurs dans Elasticsearch
                indexUserInElasticsearch(user1);
                indexUserInElasticsearch(user2);
                indexUserInElasticsearch(user3);
                
                Map<String, Object> response = new HashMap<>();
                response.put("message", "Sample data initialized");
                response.put("count", userRepository.count());
                return ResponseEntity.ok(response);
            }
            return ResponseEntity.ok(Map.of("message", "Data already exists", "count", userRepository.count()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
