{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2014 Spring4D Team                           }
{                                                                           }
{           http://www.spring4d.org                                         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Spring.Logging.NullLogger;

{$I Spring.inc}

interface

uses
  SysUtils,
  Rtti,
  Spring.Logging;

type
  {$REGION 'TNullLogger'}
  /// <summary>
  ///   Logger that does nothing and does it in fastes way possible.
  /// </summary>
  TNullLogger = class(TInterfacedObject, ILogger)
  private
    class var fGlobalInstance: ILogger;
    class function GetGlobalInstance: ILogger; static;
  public
    function GetEnabled: Boolean;
    function GetLevels: TLogLevels;
    function GetEntryTypes: TLogEntryTypes;

    function IsEnabled(level: TLogLevel; entryTypes: TLogEntryTypes): Boolean; inline;
    function IsFatalEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsTextEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsTraceEnabled: Boolean;

    procedure Log(const entry: TLogEntry); overload;

    procedure LogValue(const name: string; const value: TValue); overload;
    procedure LogValue(level: TLogLevel; const name: string;
      const value: TValue); overload;

    procedure Log(const msg: string); overload;
    procedure Log(const msg: string; const e: Exception); overload;
    procedure Log(const fmt: string; const args: array of const); overload;
    procedure Log(const fmt: string;
      const args: array of const; const e: Exception); overload;

    procedure Log(level: TLogLevel; const msg: string); overload;
    procedure Log(level: TLogLevel; const msg: string;
      const e: Exception); overload;
    procedure Log(level: TLogLevel; const fmt: string;
      const args: array of const); overload;
    procedure Log(level: TLogLevel; const fmt: string;
      const args: array of const; const e: Exception); overload;

    procedure Fatal(const msg: string); overload;
    procedure Fatal(const msg: string; const e: Exception); overload;
    procedure Fatal(const fmt: string; const args: array of const); overload;
    procedure Fatal(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Error(const msg: string); overload;
    procedure Error(const msg: string; const e: Exception); overload;
    procedure Error(const fmt: string; const args: array of const); overload;
    procedure Error(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Warn(const msg: string); overload;
    procedure Warn(const msg: string; const e: Exception); overload;
    procedure Warn(const fmt: string; const args: array of const); overload;
    procedure Warn(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Info(const msg: string); overload;
    procedure Info(const msg: string; const e: Exception); overload;
    procedure Info(const fmt: string; const args: array of const); overload;
    procedure Info(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Text(const msg: string); overload;
    procedure Text(const msg: string; const e: Exception); overload;
    procedure Text(const fmt: string; const args: array of const); overload;
    procedure Text(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Debug(const msg: string); overload;
    procedure Debug(const msg: string; const e: Exception); overload;
    procedure Debug(const fmt: string; const args: array of const); overload;
    procedure Debug(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Trace(const msg: string); overload;
    procedure Trace(const msg: string; const e: Exception); overload;
    procedure Trace(const fmt: string; const args: array of const); overload;
    procedure Trace(const fmt: string; const args: array of const;
      const e: Exception); overload;

    procedure Entering(const classType: TClass;
      const methodName: string); overload;
    procedure Entering(const instance: TObject;
      const methodName: string); overload;
    procedure Entering(level: TLogLevel; const classType: TClass;
      const methodName: string); overload;

    procedure Leaving(const classType: TClass;
      const methodName: string); overload;
    procedure Leaving(const instance: TObject;
      const methodName: string); overload;
    procedure Leaving(level: TLogLevel; const classType: TClass;
      const methodName: string); overload;

    function Track(const classType: TClass;
      const methodName: string): IInterface; overload;
    function Track(const instance: TObject;
      const methodName: string): IInterface; overload;
    function Track(level: TLogLevel; const classType: TClass;
      const methodName: string): IInterface; overload;

    class property GlobalInstance: ILogger read GetGlobalInstance;
  end;
  {$ENDREGION}

implementation


{$REGION 'TNullLogger'}

procedure TNullLogger.Log(const entry: TLogEntry);
begin
end;

procedure TNullLogger.Log(level: TLogLevel; const msg: string);
begin
end;

procedure TNullLogger.Log(level: TLogLevel; const fmt: string;
  const args: array of const);
begin
end;

procedure TNullLogger.Log(level: TLogLevel; const msg: string;
  const e: Exception);
begin
end;

procedure TNullLogger.Debug(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Debug(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

procedure TNullLogger.Debug(const msg: string);
begin
end;

procedure TNullLogger.Debug(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Error(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Entering(level: TLogLevel; const classType: TClass;
  const methodName: string);
begin
end;

procedure TNullLogger.Entering(const classType: TClass;
  const methodName: string);
begin
end;

procedure TNullLogger.Entering(const instance: TObject;
  const methodName: string);
begin
end;

procedure TNullLogger.Error(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

procedure TNullLogger.Error(const msg: string);
begin
end;

procedure TNullLogger.Error(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Fatal(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Fatal(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

function TNullLogger.GetEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.GetEntryTypes: TLogEntryTypes;
begin
  Result := [];
end;

class function TNullLogger.GetGlobalInstance: ILogger;
begin
  if not Assigned(fGlobalInstance) then
    fGlobalInstance := TNullLogger.Create;
  Result := fGlobalInstance;
end;

function TNullLogger.GetLevels: TLogLevels;
begin
  Result := [];
end;

procedure TNullLogger.Fatal(const msg: string);
begin
end;

procedure TNullLogger.Fatal(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Info(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Info(const msg: string);
begin
end;

procedure TNullLogger.Info(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

function TNullLogger.IsDebugEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsEnabled(level: TLogLevel; entryTypes: TLogEntryTypes): Boolean;
begin
  Result := False;
end;

function TNullLogger.IsErrorEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsFatalEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsInfoEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsTextEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsTraceEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsWarnEnabled: Boolean;
begin
  Result := False;
end;

procedure TNullLogger.Info(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Leaving(level: TLogLevel; const classType: TClass;
  const methodName: string);
begin
end;

procedure TNullLogger.Log(const msg: string);
begin
end;

procedure TNullLogger.Log(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Log(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Log(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

procedure TNullLogger.Leaving(const instance: TObject;
  const methodName: string);
begin
end;

procedure TNullLogger.Leaving(const classType: TClass;
  const methodName: string);
begin
end;

procedure TNullLogger.Log(level: TLogLevel; const fmt: string;
  const args: array of const; const e: Exception);
begin
end;

procedure TNullLogger.LogValue(level: TLogLevel; const name: string;
  const value: TValue);
begin
end;

procedure TNullLogger.LogValue(const name: string; const value: TValue);
begin
end;

procedure TNullLogger.Text(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Text(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

function TNullLogger.Track(const instance: TObject;
  const methodName: string): IInterface;
begin
end;

function TNullLogger.Track(const classType: TClass;
  const methodName: string): IInterface;
begin
end;

function TNullLogger.Track(level: TLogLevel; const classType: TClass;
  const methodName: string): IInterface;
begin
  Result := nil;
end;

procedure TNullLogger.Text(const msg: string);
begin
end;

procedure TNullLogger.Text(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Trace(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Trace(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

procedure TNullLogger.Trace(const msg: string);
begin
end;

procedure TNullLogger.Trace(const msg: string; const e: Exception);
begin
end;

procedure TNullLogger.Warn(const fmt: string; const args: array of const);
begin
end;

procedure TNullLogger.Warn(const fmt: string; const args: array of const;
  const e: Exception);
begin
end;

procedure TNullLogger.Warn(const msg: string);
begin
end;

procedure TNullLogger.Warn(const msg: string; const e: Exception);
begin
end;

{$ENDREGION}

end.
