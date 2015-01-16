
{docopt} = require('docopt')
require! 'fs'

shelljs = require('shelljs')

doc = shelljs.cat(__dirname+"/docs/usage.md")


get-option = (a, b, def, o) ->
    if not o[a] and not o[b]
        return def
    else 
        return o[b]

o = docopt(doc)


filename      = get-option('-f' , '--file'     , '/dev/stdin'  , o)
output        = get-option('-o' , '--output'   , '/dev/stdout' , o)

filename = o["<input>"]
filename ?= '/dev/stdin'





