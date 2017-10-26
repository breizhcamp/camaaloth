# Generateur de systeme au format ISO hybride pour Camalooth

## preparation

Pour accelérer le build, il faut d'abord générer une image racine avec debootstrap pré-configuré. Pour cela,

    ./create-deboostrap-image.sh

## développement

Lancer le container avec live-build

    docker-compose up -d

puis sauter dedans:

    docker-compose exec builder /bin/bash

après, c'est du live-build, donc pour générer l'image ISO

    lb build

## Documentation

* live-build: http://debian-live.alioth.debian.org/live-manual/unstable/manual/html/live-manual.en.html
