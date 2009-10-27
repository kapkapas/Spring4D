{***************************************************************************}
{                                                                           }
{           Delphi Spring Framework                                         }
{                                                                           }
{           Copyright (C) 2009-2010 Delphi Spring Framework                 }
{                                                                           }
{           http://delphi-spring-framework.googlecode.com                   }
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

unit Spring.IoC.LifetimeManager;

{$I Spring.inc}

interface

uses
  Classes,
  Windows,
  SysUtils,
  Spring.System,
  Spring.IoC.Core;

type
  TLifetimeManagerBase = class abstract(TInterfacedObject, ILifetimeManager, IInterface)
  private
    fActivator: IComponentActivator;
    fModel: TComponentModel;
  public
    constructor Create(const activator: IComponentActivator; model: TComponentModel);
    function GetInstance: TObject; virtual; abstract;
    procedure Release(instance: TObject); virtual; abstract;
    property Activator: IComponentActivator read fActivator;
    property Model: TComponentModel read fModel;
  end;

  TSingletonLifetimeManager = class(TLifetimeManagerBase)
  private
    fInstance: TObject;
    fLifetimeWatcher: IInterface;
  public
    function GetInstance: TObject; override;
    procedure Release(instance: TObject); override;
  end;

  TTransientLifetimeManager = class(TLifetimeManagerBase)
  public
    function GetInstance: TObject; override;
    procedure Release(instance: TObject); override;
  end;


implementation


{$REGION 'TLifetimeManagerBase'}

constructor TLifetimeManagerBase.Create(const activator: IComponentActivator;
  model: TComponentModel);
begin
  inherited Create;
  fActivator := activator;
  fModel := model;
end;

{$ENDREGION}


{$REGION 'TSingletonLifetimeManager'}

function TSingletonLifetimeManager.GetInstance: TObject;
var
  localInstance: TObject;
begin
  if fInstance = nil then
  begin
    localInstance := fActivator.CreateInstance(fModel);
    if InterlockedCompareExchangePointer(Pointer(fInstance), localInstance, nil) <> nil then
    begin
      localInstance.Free;
    end
    else if fInstance is TInterfacedObject then // Reference-Counting
    begin
      fInstance.GetInterface(IInterface, fLifetimeWatcher);
    end
    else
    begin
      fLifetimeWatcher := TLifetimeWatcher.Create(
        procedure
        begin
          fInstance.Free;
        end
      );
    end;
  end;
  Result := fInstance;
end;

procedure TSingletonLifetimeManager.Release(instance: TObject);
begin
end;

{$ENDREGION}


{$REGION 'TTransientLifetimeManager'}

function TTransientLifetimeManager.GetInstance: TObject;
begin
  Result := Activator.CreateInstance(Model);
end;

procedure TTransientLifetimeManager.Release(instance: TObject);
begin
  instance.Free;
end;

{$ENDREGION}


end.

