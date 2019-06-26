FROM node:8.16-alpine

EXPOSE 8888

WORKDIR /taiga-event/

COPY ./src/ .

RUN npm config set registry https://registry.npm.taobao.org && npm install

ENTRYPOINT ["/taiga-event/node_modules/coffeescript/bin/coffee", "index.coffee"]