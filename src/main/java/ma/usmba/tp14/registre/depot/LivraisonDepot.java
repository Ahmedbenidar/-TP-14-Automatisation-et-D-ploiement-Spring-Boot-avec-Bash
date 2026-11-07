package ma.usmba.tp14.registre.depot;

import java.util.List;
import ma.usmba.tp14.registre.modele.Livraison;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LivraisonDepot extends JpaRepository<Livraison, Long> {

    List<Livraison> findByEnvironnementOrderByHorodatageDesc(String environnement);

    long countByStatut(String statut);
}
