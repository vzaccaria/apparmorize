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
    run     = o['run']? and o['run']
    remove  = o['remove']? and o['remove']

    program = o['PROGRAM']

    return { install, run, go, remove, spool-dir: path.resolve(spool-dir), template-name, program, number-of-instances }


initLiquid = ->
    engine = require('liquid-node').Engine
    return new engine()


getProfilesPrefix = (spool-dir) ->
    absolute-filename   = path.resolve(spool-dir);
    profile-name        = absolute-filename.replace('/','')
    profile-name        = profile-name.replace(/\//g, '.')
    return "/etc/apparmor.d/#profile-name"


gen-profile = (liquid, command-name, spool-dir, template-name-a, go) ->

    template-data       = fs.readFileSync(template-name-a, 'utf-8')

    spool-dir           = path.resolve(spool-dir)
    file-name           = "#spool-dir/#command-name"

    absolute-filename   = path.resolve(file-name);
    profile-name        = absolute-filename.replace('/','')
    profile-name        = profile-name.replace(/\//g, '.')

    object = {
            profile:
                date: require('moment')().format('MMMM DDD, YYYY - HH:MM')
                program-name: absolute-filename
                profile-name: profile-name
    }


    return liquid.parseAndRender(template-data, object).then ->
        if not go
            step "Will write profile to #spool-dir/#profile-name", "WRT"
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
    complete-name = "#name"
    destination-name = "/etc/apparmor.d"
    if not go 
        step "#complete-name to #destination-name", "CPY"
    else 
        debug "Copying #complete-name to #destination-name"
        _.cp(complete-name, destination-name)

restart-apparmor = (go) ->
    if not go 
        step "Will restart apparmor", 'EXC'
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

initConfig = (spool-dir, number-of-instances) ->
    dta = {}
    dta.resources = [ { number: i, available: true } for i in [ 1 to number-of-instances] ]
    JSON.stringify(dta, 0, 4).to("#spool-dir/config.json")

getNextLocked = (lockFile, config) ->
    lock.lockAsync(lockFile)
    .then ->
         getNextAvailable(config)
    .then (n) ->
         lock.unlockAsync(lockFile)
         return n

step = (s, type='GEN') ->
    console.log " * #type: #s "

putBackLocked = (lockFile, config, n) ->
    lock.lockAsync(lockFile, { retries: 3, retryWait: 100 })
    .then ->
        putBack(config, n)
    .then ->
        lock.unlockAsync(lockFile)

removeProfiles = (opts) ->
    { spool-dir, go } = opts
    pref = getProfilesPrefix(spool-dir)
    try
        _.ls("#pref*").map ->
            if not opts.go
                step "I'd remove #it", "RMV"
            else
                _.rm("-f", it)

        restart-apparmor(opts.go).error ->
            console.error "PANIC! Cannot restart apparmor."
    catch 
        console.error "You cannot really do this.. check for permissions"
        process.exit(1)




main = ->
    opts = get-command-options!
    debug opts
    { install, run, remove, go } = opts

    if not go and not run
        console.log "\nThe following are the steps that will be done once you invoke this script with -g\n"
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
            initConfig(spool-dir, number-of-instances)
        .then ->
            restart-apparmor(opts.go)
        .then ->
            console.log "done."
        .error ->
            console.error "Sorry, cannot install: #it"

    else
        if run
            { spool-dir, program } = opts
            config = "#spool-dir/config.json"
            lockFile = "#spool-dir/lock"
            lock.lockAsync = __.promisify(lock.lock)
            lock.unlockAsync = __.promisify(lock.unlock)
            var n
            try
                getNextLocked(lockFile, config)
                .then ->
                    n := it
                .then ->
                    if n == 0
                        console.error "all slots are taken."
                        process.exit(1)
                    else
                        _.cp('-f', path.resolve(program), "#spool-dir/cmd-#n")
                        __.promisify(_.exec)("#spool-dir/cmd-#n")
                        .error ->
                            console.error "Program tried to break out. Killed by apparmor"

                        .finally ->
                            putBackLocked(lockFile, config, n)

            catch error
                console.error "Sorry, #error"
                process.exit(2)
        else
            if remove
                removeProfiles(opts)



main!







