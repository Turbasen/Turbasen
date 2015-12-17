FROM node:argon-slim

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm install --production

COPY coffee /usr/src/app/coffee
RUN npm run-script postinstall

CMD [ "node", "src/server.js" ]
