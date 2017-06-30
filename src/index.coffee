# out: ../lib/index.js

betterSpawn = require "better-spawn"
findPackages = require "find-packages"
path = require "path"
whichpm = require "which-pm"
concat = (arr1,arr2) -> Array.prototype.push.apply(arr1, arr2)
module.exports = (options) ->
  children = []
  spawnOpts = stdio: if options.silent then "pipe" else "inherit"
  spawn = (cmd, wd) => new Promise (resolve, reject) =>
    child = betterSpawn(cmd, Object.assign({cwd:wd},noOut:options.silent))
    children.push(child)
    child.on "exit", (exitCode) ->
      if exitCode
        reject(exitCode)
      else
        resolve()
  lookupByName = {}
  lookupByPm = {"not installed":[]}
  pkglist = []
  toLink = {}
  toLink[options.pm] = []
  toInstall = []
  peerDeps = {}
  if options.verbose
    console.log "linkall: searching packages" 
  Promise.all options.cwds.map((cwd) => findPackages(path.resolve(cwd)))
  .then (results) =>
    console.log "linkall: finished searching for packages" if options.verbose
    workers = []
    processPkg = (pkg,onlyLookup=false) =>
      lookupByName[pkg.manifest.name] = pkg
      pkglist.push pkg unless onlyLookup
      return whichpm(pkg.path)
        .then (pm) ->
          if pm?
            pkg.pm = pm = pm.name
          else
            pm = "not installed"
          arr = lookupByPm[pm] ?= [] 
          arr.push pkg
    for dir in options.lds
      workers.push(findPackages(path.resolve(dir))
      .then (result) ->
        workers2 = []
        for pkg in result
          workers2.push(processPkg(pkg,true))
        return Promise.all(workers2)
      )
    for res in results
      for pkg in res
        workers.push processPkg(pkg)
    return Promise.all(workers)
  .then =>
    if options.verbose
      names = []
      console.log "-----\nlinkall: found following local packages:\n"
      for pm, pkgs of lookupByPm
        console.log pm+": "+pkgs.map((pkg)=>pkg.manifest.name).join(", ")+"\n"
      #for pkg in pkglist
      #  console.log pkg.manifest.name+":\t"+pkg.path
      console.log "-----"
  .then =>
    processDep = (obj, warn=false) ->
      linkup = []
      return linkup unless obj
      addDep = (name) ->
        if (pkg = lookupByName[name])
          unless (pm = pkg.pm)?
            toInstall.push pkg if toInstall.indexOf(pkg) < 0
            pm = options.pm
          else unless toLink[pm]?
            toLink[pm] = []
          arr.push pkg if (arr = toLink[pm]).indexOf(pkg) < 0
          linkup.push name if linkup.indexOf(name) < 0
          
          if (pd = pkg.manifest.peerDependencies)?
            for n,v of pd
              addDep(n) if linkup.indexOf(n) < 0
        else if warn
          console.log "linkall: #{name} specified as dep, but not found in local packages"
      if Array.isArray(obj)
        for dep in obj
          addDep(dep)
      else
        for dep, version of obj
          addDep(dep)
      return linkup
    console.log "-----\nlinkall: local dependencies found:\n"
    anyFound = false
    for pkg in pkglist
      manifest = pkg.manifest
      if tmp = manifest.linkall
        if Array.isArray(tmp)
          linkup = processDep(tmp, true)
        else
          linkup = []
          concat(linkup,processDep(manifest.dependencies)) if tmp.dep
          concat(linkup,processDep(manifest.devDependencies)) if tmp.dev
      else
        linkup = processDep(manifest.dependencies)
        concat(linkup,processDep(manifest.devDependencies))
      if linkup.length > 0
        pkg.linkup = linkup
        unless (pm = pkg.pm)?
          toInstall.push pkg if toInstall.indexOf(pkg) < 0
        anyFound = true 
        console.log manifest.name+":\t"+linkup.join(", ")
    unless anyFound
      console.log "none, exiting ..."
      process.exit()
    console.log "-----"
  .then =>
    if options.verbose
      console.log "-----\nlinkall: need to link up the following packages:\n"
      for pm, pkgs of toLink
        console.log pm+": "+pkgs.map((pkg) => pkg.manifest.name).join(", ")+"\n"
      console.log "-----"
      if toInstall.length > 0
        console.log "-----\nlinkall: need to install these packages (using #{options.pm}):\n"
        console.log toInstall.map((pkg) => pkg.manifest.name).join(", ") + "\n-----"
      else
        console.log "linkall: no need to install any packages"
  .then ->
    unless options.test
      for pm,pkgs of toLink
        for pkg in pkgs
          console.log "linkall: linking up #{pkg.manifest.name}"
          try
            await spawn(pm+" link", pkg.path)
          catch
            console.warn "linkall: linking up #{pkg.manifest.name} failed"
      for pkg in pkglist
        if pkg.linkup?.length > 0
          pm = pkg.pm || options.pm
          console.log "linkall: linking local dependencies for #{pkg.manifest.name}"
          try
            await spawn(pm+" link "+pkg.linkup.join(" "), pkg.path)
          catch
            console.warn "linkall: linking local dependencies for #{pkg.manifest.name} failed"
  .then =>
    if !options.test and !options.noInstall
      pm = options.pm
      for pkg in toInstall
        console.log "linkall: installing #{pkg.manifest.name} in #{pkg.path}"
        try
          await spawn(pm+" install", pkg.path)
        catch
          console.warn "linkall: installing #{pkg.manifest.name} in #{pkg.path} failed"

  .catch (e) ->
    console.log e
  return (sig) ->
    for child in children
      child.close(sig)