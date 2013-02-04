siriproxy-isy99i
================

About
-----

Siriproxy-isy99i is a [SiriProxy] (https://github.com/plamoni/SiriProxy) plugin that allows you to control home automation devices using the [Universal Devices ISY-99i Series] (http://www.universal-devices.com/residential-2/isy-99i) controller through Apple's Siri interface on the iPhone 4s.

Utilizing the REST interface of the ISY-99i, this plugin matches certain voice commands and sends the appropriate command via http to the controller.  See below for specific usage.

This is a fork of [Hoopty3’s plugin] (https://github.com/hoopty3/siriproxy-isy99i) with inspiration from [elvisimprsntr’s plugin] (https://github.com/elvisimprsntr/siriproxy-isy99i).

What makes this plugin different? Abstraction. My goal of this project was to make it easier to write the rules or logic behind controlling devices with the ISY-99i without cluttering the code with technical details as everybody has their own customizations.

Currently, this is an early, but functional preview.

Changelog
---------
**Version 0.0.1** 

- Initial Creation

**Version 0.0.2** 

- Added auto-discovery of controllable devices

TODO (in no particular order)
-----------------------------
1. Finish ELK integration with ISY-99i ELK Module
2. Add support for ELK Thermostats including multiple thermostat support
3. Merge in elvisimprsntr's IP Cam logic
4. Create better documentation

I'm also welcome to other ideas to make this module fully rounded.

Installation
------------

First and foremost, [SiriProxy] (https://github.com/plamoni/SiriProxy) must be installed and working.  Do not attempt to do anything with this plugin until you have installed SiriProxy and have verified that it is working correctly.  The author provides very detailed, step-by-step written instructions, as well as video, on how to do this.  

Once SiriProxy is up and running, you'll want to add the siriproxy-isy99i plugin.  This will have to be done manually, as it is necessary to add your specific devices and their addresses to the config.yml file.  This process is described in detail below.  

It may also be helpful to look at this [video by jbaybayjbaybay] (http://www.youtube.com/watch?v=A48SGUt_7lw) as it's the one I used to figure this process out.  The video includes info on creating a new plugin and editing the files, which can be helpful when it comes to experimenting with your own plugins, but it won't be necessary in order to just install this plugin.  So, I'll skip those particular instructions below.

1.  Download the repository as a [zip file] (https://github.com/kylethedude/siriproxy-isy99i/zipball/master).
2.  Extract the full directory (i.e. kylethedude-siriproxy-isy99i-######) to `~/.rvm/gems/ruby-1.9.3-p0@SiriProxy/gems/siriproxy-0.0.2/plugins` and rename it siriproxy-isy99i. You will need to go to View and select 'Show Hidden Files' in order to see .rvm directory.
3.  Navigate to the `siriproxy-isy99i/lib` directory and open devices.rb for editing.  Gedit works just fine.
4.  Here you will need to enter your specific device info, such as what you will call them and their addresses.  This file is populated with examples and should be pretty self explanatory.  
5.  If a device is dimmable, set the @dimmable variable to 1, otherwise it is not necessary or should be set to some number other than 1.  You can control devices or scenes, but you cannot currently get the status of a scene (that's on the to do list).
6.  Copy the siriproxy-99i directory to `home/SiriProxy/plugins` directory
7.  Open up siriproxy-isy99i/config-info.yml and copy all the settings listed there.
8.  Navigate to `~/.siriproxy` and open config.yml for editing.
9.  Paste the settings copied from config-info.yml into config.yml making sure to keep format and line spacing same as the examples.  
10. Set the host, username, and password fields for your system's configuration.  Don't forget to save the file when you're done.
11. Open a terminal and navigate to ~/SiriProxy
12. Type `siriproxy bundle` <enter>
13. Type `bundle install` <enter>
14. Type `rvmsudo siriproxy server` <enter> followed by your password.
15. SiriProxy with ISY99i control is now ready for use.

**NOTE: If/when you make changes to siriproxy-isy99i.rb, you must copy it to the other plugin directory.  Remember, you put a copy in** `~/.rvm/gems/ruby-1.9.3-p###@SiriProxy/gems/siriproxy-0.3.#/plugins` **AND** `~/SiriProxy/plugins`**.  They both have to match!  Then follow steps 11 - 15 of the installation procedure to load up your changes and start the server again.**

Configuration
-------------

**Devices can be added using three different methods**

***1. Manually listed as an array in the config.yml file***

Under the "devices" configuration item, each device will have 3 parameters

1. Device name as recongnized by Siri. This can consist of multiple words or phrases seperated by a "|" character.
2. The Device address. This is either the Insteon address (. is replaced by %20) or the scene number.
3. Do you want this Device to be dimmable? 1 for yes, 0 for no.

***Example***

>- Device Name: night light
>- Device Address: 1A.EB.C.1
>- Is Dimmable: Yes


>```
>- ["night light|nightlight", "1A%20EB%20C%201", 1]
>```

***2. The plugin will scan the active devices reported by the ISY-99i and add them automatically.***

Any device added manually using method #1 above will NOT be overwritten by this automatic process. This allows you to customize the device setup and still take advantage of the auto-discovery feature. This is useful if you want a device to be recongnized by multiple phrases or wish to treat a dimmable device as non-dimmable so Siri doesn't ask to adjust On Levels.

>```ruby
>@myDevices = Devices.new
>@myDevices.addActiveDevices
>```

***3. Devices can be added programatically in the plugin code.***

***Example***
>- Device Name: night light
>- Device Address: 1A.EB.C.1
>- Is Dimmable: Yes


>```ruby
>@myDevices = Devices.new
>@myDevices.add("night light|nightlight", "1A%20EB%20C%201", 1)
>```

Usage
-----

**Turn on (device name)**

- Will check the status of that device and determine its state.  
- If it's On and it's configured as dimmable, Siri will give you the status and ask if you want to adjust the brightness settings.  
- If it's Off and it's configured as dimmable, Siri will ask what percent you would like to set the On Level to.  It it's not dimmable, it will just turn On.
- If it's On, Siri will alert you that it is already On.

**Turn off (device name)**

- Will check the status of that device and determine its state.  
- If it's On, Siri will shut it Off.  
- If it's Off, Siri will alert you that it is already Off.

**Get status of (device name)**

- Siri will request the status of the device from the ISY-99i and report it back to you.

**Turn up/turn down/set dimmer on/set level for/adjust (device name)**

- If device is configured as dimmable, Siri will ask what you would like to set the On Level to and then issue the command to change that setting.

Licensing
---------

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).

Disclaimer
----------

I'm not affiliated with Apple in any way. They don't endorse this application. They own all the rights to Siri (and all associated trademarks). 

This software is provided as-is with no warranty whatsoever. Use at your own risk!  I am not responsible for any damages/corruption which may occure to your system.  (It's not gonna happen, but I gotta say it...)

Apple could do things to block this kind of behavior if they want. Also, if you cause problems (by sending lots of trash to the Guzzoni servers or anything), I fully support Apple's right to ban your UDID (making your phone unable to use Siri). They can, and I wouldn't blame them if they do.

I'm a huge fan of Apple and the work that they do. Siri is a very cool feature and I'm pretty excited to explore it and add functionality. Please refrain from using this software for anything malicious.
