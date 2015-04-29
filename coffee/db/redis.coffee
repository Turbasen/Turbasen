createClient = require('redis').createClient
module.exports = createClient process.env.REDIS_PORT_6379_TCP_PORT, process.env.REDIS_PORT_6379_TCP_ADDR
