"use strict"

require! 'fs'
require! 'path'

{docopt} = require('docopt')
_ = require('shelljs')
__ = require('bluebird')

doc = _.cat(__dirname+"/docs/usage.md")
fs = __.promisifyAll(fs)


get-option = (a, b, def, o) ->
    if not o[a] and not o[b]
        return def
    else 
        return o[b]

o = docopt(doc)

npm-dir = path.dirname(__filename)


profile-template-name = get-option('-p' , '--profile'     , 'standard'  , o)
install = get-option('-i', '--install', false, o)

file-name = o['PROGRAM']

aprofile-template-name = "#npm-dir/profiles/#profile-template-name/profile.txt"

if not _.test('-e', "#aprofile-template-name")
    console.log "Sorry, profile '#aprofile-template-name' does not exist"
    process.exit(1)

profile-data = fs.readFileSync(aprofile-template-name, 'utf-8')

absolute-filename = path.resolve(file-name);
profile-name = absolute-filename.replace('/','')
profile-name = profile-name.replace(/\//g, '.')

object = {
        profile:
            date: require('moment')().format('MMMM DDD, YYYY - HH:MM')
            program-name: absolute-filename
            profile-name: profile-name
}

engine = require('liquid-node').Engine
e = new engine()
e.parseAndRender(profile-data, object)
.then ->
    fs.writeFileAsync("#{process.cwd()}/#profile-name", it, 'utf-8')
.then ->
        





