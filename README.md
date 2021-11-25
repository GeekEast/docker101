- [Why Docker?](#why-docker)
- [Get Started](#get-started)
- [Update Source Code](#update-source-code)
- [Share Images](#share-images)
- [Persist Data](#persist-data)
  - [Named Volume](#named-volume)
  - [Bind Volume](#bind-volume)
- [Logging](#logging)
- [Network](#network)
- [Compose](#compose)
- [Layer Cache](#layer-cache)
- [Multi-Stage Builds](#multi-stage-builds)

## Why Docker?
- **guarantee the software always run in the same way**. 
<p align="center"><img style="display: block; width: 600px; margin: 0 auto;" src=img/2020-12-15-10-10-56.png alt="no image found"></p>

## Get Started
- **build** `docker build -t sample-node-image .`
- **run** `docker run -dp 3000:3000 sample-node-image`


## Update Source Code
- **list**: `docker ps`
- **remove**: `docker rm -rf <container_id>`
- **rebuild**: `docker build -t sample-node-image .`
- **restart**: `docker run -dp 3000:3000 sample-node-image`


## Share Images
- **create**: a **public** repo in [Docker Hub](https://hub.docker.com/).
- **login**: `docker login -u <USER_NAME>`
- **tag**: `docker tag sample-node-image <USER_NAME>/sample-node-image`
- **push**: `docker push <USER_NAME>/sample-node-image`

## Persist Data
### Named Volume
- **format**: `todo-db:/etc/todos`
- **use case**: 
  - location on host doesn't matter.
  - can be easily shared between containers.
  - eg: mongodb data persist on host.
- **create**: `docker volume create todo-db`
- **run**:`docker run -dp 3000:3000 todo-db:/etc/todos sample-node-image`
- **inpect**: `docker volume inspect todo-db`

```yaml
version: "3.7"
  services:
    mysql:
        image: mysql:5.7
        volumes:
            - todo-mysql-data:/var/lib/mysql 

volumes:
    todo-mysql-data
```

### Bind Volume
- **format**: `/desktop/todo-app:/usr/local/app`
- **use case**: 
  - location on host matters
  - don't need to shared between containers
  - eg: watch development mode.
- **create**: `docker run -dp 3000:3000 -w /app -v "$(pwd):/app" node:12-alpine sh -c "yarn install && yarn run dev"`
    - `-w /app`: set working directory in container
    - `-v "$(pwd):/app"`: bind host current directory to `/app` in the container
```yaml
version: "3.7"

services:
  post-api:
    container_name: post_service
    build: ./
    command: yarn start
    volumes:
      - ./:/app
```

## Logging
- **inspect**: `docker logs -f <container_id>`
## Network
- **create**: `docker network create todo-app`
- **connect**: `docker run --network todo-app --network-alias mysql`
  - the `network-alias` will be the **hostname** of the container
```yaml
version: "2.4"

services:
  proxy:
    build: ./proxy
    networks:
      - outside_network
      - default
  app:
    build: ./app
    networks:
      - default

networks:
  outside:
    external: true
    name: outside_network
```

## Compose
- A tool used to define a complete application **stack**.
```yaml
version: "3.7"
  services:
    app:
        image: node:12-alpine
        command: yarn installl && yarn run dev
        working_dir: /app
        volumes: ./:/app
        ports:
            - 3000:3000
        environment
            MYSQL_HOST: mysql
            MYSQL_USER: root
            MYSQL_PASSWORD: secret
            MYSQL_DB: todos
    mysql:
        image: mysql:5.7
        volumes:
            - todo-mysql-data:/var/lib/mysql
        environment:
            MYSQL_ROOT_PASSWORD: secret
            MYSQL_DATABASE: todos

volumes:
    todo-mysql-data
```
- **start** 
  - `docker-compose up -d`
  - `docker-compose --env-file .docker.development.env up -d`
- **log** 
  - `docker logs -f <container_name>`
  - `docker-compose logs -f`
  - `docker-compose logs -f <service_name>`
- **remove** 
  - `docker-compose down`
  - `docker-compose down --volumes` delete volumes as well


## Layer Cache
- inspect layers: `docker image history getting-started`
- **every** command create a new layer
```yaml
FROM node:12-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node","src/index.js"]
```
- **problem**:
  - when you udpate some `dependencies`, you need to `rebuild` this image.
  - line 1,2,5 is automatically cached.
  - but what about line 3 and 4?
  - everytime you update some dependencies, you also need to copy other files **again**
  - and you also copy files from host `node_modules` to the container.
- solution: separate **unstable** parts
```yaml
# Dockerfile
FROM node:12-alpine
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --production
COPY . . # package.json change won't decache this one.
CMD ["node","src/index.js"]
```
- **important!**
```yaml
# .dockerignore
node_modules # this is important
```

## Multi-Stage Builds
- build stage: the image will be the latest stage.
- the final image only contains built code
```yaml
FROM maven AS build
WORKDIR /app
COPY . .
RUN mvn package

FROM tomcat
COPY --from=build /app/target/file.war /usr/local/tomcat/webapps
```

## multiple-platform build
- arm64
```sh
# run this only once
docker buildx create --use --name customerBuilder

# build for both arm64 and amd64
docker buildx build --platform linux/amd64,linux/arm64 -t node-awscli:<version> .

# build for amd64 only
docker buildx build --platform linux/amd64 -t node-awscli:<version> .

# export image to local docker images
docker buildx build --platform linux/amd64 -t node-awscli:<version> --load .
```