<!-- The embedded linux materials are inherited from Bootlin trainning materials -->
<!-- https://github.com/bootlin/training-materials/ -->

- [How to compile these materials](#how-to-compile-these-materials)
  - [Install dependencies](#install-dependencies)
    - [Install docker](#install-docker)
    - [Build docker](#build-docker)
    - [Run docker](#run-docker)
  - [Compile the materials](#compile-the-materials)
- [How to add new materials](#how-to-add-new-materials)

# How to compile these materials

## Install dependencies

On Ubuntu 20.04.6 LTS

### Install docker

```bash
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Set up the Docker repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce
```

### Build docker

```bash
sudo docker build -t materials -f utils/docker/Dockerfile .
```

### Run docker

```bash
# Run docker with compile command
sudo docker run -u $(id -u):$(id -g) -v $(pwd):/materials -it --rm materials make <target>

# Run docker image
sudo docker run -u $(id -u):$(id -g) -v $(pwd):/materials -it --rm materials
```

## Compile the materials

```bash
# Get available targets
make help

# List all materials
make list-materials

# Compile specific material
make <target>

Eg: make full-embedded-linux-bbb-simple-project-slides.pdf
```

# How to add new materials

