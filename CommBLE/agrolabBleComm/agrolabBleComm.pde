#include <WaspBLE.h>

#define HUMTEMP_CONFIG_CHAR			0x2C
#define HUMTEMP_NOTIFY_CHAR			0x2A
#define HUMTEMP_PERIOD_CHAR			0x2E
#define HUMTEMP_DATA_CHAR				0x29

#define LUMINOSITY_CONFIG_CHAR		0x24
#define LUMINOSITY_NOTIFY_CHAR		0x22
#define LUMINOSITY_PERIOD_CHAR		0x26
#define LUMINOSITY_DATA_CHAR			0x21

#define ENABLE									1
#define DISABLE									0

// MAC address of BLE device to find and connect.
char MAC_SENSOR1_HUM[14] 			= "b0b448c9b385";
char MAC_SENSOR2_LUMTEMP[14]	= "b0b448c9ba01";

// Datas variables
float temperature_value = 0.0;
float humidity_value = 0.0;
float luminosity_value = 0.0;

uint8_t return_code = 0;

// Functions prototypes
uint8_t findAndConnectSensor1();
uint8_t findAndConnectSensor2();

uint8_t configureLuminositySensor();
uint8_t setMeasurementLuminosity(uint8_t status);
uint8_t setPeriodLuminosity(uint8_t period);
uint8_t setNotificationLuminosity(uint8_t status);

uint8_t configureHumTempSensor();
uint8_t setMeasurementHumTemp(uint8_t status);
uint8_t setPeriodHumTemp(uint8_t period);
uint8_t setNotificationHumTemp(uint8_t status);

uint8_t getLuminosity();
uint8_t getTemperatureAndHumidity();
void sensorHdc1000Convert(uint16_t rawTemp, uint16_t rawHum, float *temp, float *hum);
float sensorOpt3001Convert(uint16_t rawData);

// Programm entry
void setup() 
{  
	BLE.ON(SOCKET1);
	USB.println(F("Application started"));
}

// Programm loop
void loop() 
{
	
	if (findAndConnectSensor1() == 0)
	{
		configureLuminositySensor();
		delay(1000);
		getLuminosity();
		setMeasurementLuminosity(DISABLE);
		BLE.disconnect(BLE.connection_handle);
	}
	
	if (findAndConnectSensor2() == 0)
	{
		configureHumTempSensor();
		delay(1000);
		getTemperatureAndHumidity();
		setMeasurementHumTemp(DISABLE);
		BLE.disconnect(BLE.connection_handle);
	}
	delay(2000);
	
}

uint8_t findAndConnectSensor1()
{
	if (BLE.scanDevice(MAC_SENSOR1_HUM) != 1)
	{
		USB.println(F("SENSOR1 not found: "));
		return 1;
	}
	if(BLE.connectDirect(MAC_SENSOR1_HUM) != 1)
	{
		USB.println(F("NOT Connected to SENSOR1"));
		return 1;
	}
	return 0;
}

uint8_t findAndConnectSensor2()
{
	if (BLE.scanDevice(MAC_SENSOR2_LUMTEMP) != 1)
	{
		USB.println(F("SENSOR2 not found: "));
		return 1;
	}
	if(BLE.connectDirect(MAC_SENSOR2_LUMTEMP) != 1)
	{
		USB.println(F("NOT Connected to SENSOR2"));
		return 1;
	}
	return 0;
}

