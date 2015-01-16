
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


profile-name = get-option('-p' , '--profile'     , 'standard'  , o)
file-name = o['PROGRAM']






