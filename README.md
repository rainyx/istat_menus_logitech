## Prepare
Ensure that Logitech G HUB.app already installed on your Mac, we need to use lghub_agent for retrieving the device's state.

## How to use
First, build the Xcode project and put libistat_menus_logitech.dylib to somewhere.
Add `DYLIB_INSERT_LIBRARIES` env variable to `com.bjango.istatmenus.daemon.plist` and `com.bjango.istatmenus.agent.plist`, they are placed at `/Library/LaunchDaemons` and `/Library/LaunchAgents` directories. The file content is as follows.
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    ......
    <key>EnvironmentVariables</key>
    <dict>
	<key>DYLD_INSERT_LIBRARIES</key>
	<string>/you/lib/dir/libistat_menus_logitech.dylib</string>
    </dict>
    ......
</dict>
</plist>
```
Finally, reload service by two lines commands.
```
❯ launchctl unload -w /Library/LaunchAgents/com.bjango.istatmenus.status.plist
❯ launchctl load -w /Library/LaunchAgents/com.bjango.istatmenus.status.plist
```
Now, your Logitech devices will appear in iStat Menus settings panel, with proper configuration, the device's battery state is available in menu bar items.

![alt tag](https://raw.githubusercontent.com/rainyx/istat_menus_logitech/main/resources/1.png)


----------
Popup window

![alt tag](https://raw.githubusercontent.com/rainyx/istat_menus_logitech/main/resources/2.png)


----------
Menu bar

![alt tag](https://raw.githubusercontent.com/rainyx/istat_menus_logitech/main/resources/3.png)


