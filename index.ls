"use strict"

# Preamble 

require! 'fs'
require! 'path'
_     = require('shelljs')
__    = require('bluebird')
___   = require('lodash')
debug = require('debug')('apparmorize')
lock  = require('lockfile')

fs = __.promisifyAll(fs)
npm-dir = path.dirname(__filename)


# Program

get-command-options = ->

    {docopt} = require('docopt')
    doc = _.cat(__dirname+"/docs/usage.md")

    get-option = (a, b, def, o) ->
        if not o[a] and not o[b]
            return def
        else 
            return o[b]

    o = docopt(doc)

    spool-dir           = get-option('-s', '--spool', "#{process.cwd()}/spool",o )
    template-name       = get-option('-p', '--profile', 'standard'  , o)
    go                  = get-option('-g', '--go', false, o)
    number-of-instances = get-option('-n', '--number' , 1 , o)
    number-of-instances = parseInt(number-of-instances)

    install = o['install']? and o['install']
    run = o['run']? and o['run']

    program = o['PROGRAM']

    return { 
        install: install, 
        run: run, 
        go: go 
        spool-dir: path.resolve(spool-dir), 
        template-name, 
        program: program,
        number-of-instances: number-of-instances 
        }


initLiquid = ->
    engine = require('liquid-node').Engine
    return new engine()

gen-profile = (liquid, command-name, spool-dir, template-name-a, go) ->

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
        if not go
            console.log "Will write profile to #spool-dir/#profile-name"
            return "#spool-dir/#profile-name"
        else 
            debug("Writing profile to #spool-dir/#profile-name")
            fs.writeFileAsync("#spool-dir/#profile-name", it, 'utf-8').then ->
                return "#spool-dir/#profile-name"


check-existing-profile = (template-name) ->
    template-name-a = "#npm-dir/profiles/#template-name/profile.txt"

    if not _.test('-e', "#template-name-a")
        console.log "Sorry, profile '#template-name-a' does not exist"
        process.exit(1)
    return { template-name-a: template-name-a }

copy = (name, from-dir, go) ->
    complete-name = "#from-dir/#name"
    destination-name = "/etc/apparmor.d"
    if not go 
        console.log "Will copy #complete-name to #destination-name"
    else 
        debug "Copying #complete-name to #destination-name"
        _.cp(complete-name, destination-name)

restart-apparmor = (go) ->
    if not go 
        console.log "Will restart apparmor"
    else 
        debug "Will restart apparmor"
        return __.promisify(_.exec)("service apparmor reload")

getNextAvailable = (config) ->
    data = JSON.parse(_.cat(config))
    av = ___.filter(data.resources, (.available))
    if av.length == 0 
        debug "No resource available"
        return 0
    else 
        av[0].available = false;
        debug "Got #{av[0].number}"
        debug data
        return av[0].number;

putBack = (config,n) ->
    data = JSON.parse(_.cat(config))
    av = ___.filter(data.resources, -> (it.number == n))
    av[0].available = true
    debug "Restored resource" 
    debug data

main = ->
    opts = get-command-options!
    debug opts
    { install, run } = opts

    if install 

        { template-name } = opts
        { template-name-a} = check-existing-profile(template-name)

        liquid = initLiquid!

        { number-of-instances, spool-dir, template-name } = opts 
        _.mkdir('-p', spool-dir)

        __.all([1 to number-of-instances].map (i) ->
            gen-profile(liquid, "cmd-#i", spool-dir, template-name-a, opts.go)
            .then ->
                copy(it, spool-dir, opts.go))
        .then ->
            dta = {}
            dta.resources = [ { number: i, available: true } for i in [ 1 to number-of-instances] ]
            JSON.stringify(dta, 0, 4).to("#spool-dir/config.json")
        .then ->
            restart-apparmor!
        .then ->
            console.log "done."
    else 
        { spool-dir, program } = opts  
        config = "#spool-dir/config.json"
        lockFile = "#spool-dir/lock"
        lock.lockAsync = __.promisify(lock.lock)
        lock.unlockAsync = __.promisify(lock.unlock)
        var n
        try 
            lock.lockAsync(lockFile)
            .then ->
                n := getNextAvailable(config)
            .then ->
                lock.unlockAsync(lockFile)
            .then ->
                if n == 0
                    console.error "all slots are taken."
                else 
                    _.cp('-f', path.resolve(program), "#spool-dir/cmd-#n")

                    __.promisify(_.exec)("#spool-dir/cmd-#n")

                    .finally ->
                        lock.lockAsync(lockFile, { retries: 3, retryWait: 100 })
                        .then ->
                            putBack(config, n)
                        .then ->
                            lock.unlockAsync(lockFile)

        catch error 
            console.error "Sorry, #error"

main!







