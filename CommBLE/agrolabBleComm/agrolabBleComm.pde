#include <WaspBLE.h>
#include <WaspLoRaWAN.h>

#define HUMTEMP_CONFIG_CHAR			0x2C
#define HUMTEMP_PERIOD_CHAR			0x2E
#define HUMTEMP_DATA_CHAR				0x29

#define LUMINOSITY_CONFIG_CHAR	0x44
#define LUMINOSITY_PERIOD_CHAR	0x46
#define LUMINOSITY_DATA_CHAR		0x41

#define ENABLE									1
#define DISABLE									0

// MAC address of BLE device to find and connect.
char MAC_SENSOR1_HUM[14] 			= "b0b448c9b385";
char MAC_SENSOR2_LUMTEMP[14]	= "b0b448c9ba01";

// Datas variables
uint16_t temperature_value = 0;
uint16_t humidity_value = 0;
uint16_t luminosity_value = 0;
uint8_t irrigation_alarm_value = 0;

//LoRaWAN variables
char DEVICE_EUI[]  = "1112131415161718";
char APP_EUI[] = "0102030405060708";
char APP_KEY[] = "01020304050607080910111213141516";
uint8_t PORT = 3;

// Functions prototypes
uint8_t findAndConnectSensor1();
uint8_t findAndConnectSensor2();

uint8_t configureLuminositySensor();
uint8_t setMeasurementLuminosity(uint8_t status);
uint8_t setPeriodLuminosity(uint8_t period);

uint8_t configureHumTempSensor();
uint8_t setMeasurementHumTemp(uint8_t status);
uint8_t setPeriodHumTemp(uint8_t period);

uint8_t getLuminosity();
uint8_t getTemperatureAndHumidity();

float sensorHdc1000ConvertTemperature(uint16_t rawTemp);
float sensorHdc1000ConvertHumidity(uint16_t rawHum);
float sensorOpt3001Convert(uint16_t rawData);
void checkCollectedDataForAlaram();
uint8_t transmitCollectedDatasToLoRaWan();

uint8_t str_to_ascii_code(char * str, char * ascii);

// Programm entry
void setup() 
{  
	uint8_t error;

	//Connect Ble module
	BLE.ON(SOCKET1);
	USB.println(F("Application started"));
	
	//Connect LoRa module
	error = LoRaWAN.ON(SOCKET0);
	if( error == 0 ) 
	USB.println(F("1. Switch ON OK"));     
	else 
	{
		USB.print(F("1. Switch ON error = ")); 
		USB.println(error, DEC);
	}
	error = LoRaWAN.setDeviceEUI(DEVICE_EUI);
	if( error == 0 ) 
		USB.println(F("2. Device EUI set OK"));     
	else 
	{
		USB.print(F("2. Device EUI set error = ")); 
		USB.println(error, DEC);
	}
	error = LoRaWAN.setAppEUI(APP_EUI);
	if( error == 0 ) 
		USB.println(F("3. Application EUI set OK"));     
	else 
	{
		USB.print(F("3. Application EUI set error = ")); 
		USB.println(error, DEC);
	}
	error = LoRaWAN.setAppKey(APP_KEY);
	if( error == 0 ) 
		USB.println(F("4. Application Key set OK"));     
	else 
	{
		USB.print(F("4. Application Key set error = ")); 
		USB.println(error, DEC);
	}
	error = LoRaWAN.saveConfig();
	if( error == 0 ) 
		USB.println(F("5. Save configuration OK"));     
	else 
	{
		USB.print(F("5. Save configuration error = ")); 
		USB.println(error, DEC);
	}
	
	do{
		error = LoRaWAN.joinOTAA();
		switch (error) {
			case 8: USB.println("JOINTOTAA: version error"); 			break;
			case 7: USB.println("JOINTOTAA: input error"); 				break;
			case 6: USB.println("JOINTOTAA: not joined"); 				break;
			case 5: USB.println("JOINTOTAA: Sending error"); 			break;
			case 4: USB.println("JOINTOTAA: Error with data length"); 	break;
			case 3: USB.println("JOINTOTAA: init error"); 				break;
			case 2: USB.println("JOINTOTAA: Module didn't response"); 	break;
			case 1: USB.println("JOINTOTAA: Module answer error"); 		break;
			case 0: USB.println("JOINTOTAA: Message sent");
		}
        delay(5000);
	}while(error);
	USB.println("OTAA joined");
}

