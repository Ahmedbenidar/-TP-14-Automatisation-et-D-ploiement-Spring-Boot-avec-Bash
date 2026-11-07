package ma.usmba.tp14.registre.service;

import jakarta.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.util.List;
import ma.usmba.tp14.registre.depot.LivraisonDepot;
import ma.usmba.tp14.registre.modele.Livraison;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LivraisonService {

    private final LivraisonDepot depot;

    @PostConstruct
    @Transactional
    public void amorcer() {
        if (depot.count() > 0) {
            return;
        }
        depot.saveAll(List.of(
                Livraison.builder().composant("api-facturation").environnement("recette")
                        .version("1.4.0").statut("SUCCES").dureeSecondes(96)
                        .horodatage(LocalDateTime.now().minusDays(3)).build(),
                Livraison.builder().composant("portail-agent").environnement("recette")
                        .version("2.1.3").statut("SUCCES").dureeSecondes(143)
                        .horodatage(LocalDateTime.now().minusDays(2)).build(),
                Livraison.builder().composant("api-facturation").environnement("production")
                        .version("1.3.7").statut("ECHEC").dureeSecondes(38)
                        .horodatage(LocalDateTime.now().minusDays(1)).build(),
                Livraison.builder().composant("portail-agent").environnement("production")
                        .version("2.1.3").statut("SUCCES").dureeSecondes(127)
                        .horodatage(LocalDateTime.now().minusHours(9)).build(),
                Livraison.builder().composant("moteur-relances").environnement("recette")
                        .version("0.9.2").statut("SUCCES").dureeSecondes(74)
                        .horodatage(LocalDateTime.now().minusHours(4)).build()));
    }

    public List<Livraison> toutes() {
        return depot.findAll();
    }

    public List<Livraison> parEnvironnement(String environnement) {
        return depot.findByEnvironnementOrderByHorodatageDesc(environnement);
    }

    public List<Livraison> parStatut(String statut) {
        return depot.findAll().stream()
                .filter(l -> l.getStatut().equalsIgnoreCase(statut))
                .toList();
    }

    public long totalSucces() {
        return depot.countByStatut("SUCCES");
    }

    public long total() {
        return depot.count();
    }

    public double dureeMoyenne() {
        return depot.findAll().stream()
                .mapToInt(Livraison::getDureeSecondes)
                .average()
                .orElse(0.0);
    }
}
