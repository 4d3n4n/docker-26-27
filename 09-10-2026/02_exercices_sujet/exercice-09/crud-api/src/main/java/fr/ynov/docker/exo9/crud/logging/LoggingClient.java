package fr.ynov.docker.exo9.crud.logging;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.OffsetDateTime;

@Component
public class LoggingClient {

    private final RestTemplate restTemplate;
    private final String logsApiUrl;

    public LoggingClient(RestTemplate restTemplate, @Value("${logging.api.url}") String logsApiUrl) {
        this.restTemplate = restTemplate;
        this.logsApiUrl = logsApiUrl;
    }

    public void send(String message, String source, LogLevel level) {
        LogRequest request = new LogRequest(message, source, OffsetDateTime.now(), level);
        try {
            restTemplate.postForEntity(logsApiUrl, request, Void.class);
        } catch (RestClientException ignored) {
        }
    }

    private record LogRequest(String message, String source, OffsetDateTime timestamp, LogLevel level) {
    }
}
