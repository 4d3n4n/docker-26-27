package fr.ynov.docker.exo9.logs;

import java.time.OffsetDateTime;

public record ApiLogRequest(String message, String source, OffsetDateTime timestamp, LogLevel level) {
}
