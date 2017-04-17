MQTT_PORT = 1883
MQTT_KEEPALIVE = 10

if pubsub then
  if pubsub.mqtt_client then
    pubsub.mqtt_client:close()
  end
end

pubsub = {

}

function pubsub.client_id()
  return
end

--  config:
--    node : string         -- local hostname
--    server   : string     -- hostname or IP
--    port : integer = 1883
--    username : string     -- optional username
--    password : string     -- optional password
function pubsub.init(config)
  local clean_session = 1

  pubsub.node_id = config.node
  pubsub.client_id = "net.qmsk.pubsub@" .. config.node
  pubsub.server = config.server
  pubsub.port = config.port or MQTT_PORT
  pubsub.modules = {}

  pubsub.mqtt_client = mqtt.Client(pubsub.client_id,
    config.keepalive or MQTT_KEEPALIVE,
    config.username,
    config.password,
    clean_session
  )

  pubsub.mqtt_client:on("message", pubsub.client_message)

  print("pubsub.init: mqtt client_id=" .. pubsub.client_id)
end

function pubsub.register_module(name, info_func)
  pubsub.modules[name] = {
    info_func = info_func
  }
end

function pubsub.query_modules()
  modules = {}

  for name, module in pairs(pubsub.modules) do
    modules[name] = module.info_func()
  end

  return modules
end

function pubsub.start()
  local secure = 0
  local autoreconnect = 0

  if pubsub.mqtt_client:connect(pubsub.server,
    pubsub.port,
    secure,
    autoreconnect,
    pubsub.client_connected,
    pubsub.client_error
  ) then
    print("pubsub.start: mqtt connect " .. pubsub.server .. ":" .. pubsub.port)
  else
    print("pubsub.start: mqtt connect " .. pubsub.server .. ":" .. pubsub.port .. " error")
  end
end


function pubsub.client_connected(mqtt_client)
  print("pubsub.client_connected: mqtt")

  pubsub.mqtt_client:subscribe("qmsk/discover", 0, function(mqtt_client)
    print("pubsub.client_connected: mqtt subscribe qmsk.net/discover")
  end)

  pubsub.publish_node()
end

function pubsub.client_error(mqtt_client, reason)
  print("pubsub.client_error: mqtt reason=" .. reason)
end

function pubsub.client_message(mqtt_client, topic, message)
  print("pubsub.client_message: mqtt " .. topic)

  if topic == "qmsk/discover" then
    pubsub.publish_node()
  else

  end
end

function pubsub.publish_node()
  print("pubsub.publish_node")

  local payload = cjson.encode({
    ID      = pubsub.node_id,
    Modules = pubsub.query_modules(),
  })

  if pubsub.mqtt_client:publish("qmsk/nodes", payload, 0, 0) then
    print("pubsub.publish_node: mqtt publish qmsk/nodes")
  else
    print("pubsub.publish_node: mqtt publish qmsk/nodes: error")
  end
end

function pubsub.publish_module(name, data)
  data.Node = pubsub.node_id

  local topic = "qmsk/" .. name .. "/" .. pubsub.node_id
  local payload = cjson.encode(data)

  if pubsub.mqtt_client:publish(topic, payload, 0, 0) then
    print("pubsub.publish_module: mqtt publish " .. topic)
  else
    print("pubsub.publish_module: mqtt publish " .. topic .. ": error")
  end
end
