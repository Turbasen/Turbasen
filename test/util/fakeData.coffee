"use strict"

ObjectID = require('mongodb').ObjectID
crypto = require('crypto')

Generator = (type, opts) ->
  opts = type if typeof n is 'object' and typeof opts is 'undefined'
  type = 'turer' if typeof type isnt 'string'

  @oid     = opts?.oid or false
  @type    = type or 'turer'
  @exclude = opts?.exclude or []
  @only    = opts?.only or []
  @static  = opts?.static or {}

  @

Generator.prototype.checksum = (data) ->
  crypto.createHash('md5').update(JSON.stringify(data)).digest("hex")

Generator.prototype.rand = (min, max) ->
  Math.floor (Math.random() * (max - min + 1) + min)

Generator.prototype.genId = (n, a, o) ->
  return [] if n is 0 and a
  return new ObjectID() if n is 1 and o
  return new ObjectID().toString() if (typeof n is 'undefined' or n is 1) and not a
  res = []
  res.push(new ObjectID().toString()) for [1..n]
  return res

Generator.prototype.genProvider = ->
  providers = [
    "DNT"
    "NRK"
    "TURAPP"
  ]
  providers[@rand(0, providers.length-1)]

Generator.prototype.genLicense = ->
  lisences = [
    "CC BY-NC-ND 3.0 NO"
    "CC BY-NC-SA 3.0 NO"
    "CC BY-NC 3.0 NO"
    "CC BY-ND 3.0 NO"
    "CC BY-SA 3.0 NO"
    "CC BY 3.0 NO"
  ]
  lisences[@rand(0, lisences.length-1)]

Generator.prototype.genStatus = ->
  statuses = [
    "Offentlig"
    "Privat"
    "Kladd"
    "Slettet"
  ]
  statuses[@rand(0, statuses.length-1)]

Generator.prototype.genGroups = (len) ->
  groups = [
    '52c672252dc5138712808e01'
    '52c672252dc5138712808e02'
    '52c672252dc5138712808e03'
    '52c672252dc5138712808e04'
    '52c672252dc5138712808e05'
    '52c672252dc5138712808e06'
    '52c672252dc5138712808e07'
    '52c672252dc5138712808e08'
    '52c672252dc5138712808e09'
    '52c672252dc5138712808e10'
  ]
  res = []
  while res.length < len
    rand = @rand(0, groups.length-1)
    res.push groups[rand] if groups[rand] not in res
  res

Generator.prototype.genTags = ->
  res = []
  tags =
    steder: [
      'Hytte'
      'Fjelltopp'
      'Gapahuk'
      'Rasteplass'
      'Teltplass'
    ]
    turer: [
      'Fottur'
      'Skitur'
      'Sykkeltur'
      'Padletur'
      'Klatretur'
      'Bretur'
    ]
  res.push tags[@type][@rand(0, tags[@type].length-1)]
  res

Generator.prototype.genPrivat = ->
  return {
    foo: 'bar'
    bar: 'foo'
  }

Generator.prototype.doc = ->
  now = new Date().getTime()
  past = now - 100000000000

  doc =
    _id     : @genId(1, false, @oid)
    tilbyder: @genProvider()
    endret  : new Date(@rand(past, now)).toISOString()
    lisens  : @genLicense()
    status  : @genStatus()
    navn    : @checksum(Date.now())
    tags    : @genTags()
    privat  : @genPrivat()
    grupper : @genGroups(@rand(0,3))
    bilder  : @genId(@rand(0,20), true)

  doc.checksum = @checksum doc

  delete doc[key] for key of doc when key in @exclude
  delete doc[key] for key of doc when key not in @only if @only.length > 0

  doc[key] = val for key, val of @static

  return doc

Generator.prototype.gen = (n, opts) ->
  opts = n if typeof n is 'object' and typeof opts is 'undefined'
  n = 1 if typeof n isnt 'number'

  if opts
    backup =
      oid     : @oid
      type    : @type
      exclude : JSON.parse(JSON.stringify(@exclude))
      only    : JSON.parse(JSON.stringify(@only))
      static  : JSON.parse(JSON.stringify(@static))

    @oid          = opts.oid if opts.oid
    @type         = opts.type if opts.type
    @only         = opts.only if opts.only
    @exclude      = @exclude.concat(opts.exclude) if opts.exclude
    @static[key]  = val for key, val of opts.static if opts.static

    if opts.include
      for key in opts.include when @exclude.indexOf(key) >= 0
        @exclude.splice(@exclude.indexOf(key), 1)

  throw new Error('Invalid type') if @type not in ['steder', 'turer']

  if typeof n is 'undefined' or n is 1
    res = @doc()
  else
    res = []
    res.push(@doc()) for i in [1..n]

  if opts
    @oid          = backup.oid
    @type         = backup.type
    @exclude      = backup.exclude
    @only         = backup.only
    @static       = backup.static

  return res

#
# JavaScript Object to Redis Objects
#
# @param data - {@code object} data object
#
# @return {@code object}
#
redisify = (data) ->
  obj = {}
  for key in Object.keys data
    val = data[key]
    val = val.join(',') if val instanceof Array
    obj[key] = val
  return obj

module.exports =
  Generator: Generator
  redisify: redisify

