package fr.ynov.docker.exo9.crud.dog;

import fr.ynov.docker.exo9.crud.logging.LogLevel;
import fr.ynov.docker.exo9.crud.logging.LoggingClient;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/dogs")
public class DogController {

    private final DogRepository repository;
    private final LoggingClient loggingClient;

    public DogController(DogRepository repository, LoggingClient loggingClient) {
        this.repository = repository;
        this.loggingClient = loggingClient;
    }

    @GetMapping
    public List<Dog> findAll() {
        loggingClient.send("Dogs list retrieved", "[CrudAPI] GET /api/v1/dogs", LogLevel.INFO);
        return repository.findAll();
    }

    @GetMapping("/{dogId}")
    public Dog findById(@PathVariable Long dogId) {
        Dog dog = getDog(dogId, "GET");
        loggingClient.send("Dog retrieved", source("GET", dogId), LogLevel.INFO);
        return dog;
    }

    @PostMapping
    public ResponseEntity<Dog> create(@RequestBody Dog dog) {
        Dog savedDog = repository.save(dog);
        loggingClient.send("Dog created", "[CrudAPI] POST /api/v1/dogs", LogLevel.INFO);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedDog);
    }

    @PutMapping("/{dogId}")
    public Dog update(@PathVariable Long dogId, @RequestBody Dog changes) {
        Dog dog = getDog(dogId, "PUT");
        dog.setName(changes.getName());
        dog.setBirthDate(changes.getBirthDate());
        dog.setBreed(changes.getBreed());
        dog.setSterilized(changes.isSterilized());
        Dog savedDog = repository.save(dog);
        loggingClient.send("Dog updated", source("PUT", dogId), LogLevel.INFO);
        return savedDog;
    }

    @DeleteMapping("/{dogId}")
    public ResponseEntity<Void> delete(@PathVariable Long dogId) {
        repository.delete(getDog(dogId, "DELETE"));
        loggingClient.send("Dog deleted", source("DELETE", dogId), LogLevel.INFO);
        return ResponseEntity.noContent().build();
    }

    private Dog getDog(Long dogId, String method) {
        return repository.findById(dogId).orElseThrow(() -> {
            loggingClient.send("Dog not found", source(method, dogId), LogLevel.ERR);
            return new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found");
        });
    }

    private String source(String method, Long dogId) {
        return "[CrudAPI] " + method + " /api/v1/dogs/" + dogId;
    }
}
