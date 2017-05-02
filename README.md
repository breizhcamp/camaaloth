# Camaaloth, la malette vidéo du BreizhCamp

Pour le BreizhCamp nous cherchions une solution de captation qui fonctionne en plug'n play et qui dépote du pâté, après avoir essayé diverses solutions nous avons choisi de la développer nous même ...

## Cahier des charges

- [X] capture de la douce voix du speaker avec la meilleure qualité possible
- [ ] capture du son d'ambiance pour un rendu "live" plus sympatique
- [X] capture de l'affichage du speaker (slides, demos, etc) en haute résolution, sans impact sur sa machine
- [X] prise en compte de cette #&$!@ de HDCP (en particulier sur les Macs)
- [X] pass-through de l'affichage speaker vers le système de projection, équipé soit en HDMi soit en VGA
- [X] capture de la délicieuse plastique du speaker en pleine action
- [X] composition en direct des flux audio et vidéo pour produire la vidéo diffusable
- [X] le tout dans une boite solide type flight-case, pratique à transporter, sans complexité de mise en oeuvre
- [X] éprouvé après des mois d'utilisation sur les divers événements des communautés BreizhCamp (TM)


## Matos

### Proof of Concept (4/10/2016)

- un PC mini tour quad core (tour qui sera explosée dans le flight, mais dont on garde les fixations)
- carte BlackMagic intensity 4K
- carte BlackMagic Declink
- micro cravate ("lavalier"). Seenheiser AVX MKE2, parce que même s'il coute un bras, il a un putain de bon son
- camescope avec sortie HDMi
- système Linux (Ubuntu, faisons simple)
- [OBS](https://obsproject.com/)

Le PC speaker est raccordé à la intensity 4K. Celle-ci peut capturer en 1080p60 et faire pass-through HDMi
La caméra est raccordée à la DecLink, qui ne monte pas aussi haut en résolution mais ça suffit largement
Micro raccordé à l'entrée son du PC via une table de mixage (qui permettra à termes de mixer un micro d'ambiance, entrée audio PC, etc)

et voilà [le résultat](https://youtu.be/TmFP9R4AD-c)

Sur cette première expérimentation le résultat est super encourageant, mais le setup reste plutôt fastidieux. La mise en flight-case est donc une étape à considérer rapidement :P
