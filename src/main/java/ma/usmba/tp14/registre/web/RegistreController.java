package ma.usmba.tp14.registre.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import ma.usmba.tp14.registre.modele.Livraison;
import ma.usmba.tp14.registre.service.LivraisonService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/registre")
@RequiredArgsConstructor
public class RegistreController {

    private final LivraisonService service;

    @GetMapping("/livraisons")
    public List<Livraison> livraisons() {
        return service.toutes();
    }

    @GetMapping("/environnements/{environnement}")
    public List<Livraison> parEnvironnement(@PathVariable String environnement) {
        return service.parEnvironnement(environnement);
    }

    @GetMapping("/statuts/{statut}")
    public List<Livraison> parStatut(@PathVariable String statut) {
        return service.parStatut(statut);
    }

    @GetMapping("/synthese")
    public Map<String, Object> synthese() {
        Map<String, Object> reponse = new LinkedHashMap<>();
        reponse.put("projet", "pilotage-deploiement");
        reponse.put("livraisonsEnregistrees", service.total());
        reponse.put("livraisonsReussies", service.totalSucces());
        reponse.put("dureeMoyenneSecondes", Math.round(service.dureeMoyenne()));
        return reponse;
    }
}
