## Theory
- Docker: **guarantee the software always run in the same way**. 

## Get Started
- **build** `docker build -t sample-node-image .`
- **run** `docker run -dp 3000:3000 sample-node-image`, **(host:container)**


## Update Source Code
- `remove`: `docker rm -rf <container_id>`
- `rebuild`: `docker build -t sample-node-image .`
- `restart`: `docker run -dp 3000:3000 sample-node-image`


## Share Images
- Create a public repo in Docker Hub.
- `docker login -u <USER_NAME>`
- `docker tag sample-node-image <USER_NAME>/sample-node-image`
- `docker push <USER_NAME>/sample-node-image`s

## Persist Data
- While containers can `create`, `update`, and `delete` files, those changes are **lost** when the container is **removed** and all changes are isolated to that container.
- **Volumes**: They provide the ability to connect specific filesystem paths of the container back to the host machine.

### Named Volume
- usecase: persist data `from container to host`
- create `docker volume create todo-db`
- run a container with volume `docker run -dp 3000:3000 todo-db:/etc/todos sample-node-image` (host:container) `docker will create the volume if you don't do step 2`
- inpect the volume `docker volume inspect todo-db`
- mapping: `todo-db:/usr/local/data`

### Bind Volume
- usecase: watch mode for development `from host to container`
- mapping: `/desktop/todo-app:/usr/local/app`
- create: `docker run -dp 3000:3000 -w /app -v "$(pwd):/app" node:12-alpine sh -c "yarn install && yarn run dev"`
    - `-w /app`: set working directory in container
    - `-v "$(pwd):/app"`: bind host current directory to `/app` in the container


## Logging
- command `docker logs -f <container_id>`


## Network
- create: `docker network create todo-app`
- connect: `docker run --network todo-app --network-alias mysql`
  - the `network-alias` will be the **hostname** of the container

## Compose
- A tool used to define a complete application **stack**.
- example file
```yaml
version: "3.7"
  services:
    app:
        image: node:12-alpine
        command: yarn installl && yarn run dev
        working_dir: /app
        volumes: ./:/app # binding volume
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
            - todo-mysql-data:/var/lib/mysql # apply naming volume
        environment:
            MYSQL_ROOT_PASSWORD: secret
            MYSQL_DATABASE: todos

volumes:
    todo-mysql-data # naming volume definition
```
- start `docker-compose up -d`
- log `docker-compose logs -f` or `docker-compose logs -f <service_name>` if you want to see speccific service logs.
- remove `docker-compose down` or `docker-compose down --volumes` if you want to remove volues as well.


## Layer Cache
- inspect layers: `docker image history getting-started`
- every command create a new layer
```yaml
FROM node:12-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node","src/index.js"]
```
- problem:
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