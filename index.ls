"use strict"

# Preamble 

require! 'fs'
require! 'path'

_ = require('shelljs')
__ = require('bluebird')

fs = __.promisifyAll(fs)
npm-dir = path.dirname(__filename)

get-command-options = ->

    {docopt} = require('docopt')
    doc = _.cat(__dirname+"/docs/usage.md")

    get-option = (a, b, def, o) ->
        if not o[a] and not o[b]
            return def
        else 
            return o[b]

    o = docopt(doc)

    spool-dir               = get-option('-s', '--spool', "#{process.cwd()}/spool",o )
    template-name   = get-option('-p', '--profile', 'standard'  , o)
    number-of-instances     = get-option('-n', '--number' , 1 , o)
    number-of-instances = parseInt(number-of-instances)

    install = o['install']? and o['install']
    run = o['run']? and o['run']

    program = o['PROGRAM']

    return { 
        install: install, 
        run: run, 
        spool-dir: path.resolve(spool-dir), 
        template-name, 
        program: program,
        number-of-instances: number-of-instances 
        }


initLiquid = ->
    engine = require('liquid-node').Engine
    return new engine()

gen-profile = (liquid, command-name, spool-dir, template-name-a) ->

    template-data = fs.readFileSync(template-name-a, 'utf-8')

    spool-dir = path.resolve(spool-dir)
    file-name = "#spool-dir/#command-name"

    absolute-filename = path.resolve(file-name);
    profile-name = absolute-filename.replace('/','')
    profile-name = profile-name.replace(/\//g, '.')

    object = {
            profile:
                date: require('moment')().format('MMMM DDD, YYYY - HH:MM')
                program-name: absolute-filename
                profile-name: profile-name
    }


    return liquid.parseAndRender(template-data, object).then ->
        fs.writeFileAsync("#spool-dir/#profile-name", it, 'utf-8')

check-existing-profile = (template-name) ->
    template-name-a = "#npm-dir/profiles/#template-name/profile.txt"

    if not _.test('-e', "#template-name-a")
        console.log "Sorry, profile '#template-name-a' does not exist"
        process.exit(1)
    return { template-name-a: template-name-a }


main = ->
    opts = get-command-options!
    { install, run } = opts

    if install 

        { template-name } = opts
        { template-name-a} = check-existing-profile(template-name)

        liquid = initLiquid!

        { number-of-instances, spool-dir, template-name } = opts 
        _.mkdir('-p', spool-dir)

        __.all([1 to number-of-instances].map (i) ->
            gen-profile(liquid, "cmd-#i", spool-dir, template-name-a).then ->
                JSON.stringify(opts, 0, 4).to("#spool-dir/config.json"))
    else 
        console.log "not implemented yet"

main!







