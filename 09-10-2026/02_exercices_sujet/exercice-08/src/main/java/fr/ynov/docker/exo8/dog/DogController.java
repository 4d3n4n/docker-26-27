package fr.ynov.docker.exo8.dog;

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

    public DogController(DogRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Dog> findAll() {
        return repository.findAll();
    }

    @GetMapping("/{dogId}")
    public Dog findById(@PathVariable Long dogId) {
        return getDog(dogId);
    }

    @PostMapping
    public ResponseEntity<Dog> create(@RequestBody Dog dog) {
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(dog));
    }

    @PutMapping("/{dogId}")
    public Dog update(@PathVariable Long dogId, @RequestBody Dog changes) {
        Dog dog = getDog(dogId);
        dog.setName(changes.getName());
        dog.setBirthDate(changes.getBirthDate());
        dog.setBreed(changes.getBreed());
        dog.setSterilized(changes.isSterilized());
        return repository.save(dog);
    }

    @DeleteMapping("/{dogId}")
    public ResponseEntity<Void> delete(@PathVariable Long dogId) {
        repository.delete(getDog(dogId));
        return ResponseEntity.noContent().build();
    }

    private Dog getDog(Long dogId) {
        return repository.findById(dogId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found"));
    }
}
