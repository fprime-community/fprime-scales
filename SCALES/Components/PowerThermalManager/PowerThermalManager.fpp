module components {

  # Defining types needed for this component
  enum SystemState: U8 {
    STANDBY = 0 @< System in standby mode
    NORMAL = 1 @< System in normal operation
    SAFE = 2 @< System in safe mode
    CRITICAL = 3 @< System in critical mode
    UNKNOWN = 4 @< System state not determined
  }
  
  struct PowerReading {
    voltage: F32 @< Voltage reading in volts
    current: F32 @< Current reading in amps
    power: F32 @< Power consumption in watts
    sourceId: U8 @< ID of the power source/sensor
    timestamp: U32 @< Timestamp of reading
  }
  
  struct ThermalReading {
    temperature: F32 @< Temperature in degrees Celsius
    sensorId: U8 @< ID of the thermal sensor
    location: string size 32 @< Description of sensor location
    timestamp: U32 @< Timestamp of reading
  }
  
  struct SystemStateData {
    state: SystemState @< Current spacecraft state
    timestamp: U32 @< Timestamp of state update
    modeDescription: string size 64 @< Optional detailed mode description
  }
  
  struct PowerThermalStatus {
    powerReadings: PowerReading @< Power readings
    thermalReadings: ThermalReading @< Thermal readings
    systemRecommendation: SystemState @< Recommended system state based on power/thermal
    criticalFlag: bool @< Flag indicating if any readings are in critical range
    timestamp: U32 @< Timestamp of status update
  }

  @ Component to manage and monitor power and thermal conditions of the system
  active component PowerThermalManager {
    
    ###############################################################################
    #                                 General Ports                               #
    ###############################################################################
    
    @ Port for receiving power data
    async input port powerData: components.PowerReading
    
    @ Port for receiving thermal data
    async input port thermalData: components.ThermalReading
    
    @ Input port for receiving system state information
    async input port systemStateIn: components.SystemStateData
    
    @ Output port for all power and thermal telemetry data
    output port dataOut: components.PowerThermalStatus
    
    @ Output port for sending power/thermal status to SystemResources component
    output port systemResourcesOut: components.PowerThermalStatus
    
    ###############################################################################
    # Standard AC Ports: Required for Channels, Events, Commands, and Parameters  #
    ###############################################################################
    @ Port for requesting the current time
    time get port timeCaller
    
    @ Port for sending command registrations
    command reg port cmdRegOut
    
    @ Port for receiving commands
    command recv port cmdIn
    
    @ Port for sending command responses
    command resp port cmdResponseOut
    
    @ Port for sending textual representation of events
    text event port logTextOut
    
    @ Port for sending events to downlink
    event port logOut
    
    @ Port for sending telemetry channels to downlink
    telemetry port tlmOut
    
    @ Port to return the value of a parameter
    param get port prmGetOut
    
    @ Port to set the value of a parameter
    param set port prmSetOut
    
    ###############################################################################
    #                                  Commands                                   #
    ###############################################################################
    
    @ Command to force a full power/thermal status update
    async command UPDATE_STATUS
    
    @ Command to set thermal limit thresholds
    async command SET_THERMAL_LIMITS(
      warningTemp: F32 @< Warning temperature threshold in degrees C
      criticalTemp: F32 @< Critical temperature threshold in degrees C
    )
    
    @ Command to set power limit thresholds
    async command SET_POWER_LIMITS(
      warningWatts: F32 @< Warning power threshold in watts
      criticalWatts: F32 @< Critical power threshold in watts
    )
    
    ###############################################################################
    #                                   Events                                    #
    ###############################################################################
    
    @ Event indicating thermal warning threshold exceeded
    event THERMAL_WARNING(
      sensorId: U8 @< ID of the thermal sensor
      temperature: F32 @< Current temperature
      threshold: F32 @< Warning threshold
      location: string size 32 @< Sensor location
    ) severity warning high id 0 format "Thermal warning: {} at {} is {°C} (threshold: {°C})"
    
    @ Event indicating thermal critical threshold exceeded
    event THERMAL_CRITICAL(
      sensorId: U8 @< ID of the thermal sensor
      temperature: F32 @< Current temperature
      threshold: F32 @< Critical threshold
      location: string size 32 @< Sensor location
    ) severity warning high id 1 format "CRITICAL THERMAL: {} at {} is {°C} (threshold: {°C})"
    
    @ Event indicating power warning threshold exceeded
    event POWER_WARNING(
      sourceId: U8 @< ID of the power source
      power: F32 @< Current power consumption
      threshold: F32 @< Warning threshold
    ) severity warning high id 2 format "Power warning: Source {} at {W} (threshold: {W})"
    
    @ Event indicating power critical threshold exceeded
    event POWER_CRITICAL(
      sourceId: U8 @< ID of the power source
      power: F32 @< Current power consumption
      threshold: F32 @< Critical threshold
    ) severity warning high id 3 format "CRITICAL POWER: Source {} at {W} (threshold: {W})"
    
    @ Event indicating limits updated
    event LIMITS_UPDATED(
      type: string size 16 @< Type of limit updated (THERMAL or POWER)
      warning: F32 @< New warning threshold
      critical: F32 @< New critical threshold
    ) severity activity high id 5 format "{} limits updated: Warning {} Critical {}"

    @ Event indicating power is out of range
    event POWER_OUT_OF_RANGE(
      sourceId: U8 @< ID of the power source
      power: F32 @< Current power consumption
      lowerLimit: F32 @< Lower limit
      upperLimit: F32 @< Upper limit
    ) severity warning high id 8 format "Power out of range: Source {} at {W} (limits: {W}-{W})"
    
    @ Event indicating thermal is out of range
    event THERMAL_OUT_OF_RANGE(
      sensorId: U8 @< ID of the thermal sensor
      temperature: F32 @< Current temperature
      lowerLimit: F32 @< Lower limit
      upperLimit: F32 @< Upper limit
      location: string size 32 @< Sensor location
    ) severity warning high id 9 format "Thermal out of range: {} at {} is {°C} (limits: {°C}-{°C})"
    
    @ Event indicating power transition due to state change
    event POWER_TRANSITION(
      previousState: components.SystemState @< Previous system state
      newState: components.SystemState @< New system state
      powerChange: F32 @< Change in power consumption
    ) severity activity high id 10 format "Power transition from {} to {}: {W} change"
    
    ###############################################################################
    #                                 Telemetry                                   #
    ###############################################################################
    
    @ Maximum temperature currently detected
    telemetry MaxTemperature: F32
    
    @ Minimum temperature currently detected
    telemetry MinTemperature: F32
    
    @ Average temperature across all sensors
    telemetry AvgTemperature: F32
    
    @ Total power consumption in watts
    telemetry TotalPower: F32
    
    @ Current thermal warning threshold
    telemetry ThermalWarningThreshold: F32
    
    @ Current thermal critical threshold
    telemetry ThermalCriticalThreshold: F32
    
    @ Current power warning threshold
    telemetry PowerWarningThreshold: F32
    
    @ Current power critical threshold
    telemetry PowerCriticalThreshold: F32
    
    @ Current system state
    telemetry CurrentSystemState: components.SystemState
  }
}