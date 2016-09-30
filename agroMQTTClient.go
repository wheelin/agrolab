package main

import (
	"fmt"
	//import the Paho Go MQTT library
	"encoding/base64"
	"encoding/json"
	"os"
	"time"

	MQTT "github.com/eclipse/paho.mqtt.golang"
)

func main() {
	//create a ClientOptions struct setting the broker address, clientid, turn
	//off trace output and set the default message handler
	opts := MQTT.NewClientOptions().AddBroker("tcp://192.168.32.4:1883")
	opts.SetClientID("11-12-13-14-15-16-17-18")
	opts.SetDefaultPublishHandler(func(client MQTT.Client, msg MQTT.Message) {
		data := make(map[string]interface{})
		if err := json.Unmarshal(msg.Payload(), &data); err != nil {
			panic(err)
		}
		byte_data, err := base64.StdEncoding.DecodeString(data["data"].(string))
		if err != nil {
			panic(err)
		}
		str_data := string(byte_data)
		fmt.Printf("TOPIC: %s\n", msg.Topic())
		fmt.Printf("DATA: %s\n", str_data)
		if err := json.Unmarshal(byte_data, &data); err != nil {
			panic(err)
		}
		fmt.Printf("Temperature : %s\n", data["temp"])
		fmt.Printf("Humidity : %s\n", data["hum"])
		fmt.Printf("Luminence : %s\n", data["lum"])
		fmt.Printf("Irrigation alarm : %s\n", data["irr"])
	})

	c := MQTT.NewClient(opts)
	if token := c.Connect(); token.Wait() && token.Error() != nil {
		panic(token.Error())
	}

	if token := c.Subscribe("lora/11-12-13-14-15-16-17-18/up", 0, nil); token.Wait() && token.Error() != nil {
		fmt.Println(token.Error())
		os.Exit(1)
	}

	time.Sleep(60 * 10 * time.Second)

	if token := c.Unsubscribe("go-mqtt/sample"); token.Wait() && token.Error() != nil {
		fmt.Println(token.Error())
		os.Exit(1)
	}

	c.Disconnect(250)
}
