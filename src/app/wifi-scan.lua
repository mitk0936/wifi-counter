local utils = require('app/utils');
local file_helper = require('lib/file');

local max_batch_length = 5;
local counting_time_minutes = 2;

local known_devices_ok, known_devices = file_helper.read_json_file('static/known-devices.json');

local devices = {};
local batch_of_devices = {};

if (not known_devices_ok) then
  error('Cannot read known devices');
end

local start_scanning_process = function (publish)
  devices = {}
  batch_of_devices = {}

  wifi.eventmon.unregister(wifi.eventmon.AP_PROBEREQRECVED);

  wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T)
    local mac_address = string.lower(T.MAC);
    local is_known = known_devices.wifi[mac_address];

    if (not devices[mac_address]) then
      devices[mac_address] = true;
      
      local device = {
        rssi = T.RSSI,
        ts = rtctime.get(),
        known = known_devices.wifi[mac_address] or nil
      };

      batch_of_devices[mac_address] = device;
    end

    if (utils.get_count_of_table(batch_of_devices) == max_batch_length) then
      publish('/wifi-devices-found', sjson.encode(batch_of_devices), 2, 1);
      batch_of_devices = {};
    end
  end)
end

local start = function (publish)
  local counting_timer = tmr.create();

  counting_timer:register(1000 * 60 * counting_time_minutes , tmr.ALARM_AUTO, function()
    print('Scan finished, found', utils.get_count_of_table(devices));

    if (utils.get_count_of_table(batch_of_devices) > 0) then
      publish('/wifi-devices-found', sjson.encode(batch_of_devices), 2, 1);
    end

    start_scanning_process(publish);
  end);

  start_scanning_process(publish);
  counting_timer:start();
end

return start;