#!/usr/bin/env /usr/local/bin/coffee

fs        = require('fs')
cjson     = require('cjson')
moment    = require('moment')
spawn = require('child_process').spawnSync

try
  config = cjson.load("mup.json")
  console.log("")
  console.log("config:", config)
  console.log("")
catch error
  console.log("Error reading config file".red, error)



transferfile = (file) ->
  for server of config.servers
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
    shell: true

  console.log("Building ...")
  console.log("\t #{buildCmd}\n")

  meteor = spawn(exec, args, options)

  meteor.stdout.setEncoding('utf8')
  meteor.stdout.on 'data', (data) ->
    console.log(data)

  meteor.stderr.setEncoding('utf8')
  meteor.stderr.on 'data', (data) ->
    console.log(data)


  meteor.on 'close', ->
    transferfile(buildLocaltion)

  #remoteConfig()

catch error
  console.log("Error building app", error)





