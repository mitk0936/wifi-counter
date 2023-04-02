return function (config)
  local mqtt_client = mqtt.Client(
    config.device.id, 20,
    config.device.user,
    config.device.password
  );

  mqtt_client:on('connect', function ()
    local start_wifi_scan = require('app/wifi-scan');
    -- local start_bluetooth_scan = require('app/ble-scan');

    local publish = require('app/publisher')(mqtt_client);

    local publish_callback = function (topic, value, qos, retain)
      publish(topic, value, qos, retain);
      collectgarbage();
    end

    start_wifi_scan(publish_callback);
    -- start_bluetooth_scan(publish_callback);
  end);

  mqtt_client:lwt('/connectivity', 'offline', 2, 1);

  mqtt_client:on('offline', node.restart);

  mqtt_client:connect(config.mqtt.address, config.mqtt.port);
end