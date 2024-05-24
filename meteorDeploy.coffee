#!/usr/bin/env /usr/local/bin/coffee

fs        = require('fs')
cjson     = require('cjson')
moment    = require('moment')
spawnSync = require('child_process').spawnSync

try
  config = cjson.load("mup.json")
  console.log("")
  console.log("config:", config)
  console.log("")
catch error
  console.log("Error reading config file".red, error)



transferfile = (file) ->
  foreach server of config.servers
  console.log("scp #{file} #{server.host}:/opt/#{config.appName}/tmp/.")
  spawnSync("scp #{file} #{server.host}:/opt/#{config.appName}/tmp/.")


remoteConfig = ->
  console.log("remote config")



try

  exec = 'meteor'
  
  buildLocaltion = "/tmp/mup/#{config.appName}/#{moment().format('YYYY-MM-DD')}/bundle.tar.gz"

  args = [
    "build",
    "--directory", buildLocaltion,
    "--architecture", "os.linux.x86_64",
    "--server", "http://localhost:3000"
  ]

  if config.serverOnly
    console.log("   Server only")
    args.push('--server-only')

  dateString = moment()
  buildCmd = exec + " " + args.join(' ')

  options =
    cwd: config.app

  console.log("Building ...")
  console.log("\t #{buildCmd}")

  meteor = spawnSync(exec, args, options)
  
  transferfile(buildLocaltion)

  remoteConfig()

catch error
  console.log("Error building app", error)


finally
  console.log("Done")



