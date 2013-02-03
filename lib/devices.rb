require 'rubygems'
require 'httparty'
require 'singleton'

class Devices
  # Index Constants
  DEVICENAME = 0
  DEVICEID = 1
  DIMMABLE = 2
 
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
  
  # Returns a Device object based upon the index it was added to the class, starting with index 0. Returns nil if an invalid index is provided.
  #  => Use this for quick access to a device
  def getDevice(index)
    if (index >= 0 && index < devices.length)
        return Device.new(@devices[index][DEVICENAME], @devices[i][DEVICEID], @devices[i][DIMMABLE])
    else
        return nil
    end
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
=end
