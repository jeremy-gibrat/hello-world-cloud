package com.hello.controller;

import com.hello.service.MessageConsumer;
import com.hello.service.MessageProducer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
@CrossOrigin(origins = "*")
public class MessageController {

    private final MessageProducer messageProducer;
    private final MessageConsumer messageConsumer;

    public MessageController(MessageProducer messageProducer, MessageConsumer messageConsumer) {
        this.messageProducer = messageProducer;
        this.messageConsumer = messageConsumer;
    }

    @PostMapping("/send")
    public ResponseEntity<Map<String, String>> sendMessage(@RequestBody Map<String, String> payload) {
        String message = payload.get("message");
        if (message == null || message.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Message cannot be empty"));
        }
        
        messageProducer.sendMessage(message);
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "Message sent successfully");
        response.put("message", message);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/received")
    public ResponseEntity<List<String>> getReceivedMessages() {
        return ResponseEntity.ok(messageConsumer.getReceivedMessages());
    }
}
