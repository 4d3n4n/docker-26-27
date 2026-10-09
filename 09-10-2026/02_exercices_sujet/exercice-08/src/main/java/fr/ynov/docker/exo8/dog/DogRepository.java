package fr.ynov.docker.exo8.dog;

import org.springframework.data.jpa.repository.JpaRepository;

public interface DogRepository extends JpaRepository<Dog, Long> {
}
