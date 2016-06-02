#include <WaspLoRaWAN.h>

uint8_t socket = SOCKET0;
char DEVICE_EUI[]  = "1112131415161718";
char APP_EUI[] = "0102030405060708";
char APP_KEY[] = "01020304050607080910111213141516";
uint8_t PORT = 3;
char data[] = "010203040506070809030303030303";

uint8_t str_to_ascii_code(char * str, char * ascii);
uint8_t sendTemp(uint16_t val);
uint8_t sendHum(uint16_t val);
uint8_t sendLum(uint16_t val);
uint8_t sendAlarm(bool irr);

// variable
uint8_t error;

void setup() 
{
	error = LoRaWAN.ON(socket);
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



void loop() 
{
	error = LoRaWAN.sendConfirmed( PORT, data);
	switch (error) {
		case 6: USB.println("Module hasn't joined a network"); break;
		case 5: USB.println("Sending error"); break;
		case 4: USB.println("Error with data length	  "); break;
		case 2: USB.println("Module didn't response"); break;
		case 1: USB.println("Module communication error   "); break;
		case 0: USB.println("Message sent");
	}
	
	USB.println();
	delay(10000);
}


uint8_t sendTemp(uint16_t val)
{
	char msg[10];
	sprintf(msg, "temp :val", val);

	return LoRaWAN.sendConfirmed(PORT, msg);		
}

uint8_t sendHum(uint16_t val)
{
	char msg[10];

	return LoRaWAN.sendConfirmed(PORT, msg);		
}

uint8_t sendLum(uint16_t val)
{
	char msg[10];

	return LoRaWAN.sendConfirmed(PORT, msg);	
}

uint8_t sendAlarm(bool irr)
{
	char msg[10];

	return LoRaWAN.sendConfirmed(PORT, msg);
}
