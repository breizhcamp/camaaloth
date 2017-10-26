#!/bin/bash

compose() {
  docker-compose -p camalooth -f docker-compose-debootstrap.yaml "$@"
}

compose up --build

docker commit \
    -c 'ENTRYPOINT ["/bin/bash"]' \
    camalooth_debootstrap_1  camalooth:initial

compose rm -f -s
