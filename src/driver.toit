import serial
import .system_config
import .system_status
import .utils
import .register
import .charge_settings
import .charger_config
import .charger_state
import .charge_status

I2C_ADDRESS ::= 0x68

class LTC4162:

  /** internal span term of 18191 counts per Volt */
  static INTERNAL_SPAN_TERM ::= 18191.0
  /** Analog/Digital Amplifier gain value */
  static AD_GAIN ::= 37.5
  static VINDIV ::= 30.0
  static VBATDIV ::= 3.5
  static AVCLPROG ::= 37.5
  static VOUTDIV ::= 30.07
  static TEMP_OFFSET ::= 264.4

  RSNSB/float
  RSNSI/float

  registers_/serial.Registers

  /**
    Creates a ltc4162 device object with the given $serial.Device. Optional it is possible to set the 
    input and charge sens restistor values $rsnsb and $rsnsi value. The default for both is 0.068 in Ohm.
  */
  constructor device/serial.Device rsnsb/float=0.068 rsnsi/float=0.068:
    registers_ = device.registers
    RSNSB = rsnsb
    RSNSI = rsnsi

  /**
    Returns the u16_le value from the given $address register of the LTC4162
  */
  read address/int -> int:
    return registers_.read_u16_le address

  /**
    Writes the given $value to the given $address register of the LTC4162 as u16_le
  */
  write address/int value/int:
    registers_.write_u16_le address value

  /**
    Returns the VBAT (battery volatage) value as %.2f string
  */
  vbat -> string:
    cell_count := 1
    value := read VBAT
    vbat_span_term := ((VBATDIV * cell_count)/INTERNAL_SPAN_TERM) 
    vbat := (vbat_span_term * value).stringify 2
    debug "vbat reg: $value calculates to: $vbat"
    return vbat

  /**
    Returns the IBAT (battery current) value as %.2f string
  */
  ibat -> string:
    value := read IBAT
    debug "ibat register value: $value"
    ad_sensitivity := 1/(INTERNAL_SPAN_TERM*RSNSB*AD_GAIN)
    debug "ad_sensitivity: $ad_sensitivity"
    ibat := (ad_sensitivity * value).stringify 3
    debug "ibat reg: $value calculates to: $ibat A"
    return ibat

  /**
    Returns the VIN (voltage input) value as %.2f string
  */
  vin -> string:
    value := read VIN
    vin := ((VINDIV/INTERNAL_SPAN_TERM) * value).stringify 2
    debug "vin reg: $value calculates to: $vin"
    return vin

  /**
    Returns the IIN (input current) value as %.2f string
  */
  iin -> string:
    value := read IIN
    debug "iin register value: $value"
    ad_sensitivity := 1/(INTERNAL_SPAN_TERM*RSNSI*AD_GAIN)
    debug "ad_sensitivity: $ad_sensitivity"
    iin := (ad_sensitivity * value).stringify 3
    debug "iin reg: $value calculates to: $iin A"
    return iin
  
  /**
    Returns the VOUT (voltage output) value as %.2f string
  */
  vout -> string:
    value := read VOUT
    vout := ((VOUTDIV/INTERNAL_SPAN_TERM) * value).stringify 2
    debug "vout reg: $value calculates to: $vout V"
    return vout

  /**
    Returns the DIE_TEMP value as %.2f string
  */
  temp -> string:
    reg := read DIE_TEMP
    temp := (reg * 0.0215 - TEMP_OFFSET).stringify 2
    debug "temp reg: $reg calculates to: $temp C°"
    return temp

  /**
    Returns the current config of the LTC4162 as $SystemConfig object.
  */
  read_system_config -> SystemConfig:
    value := read CONFIG_BITS_REG.REG_VALUE
    debug "config bits: $value"
    return SystemConfig value

  /**
    Writes the given $system_config to the LTC4162
  */
  write_system_config system_config/SystemConfig:
    write CONFIG_BITS_REG.REG_VALUE system_config.system_config
    debug "config bits written: $system_config.system_config"

  /**
    Returns the current system status as int. 
  */
  read_system_status -> SystemStatus:
    value := read SYSTEM_STATUS
    system_status := SystemStatus value
    debug "system status: $value"
    return system_status
  
  /**
    Returns the current charger state as $ChargerState.
  */
  read_charger_state -> ChargerState:
    value := read CHARGER_STATE
    debug "charger state: $value"
    return ChargerState value

  /**
    Returns $ChargeSettings of the VChargeSettings from the LTC4162 device
  */
  read_v_charge_settings -> ChargeSettings:
    jeita_6_5 := read CHARGE.VCHARGE_JEITA_6_5_REG
    jeite_4_3_2 := read CHARGE.VCHARGE_JEITA_4_3_2_REG
    return ChargeSettings jeita_6_5 jeite_4_3_2
  
  /**
    Writes the given VChargeSettings $charge_settings to the LTC4162 device
  */
  write_v_charge_settings charge_settings/ChargeSettings:
    write CHARGE.VCHARGE_JEITA_6_5_REG charge_settings.get_jeiter_6_5
    write CHARGE.VCHARGE_JEITA_4_3_2_REG charge_settings.get_jeiter_4_3_2

  /**
    Returns $ChargeSettings of the IChargeSettings from the LTC4162 device
  */
  read_i_charge_settings -> ChargeSettings:
    jeita_6_5 := read CHARGE.ICHARGE_JEITA_6_5_REG
    jeite_4_3_2 := read CHARGE.ICHARGE_JEITA_4_3_2_REG
    return ChargeSettings jeita_6_5 jeite_4_3_2
  
  /**
    Writes the given IChargeSettings $charge_settings to the LTC4162 device
  */
  write_i_charge_settings charge_settings/ChargeSettings:
    write CHARGE.ICHARGE_JEITA_6_5_REG charge_settings.get_jeiter_6_5
    write CHARGE.ICHARGE_JEITA_4_3_2_REG charge_settings.get_jeiter_4_3_2
  
  /**
    Returns a list containing config for en_c_over_x_term [0] and en_jeita [1]
  */
  read_charger_config -> ChargerConfig:
    value := read CHARGER_CONFIG_BITS.REG_VALUE
    return ChargerConfig value

  /**
    Writes charger config for en_c_over_x_term and en_jeita to the register
  */
  write_charger_config charger_config/ChargerConfig:
    write CHARGER_CONFIG_BITS.REG_VALUE charger_config.get_charger_config

  /**
    Returns the current charge status as $ChargeStatus.
  */
  read_charge_status -> ChargeStatus:
    value := read CHARGE_STATUS
    debug "charge status: $value"
    return ChargeStatus value
