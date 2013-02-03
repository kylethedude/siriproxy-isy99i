require 'uri'
require 'cora'
require 'httparty'
require 'rubygems'
require 'devices'
require 'siri_objects'


class SiriProxy::Plugin::Isy99i < SiriProxy::Plugin
  attr_accessor :password
  attr_accessor :username
  attr_accessor :host
  
  # Some commonly used constants
  YES = "yes|sure|yep|yup|yea|yeah|whatever|why not|ok|i guess"
  
  def initialize(config)  
    # Setup the Rest Class that is used for all communications with the ISY
    Rest.instance.setConnParameters(config["host"], config["username"], config["password"])
    
    # Create an instance of the Devices Class to manage your devices. Pass in the devices set in the config.yml
    @myDevices = Devices.new(config["devices"])
    
    puts "**[ISY-99i Module Loaded]**"
  end
  
  #listen_for(/good night|goodnight/i) {good_night()}
  #listen_for(/good morning/i) {good_morning()}
  #listen_for(/ready to go|leave/i) {open_garage_door}
  #listen_for(/close the garage door/i) {close_garage_door}
  #listen_for (/cooling.*([0-9]{2})|cool setpoint.*([0-9]{2})|cooling setpoint.*([0-9]{2})/i) { |cooling_temp| set_cool_temp(cooling_temp) }
  #listen_for (/heat.*([0-9]{2})|heating.*([0-9]{2})|heat setpoint.*([0-9]{2})|heating setpoint.*([0-9]{2})/i) { |heating_temp| set_heat_temp(heating_temp) }
  #listen_for(/i'm cold|i am cold/i) {increment_heat_temp()}
  #listen_for(/i'm hot|i am hot/i) {decrement_cool_temp()}

  listen_for (/turn on (.*)/i) do |device|
    deviceName = URI.unescape(device.strip)
    device = @myDevices.findDevice(deviceName)
    
    if (!device.nil? && device.deviceAddress != 0)
        puts "[[turn on]] deviceName => #{deviceName}, deviceAddress => #{device.deviceAddress}";
        if (device.getOnOffStatus == "On")
            if (device.isDimmable)
                if (device.getOnLevel == 100)
                    response = ask "This device is already On, and it's set to 100%. Do you want to change the level?"
                    if (response =~ /#{YES}/i)
                        level = ask "OK. What level would you like to set #{deviceName} to?"
                        say "Setting #{deviceName} to #{level.to_i}%."
                        device.setOnLevel(level)
                    else
                        say "OK. No adjustment will occur."
                    end
                else
                    say "#{deviceName} is already On, and set to #{device.getOnLevel.to_s}%"
                    response = ask "Would you like to adjust the brightness?"
                    if (response =~ /#{YES}/i)
                        level = ask "OK. What level would you like to set #{deviceName} to?"
                        say "Setting #{deviceName} to #{level}%."
                        device.setOnLevel(level)
                    else 
                        say "OK. No adjustment will occur."
                    end
                end
            else
                say "#{deviceName} is already On"
            end
        elsif (device.getOnOffStatus == "Off" || device.isScene)
            if (device.isDimmable)
                level = ask "This device is dimmable.  What would you like to set the level to?"
                say "Setting #{deviceName} to #{level.to_i}%."
                device.setOnLevel(level)
            else 
                say "Turning on #{deviceName} now."
                device.turnFastOn
            end
        else
            say "Sorry. I'm having a difficult time controlling #{deviceName}."
        end
    else 
        say "I'm sorry, but I cannot control #{deviceName}."
    end
    request_completed
  end

 
  listen_for (/turn off (.*)/i) do |device|
    deviceName = URI.unescape(device.strip)
    device = @myDevices.findDevice(deviceName)
    
    if (!device.nil? && device.deviceAddress != 0)
        status = device.getOnOffStatus
        puts "[[turn off]] deviceName => #{deviceName}, deviceAddress => #{device.deviceAddress}, status => #{status}";
        if (status == "On" || device.isScene)
            say "Turning off #{deviceName}."
            device.turnOff
        elsif (status == "Off")
            say "#{deviceName} is already off."
        else
            say "Sorry. I am unable to control #{deviceName}."
        end
    else
        say "Sorry. I am unable to control #{deviceName}."
    end
    request_completed
  end


  listen_for (/get status of (.*)/i) do |device|
    deviceName = URI.unescape(device.strip)
    device = @myDevices.findDevice(deviceName)
    
    if (!device.nil? && device.deviceAddress != 0)
        if (device.isScene)
            say "No status available for scenes."
        else
            onlevel = device.getOnLevel
            puts "[[status]] deviceName => #{deviceName}, deviceAddress => #{device.deviceAddress}, onLevel => #{onlevel}";
            if (onlevel == 100)
                say "#{deviceName} is On."
            elsif (onlevel == 0)
                say "#{deviceName} is Off."
            elsif (onlevel == -1)
                say "Sorry. I am unable to control #{deviceName}."
            else
                say "#{deviceName} is at #{onlevel}%."
            end
        end
    else 
        say "Sorry. I am unable to control #{deviceName}."
    end
    request_completed
  end

  listen_for (/(turn down|turndown|turn up|turnup|set level for|adjust) (.*) to (.*)/i) do |keywords, device, level|
    deviceName = URI.unescape(device.strip)
    device = @myDevices.findDevice(deviceName)
    
    if (!device.nil? && device.deviceAddress != 0)
        if (device.isDimmable)
            setDeviceLevel(device, level)
        else 
            say "#{deviceName} is not dimmable."
        end
    else 
        say "Sorry. I am unable to control #{deviceName}."
    end
    request_completed
  end
  
  listen_for (/(turn down|turndown|turn up|turnup|set level for|adjust) (.*)/i) do |keywords, device|
    deviceName = URI.unescape(device.strip)
    device = @myDevices.findDevice(deviceName)
    
    if (!device.nil? && device.deviceAddress != 0)
        if (device.isDimmable)
            level = ask "What would you like to set the level to?"
            setDeviceLevel(device, level)
        else 
             say "#{deviceName} is not dimmable."
        end
    else 
        say "Sorry. I am unable to control #{deviceName}."
    end
    request_completed
  end
  
  def setDeviceLevel(device, level)
    if (!device.nil? && device.deviceAddress != 0)
        if (device.isScene)
            say "Unable to change the level for a scene."
        else
            puts "[[set level]] deviceAddress => #{device.deviceAddress}, newOnLevel => #{level}";
            if (level <= 100 && level >= 0)
                device.setOnLevel(level)
            else
                say "Sorry, #{level} is not valid."
            end
        end
    else 
        say "Sorry. I am unable to control #{deviceName}."
    end
    request_completed
  end

=begin 
  listen_for (/temperature.*inside|inside.*temperature|temperature.*in here/i) do 
    deviceName = "thermostat"
    deviceAddress = deviceCrossReference(deviceName)
      if deviceAddress != 0
        #say "Checking the inside temperature."
        check_status = Rest.get("#{self.host}/rest/status/#{deviceAddress}", :basic_auth => @auth).inspect
        indoor_temp = check_status.gsub(/^.*"ST\D+\d+\D+/, "")
        indoor_temp = indoor_temp.gsub(/\D\d\d", "uom.*$/, "")
        say "The current temperature in your house is #{indoor_temp} degrees."
      end
    request_completed 
  end


  listen_for (/thermostat.*status|status.*thermostat/i) do 
    deviceName = "thermostat"
    deviceAddress = deviceCrossReference(deviceName)
    #say "Checking the status of the thermostat."
    check_status = Rest.get("#{self.host}/rest/status/#{deviceAddress}", :basic_auth => @auth).inspect
    indoor_temp = check_status.gsub(/^.*"ST\D+\d+\D+/, "")
    indoor_temp = indoor_temp.gsub(/\D\d\d", "uom.*$/, "")
    say "The current temperature in your house is #{indoor_temp} degrees." 
    clispc = check_status.gsub(/^.*"CLISPC\D+\d+\", "\w+"=>"/, "")
    clispc = clispc.gsub(/\D\d\d", "uom.*$/, "")
    say "The cooling setpoint is #{clispc} degrees"
    clisph = check_status.gsub(/^.*"CLISPH\D+\d+\", "\w+"=>"/, "")
    clisph = clisph.gsub(/\D\d\d", "uom.*$/, "")
    say "The heating setpoint is #{clisph} degrees"
    climd = check_status.gsub(/^.*"CLIMD\D+\d+\", "\w+"=>"/, "")
    climd = climd.gsub(/", "uom.*$/, "")
    say "The mode is currently set to #{climd}"
    request_completed 
  end




  def set_cool_temp(cooling_temp)
    deviceName = "thermostat"
    deviceAddress = deviceCrossReference(deviceName)
    cooling_temp = cooling_temp.to_i * 2   #necessary as thermostat input must be doubled
    say "One moment while I set the cooling setpoint to #{cooling_temp} degrees."
    Rest.get("#{self.host}/rest/nodes/#{deviceAddress}/set/CLISPC/#{cooling_temp}", :basic_auth => @auth).inspect
    request_completed
  end


  def set_heat_temp(heating_temp)
    deviceName = "thermostat"
    deviceAddress = deviceCrossReference(deviceName)
    heating_temp = heating_temp.to_i * 2   #necessary as thermostat input must be doubled
    say "One moment while I set the heating setpoint to #{heating_temp} degrees."
    Rest.get("#{self.host}/rest/nodes/#{deviceAddress}/set/CLISPH/#{heating_temp}", :basic_auth => @auth).inspect
    request_completed
  end


  def anything_else
    response = ask "Is there anything else you would like me to do?"
      if (response =~ /yes|sure|yep|yeah|whatever|why not|ok|I guess/i)
        say "OK, but I'm still working on that part of my programming."
      else say "Good.  Because I can't do that yet."
      end
    request_completed
  end


  def open_small_garage_door
    say "OK.  I'll open the garage door for you"
    Rest.get("#{self.host}/rest/nodes/46642/cmd/DON", :basic_auth => @auth)
    request_completed 
  end


  def close_small_garage_door
    say "Garage door is now closing."
    Rest.get("#{self.host}/rest/nodes/46642/cmd/DOF", :basic_auth => @auth)
    request_completed 
  end


  def merry_christmas
    response = ask "Merry Christmas #{self.yourname}! Do you want me to put the tree lights on?"
      if (response =~ /yes|sure|yep|yeah|whatever|why not|ok|I guess/i)
        Rest.get("#{self.host}/rest/nodes/24409/cmd/DON", :basic_auth => @auth)
      else say "Scrooge!"
      end
    request_completed 
  end

  def scrooge
    say "Scrooge!"
    Rest.get("#{self.host}/rest/nodes/24409/cmd/DOF", :basic_auth => @auth)
    request_completed 
  end

  def test
    deviceName = "cabinet light"
    @dimmable = 0 #sets default as non-dimmable - must be set to 1 in devices file otherwise
    deviceAddress = deviceCrossReference(deviceName)
    puts "deviceName = #{deviceName}"
    puts "deviceAddress = #{deviceAddress}"
      if deviceAddress.is_a?(Numeric)
        scene = 1
        puts "scene = #{scene}"
      else puts "this ain't workin"
      end
    request_completed
  end 

  def test
    response = ask "Do you want to run the test?"
      if (response =~ /yes|sure|yep|yeah|whatever|why not|ok|I guess/i)
        say "OK. Running test."
      else say "Never mind."
      end
    request_completed 
  end
=end
end
