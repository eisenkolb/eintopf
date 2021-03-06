config = require 'config'
jetpack = require 'fs-jetpack'
spawn = require('child_process').spawn
_r = require('kefir');

watcherModel = require '../stores/watcher.coffee'

model = {}

# use original config first and let it overwrite later with the custom config
model.setConfig = (newConfig) ->
  return false if ! newConfig || typeof newConfig != "object"
  config = newConfig
  return true

model.getPathResolvedWithRelativeHome = (fsPath) ->
  return null if typeof fsPath != "string"
  homePath = @getEintopfHome()
  fsPath = fsPath.replace /^(~|~\/)/, homePath if homePath?
  return fsPath

model.getEintopfHome = () ->
  return process.env.EINTOPF_HOME if process.env.EINTOPF_HOME
  return process.env.USERPROFILE if process.platform == 'win32'
  return process.env.HOME

model.getConfigPath = () ->
  return @getPathResolvedWithRelativeHome "#{@getEintopfHome()}/.eintopf";

model.getConfigModulePath = () ->
  return null if ! (configPath = @getConfigPath())? || ! config?.app?.defaultNamespace
  return jetpack.cwd(configPath).path config.app.defaultNamespace

model.loadUserConfig = (callback) ->
  return callback new Error 'Failed to get config module path' if ! (configModulePath = @getConfigModulePath())
  @loadJson  jetpack.cwd(configModulePath).path('config.json'), callback

model.loadJson = (path, callback) ->
  return callback new Error 'Invalid path' if ! path

  try
    userConfig = jetpack.read path, 'json'
  catch err
    return callback err

  return callback null, userConfig

model.loadJsonAsync = (path, callback) ->
  return callback new Error 'Invalid path' if ! path

  jetpack.readAsync path, 'json'
  .fail callback
  .then (json) ->
    callback null, json

model.loadMarkdowns = (path, callback) ->
  jetpack.findAsync path, {matching: ["README*.{md,markdown,mdown}"], absolutePath: true}, "inspect"
  .fail (err) ->
    callback err
  .then (markdowns) ->
    callback null, markdowns

model.loadCertFiles = (path, callback) ->
  jetpack.findAsync path, {matching: ['*.crt', '*.key'], absolutePath: true}, "inspect"
  .fail (err) ->
    callback err
  .then (certs) ->
    callback null, certs

model.getProjectsPath = () ->
  return null if ! (configModulePath = @getConfigModulePath())
  return jetpack.cwd(configModulePath).path('configs')

model.getProxyCertsPath = () ->
  return null if ! (configModulePath = @getConfigModulePath())
  return jetpack.cwd(configModulePath).path('proxy/certs')

model.getProjectNameFromGitUrl = (gitUrl) ->
  return null if !(projectName = gitUrl.match(/^[:]?(?:.*)[\/](.*)(?:s|.git)?[\/]?$/))?
  return projectName[1].substr(0, projectName[1].length-4) if projectName[1].match /\.git$/i
  return projectName[1]

model.typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

model.folderExists = (path) ->
  return null if ! path
  return true if jetpack.exists(path) == "dir"
  return false

#@todo refactoring: use clear naming (renaming project|recommendations and not just here)
model.isProjectInstalled = (projectId) ->
  return null if ! projectId || ! (projectsPath = @getProjectsPath())
  return @folderExists jetpack.cwd(projectsPath).path(projectId)

model.runCmd = (cmd, config, logName, callback) ->
  config = {} if ! config
  output = ''

  sh = 'sh'
  shFlag = '-c'

  if process.platform == 'win32'
    sh = process.env.comspec || 'cmd'
    shFlag = '/d /s /c'
    config.windowsVerbatimArguments = true

  proc = spawn sh, [shFlag, cmd], config
  proc.on 'error', (err) ->
    return callback err if callback
  proc.on 'close', (code, signal) ->
    return callback null, output if callback
  proc.stdout.on 'data', (chunk) ->
    watcherModel.log logName, chunk.toString() if logName
    output += chunk.toString()
  proc.stderr.on 'data', (chunk) ->
    watcherModel.log logName, chunk.toString() if logName
    output += chunk.toString()

model.syncCerts = (path, files, callback) ->
  return callback new Error 'Invalid path given' if ! path

  copyStream = _r.sequentially 0, files
  .filter (file) ->
    return true if file.name && file.absolutePath
  .flatMap (file) ->
    _r.fromPromise jetpack.copyAsync file.absolutePath, jetpack.cwd(path).path(file.name), {overwrite:true}

  purgeStream = _r.fromNodeCallback (cb) ->
    model.loadCertFiles path, cb
  .flatten().filter (file) ->
    (return false if file.name == certFile.name) for certFile in files
    return true
  .flatMap (file) ->
    _r.fromPromise jetpack.removeAsync jetpack.cwd(path).path(file.name)

  _r.merge [purgeStream, copyStream]
  .onEnd () ->
    return callback null, true

model.removeFileAsync = (path, callback) ->
  return callback new Error 'Invalid path' if ! path

  _r.fromPromise jetpack.removeAsync path
  .onError callback
  .onValue (val) ->
    return callback null, true

module.exports = model