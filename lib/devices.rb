# == devices.rb
# This file contains the various classes that can be used within the ISY-99i SiriProxy plugin to easily access and control the ISY-99i.

require 'rubygems'
require 'httparty'
require 'singleton'

#
# A class that contains information about all the Devices to be controlled by the SiriProxy plugin. The Devices can be added manually or the class
# can scan for available Devices.
#
# == Summary
# For use with the SiriProxy plugin, this class is first utilized to setup all available ISY-99i Devices to be accessed via the Siri commands configured 
# in the plugin. Once configured, a single Device Object can be easily obtained for further control or status commands.
#
# == Example - Auto Discover Devices
#
#   @myDevices = Devices.new
#   @myDevices.addActiveDevices
#   device = myDevices.findDevice("hall light")
#
class Devices
  # Index Constants
  DEVICENAME = 0
  DEVICEID = 1
  DIMMABLE = 2
  
  # These Device Types will be automatically added to the Device List
  #     Dimmable, Switched/Relay, Irrigation, Climate, Pool Control, Sensors, Energy Management, Windows/Shades, Access Control, Security, X10
  CONTROLLABLE = ["1","2","4","5","6","7","9","14","15","16","113"]
 
  def initialize(d)
    # A multdimensional array where each element is an array consisting of 4 elements:
    #     0 => Device Name: A regular expression of the device name to be recongnized by Siri
    #     1 => Device Address: Either the ISY-99i Scene ID or the Device ID with spaces converted to %20
    #     2 => Is the Device Dimmable? 0 = no, 1 = yes
    if (d.nil?)
        @devices = []
    else
        @devices = d
    end
  end
 
  def add(deviceName, deviceId, isDimmable)
    @devices << [deviceName, deviceId, isDimmable]
  end
  
  def addActiveDevices
    nodes = Rest.get("#{Rest.instance.host}/rest/nodes", :basic_auth => Rest.instance.auth).parsed_response["nodes"] 
    
    # Add Devices
    nodes["node"].each do |node|
        deviceId = formatDeviceId(node["address"])
        
        if (node["enabled"] == "true" && !deviceExists(deviceId) && isControllable(node["type"]) && !node["name"].match(/^~/)) 
            name = node["name"].downcase.strip.gsub(/[^0-9a-z ]/i, '').gsub(/\s+/, ' ')
            isDimmable = determineIfDimmable(node["type"])
            puts "Adding Device: [#{name}] [#{deviceId}] [#{isDimmable}]"
            add(name, deviceId, isDimmable)
        end
    end
    
    # Add Scenes
    nodes["group"].each do |group|
        deviceId = group["address"].strip
        
        if (deviceId.match(/^\d+$/) && !deviceExists(deviceId)) 
            name = group["name"].downcase.strip.gsub(/[^0-9a-z ]/i, '').gsub(/\s+/, ' ')
            puts "Adding Scene: [#{name}] [#{deviceId}] [0]"
            add(name, deviceId, "0")
        end
    end
  end
  
  # Returns a Device object based upon the Device Name or nil if no Device could be found
  def findDevice(deviceName)
    puts "findDevice(#{deviceName})"
    @devices.each_index do |i|
        if (@devices[i][DEVICENAME].match(/#{deviceName}/i))
            return Device.new(@devices[i][DEVICENAME], @devices[i][DEVICEID], @devices[i][DIMMABLE])
        end
    end
    
    return nil
  end
  
  # Returns true if the DeviceID already exists in the Device List
  def deviceExists(deviceId)
    @devices.each_index do |i|
        if (@devices[i][DEVICEID].match(/#{deviceId}/i))
            return true
        end
    end
    
    return false  
  end
  
  # Returns a Device object based upon the index it was added to the class, starting with index 0. Returns nil if an invalid index is provided.
  #  => Use this for quick access to a device
  def getDevice(index)
    if (index >= 0 && index < devices.length)
        return Device.new(@devices[index][DEVICENAME], @devices[i][DEVICEID], @devices[i][DIMMABLE])
    else
        return nil
    end
  end
  
  def formatDeviceId(address)
    return address.strip.gsub(/\s+/, "%20")
  end
  
  def determineIfDimmable(type)
    if (type.strip.split(".").first == "1")
        return 1
    else
        return 0
    end
  end
  
  def isControllable(type)
    CONTROLLABLE.include?(type.strip.split(".").first)
  end
end

class Rest    
    attr_accessor :host, :auth, :elkCode
    
    include Singleton
    include HTTParty
    format :xml
    
    def setConnParameters(host, user, pass)
        @host = host
        @auth = {:username => "#{user}", :password => "#{pass}"}  
    end
    
    def setElkParameters(elkcode)
        @elkCode = elkcode
    end
end

class Device
    attr_reader :deviceAddress
    
    def initialize(deviceName, deviceAddress, isDimmable)
        @deviceName = deviceName
        @deviceAddress = deviceAddress
        @isDimmable = isDimmable
        
        if (is_number?(deviceAddress))
            @isScene = 1
            @isDimmable = 0
        else
            @isScene = 0
        end
    end
    
    # Returns a Boolean value representing if the Device is Dimmable
    def isDimmable()
        if (@isDimmable == 1)
            return true
        end
    
        return false
    end
  
    # Returns a Boolean value representing if the Device is a Scene
    def isScene()
        if (@isScene == 1)
            return true
        end
    
        return false
    end
    
    # Returns the %/On/Off status of the Device [string]
    def getStatus
        # Scenes don't have a status
        if (@isScene == 1)  
            return ""
        else
            return Rest.get("#{Rest.instance.host}/rest/status/#{@deviceAddress}", :basic_auth => Rest.instance.auth).parsed_response["properties"]["property"]["formatted"]
        end
    end
    
    # Probe the device to determine if it's capable of dimming; true => capable, false => not capable
    def determineIfDimmable
        uom = Rest.get("#{Rest.instance.host}/rest/status/#{@deviceAddress}", :basic_auth => Rest.instance.auth).parsed_response["properties"]["property"]["uom"]
        
        if (uom.match(/^%/))
            return true
        end
        
        return false
    end
    
    # Returns the On/Off status of the Device [string]
    def getOnOffStatus
        # Scenes don't have a status
        if (@isScene == 1)  
            return ""
        else
            status = getStatus();
            onLevel = status.to_i

            if (onLevel > 0)
                return "On"
            else
                return status
            end
        end
    end
    
    # Returns the percentage value of the On Level; -1 on error [integer]
    def getOnLevel
        # Scenes don't have a status
        if (@isScene == 1)  
            return -1
        else
            onlevel = getStatus()
            puts "getOnLevel => #{onlevel}"
            
            if (onlevel == "On") 
                return 100
            elsif (onLevel == "Off")
                return 0
            else 
                return onlevel.to_i  
            end  
        end
    end
    
    # Set Device On Level percentage [string]
    def setOnLevel(percent)
        percent = percent.to_i
        if (percent >= 0 && percent <= 100)
            percent *= 2.55
            nodeCmd("DON/#{percent.to_i}")
        end
    end
    
    def turnOff
        nodeCmd("DOF")
    end
    
    def turnOn
        nodeCmd("DON")
    end
    
    def turnFastOff
        nodeCmd("DFOF")
    end
    
    def turnFastOn
        nodeCmd("DFON")
    end
    
    # Increases the On Level by ~3%
    def brighten
        nodeCmd("BRT")
    end
    
    # Decreases the On Level by ~3%
    def dim
        nodeCmd("DIM")
    end
    
    def nodeCmd(cmd)
        return Rest.get("#{Rest.instance.host}/rest/nodes/#{@deviceAddress}/cmd/#{cmd}", :basic_auth => Rest.instance.auth)    
    end
    
    def is_number?(n)
        true if Float(n) rescue false
    end
end

# Elk Classes are still under development
=begin
class ElkArea
    attr_reader :areaId  
    
    def initialize(area)
        @areaId = area
    end  
    
    def getStatus
        return Rest.get("#{Rest.instance.host}/rest/elk/area/#{@areaId}/get/status", :basic_auth => Rest.instance.auth).parsed_response["properties"]["property"]["formatted"]    
    end
    
    def armAway
        areaCmdWithCode("arm?armType=1&")
    end
    
    def armStay
        areaCmdWithCode("arm?armType=2&")
    end
    
    def armStayInstant
        areaCmdWithCode("arm?armType=3&")
    end
    
    def armNight
        areaCmdWithCode("arm?armType=4&")
    end
    
    def armNightInstant
        areaCmdWithCode("arm?armType=5&")
    end
    
    def armVacation
        areaCmdWithCode("arm?armType=6&")
    end
    
    def disarm
        areaCmdWithCode("disarm?")
    end
    
    def areaCmd(cmd)
        return Rest.get("#{Rest.instance.host}/rest/elk/area/#{@areaId}/cmd/#{cmd}", :basic_auth => Rest.instance.auth)    
    end
    
    def areaCmdWithCode(cmd)
        return areaCmd("#{cmd}code=#{Rest.instance.elkCode}")
    end
end

class ElkZones  
    def initialize
        @zones = []
        
        getTopology()
    end  
    
    def add(zoneId, zoneName)
        @zones << [zoneId, zoneName]   
    end
    
    def getTopology
        topology = getStatus()
        
        # Iterate through topology and add zones  
    end
    
    def getStatus
        return Rest.get("#{Rest.instance.host}/rest/elk/get/status", :basic_auth => Rest.instance.auth)    
    end
end

class ElkZone
    attr_reader :zoneId  
    
    def initialize(zone)
        @zoneId = zone
    end 
    
    def getVoltage
        return zoneCmd("query/voltage")
    end
    
    def getTemperature
        return zoneCmd("query/temperature")
    end
    
    def open
        zoneCmd("cmd/trigger/open")
    end
    
    def bypass
        zoneCmdWithCode("cmd/toggle/bypass?")
    end
    
    def zoneCmd(cmd)
        return Rest.get("#{Rest.instance.host}/rest/elk/zones/#{@zoneId}/#{cmd}", :basic_auth => Rest.instance.auth)    
    end
    
    def zoneCmdWithCode(cmd)
        return zoneCmd("#{cmd}code=#{Rest.instance.elkCode}")
    end
end

class ElkKeypad
    attr_reader :keypadId
    
    def initialize(keypad)
        @keypadId = keypad
    end
    
    def pressFuncKey(key)
        if (key >= 1 && key <= 6 || key == 11 || key >= 20 && key <= 30)
            keypadCmd("cmd/press/funcKey/#{key}")
            return true
        else
            return false
        end
    end
    
    def getTemperature
        return keypadCmd("query/temperature")
    end
    
    def getStatus
        return keypadCmd("get/status")
    end 
    
    def keypadCmd(cmd)
        return Rest.get("#{Rest.instance.host}/rest/elk/keypad/#{@keypadId}/#{cmd}", :basic_auth => Rest.instance.auth)    
    end
end

class ElkOutput
    attr_reader :outputId
    
    def initialize(output)
        @outputId = output
    end
    
    def getStatus
        return outputCmd("get/status")
    end
    
    def on
        outputCmd("cmd/on")
    end
    
    def onWithTimer(time)
        outputCmd("cmd/on?offTimerSeconds=#{time}")
    end
    
    def off
        outputCmd("cmd/off")
    end
    
    def outputCmd(cmd)
        return Rest.get("#{Rest.instance.host}/rest/elk/output/#{@outputId}/#{cmd}", :basic_auth => Rest.instance.auth)    
    end
end

class ElkVoice
    def ElkVoice.speakWord(wordId)
        Rest.get("#{Rest.instance.host}/rest/elk/speak/word/#{@wordId}", :basic_auth => Rest.instance.auth)    
    end
    
    def ElkVoice.speakPhrase(phraseId)
        Rest.get("#{Rest.instance.host}/rest/elk/speak/phrase/#{@phraseId}", :basic_auth => Rest.instance.auth)    
    end
end
=end
