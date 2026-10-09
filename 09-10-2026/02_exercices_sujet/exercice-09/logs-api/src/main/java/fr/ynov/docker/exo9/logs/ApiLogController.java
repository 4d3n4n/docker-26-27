package fr.ynov.docker.exo9.logs;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/logs")
public class ApiLogController {

    private final ApiLogRepository repository;

    public ApiLogController(ApiLogRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<ApiLog> findAll() {
        return repository.findAllByOrderByTimestampAsc();
    }

    @PostMapping
    public ResponseEntity<ApiLog> create(@RequestBody ApiLogRequest request) {
        ApiLog log = new ApiLog();
        log.setMessage(request.message());
        log.setSource(request.source());
        log.setTimestamp(request.timestamp() == null ? OffsetDateTime.now() : request.timestamp());
        log.setLevel(request.level());
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(log));
    }
}
