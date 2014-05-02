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

unit ControlThreadU;

interface

uses
  System.Classes, Androidapi.JNI.JavaTypes, CommonsU;

procedure StartControl(OutputStream: JOutputStream);
function ConnectionIsAlive: Boolean;
procedure StopControl;
function GetControlStatus: TControlsStates;
procedure SetControlStatus(AControlStates: TControlsStates);

implementation

uses
  System.SysUtils, FMX.Types, System.SyncObjs;

type
  TControlThread = class(TThread)
  private
    FControlStates: TControlsStates;
    FControlStream: JOutputStream;
    FPipeIsBrokenEvent: TEvent;
  protected
    procedure Execute; override;
  public
    property PipeIsBrokenEvent: TEvent read FPipeIsBrokenEvent;
    constructor Create(ACreateSuspended: Boolean);
    property ControlStates: TControlsStates read FControlStates
      write FControlStates;
    property ControlStream: JOutputStream read FControlStream
      write FControlStream;
  end;

  { TControlThread }
var
  Th: TControlThread = nil;

function ConnectionIsAlive: Boolean;
begin
  Result := Assigned(Th);
  if Result then
  begin
    Result := Th.PipeIsBrokenEvent.WaitFor(1) <> wrSignaled;
  end;
end;

procedure StartControl(OutputStream: JOutputStream);
begin
  Th := TControlThread.Create(true);
  Th.FreeOnTerminate := False;
  Th.ControlStream := OutputStream;
  Th.Start;
end;

constructor TControlThread.Create(ACreateSuspended: Boolean);
begin
  inherited Create(ACreateSuspended);
  FPipeIsBrokenEvent := TEvent.Create(nil, true, False, '');
end;

procedure TControlThread.Execute;
var
  cmd: TControlState;
  BrokenPipe: Boolean;
begin
  inherited;
  BrokenPipe := False;
  while not(Terminated or BrokenPipe) do
  begin
    try
      TMonitor.Enter(Self);
      try
        for cmd := TControlState.csForwardStop to TControlState.csRight do
        begin
          if cmd in FControlStates then
          begin
            FControlStream.write(Ord(cmd));
          end;
        end;
      finally
        TMonitor.Exit(Self);
      end;
      TThread.Sleep(10);
    except
      on E: EJNIException do
      begin
        Log.d('THREAD EXCEPTION: ' + E.classname + ' >> ' + E.message);
        BrokenPipe := true;
      end;
      on E: Exception do
      begin
        Log.d('THREAD EXCEPTION: ' + E.classname + ' >> ' + E.message);
        TThread.Sleep(1000);
      end;
    end;
  end; // while
  if BrokenPipe then
    FPipeIsBrokenEvent.SetEvent;
end;

procedure SetControlStatus(AControlStates: TControlsStates);
begin
  if Assigned(Th) then
  begin
    TMonitor.Enter(Th);
    try
      Th.ControlStates := AControlStates;
    finally
      TMonitor.Exit(Th);
    end;
  end;
end;

function GetControlStatus: TControlsStates;
begin
  if Assigned(Th) then
  begin
    TMonitor.Enter(Th);
    try
      Result := Th.ControlStates;
    finally
      TMonitor.Exit(Th);
    end;
  end
  else
    Result := [];
end;

procedure StopControl;
begin
  if Assigned(Th) then
  begin
    Th.Terminate;
    Th.DisposeOf;
    Th := nil;
  end;
end;

end.
