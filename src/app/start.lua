local wifi_helper = require('lib/wifi');
local sntp_helper = require('lib/sntp');
local file_helper = require('lib/file');

local ok, config = file_helper.read_json_file('static/config.json');
local known_devices_ok, known_devices = file_helper.read_json_file('static/known-devices.json');

if (ok) then
  wifi_helper.wifi_config_sta(config.wifi.ssid, config.wifi.pwd, wifi.STATIONAP);
  wifi_helper.wifi_config_ap(config.ap.ssid, config.ap.pwd);

  local main = require('app/main');

  wifi_helper.wifi_connect(
    config.wifi.ssid,
    2000,
    function (ip)
      print('Connected, IP is '..ip);

      sntp_helper.sync_time(
        { '0.bg.pool.ntp.org', '1.bg.pool.ntp.org', '0.pool.ntp.org' },
        function()
          main(config, known_devices or { wifi = {} });
        end
      );
    end
  );
else
  print('Cannot open static/config.json');
end