// Programm loop
void loop() 
{
	uint8_t error;
	// Collect luminosity value from sensor 1
	if (findAndConnectSensor1() == 0)
	{
		configureLuminositySensor();
		delay(1000);
		getLuminosity();
		setMeasurementLuminosity(DISABLE);
		BLE.disconnect(BLE.connection_handle);
	}
	
	// Collect Humidity and temperature value from sensor 2
	if (findAndConnectSensor2() == 0)
	{
		configureHumTempSensor();
		delay(1000);
		getTemperatureAndHumidity();
		setMeasurementHumTemp(DISABLE);
		BLE.disconnect(BLE.connection_handle);
	}
	
	//Check if irrigation alarme must be generated
	checkCollectedDataForAlaram();
		
	// Transmit the sensors data to the LoRaWAN Network
	if (transmitCollectedDatasToLoRaWan() != 0)
	{
		//wait 10secondes and retry the entire process
		USB.println("ERROR in data transmission to LoRa");
		delay(5000);
	}
	// If data has been correctely transmitted, wait 5minutes
	else
	{
		//Maintain sensor awake and wait 5minutes
		for(int i=0;i<5;i++)
		{
			//Try to connect sensor1
			if (findAndConnectSensor1() == 0)
			{
				delay(1000);
				BLE.disconnect(BLE.connection_handle);	
			}
			else
			{
				delay(1000);
			}
			//Try to connect sensor2
			if (findAndConnectSensor2() == 0)
			{
				delay(1000);
				BLE.disconnect(BLE.connection_handle);
			}
			else
			{
				delay(1000);
			}
			
			// Wait 58 secondes (1minute for the entire function)
			delay(58000);
		}
	}
}

uint8_t findAndConnectSensor1()
{
	//Search sensor 1
	if (BLE.scanDevice(MAC_SENSOR1_HUM) != 1)
	{
		USB.println(F("SENSOR1 not found: "));
		return 1;
	}
	//Connect to sensor 1
	if(BLE.connectDirect(MAC_SENSOR1_HUM) != 1)
	{
		USB.println(F("NOT Connected to SENSOR1"));
		return 1;
	}
	return 0;
}

uint8_t findAndConnectSensor2()
{
	//Search sensor 2
	if (BLE.scanDevice(MAC_SENSOR2_LUMTEMP) != 1)
	{
		USB.println(F("SENSOR2 not found: "));
		return 1;
	}
	//Connect to sensor 2
	if(BLE.connectDirect(MAC_SENSOR2_LUMTEMP) != 1)
	{
		USB.println(F("NOT Connected to SENSOR2"));
		return 1;
	}
	return 0;
}

uint8_t configureLuminositySensor()
{
	//Set collecting period to 100ms
	if(setPeriodLuminosity(0x0A) != 0)
		return 1;
	//Enable measurement
	if(setMeasurementLuminosity(ENABLE) != 0)
		return 1;
	return 0;
}
uint8_t setMeasurementLuminosity(uint8_t status)
{
	uint8_t attr[1] = {status};
	// Enable/Disable Luminosity sensor
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
	// Configure period of Luminosity sensor
	if(BLE.attributeWrite(BLE.connection_handle, LUMINOSITY_PERIOD_CHAR, attr,1))
	{
		USB.println(F("Can't configure period Luminosity/Temperature sensor"));
		return 1;
	}
	return 0;
}

uint8_t configureHumTempSensor()
{
	//Set collecting period to 100ms
	if(setPeriodHumTemp(0x0A) != 0)
		return 1;
	//Enable measurement
	if(setMeasurementHumTemp(ENABLE) != 0)
		return 1;
	return 0;	
}
uint8_t setMeasurementHumTemp(uint8_t status)
{
	uint8_t attr[1] = {status};
	// Enable/Disable Humidity and temperature sensor
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
	// Configure period of Humidity and temperature sensor
	if(BLE.attributeWrite(BLE.connection_handle, HUMTEMP_PERIOD_CHAR, attr,1))
	{
		USB.println(F("Can't configure period Humidity sensor"));
		return 1;
	}
	return 0;
}

uint8_t getLuminosity()
{
	uint16_t rawLum = 0;
	
	//Read Luminosity value
	BLE.attributeRead(BLE.connection_handle, LUMINOSITY_DATA_CHAR); 

	// Print received datas
	/*USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.println();*/
		
	// Get raw luminosity data
	rawLum = (uint16_t)(BLE.attributeValue[2] << 8) + (uint16_t)BLE.attributeValue[1];
	
	// Convert raw data to real value
	luminosity_value = (uint16_t)sensorOpt3001Convert(rawLum);
	
	// Print Luminosity value
	USB.print("Lum: ");
	USB.println(luminosity_value);

	return 0;
}

