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

# Use the latest Ubuntu base image
FROM ubuntu:latest

LABEL maintainer="Ngoc Ho" \
description="Container with everything needed to build materials"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    texlive-plain-generic \
    texlive-lang-french \
    # To reduce image size
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables to non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Set default working directory
WORKDIR /materials

# Default command
CMD [ "bash" ]
