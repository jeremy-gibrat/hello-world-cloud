package com.hello.controller;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.IndexRequest;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/elasticsearch")
@CrossOrigin(origins = "*")
public class ElasticsearchController {

    @Autowired
    private ElasticsearchClient elasticsearchClient;

    @GetMapping("/search/{index}")
    public ResponseEntity<?> searchIndex(@PathVariable String index, 
                                         @RequestParam(defaultValue = "10") int size) {
        try {
            SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index(index)
                    .size(size)
            );

            SearchResponse<ObjectNode> response = elasticsearchClient.search(searchRequest, ObjectNode.class);

            List<Map<String, Object>> results = response.hits().hits().stream()
                    .map(hit -> {
                        Map<String, Object> doc = new HashMap<>();
                        doc.put("id", hit.id());
                        doc.put("source", hit.source());
                        return doc;
                    })
                    .collect(Collectors.toList());

            Map<String, Object> result = new HashMap<>();
            result.put("total", response.hits().total().value());
            result.put("documents", results);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("index", index);
            return ResponseEntity.status(500).body(error);
        }
    }

    @PostMapping("/index/{index}")
    public ResponseEntity<?> indexDocument(@PathVariable String index, @RequestBody Map<String, Object> document) {
        try {
            document.put("@timestamp", LocalDateTime.now().toString());
            
            IndexRequest<Map<String, Object>> request = IndexRequest.of(i -> i
                    .index(index)
                    .document(document)
            );

            var response = elasticsearchClient.index(request);

            return ResponseEntity.ok(Map.of(
                    "id", response.id(),
                    "result", response.result().toString()
            ));
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("index", index);
            return ResponseEntity.status(500).body(error);
        }
    }

    @GetMapping("/indices")
    public ResponseEntity<?> listIndices() {
        try {
            var response = elasticsearchClient.cat().indices();
            
            List<String> indices = response.valueBody().stream()
                    .map(record -> record.index())
                    .filter(idx -> !idx.startsWith("."))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of("indices", indices));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}
