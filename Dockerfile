FROM node:lts-alpine as build-stage
WORKDIR /app
COPY . .
RUN npm install
CMD npm run serve
EXPOSE 8080
