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

unit MainFMX;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.MobilePreview,
  System.Actions,
  FMX.ActnList,
  Androidapi.JNI.BluetoothAdapter,
  Android.JNI.Toast,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  FMX.Edit,
  FMX.Gestures,
  FMX.Objects,
  // multitouch support
  Cromis.Multitouch.Custom,
  ControlThreadU,
  CommonsU,
  FMX.Effects,
  FMX.TabControl,
  FMX.Layouts,
  FMX.Ani;

type

  TMain = class(TForm)
    Header: TToolBar;
    HeaderLabel: TLabel;
    ActionList1: TActionList;
    btnForward: TImage;
    btnLeft: TImage;
    btnBack: TImage;
    btnRight: TImage;
    effBack: TShadowEffect;
    effForward: TShadowEffect;
    effLeft: TShadowEffect;
    effRight: TShadowEffect;
    Image1: TImage;
    ReflectionEffect1: TReflectionEffect;
    tmrConnectionProblems: TTimer;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Image2: TImage;
    Layout1: TLayout;
    Layout2: TLayout;
    ChangeTabAction1: TChangeTabAction;
    FloatAnimation1: TFloatAnimation;
    acInvertCtrls: TAction;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrConnectionProblemsTimer(Sender: TObject);
    procedure Layout1Click(Sender: TObject);
    procedure Layout2Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);

  private
    FLastControlStates: TControlsStates;
    FCurrentControlStates: TControlsStates;
    FBTConnected: Boolean;
    FCurrentCar: string;
    FOStream: JOutputStream;
    FIStream: JInputstream;
    procedure OnTouchEvent(const Event: TTouchEvent);
    procedure TouchToAction(const Points: TTouchPoints);
  end;

var
  Main: TMain;

implementation

{$R *.fmx }

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FinalizeTouchListener;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  FBTConnected := False;
  InitializeTouchListener;
  TouchEventListener.AddHandler(OnTouchEvent);
end;

procedure TMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if Key = vkHardwareBack then
    Key := 0;

end;

procedure TMain.Layout1Click(Sender: TObject);
begin
  FCurrentCar := MACCAR1;
  if DoConnect(FCurrentCar, FIStream, FOStream) then
  begin
    StartControl(FOStream);
    ChangeTabAction1.ExecuteTarget(Self);
    FBTConnected := true;
  end;
end;

procedure TMain.Layout2Click(Sender: TObject);
begin
  FCurrentCar := MACCAR2;
  if DoConnect(FCurrentCar, FIStream, FOStream) then
  begin
    StartControl(FOStream);
    ChangeTabAction1.ExecuteTarget(Self);
    FBTConnected := true;
  end;
end;

procedure TMain.OnTouchEvent(const Event: TTouchEvent);
begin
  case Event.EventType of
    teDown:
      Log.d('teDown Points' + Length(Event.Points).ToString);
    teMove:
      Log.d('teMove Points' + Length(Event.Points).ToString);
    teUp:
      Log.d('teUp Points: ' + Length(Event.Points).ToString);
    teCanceled:
      Log.d('teCanceled Points' + Length(Event.Points).ToString);
  end;

  TouchToAction(TTouchPoints(Event.Points));

  effForward.Enabled := not(TControlState.csForward in FCurrentControlStates);
  effBack.Enabled := not(TControlState.csBack in FCurrentControlStates);
  effLeft.Enabled := not(TControlState.csLeft in FCurrentControlStates);
  effRight.Enabled := not(TControlState.csRight in FCurrentControlStates);

  if FCurrentControlStates <> [] then
    SetControlStatus(FCurrentControlStates);
end;

procedure TMain.tmrConnectionProblemsTimer(Sender: TObject);
begin
  if FBTConnected then
    if not ConnectionIsAlive then
    begin
      FBTConnected := False;
      Toast('Connection is lost...');
      StopControl;
    end;
end;

procedure TMain.TouchToAction(const Points: TTouchPoints);
var
  I: Integer;
  mPosition: TPointF;
begin
  FCurrentControlStates := [];
  for I := 0 to Length(Points) - 1 do
  begin
    mPosition := Points[I].Position;
    if btnForward.PointInObject(mPosition.X, mPosition.Y) then
    begin
      if pfTouchUp in Points[I].Flags then
        Include(FCurrentControlStates, TControlState.csForwardStop)
      else
        Include(FCurrentControlStates, TControlState.csForward);
    end;
    if btnBack.PointInObject(mPosition.X, mPosition.Y) then
    begin
      if pfTouchUp in Points[I].Flags then
        Include(FCurrentControlStates, TControlState.csBackStop)
      else
        Include(FCurrentControlStates, TControlState.csBack);
    end;
    if btnLeft.PointInObject(mPosition.X, mPosition.Y) then
    begin
      if pfTouchUp in Points[I].Flags then
        Include(FCurrentControlStates, TControlState.csLeftStop)
      else
        Include(FCurrentControlStates, TControlState.csLeft);
    end;
    if btnRight.PointInObject(mPosition.X, mPosition.Y) then
    begin
      if pfTouchUp in Points[I].Flags then
        Include(FCurrentControlStates, TControlState.csRightStop)
      else
        Include(FCurrentControlStates, TControlState.csRight);
    end;
  end;

  // reset lost events...
  FLastControlStates := GetControlStatus;

  if (FCurrentControlStates * [TControlState.csForward] = []) and
    (FLastControlStates * [TControlState.csForward] <> []) then
    Include(FCurrentControlStates, TControlState.csForwardStop);

  if (FCurrentControlStates * [TControlState.csBack] = []) and
    (FLastControlStates * [TControlState.csBack] <> []) then
    Include(FCurrentControlStates, TControlState.csBackStop);

  if (FCurrentControlStates * [TControlState.csLeft] = []) and
    (FLastControlStates * [TControlState.csLeft] <> []) then
    Include(FCurrentControlStates, TControlState.csLeftStop);

  if (FCurrentControlStates * [TControlState.csRight] = []) and
    (FLastControlStates * [TControlState.csRight] <> []) then
    Include(FCurrentControlStates, TControlState.csRightStop);

end;

end.