uint8_t configureLuminositySensor()
{
	if(setPeriodLuminosity(50) != 0)
		return 1;
	if(setMeasurementLuminosity(ENABLE) != 0)
		return 1;
	return 0;
}
uint8_t setMeasurementLuminosity(uint8_t status)
{
	uint8_t attr[1] = {status};
	// Enable/Disable Luminosity and Temperature sensor
	if(BLE.attributeWrite(BLE.connection_handle, LUMINOSITY_CONFIG_CHAR, attr,1))
	{
		USB.println(F("Can't enable/disable Luminosity/Temperature sensor"));
		return 1;
	}
	return 0;
}
uint8_t setPeriodLuminosity(uint8_t period)
{
	uint8_t attr[1] = {period};
	// Configure period of Luminosity and Temperature sensor
	if(BLE.attributeWrite(BLE.connection_handle, LUMINOSITY_PERIOD_CHAR, attr,1))
	{
		USB.println(F("Can't configure period Luminosity/Temperature sensor"));
		return 1;
	}
	return 0;
}
uint8_t setNotificationLuminosity(uint8_t status)
{
	// Enable/Disable notification Luminosity and Temperature measure
	uint8_t attr[2] = {0};
	attr[0] = status;
	attr[1] = 0;
	if(BLE.attributeWrite(BLE.connection_handle, LUMINOSITY_NOTIFY_CHAR, attr, 2))
	{
		USB.println(F("Can't enable/disable notification on Luminosity/Temperature measure"));
		return 1;
	}
	return 0;
}
uint8_t configureHumTempSensor()
{
	if(setPeriodHumTemp(50) != 0)
		return 1;
	if(setMeasurementHumTemp(ENABLE) != 0)
		return 1;
	return 0;	
}
uint8_t setMeasurementHumTemp(uint8_t status)
{
	uint8_t attr[1] = {status};
	// Enable/Disable Humidity sensor
	if(BLE.attributeWrite(BLE.connection_handle, HUMTEMP_CONFIG_CHAR, attr,1))
	{
		USB.println(F("Can't enable/disable Humidity sensor"));
		return 1;
	}
	return 0;
}
uint8_t setPeriodHumTemp(uint8_t period)
{
	uint8_t attr[1] = {period};
	// Configure period of Humidity sensor
	if(BLE.attributeWrite(BLE.connection_handle, HUMTEMP_PERIOD_CHAR, attr,1))
	{
		USB.println(F("Can't configure period Humidity sensor"));
		return 1;
	}
	return 0;
}
uint8_t setNotificationHumTemp(uint8_t status)
{
	// Enable/Disable notification Humidity measure
	uint8_t attr[2] = {0};
	attr[0] = status;
	attr[1] = 0;
	if(BLE.attributeWrite(BLE.connection_handle, HUMTEMP_NOTIFY_CHAR, attr, 2))
	{
		USB.println(F("Can't enable/disable notification on Humidity measure"));
		return 1;
	}
	return 0;
}
uint8_t getLuminosity()
{
	uint16_t rawLum = 0;
	
	BLE.attributeRead(BLE.connection_handle, LUMINOSITY_DATA_CHAR); 

	//Save data values
	USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[3]);    
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.printHex(BLE.attributeValue[0]);
	USB.println();	
		
	rawLum = (uint16_t)(BLE.attributeValue[3] << 8) + (uint16_t)BLE.attributeValue[2];
	USB.printHex(rawLum);    
	luminosity_value = sensorOpt3001Convert(rawLum);
	USB.print("Lum: ");
	USB.println(luminosity_value);

	return 0;
}

float sensorOpt3001Convert(uint16_t rawData)
{
  uint16_t e, m;
 
  m = rawData & 0x0FFF;
  e = (rawData & 0xF000) >> 12;
 
  return m * (0.01 * pow(2.0,e));
}

uint8_t getTemperatureAndHumidity()
{	
	uint16_t rawTemp = 0;
	uint16_t rawHum = 0;
	
	BLE.attributeRead(BLE.connection_handle, HUMTEMP_DATA_CHAR); 

	//Save data values
	USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[3]);    
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.printHex(BLE.attributeValue[0]);
	USB.println();	
		
	rawTemp = (uint16_t)(BLE.attributeValue[1] << 8) + (uint16_t)BLE.attributeValue[0];
	rawHum = (uint16_t)(BLE.attributeValue[3] << 8) + (uint16_t)BLE.attributeValue[2];
	USB.printHex(rawTemp);    
	USB.printHex(rawHum);
	sensorHdc1000Convert(rawTemp,rawHum,&temperature_value,&humidity_value);
	USB.print("hum: ");
	USB.println(humidity_value);
	USB.print("temp: ");
	USB.println(temperature_value);

	return 0;

	USB.print(F("Attribute Value: "));
	for(uint8_t i = 0; i < BLE.attributeValue[0]; i++)
	{
		USB.printHex(BLE.attributeValue[i+1]);        
	}
	USB.println();
}

void sensorHdc1000Convert(uint16_t rawTemp, uint16_t rawHum,
                        float *temp, float *hum)
{
  //-- calculate temperature [°C]
  *temp = ((double)(int16_t)rawTemp / 65536)*165 - 40;
 
  //-- calculate relative humidity [%RH]
  *hum = ((double)rawHum / 65536)*100;
}





