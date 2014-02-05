API for Nasjonal Turbase [![Build Status](https://drone.io/github.com/Turistforeningen/nasjonalturbase/status.png)](https://drone.io/github.com/Turistforeningen/nasjonalturbase/latest)
========================

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

## License

> The MIT License (MIT)
>
> Copyright (c) 2013-2014 Turistforeningen, Hans Kristian Flaatten
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
> FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
> COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
> IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

