local utils = require('app/utils');

local start_scanning_process;
local last_scanning_devices = {};
local max_batch_length = 5;
local counting_time_minutes = 3;

start_scanning_process = function (known_devices, publish)
  local devices = {};
  local batch_of_devices = {};

  wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T)
    local mac_address = string.lower(T.MAC);
    local is_new = last_scanning_devices[mac_address] == nil;
    local is_known = known_devices.wifi[mac_address];

    if (devices[mac_address] == nil or is_known) then
      local device = {
        rssi = T.RSSI,
        ts = rtctime.get(),
        new = is_new,
        known = known_devices.wifi[mac_address] or nil
      };

      batch_of_devices[mac_address] = device;
    end

    if (utils.get_count_of_table(batch_of_devices) == max_batch_length) then
      publish('/wifi-devices-found', sjson.encode(batch_of_devices), 2, 1);
      batch_of_devices = {};
    end
    
    devices[mac_address] = true;
  end)

  local counting_timer = tmr.create();

  counting_timer:register(1000 * 60 * counting_time_minutes , tmr.ALARM_SINGLE, function()
    local count = utils.get_count_of_table(devices);

    if (utils.get_count_of_table(batch_of_devices) > 0) then
      publish('/wifi-devices-found', sjson.encode(batch_of_devices), 2, 1);
    end

    publish('/count', count, 2, 1);

    last_scanning_devices = devices;

    wifi.eventmon.unregister(wifi.eventmon.AP_PROBEREQRECVED);
    start_scanning_process(known_devices, publish);
  end);

  counting_timer:start();
end

return start_scanning_process;