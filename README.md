# Nasjonal Turbase API Server

[![Build status](https://app.wercker.com/status/b8dc87b43260bb78fc535fe7cc0c03ff/s "wercker status")](https://app.wercker.com/project/bykey/b8dc87b43260bb78fc535fe7cc0c03ff)
[![Codacy grade](https://img.shields.io/codacy/grade/6362f4d1ca3c40ee817d2ae20017faee.svg "Codacy grade")](https://www.codacy.com/app/Turbasen/Turbasen)
[![Codacy coverage](https://img.shields.io/codacy/coverage/6362f4d1ca3c40ee817d2ae20017faee.svg "Codacy coverage")](https://www.codacy.com/app/Turbasen/Turbasen)
[![NPM downloads](https://img.shields.io/npm/dm/@turbasen/server.svg "NPM downloads")](https://www.npmjs.com/package/@turbasen/server)
[![NPM version](https://img.shields.io/npm/v/@turbasen/server.svg "NPM version")](https://www.npmjs.com/package/@turbasen/server)
[![Node version](https://img.shields.io/node/v/@turbasen/server.svg "Node version")](https://www.npmjs.com/package/@turbasen/server)
[![Dependency status](https://img.shields.io/david/Turbasen/Turbasen.svg "Dependency status")](https://david-dm.org/Turbasen/Turbasen)

The National Trekking Database (Nasjonal Turbase) is the Norwegian national
platform to collect, manage, and distribute standardised trekking and outdoor
data from all participants who facilitate outdoor recreation.

| Website         | http://www.nasjonalturbase.no                     |
| --------------- | ------------------------------------------------- |
| Data liceses    | http://www.nasjonalturbase.no/lisenser.html       |
| Attribution     | http://www.nasjonalturbase.no/navngiving.html     |
| API docs        | http://www.nasjonalturbase.no/api.html            |
| Technical docs  | https://github.com/Turistforeningen/Turbasen/wiki |

## Technology

* [Node.JS](https://nodejs.org) (Express.JS)
* [MongoDB](https://www.mongodb.org)
* [Redis](https://redis.io)

## Development

### Requirements

* [Docker](https://docs.docker.com/) >= v1.6
* [Docker Compose](https://docs.docker.com/compose/) >= v1.2

### Environment

* `NODE_ENV`
* `APP_PORT` (default `8080`)
* `REDIS_PORT_6379_TCP_PORT`
* `REDIS_PORT_6379_TCP_ADDR`
* `MONGO_PORT_27017_TCP_PORT`
* `MONGO_PORT_27017_TCP_ADDR`

### Test

```
docker-compose run www npm test
```
### Start

```
docker-compose run www npm run-script devserver
```

## [MIT License](https://github.com/Turistforeningen/Turbasen/blob/master/LICENSE)
