BeeMiniCtrl
===========

Android client app to control a [BeeWi - BBZ201 - Mini Cooper S Bluetooth Car.](http://www.bee-wi.com/bluetooth-controlled-car-bbz201-beewi,us,4,BBZ201-A0.cfm "BBZ201 - Mini Cooper S Bluetooth Car") May work with other BeeWi Bluetooth remote control vehicles. 

Original app by [Daniele Teti](http://www.danieleteti.it/ "while true do;") & [Daniele Spinetti](http://www.danielespinetti.it/ "Where is the WOW") of [bit Time Software](http://www.bittime.it/ "bit Time Software's home page").

The Multitouch code is Copyright (c) 2006-2014 [Iztok Kacin, Cromis](http://www.cromis.net/blog/ "From Zero To One") and used under the BSD license.

Currently there is no Bluetooth discovery functionality, so you have to hard code the Bluetooth MAC addresses (in unit CommonsU.pas). There are 2 consts declared as following:

    const 
      MACCAR1 = '00:13:EF:A0:41:B9'; // daniele teti
      MACCAR2 = '00:24:94:D0:24:62'; // daniele spinetti

Here you have to put yours MAC addresses. The MAC address is found on the bottom of the car. Be sure you pair the car with your Android device first.

