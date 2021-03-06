config = require '../stores/config'
_r = require 'kefir'
vagrant = require 'node-vagrant'
fsModel = require './fs.coffee'
utilModel = require '../util/'

isVagrantInstalled = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = getVagrantMachine())?

  child = machine._run ['version']
  child.on 'close', () ->
    callback null, true
  child.on 'error', (err) ->
    callback new Error 'vagrant is apparently not installed'

getVagrantMachine = (callback) ->
  return callback new Error '' if ! (configModulePath = utilModel.getConfigModulePath())?
  return machine = vagrant.create {cwd: configModulePath}

model = {}
model.getStatus = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = getVagrantMachine())?
  machine.status (err, result) ->
    return callback new Error err if err
    return callback(null, i.status) for own d, i of result

model.getSshConfig = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = getVagrantMachine())?
  machine.sshConfig callback

model.up = (callback) ->
  if process.platform != 'win32'
    errorMessage = 'Your OS is currently not supported for automatic vagrant start.'
    errorMessage += '\nPlease start vagrant manually.'
    errorMessage += '\nOpen a shell/terminal and enter:'
    errorMessage += '\n'
    errorMessage += '\ncd ' + utilModel.getConfigModulePath()
    errorMessage += '\nvagrant up'
    return callback errorMessage

  return callback new Error 'failed to initialize vagrant' if ! (machine = getVagrantMachine())?
  machine.up callback

model.run = (callback) ->
  runningMessage = 'is_runnning'

  _r.fromNodeCallback (cb) ->
    setTimeout () ->
      isVagrantInstalled cb
    , 1
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.getStatus (err, status) ->
        return cb new Error err if err
        return cb runningMessage if status == 'running'
        cb null, true
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
        model.up cb
  .onValue (val) ->
    callback null, val
  .onError (err) ->
    return callback null, true if err == runningMessage
    return callback new Error err if typeof err != "object"
    callback err

module.exports = model;
