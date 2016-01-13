Redis = require 'ioredis'

module.exports = new Redis \
  process.env.REDIS_PORT_6379_TCP_PORT, \
  process.env.REDIS_PORT_6379_TCP_ADDR
