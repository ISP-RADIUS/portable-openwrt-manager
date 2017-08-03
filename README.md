# portable-openwrt-manager
Some scripts to help OpenWRT portable router owners to manage WiFi and Wan.

wifier.sh Usage
---------------

To disable your sta interface, use:
`$ wifier.sh disable-sta`
 
To scan and show nearby Wifis, use:
`$ wifier.sh scan`

To save your current WWAN profile (ssid, bssid, encryption type and password), use:
`$ wifier.sh save <profile-name>`

E.g.: `$ wifier.sh save home-wifi`
 
To use it without being prompted for yes or no use `-y`:
`$ wifier.sh save home-wifi -y`

To load a profile, use: 
`$ wifier.sh load <profile-name>`

E.g.: `$ wifier.sh load home-wifi`

To use it without being prompted for yes or no use `-y`:
`$ wifier.sh save home-wifi -y`

#TODO
-----

- [ ] Create `wanner.sh` script, which will alternate wan modes. E.g. `wanner.sh set usb-mode` or
`wanner.sh set wireless-wan-mode`, etc.

