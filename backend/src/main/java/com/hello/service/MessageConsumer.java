package com.hello.service;

import com.hello.config.RabbitMQConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class MessageConsumer {

    private static final Logger logger = LoggerFactory.getLogger(MessageConsumer.class);
    private final List<String> receivedMessages = new ArrayList<>();

    @RabbitListener(queues = RabbitMQConfig.QUEUE_NAME)
    public void receiveMessage(String message) {
        logger.info("Received message: {}", message);
        receivedMessages.add(message);
        
        // Garder seulement les 50 derniers messages
        if (receivedMessages.size() > 50) {
            receivedMessages.remove(0);
        }
    }

    public List<String> getReceivedMessages() {
        return new ArrayList<>(receivedMessages);
    }
}
