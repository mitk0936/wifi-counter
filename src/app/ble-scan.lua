local tmr_helper = require('lib/tmr');
local uart_helper = require('lib/uart');
local utils = require('app/utils');

local parse_ok = function (response)
  if (string.match(response, 'OK')) then
    return true, response;
  end
end

local parse_set_device_name = function (name)
  return function (response)
    if (string.match(response, 'OK') and string.match(response, '+') and string.match(response, 'Set:') and string.match(response, name)) then
      return true, response;
    end
  end
end

local parse_set_1 = function (response)
  if (string.match(response, 'OK') and string.match(response, '+') and string.match(response, 'Set:1')) then
    return true, response;
  end
end

local parse_set_3 = function (response)
  if (string.match(response, 'OK') and string.match(response, '+') and string.match(response, 'Set:3')) then
    return true, response;
  end
end

local parse_reset = function (response)
  if (string.match(response, 'OK') and string.match(response, '+') and string.match(response, 'RESET')) then
    return true, response;
  end
end

local parse_disi_search = function (response)
  if (string.match(response, 'OK') and string.match(response, '+') and string.match(response, 'DISCE')) then
    return true, response;
  end
end

local extract_ble_addresses = function (response)
  local result = {};

  for match in (response):gmatch "%x%x%x%x%x%x%x%x%x%x%x%x:%p0%w%wOK%p" do
    local mac = string.match(match, '(%x%x%x%x%x%x%x%x%x%x%x%x):%p0%w%wOK%p');
    local rssi = string.match(match, '%x%x%x%x%x%x%x%x%x%x%x%x:%p0(%w%w)OK%p');

    print(mac, -rssi);

    result[mac] = {
      rssi = -rssi,
      ts = rtctime.get(),
      bluetooth = true
    };
  end

  return result;
end

local start = function (publish)
  local exec = nil;
  local empty_disi_responses = 0;
  
  local on_at_command_completed = function (result, parsed, timeouted)
    if (parsed) then
      print('<< '..result);
      return true;
    end

    return false;
  end

  local on_disi_completed = function (result, parsed, timeouted)
    if (timeouted) then
      local devices = extract_ble_addresses(result);

      if (utils.get_count_of_table(devices) > 0) then
        empty_disi_responses = 0;
        publish('/wifi-devices-found', sjson.encode(devices), 2, 1);
      else
        empty_disi_responses = empty_disi_responses + 1;

        if (empty_disi_responses > 2) then
          node.restart();
        end
      end
    end
    
    return false;
  end

  tmr_helper.set_timeout(2000, function ()
    softuart_instance = softuart.setup(9600, 1, 2);
    exec = uart_helper.create_commander(
      function (until_char, feed)
        softuart_instance:on('data', until_char, feed);
      end,
      function (data)
        softuart_instance:write(data);
      end,
      function ()
        -- cleanup uart
        -- not needed with softuart
      end,
      tmr_helper.set_timeout
    );

    exec('AT+RESET', parse_reset, on_at_command_completed, 'T');
    exec('AT', parse_ok, on_at_command_completed, 'K');
    exec('AT+ROLE1', parse_set_1, on_at_command_completed, '1');
    exec('AT+IMME1', parse_set_1, on_at_command_completed, '1');
    exec('AT+SHOW1', parse_set_1, on_at_command_completed, '1');
    exec('AT+POWE3', parse_set_3, on_at_command_completed, '3');
    exec('AT+RESET', parse_reset, on_at_command_completed, 'T');
    
    exec('AT+DISI?', parse_disi_search, on_disi_completed, '+', 60000);
  end)
end

return start;