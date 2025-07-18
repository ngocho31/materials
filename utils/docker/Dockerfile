# Docker file to create a container with everything needed to build materials
#
# Build the container (once):
#
#  sudo docker build -t materials -f utils/docker/Dockerfile .
#
# Use the container:
#
#  sudo docker run -u $(id -u):$(id -g) -v $(pwd):/materials -it --rm materials make <target>
#
# Note: "docker run" must run from the top-level directory of the materials

# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

LABEL maintainer="Ngoc Ho" \
description="Container with everything needed to build materials"

# Set environment variables to non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    dia \
    fakeroot \
    ghostscript \
    git \
    inkscape \
    fonts-inconsolata \
    fonts-liberation \
    make \
    python3-pygments \
    rsync \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-font-utils \
    texlive-fonts-recommended \
    texlive-extra-utils \
    texlive-fonts-extra \
    texlive-xetex \
    xfonts-scalable \
    lmodern \
    texlive-science \
    texlive-plain-generic

# Texlive packages for Vietnamese
RUN apt-get update && apt-get install -y \
    texlive-lang-other \
    tex-gyre

RUN useradd -ms /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER developer

# Set default working directory
WORKDIR /materials

# Default command
CMD [ "bash" ]
