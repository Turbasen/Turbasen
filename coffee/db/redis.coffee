"use strict"

createClient = require('redis').createClient

port = process.env.DOTCLOUD_CACHE_REDIS_PORT or 6379
host = process.env.DOTCLOUD_CACHE_REDIS_HOST or 'localhost'
pass = process.env.DOTCLOUD_CACHE_REDIS_PASSWORD or null

module.exports = createClient port, host, auth_pass: pass

