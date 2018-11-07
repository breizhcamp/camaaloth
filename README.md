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


## Matos en production (2018)

Après un Proof of Concept en 2016 (voir ci-dessous), nous avons évolué sur une version 'production' depuis le BreizhCamp 2017
qui nous permet de capturer, de monter et de mixer en live les conférences.

Voici le résultat : [Introduction à Flutter](https://www.youtube.com/watch?v=K-tXEkGTzfE)

### Captation du speaker

- Un camescope disposant d'une sortie HDMI clean (n'affichant aucune donnée sur la sortie, et configurable niveau résolution).
  Le notre c'est un Sony HDR-CX740VE, on a aussi des Sony HDR-CX240E.
- Un boitier de conversion [BlackMagic MicroConverter HDMI to SDI](https://www.blackmagicdesign.com/products/microconverters/techspecs/W-CONU-04)
  permettant de faire 10m sans avoir les soucis du HDMI et un câble qui pèse 3 tonnes.

### Captation de l'écran du PC

Pour récupérer le signal HDMI du PC, le recopier sur le vidéo projecteur, et l'envoyer vers notre machine de captation, nous utilisons le boitier
[Decimator MD HX](http://www.decimator.com/Products/MiniConverters/MD-HX/MD-HX.html). Il permet d'une part de recopier le signal HDMI en input
vers un HDMI en output (pour le vidéoprojecteur), et d'autre part, de convertir le signal dans la résolution souhaitée (ici 720p60) et de l'envoyer
en SDI.

Il est aussi possible de faire le conversion avec le boitier [BlackMagic Mini Converter UpDownCross HD](https://www.blackmagicdesign.com/products/miniconverters/techspecs/W-CONM-28)
qui est un peu moins cher que le Decimator. Il ne peut cependant pas faire de recopie sans conversion de format et entraine une perte (si le speaker
envoi en 1080p et qu'on converti en 720p pour la capture, le vidéoprojecteur n'affichera que du 720p).

On a pas mal galéré avec les différents format de sortie des PC et le boitier de conversion est indispensable pour que cela fonctionne
de manière simple et fiable.

Prévoir tous les adaptateurs possible et inimaginable pour convertir en HDMI (Mini Display Port, Display Port, Mini HDMI, Micro HDMI, USB Type-C...)

### Machine de captation

Le PC qui nous permet de récupérer le son, l'image du speaker et l'écran et de mixer tout ça en side by side.

Il est composé du matériel suivant :

- Un boitier rackable 2U [Logic Case](https://www.logic-case.com/products/rackmount-chassis/2u/2u-short-depth-chassis--sc-2380/)
- Une carte mère Gigabyte GA-Z270-HD3P
- Un CPU Intel Core i5-7600K et son ventirad Noctua NH-L9x65
- 8 Go de RAM et 240Go de SSD
- Une carte d'acquisition [BlackMagic DeckLink Duo 2](https://www.blackmagicdesign.com/products/decklink/techspecs/W-DLK-31)

Côté logiciel, nous avions commencé par utiliser [OBS](https://obsproject.com/), très simple et bien supporté par la communauté
de streameur de jeux vidéo. Nous avons cependant eu des problèmes de décalage audio/vidéo non reproductible (sûrement corrigé depuis).

Nous avons donc migré vers un logiciel un peu plus "roots" : [Nageru](https://nageru.sesse.net/). Les thèmes sont a écrire en Lua
mais ça fonctionne bien une fois en route.

L'OS tourne sous Ubuntu Studio, tous les softs utilisés sont Open Source.

Nous avons aussi un pad [Akai MPD 218](https://www.thomann.de/fr/akai_mpd_218.htm) nous permettant de gérer les transitions pendant le mixage vidéo.

### Captation de l'audio

L'audio est la partie principale à avoir dans une vidéo technique pour que celle-ci soit regardable. Nous avons donc mis le paquet sur
cette partie pour avoir ça au top. Nous avons fait des tests sur du matos d'entrée de gamme qui ne nous a jamais satisfait. 

Nous avons donc investi dans la référence du marché, à savoir [Sennheiser ew](https://www.thomann.de/fr/sennheiser_ew_100_g4_me2_1g8_band.htm) pour les transmetteurs HF.

Pour les micros, nous sommes parti sur des micro "serre tête" pour éviter les variations de volume pendant la présentation (comme avec des micro-cravate ou mains).
Nous avons un micro [Sennheiser HSP 2 EW 3 Beige](https://www.thomann.de/fr/sennheiser_hsp_2_ew_beige.htm) qui marchent très très bien
mais comme il coûte un bras, on a aussi des [Rode HS2-P](https://www.thomann.de/fr/rode_hs2_p_small.htm) qui marchent bien.

Pour injecter tout ça dans le PC, on a une carte son rackable [Focusrite Scarlett 18i20](https://www.thomann.de/fr/focusrite_scarlett_18i20_2nd_gen.htm) 
reliée en USB au PC. L'avantage c'est, qu'en outre de bien capter le son et de fonctionner sous Linux, elle nous permet de faire le mixage pour ressortir
directement vers des enceintes. Sinon n'importe quelle carte son USB Focusrite peut faire l'affaire.

On a aussi des micros mains pour les questions du public. Nos modèles sont pas terrible, donc comme pour les transmetteurs HF, se tourner vers de la qualité
(Sennheiser ou Shure) pour être tranquille.

## Évolutions

Nous sommes en train de préparer une V2 plus lègère car ça fait quand même pas mal de choses à trimbaler. Nous partons sur un rack 1.5U, des Sennheiser AVX
et une caméra [BlackMagic Studio](https://www.blackmagicdesign.com/products/blackmagicstudiocamera/techspecs/W-CST-01) nous permettant d'avoir un retour de mixage directement sur la caméra.


## Proof of Concept (4/10/2016)

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

### BreizhCamp 2017
Après plusieurs mois de mise au point et de galères diverses entre les équipements désuets des salles de conférence (connectique VGA 1024x768) ou les PC speakers exotiques (MacBook dernière génération USB-C only, PC Windows 10 4k ...) nous avons pas mal éprouvé le bébé et étions fin prêts pour le BreizhCamp. Résultat : 30 session capturées sans soucis avec une super qualité !

Par rapport au proto

- troisième carte BlackMagic permettant de changer d'angle de caméra
- micro serre tête sennheiser. Coute le deuxième bras, mais qu'est ce que le son est bon !
- compresseur / gate audio. Permet d'avoir un niveau audio constant et d'éviter le bruit de fond résiduel pendant les "blancs"
- diverses mises à jour système
- le tout dans un rack tout intégré avec écran de contrôle, lourd comme une vache mais drôlement pratique quand même.

