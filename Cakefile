{spawn, exec} = require 'child_process'

options =
  compress    : no
  json		    : no
  validate  	: no
  verbose	    : no
  watch		    : no

option '-x', '--compress', 'Compressed output'
option '-j', '--json',	   'JSON output which can be used in various programs'
option '-v', '--validate', 'JSHint and CSSLint validation'
option '-d', '--verbose',  'Output debug information'
option '-w', '--watch',    'Watch files for change and automatically recompile'

task 'clean', 'Compile up build files...', (opts) ->
  clean 'src/', ->
    debug 'Cleanup finished!', 0

task 'compile', 'Compile all source files...', (opts) ->
  options.extend opts
  compile 'coffee/', 'src/', ->
    debug 'Compile finsihed!', 0

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                 CLEAN UP SRC FOLDER
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
clean = (dir, cb) ->
  child = exec "rm -rf #{dir}*", (error, stdout, stderr) -> 
    if stderr
      debug 'Clean: failed!', 1, stderr
    else
      debug 'Clean: complete!'
      cb()
  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                 COFFEESCRIPT COMPILE
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
compile = (src, out, cb) ->
  debug 'CoffeeScript: compiling...'
  child = exec "coffee -o #{out} -c #{src}", (error, stdout, stderr) ->    
    if stderr
      debug 'Compile: failed!', 1, stderr
    else
      debug 'Compile: complete!'
      validate src, out, cb

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                 JAVASCRIPT VALIDATE
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
validate = (src, out, cb) ->
  return watch src, out, cb if not options.validate
  
  debug 'JShint: validating...'
  child = exec "jshint #{out}", (error, stdout, stderr) ->    
    if error
      debug "JShint: validation failed!\n", 1, stdout
    else
      debug 'JSHint: validateion completed!'
      watch src, out, cb

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                 WATCH FOR CHANGES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
watch = (src, out, cb) ->
  return cb() if not options.watch
  
  fs = require 'fs'  
  fs.readdir src, (err, files) ->
    for file in files
      fs.watchFile src + file, (event, filename) ->
        compile(src, out, cb)

  options.watch = off
  cb()

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                   HELPER FUNCTIONS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Get now time
now = ->
  t = new Date()
  
  h = t.getHours()
  m = t.getMinutes()
  s = t.getSeconds()
  
  h = "0#{h}" if h < 10
  m = "0#{m}" if m < 10
  s = "0#{s}" if s < 10
  
  "#{h}:#{m}:#{s}"

# Debug function
debug = (msg, errors, details) ->
  if typeof errors isnt "undefined"
  	if options.json
  	  console.log
  	    msg    : msg
  	    errors : errors
  	    details: details
  	else
  	 console.log "#{now()} - #{msg}"
  	 console.log details if typeof details isnt 'undefined'
  else if options.verbose
    console.log "#{now()} - #{msg}"

# Helpers functions
String::endsWith = (str) -> this.substr(this.length - str.length) is str
Array::last = -> this[this.length -1]
Array::implode = (sep) -> this.toString().replace ',', sep
Object::extend = (obj) ->
  org = this
  Object.keys(obj).forEach (key) ->
    prop = Object.getOwnPropertyDescriptor obj, key
    Object.defineProperty org, key, prop
  this