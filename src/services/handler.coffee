parser = require "../utils/parser"
math = require "../utils/math"
logger = require "../utils/logger"

Authentication = require "../workers/authentication"
Chat = require "../workers/chat"
Commander = require "../workers/commander"

module.exports =
class Handler
  ###
  Section: Properties
  ###
  logger: new logger(name: 'Handler')
  user: {}
  chat: null

  ###
  Section: Construction
  ###
  constructor: (@socket) ->

  ###
  Section: Private
  ###
  read: (packet) ->
    @logger.log @logger.level.DEBUG, "-> #{packet}"

    packetTag = parser.getTagName(packet)

    # TODO: Kick when the user is spamming packets
    return if packetTag is null

    switch packetTag
      when "policy-file-request"
        @send "<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\"><cross-domain-policy><site-control permitted-cross-domain-policies=\"master-only\"/>#{global.Application.config.allow}</cross-domain-policy>\0"          
      when "y"
        ###
        @spec <y r="1" v="0" u="USER_ID(int)" />
        ###
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        @send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_102\" />"
      when "j2"
        ###
        Authenticate the client and join room
        @spec <j2 cb="0" l5="4288326302" l4="1400" l3="1267" l2="0" q="1" y="72226157" k="f13cee2b165605b4e400" k3="0" p="0" c="1" f="1" u="USER_ID(int)" d0="0" n="USERNAME(str)" a="91" h="" v="1" />
        ###
        Authentication.process(@, packet).then(() =>
          for client in global.Server.clients
            console.log client.handler.user
            client.write '<dup />\0' if client.handler.user.id is @user.id and client.handler.socket != @socket

          Chat.joinRoom(@, @user.chat)
        ).catch((err) => @logger.log @logger.level.ERROR, err, null)
      when "m"
        ###
        Send message
        @spec <m t="MESSAGE(str)" u="USER_ID(int)" />
        ###
        user = parser.getAttribute(packet, 'u')
        msg = parser.getAttribute(packet, 't')

        Chat.sendMessage(@, user, msg) unless msg.indexOf(Commander.identifier) is 0
        Commander.process(@, user, msg)
      when "z"
        ###
        User profile
        @spec <z d="USER_ID_PROFILE(int)" u="USER_ID_ORIGIN(int)" t="TYPE(str)" />
        ###
        userProfileId = parser.getAttribute(packet, 'd')
        userProfile = global.Server.getClientById( userProfileId )?.handler.user || null
        userOrigin = parser.getAttribute(packet, 'u')
        type = parser.getAttribute(packet, 't')

        # TODO: 
        # - Move this to a new worker
        # - If the user is not online then query it from the database
        return if userProfile is null

        if type is '/l'
          username = userProfile.username ? 'N=\"#{userProfile.username}\"' : ''
          status = "t=\"/a_Nofollow\"" # t=\"/a_on GROUP\"
          @send "<z b=\"1\" d=\"#{@user.id}\" u=\"#{userProfile.id}\" #{status} po=\"0\" #{userProfile.pStr} x=\"#{userProfile.xats||0}\" y=\"#{userProfile.days||0}\" q=\"3\" #{username} n=\"#{userProfile.nickname}\" a=\"#{userProfile.avatar}\" h=\"#{userProfile.url}\" v=\"2\" />"
        else if type is '/a'
          return
        else
          @send "<z u=\"#{@user.id}\" t=\"#{type}\" s=\"#{parser.getAttribute(packet, 's')}\" d=\"#{userProfileId}\" />"
      else
        if packetTag.indexOf('w') is 0
          ###
          Room pools
          @spec <w v="ACTUAL_POOL(int) POOLS(int,int..)"  />
          ###
          @chat.onPool = packetTag.split('w')[1]
          Chat.joinRoom(@, @user.chat)
        else
          @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag

          # INFO: We emit an event with the unrecognized packet so a plugin will be able to handle it in a future.
          # global.Server.emit 'unrecognized-packet', packet

  send: (packet) ->
    @socket.write "#{packet}\0"

    # Debug
    @logger.log @logger.level.DEBUG, "-> Sent: #{packet}"

  broadcast: (packet) ->
    for client in global.Server.clients
      client.write "#{packet}\0"
  
  dispose: ->
    @socket.end()
    @socket.destroy()