float sensorOpt3001Convert(uint16_t rawData)
{
  uint16_t e, m;
 
	//-- calculate luminosity [Lux]
  m = rawData & 0x0FFF;
  e = (rawData & 0xF000) >> 12;
 
  return m * (0.01 * pow(2.0,e));
}

uint8_t getTemperatureAndHumidity()
{	
	uint16_t rawTemp = 0;
	uint16_t rawHum = 0;
	
	//Read Humidity and Temperature value
	BLE.attributeRead(BLE.connection_handle, HUMTEMP_DATA_CHAR); 

	//Print received datas
	/*USB.print(F("Attribute Value: "));
	USB.printHex(BLE.attributeValue[4]);   
	USB.printHex(BLE.attributeValue[3]);    
	USB.printHex(BLE.attributeValue[2]);
	USB.printHex(BLE.attributeValue[1]);
	USB.println();	*/
		
	// Get raw Humidity and Temperature value
	rawTemp = (uint16_t)(BLE.attributeValue[2] << 8) + (uint16_t)BLE.attributeValue[1];
	rawHum = (uint16_t)(BLE.attributeValue[4] << 8) + (uint16_t)BLE.attributeValue[3];
	
	// Convert raw value to real value
	temperature_value = (uint16_t)sensorHdc1000ConvertTemperature(rawTemp);
	humidity_value = (uint16_t)sensorHdc1000ConvertHumidity(rawHum);
	
	// Print Humidity and Temperature value
	USB.print("hum: ");
	USB.println(humidity_value);
	USB.print("temp: ");
	USB.println(temperature_value);

	return 0;
}
float sensorHdc1000ConvertTemperature(uint16_t rawTemp)
{
  //-- calculate temperature [°C]
  return ((double)(int16_t)rawTemp / 65536) *165 - 40;
}

float sensorHdc1000ConvertHumidity(uint16_t rawHum)
{
  //-- calculate relative humidity [%RH]
  return ((double)rawHum / 65536)*100;
}

// Check if collected value need to generate irrigation alarme
void checkCollectedDataForAlaram()
{
	irrigation_alarm_value = 0;
	
	//Alarme required when humidity lower than 30%
	if(humidity_value < 30)
	{
		irrigation_alarm_value = 1;
	}
	//Alarme required when luminosity higher than 30000 lux,
	//that's equivalent to full sun exposition
	if(luminosity_value > 30000)
	{
		irrigation_alarm_value = 1;
	}
	//Alarme required when Temperature higher than 30°C
	if(temperature_value > 30)
	{
		irrigation_alarm_value = 1;
	}
}

// Tramsmit all collected data to LoRaWAN
uint8_t transmitCollectedDatasToLoRaWan()
{
	char msg[60];
	char msg_ascii[120];
	uint8_t error;
	
	sprintf(msg, "{\"temp\":\"%d\",\"hum\":\"%d\",\"lum\":\"%d\",\"irr\":\"%d\"}", temperature_value,humidity_value,luminosity_value,irrigation_alarm_value);
	string_to_hex(msg,msg_ascii);
	
	/*USB.println(msg);
	USB.println(msg_ascii);*/
	
	error = LoRaWAN.sendUnconfirmed(PORT, msg_ascii);
	if (error == 0)
	{
		USB.println("Message sent");
		return 0;
	}
	else
	{
		checkLoRaWanSendingErrors(error);
		return 1;
	}
}

void checkLoRaWanSendingErrors(uint8_t error)
{
	switch (error) {
		case 6: USB.println("Module hasn't joined a network"); break;
		case 5: USB.println("Sending error"); break;
		case 4: USB.println("Error with data length	  "); break;
		case 2: USB.println("Module didn't response"); break;
		case 1: USB.println("Module communication error   "); break;
		case 0: USB.println("Message sent");
	}
	USB.println();
}

//Convert string to hex ASCII
void string_to_hex(char * str, char * ascii)
{
		uint8_t j = 0;
    size_t len = strlen(str);
		
    for (size_t i = 0; i < len; ++i)
    {
				const unsigned char c = str[i];
        sprintf(&ascii[j], "%x", c);
        j+=2;
    }
}
