FROM ubuntu:17.10
RUN apt-get update && \
    apt-get install -y git-buildpackage

RUN apt-get build-dep -y nageru
RUN apt-get install -y liblua5.2-dev
