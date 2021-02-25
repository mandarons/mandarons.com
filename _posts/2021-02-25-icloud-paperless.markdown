---
layout: single
title:  "Searchable Scanned Documents in iCloud Drive"
date:   2021-02-23 14:17:47 -0800
categories: Tutorial
tag-name: self-host tutorial
---
## Problem statement

With an ongoing shift to paperless transactions, it has been easier than ever to reduce paper (and save the environment) in our lives. However, with a lot of real-world paper is going electronic, searching for something in the scanned documents has been a huge challenge for me. 

I started to look for answers.

## Background

Being in Apple ecosystem, I wanted something to allow me to index specific folder in iCloud drive (I prefer all of my scanned documents go in a specific folder), with a web interface and of course, ability to self-host. 

I stumbled upon the [Paperless-ng project](https://github.com/jonaswinkler/paperless-ng). It has the features I am looking for - web GUI and [dockerized for self-hosting](https://paperless-ng.readthedocs.io/en/latest/setup.html#setup-docker-hub). Cool! But how about dockerized iCloud drive client?

Well, I couldn't find any reliable ones. So I decided to make one - [Dockerized iCloud Drive](https://github.com/mandarons/icloud-drive-docker). By the way, [pyiCloud](https://github.com/picklepete/pyicloud) is awesome! :sunglasses:

## Solution

### prerequisites

  - [ ] [Docker](https://www.docker.com/products/docker-desktop) (on Windows/Linux/MacOS or any other OS you have) [Required]
  - [ ] [Docker-Compose](https://docs.docker.com/compose/install/) [Strongly recommended]

### Setup
- [ ] Create following directories in your `home` (or any other location) for our applications: 
  - [ ] `/home/mandarons/paperless-ng` 
  - [ ] `/home/mandarons/icloud-drive`
  - [ ] `/home/mandarons/postgres`
  - [ ] `/home/mandarons/redis`

- [ ] Create a directory for syncing iCloud Drive (one way):
Let's call it as `drive` located at `/home/mandarons/icloud-drive/drive`. This will be shared between `icloud-drive` and `paperless-ng` docker containers.

- [ ] Create `config.yml` file at `/home/mandarons/icloud-drive/config.yml` with following configuration:

```yaml
credentials:
  # iCloud drive username
  username: <icloud-username> # replace with your icloud username/email
  # iCloud drive password - leave it empty. We will configure keyring in the next step
  password:
settings:
  sync_interval: 1800 # every 30 minutes
  destination: './drive' # local to icloud-drive container
  remove_obsolete: false # to retain deleted items on iCloud server
  verbose: false # not needed until something goes wrong.
filters:
  # File filters to be included in syncing iCloud drive content
  folders:
    - Documents #relative location in your iCloud drive to contents to scan
  file_extensions:
    # File extensions to be included - below are common scanned document formats
    - pdf
    - png
    - jpg
    - jpeg
```

- [ ] Create a `docker-compose.yml` file `/home/mandarons/docker-compose.yml`.

- [ ] Copy following code into `docker-compose.yml` file

```yaml
version: "3.4"

services:
  postgres:
    container_name: postgres
    image: postgres:11.3-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=<unique-complex-string> #Change it
    ports:
      - 5432:5432
    volumes:
      - ${PWD}/postgres/data:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -U postgres
      interval: 10s
      timeout: 10s
      retries: 3
      start_period: 30s

  redis:
    container_name: redis
    image: redis:alpine3.12
    restart: unless-stopped
    ports:
      - 6379:6379
    command: redis-server --appendonly yes
    volumes:
      - ${PWD}/redis/data:/data
    healthcheck:
      test: redis-cli server ping
      interval: 10s
      timeout: 10s
      retries: 3
      start_period: 30s

  paperless-ng:
    image: jonaswinkler/paperless-ng:0.9.13
    container_name: paperless-ng
    restart: unless-stopped
    depends_on:
      - postgres
      - redis
      - icloud-drive
    ports:
      - 8083:8000 # or any other port you want to use
    volumes:
      - ${PWD}/paperless-ng/data/data:/usr/src/paperless/data
      - ${PWD}/paperless-ng/data/media:/usr/src/paperless/media
      - ${PWD}/paperless-ng/data/export:/usr/src/paperless/export
      - ${PWD}/icloud-drive/drive:/usr/src/paperless/consume
    environment:
      USERMAP_UID: 1000
      USERMAP_GID: 1000
      PAPERLESS_OCR_LANGUAGES: eng
      PAPERLESS_SECRET_KEY: random-secret-key # Feel free to change it to anything else
      PAPERLESS_TIME_ZONE: America/Los_Angeles # Or your time zone
      PAPERLESS_REDIS: redis://redis:6379
      PAPERLESS_DBHOST: postgres
      PAPERLESS_DBNAME: paperless-ng-db 
      PAPERLESS_DBUSER: paperless-ng-db-user 
      PAPERLESS_DBPASS: paperless-ng-db-user-password
      PAPERLESS_CONSUMER_RECURSIVE: 'true' # For recursive scanning of `drive` directory
    healthcheck:
      test: ["CMD", "curl", "-f", "http://<host-ip-address>:8083"] # <host-ip-address> is your system's IP address on which docker is installed
      interval: 30s
      timeout: 10s
      retries: 5

  icloud-drive:
    image: mandarons/icloud-drive:1.0.0
    container_name: icloud-drive
    restart: unless-stopped
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - ${PWD}/icloud-drive/config.yaml:/app/config.yaml # We will create the config file in next step
      - ${PWD}/icloud-drive/drive:/app/drive
```

- [ ] On a command line, change current directory to `/home/mandarons` and Run `docker-compose up -d` to create containers.

- [ ] Create POSTGRES database for `paperless-ng`
  - [ ] Log into `postgres` container: `docker exec -it postgres /bin/sh`
  - [ ] Run following commands:
  ```
  # su - postgres
  $ psql
  postgres=# create database paperless-ng;
  postgres=# create user paperless-ng-user with encrypted password 'paperless-ng-user-password';
  postgres=# grant all privileges on database paperless-ng to paperless-ng-user;
  ```
  We are now set with the database. No special configuration is required for `redis`.

- [ ] Configure `icloud-drive` for auto-login using `keyring` utility by running command: `docker exec -it icloud-drive /bin/sh -c "icloud --username=<icloud-username>"` and follow the prompts to authenticate.

- [ ] Relaunch the containers with updated configuration from `/home/mandarons/` using `docker-compose down && docker-compose up -d`

- [ ] Navigate to `http://<host-ip-address>:8083` to lauch `paperless-ng`.

And that's it! Depending on number and size of your scanned documents, it will take some time to show all of them in `paperless-ng` web app.

May the Laziness with you! :smile:

[![Join the chat at https://gitter.im/mandarons/community](https://badges.gitter.im/mandarons/iCloud-drive-docker.svg)](https://gitter.im/mandarons/community) <a href="https://www.buymeacoffee.com/mandarons" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 20px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>