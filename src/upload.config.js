module.exports = {
  connectionDelay: 200,
  baud: 115200,
  source: {
    libs: [
      '../lib/nodemcu-esp8266-helpers/wifi.lua',
      '../lib/nodemcu-esp8266-helpers/sntp.lua',
      '../lib/nodemcu-esp8266-helpers/file.lua',
      '../lib/nodemcu-esp8266-helpers/uart.lua',
      '../lib/nodemcu-esp8266-helpers/tmr.lua',  
    ],
    scripts: './app/*.lua',
    static: './static/*.json'
  }
};
