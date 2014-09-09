{
  Copyright (c) 2014 Daniele Teti, Daniele Spinetti, bit Time Software (daniele.teti@gmail.com).
  All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit CommonsU;
{$SCOPEDENUMS ON}

interface

uses
  Cromis.Multitouch.Custom, Androidapi.JNI.JavaTypes;

const
  MACCAR1 = '00:13:EF:D6:67:0D'; // daniele teti
  MACCAR2 = '00:24:94:D0:24:62'; // daniele spinetti

type
  TControlState = (csForwardStop = 0, csForward = 1, csBackStop = 2, csBack = 3,
    csLeftStop = 4, csLeft = 5, csRightStop = 6, csRight = 7);
  TControlsStates = set of TControlState;
  TTouchPoints = array of TTouchPoint;

function DoConnect(MACAddress: String; out istream: JInputstream;
  out ostream: JOutputStream): Boolean;

implementation

uses
  Androidapi.Helpers, Androidapi.JNI.BluetoothAdapter, Android.JNI.Toast,
  System.SysUtils;

function DoConnect(MACAddress: String; out istream: JInputstream;
  out ostream: JOutputStream): Boolean;
var
  uid: JUUID;
  targetMAC: string;
  Adapter: JBluetoothAdapter;
  remoteDevice: JBluetoothDevice;
  Sock: JBluetoothSocket;
begin
  uid := TJUUID.JavaClass.fromString
    (stringtojstring('00001101-0000-1000-8000-00805F9B34FB'));
  targetMAC := MACAddress;
  Adapter := TJBluetoothAdapter.JavaClass.getDefaultAdapter;
  remoteDevice := Adapter.getRemoteDevice(stringtojstring(targetMAC));
  Toast('Connecting to ' + targetMAC);
  Sock := remoteDevice.createRfcommSocketToServiceRecord(uid);
  try
    Sock.connect;
  except
    Toast('Could not create service record!');
    Exit(False);
  end;
  if not Sock.isConnected then
  begin
    Toast('Failed to connect to ' + targetMAC + '! Try again...');
    Exit(False);
  end;
  Toast('Connected!');
  ostream := Sock.getOutputStream; // record io streams
  istream := Sock.getInputStream;

  // Application.ProcessMessages;

  ostream.write(ord(255)); //
  ostream.write(ord(255)); // get device id   (nur Chitanda)
  Sleep(200);
  Result := True;
end;

end.
