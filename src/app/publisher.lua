return function (mqtt_client)
  local queue = {};
  local is_sending = false;
  local send;

  local mqtt_pub = function (message, on_complete)
    mqtt_client:publish(message.topic, message.value, message.qos, message.retain, on_complete);
  end

  send = function ()
    if (#queue > 0) then
      local message = table.remove(queue, 1);
      print('MQTT messages QUEUE SIZE', #queue);

      local sent, err = pcall(mqtt_pub, message, function ()
        send();
      end)

      if (not sent) then
        print('Error with sending: ', err);
        queue[#queue + 1] = message;
      end
    else
      is_sending = false;
      collectgarbage();
      print('HEAP: ', node.heap());
    end
  end

  --publish
  return function (topic, value, qos, retain)
    print('adding', topic, value, qos, retain);

    queue[#queue + 1] = {
      topic = topic,
      value = value,
      qos = qos,
      retain = retain
    };

    if (not is_sending) then
      is_sending = true;
      send();
    end
  end
end