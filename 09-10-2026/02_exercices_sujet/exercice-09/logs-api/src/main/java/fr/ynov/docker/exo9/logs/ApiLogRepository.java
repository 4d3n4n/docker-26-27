package fr.ynov.docker.exo9.logs;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ApiLogRepository extends JpaRepository<ApiLog, Long> {
    List<ApiLog> findAllByOrderByTimestampAsc();
}
