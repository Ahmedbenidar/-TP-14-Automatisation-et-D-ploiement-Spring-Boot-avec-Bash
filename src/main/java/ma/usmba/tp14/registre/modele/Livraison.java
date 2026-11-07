package ma.usmba.tp14.registre.modele;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "livraison")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Livraison {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 80)
    private String composant;

    @Column(nullable = false, length = 40)
    private String environnement;

    @Column(nullable = false, length = 20)
    private String version;

    @Column(nullable = false, length = 20)
    private String statut;

    @Column(name = "duree_secondes", nullable = false)
    private Integer dureeSecondes;

    @Column(name = "horodatage", nullable = false)
    private LocalDateTime horodatage;
}
