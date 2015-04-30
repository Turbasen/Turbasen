# Nasjonal Turbase [![Build status](https://img.shields.io/wercker/ci/5540e465dc16db44790b428d.svg "Build status")](https://app.wercker.com/project/bykey/ac9dffab857ff18e13ae57d86d6cee9a)

The National Trekking Database (Nasjonal Turbase) is the Norwegian national
platform to collect, manage, and distribute standardised trekking and outdoor
data from all participants who facilitate outdoor recreation.

| --------------- | ------------------------------------------------- |
| Website         | http://www.nasjonalturbase.no                     |
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
