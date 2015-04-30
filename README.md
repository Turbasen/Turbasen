# Nasjonal Turbase [![Build status](https://img.shields.io/wercker/ci/5540e465dc16db44790b428d.svg "Build status")](https://app.wercker.com/project/bykey/ac9dffab857ff18e13ae57d86d6cee9a)

## Resources

 * [Website](http://documentation.nasjonalturbase.no)
 * [API docs](http://documentation.nasjonalturbase.no/api.html)
 * [Technical docs](https://turistforeningen.atlassian.net/wiki/display/dnt/Nasjonal+Turbase)
 * [Data licenses](http://documentation.nasjonalturbase.no/lisenser.html)
 * [Attribution](http://documentation.nasjonalturbase.no/navngiving.html)

## The stack

The API is a RESTfull API with JSON as it's only supported input/output format.
The API is wirtten in JavaScript for [Node.JS](http://nodejs.org) using
[Literate](http://coffeescript.org/#literate)
[CoffeeScript](http://coffeescript.org). It reads and writes to a
[MongoDB](http://www.mongodb.org) database and caches ifemeral data in
[Redis](http://redis.io).

## Developing

### Environment Varaibles

* `NODE_ENV`
* `PORT_WWW`
* `MONGO_URI`
* `DOTCLOUD_CACHE_REDIS_HOST`
* `DOTCLOUD_CACHE_REDIS_PORT`

### Install using Vagrant

```bash
vagrant up
vagrant ssh
```

### Install manually

`NB` this assumes that you already have Node, MongoDB and Redis running locally
on your machine.

```bash
npm install
```

### Testing

```
npm test
```

## [MIT License](https://github.com/Turistforeningen/Turbasen/blob/master/LICENSE)
