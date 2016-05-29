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
uint16_t temperature_value = 0;
uint16_t humidity_value = 0;
uint16_t luminosity_value = 0;

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
		for(int i = 0; i<10; i++)
		{
			getLuminosity();
			delay(1000);
		}
		setMeasurementLuminosity(DISABLE);
		BLE.disconnect(BLE.connection_handle);
	}
	
	delay(2000);
	
	if (findAndConnectSensor2() == 0)
	{
		configureHumTempSensor();
		delay(1000);
		for(int i = 0; i<10; i++)
		{
			getTemperatureAndHumidity();
			delay(1000);
		}
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
	/*if (setNotificationLuminosity(ENABLE) != 0)
		return 1;
	
	return_code = BLE.waitEvent(10000);
	if(return_code == BLE_EVENT_ATTCLIENT_ATTRIBUTE_VALUE)
	{
		USB.print(F("Attribute Value: "));
		USB.printHex(BLE.event[3]);    
		USB.printHex(BLE.event[2]);
		USB.printHex(BLE.event[1]);
		USB.printHex(BLE.event[0]);
		USB.println();
		
		//Save data values	
		luminosity_value = (uint16_t)(BLE.event[3] << 8) + (uint16_t)BLE.event[2];
		USB.print("Lum: ");
		USB.println(luminosity_value);
		
		if (setNotificationLuminosity(DISABLE) != 0)
			return 1;
		return 0;
	}
	USB.println(F("Can't read Luminosity measure"));
	return 1;
	*/
	BLE.attributeRead(BLE.connection_handle, LUMINOSITY_DATA_CHAR); 

	//Save data values
	USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[3]);    
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.printHex(BLE.attributeValue[0]);
	USB.println();	
		
	temperature_value = (uint16_t)(BLE.attributeValue[2] << 8) + (uint16_t)BLE.attributeValue[3];
	luminosity_value = (uint16_t)(BLE.attributeValue[0] << 8) + (uint16_t)BLE.attributeValue[1];
	USB.print("Lum: ");
	USB.println(luminosity_value);
	USB.print("temp: ");
	USB.println(temperature_value);

	return 0;
}
uint8_t getTemperatureAndHumidity()
{
	/*if (setNotificationHumTemp(ENABLE) != 0)
		return 1;
	
	return_code = BLE.waitEvent(10000);
	if(return_code == BLE_EVENT_ATTCLIENT_ATTRIBUTE_VALUE)
	{
		USB.print(F("Attribute Value: "));
		USB.printHex(BLE.event[0]);    
		USB.printHex(BLE.event[1]);
		USB.printHex(BLE.event[2]);
		USB.printHex(BLE.event[3]);
		USB.println();		
		
		//Save data values
		temperature_value = (uint16_t)(BLE.event[1] << 8) + (uint16_t)BLE.event[0];
		humidity_value = (uint16_t)(BLE.event[3] << 8) + (uint16_t)BLE.event[2];
		USB.print("hum: ");
		USB.println(humidity_value);
		USB.print("temp: ");
		USB.println(temperature_value);

		if (setNotificationHumTemp(DISABLE) != 0)
			return 1;
		return 0;
	}
	USB.println(F("Can't read Humidity/Temperature measure"));
	return 1;*/
	BLE.attributeRead(BLE.connection_handle, HUMTEMP_DATA_CHAR); 

	//Save data values
	USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[3]);    
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.printHex(BLE.attributeValue[0]);
	USB.println();	
		
	temperature_value = (uint16_t)(BLE.attributeValue[2] << 8) + (uint16_t)BLE.attributeValue[3];
	humidity_value = (uint16_t)(BLE.attributeValue[0] << 8) + (uint16_t)BLE.attributeValue[1];
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






