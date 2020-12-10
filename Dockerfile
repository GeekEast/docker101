# command to run when you `docker build`
FROM node:12-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
# command to run when you `docker run`
CMD ["node", "src/index.js"] 