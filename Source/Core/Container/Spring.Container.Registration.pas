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

unit Spring.Container.Registration;

{$I Spring.inc}

interface

uses
  Rtti,
  Spring,
  Spring.Collections,
{$IFDEF DELPHIXE}
  Spring.Reflection.Compatibility,
{$ENDIF}
  Spring.Container.Common,
  Spring.Container.Core;

type
  ///	<summary>
  ///	  TComponentRegistry
  ///	</summary>
  TComponentRegistry = class(TInterfacedObject, IComponentRegistry)
  private
    fKernel: IKernel;
    fRttiContext: TRttiContext;
    fModels: IList<TComponentModel>;
    fDefaultRegistrations: IDictionary<PTypeInfo, TComponentModel>;
    fUnnamedRegistrations: IDictionary<PTypeInfo, IList<TComponentModel>>;
    fServiceTypeMappings: IDictionary<PTypeInfo, IList<TComponentModel>>;
    fServiceNameMappings: IDictionary<string, TComponentModel>;
  protected
    function BuildActivatorDelegate(elementTypeInfo: PTypeInfo; out componentType: TRttiType): TActivatorDelegate;
    procedure CheckIsNonGuidInterface(serviceType: TRttiType);
{$IFDEF DELPHIXE_UP}
    procedure InternalRegisterFactory(const model: TComponentModel;
      const invokeEvent: TVirtualInterfaceInvokeEvent);
{$ENDIF}
    procedure RegisterUnnamed(const model: TComponentModel; serviceType: PTypeInfo);
    procedure Validate(componentType, serviceType: PTypeInfo; var serviceName: string);
  public
    constructor Create(const kernel: IKernel);
    destructor Destroy; override;
    function RegisterComponent(componentTypeInfo: PTypeInfo): TComponentModel;
    procedure RegisterService(const model: TComponentModel; serviceType: PTypeInfo); overload;
    procedure RegisterService(const model: TComponentModel; serviceType: PTypeInfo; const name: string); overload;
    procedure RegisterDefault(const model: TComponentModel; serviceType: PTypeInfo);
{$IFDEF DELPHIXE_UP}
    procedure RegisterFactory(const model: TComponentModel); overload;
    procedure RegisterFactory(const model: TComponentModel; const name: string); overload;
{$ENDIF}
    procedure UnregisterAll;
    function HasService(serviceType: PTypeInfo): Boolean; overload;
    function HasService(const name: string): Boolean; overload;
    function HasService(serviceType: PTypeInfo; const name: string): Boolean; overload;
    function HasDefault(serviceType: PTypeInfo): Boolean;
    function FindOne(componentType: PTypeInfo): TComponentModel; overload;
    function FindOne(const name: string): TComponentModel; overload;
    function FindOne(serviceType: PTypeInfo; const argument: TValue): TComponentModel; overload;
    function FindDefault(serviceType: PTypeInfo): TComponentModel;
    function FindAll: IEnumerable<TComponentModel>; overload;
    function FindAll(serviceType: PTypeInfo): IEnumerable<TComponentModel>; overload;
  end;

  ///	<summary>
  ///	  Internal helper class for non-generic fluent style registration of a
  ///	  component.
  ///	</summary>
  TRegistration = record
  private
{$IFNDEF DELPHIXE_UP}
    fRegistry: TComponentRegistry;
{$ELSE}
    fRegistry: IComponentRegistry;
{$ENDIF}
    fModel: TComponentModel;
    constructor Create(const registry: IComponentRegistry; componentType: PTypeInfo);
  public
    function Implements(serviceType: PTypeInfo): TRegistration; overload;
    function Implements(serviceType: PTypeInfo; const name: string): TRegistration; overload;

    function DelegateTo(const delegate: TActivatorDelegate): TRegistration; overload;

    {$REGION 'Typed Injections'}

    function InjectConstructor(const parameterTypes: array of PTypeInfo): TRegistration; overload;
    function InjectProperty(const propertyName: string): TRegistration; overload;
    function InjectMethod(const methodName: string): TRegistration; overload;
    function InjectMethod(const methodName: string; const parameterTypes: array of PTypeInfo): TRegistration; overload;
    function InjectField(const fieldName: string): TRegistration; overload;

    {$ENDREGION}

    {$REGION 'Named/Valued Injections'}

    function InjectConstructor(const arguments: array of TValue): TRegistration; overload;
    function InjectProperty(const propertyName: string; const value: TValue): TRegistration; overload;
    function InjectMethod(const methodName: string; const arguments: array of TValue): TRegistration; overload;
    function InjectField(const fieldName: string; const value: TValue): TRegistration; overload;

    {$ENDREGION}

    function AsSingleton: TRegistration; overload;
    function AsSingleton(refCounting: TRefCounting): TRegistration; overload;
    function AsSingletonPerThread: TRegistration;
    function AsTransient: TRegistration;
    function AsPooled(minPoolSize, maxPoolSize: Integer): TRegistration; {$IFDEF CPUARM}experimental;{$ENDIF}

    function AsDefault: TRegistration; overload;
    function AsDefault(serviceType: PTypeInfo): TRegistration; overload;

{$IFDEF DELPHIXE_UP}
    function AsFactory: TRegistration; overload;
    function AsFactory(const name: string): TRegistration; overload;
{$ENDIF}
  end;

  ///	<summary>
  ///	  Internal helper class for generic fluent style registration of a
  ///	  component.
  ///	</summary>
  TRegistration<T> = record
  private
    fRegistration: TRegistration;
    constructor Create(const registry: IComponentRegistry);
  public
    function Implements(serviceType: PTypeInfo): TRegistration<T>; overload;
    function Implements(serviceType: PTypeInfo; const name: string): TRegistration<T>; overload;
    function Implements<TServiceType>: TRegistration<T>; overload;
    function Implements<TServiceType>(const name: string): TRegistration<T>; overload;

    function DelegateTo(const delegate: TActivatorDelegate<T>): TRegistration<T>; overload;

  {$REGION 'Typed Injections'}

    function InjectConstructor(const parameterTypes: array of PTypeInfo): TRegistration<T>; overload;
    function InjectProperty(const propertyName: string): TRegistration<T>; overload;
    function InjectMethod(const methodName: string): TRegistration<T>; overload;
    function InjectMethod(const methodName: string; const parameterTypes: array of PTypeInfo): TRegistration<T>; overload;
    function InjectField(const fieldName: string): TRegistration<T>; overload;

  {$ENDREGION}

  {$REGION 'Named/Valued Injections'}

    function InjectConstructor(const arguments: array of TValue): TRegistration<T>; overload;
    function InjectProperty(const propertyName: string; const value: TValue): TRegistration<T>; overload;
    function InjectMethod(const methodName: string; const arguments: array of TValue): TRegistration<T>; overload;
    function InjectField(const fieldName: string; const value: TValue): TRegistration<T>; overload;

  {$ENDREGION}

    function AsSingleton: TRegistration<T>; overload;
    function AsSingleton(refCounting: TRefCounting): TRegistration<T>; overload;
    function AsSingletonPerThread: TRegistration<T>;
    function AsTransient: TRegistration<T>;
    function AsPooled(minPoolSize, maxPoolSize: Integer): TRegistration<T>; {$IFDEF CPUARM}experimental;{$ENDIF}

    function AsDefault: TRegistration<T>; overload;
    function AsDefault(serviceType: PTypeInfo): TRegistration<T>; overload;
    function AsDefault<TServiceType>: TRegistration<T>; overload;

{$IFDEF DELPHIXE_UP}
    function AsFactory: TRegistration<T>; overload;
    function AsFactory(const name: string): TRegistration<T>; overload;
{$ENDIF}
  end;

  ///	<summary>
  ///	  Provides both generic and non-generic fluent-style registration
  ///	  methods.
  ///	</summary>
  ///	<remarks>
  ///	  Why both TRegistration and TRegistration(T) are defined as record and
  ///	  their constructors are private, is to provide generic and non-generic
  ///	  fluent-style registration with only necessary methods.
  ///	</remarks>
  TRegistrationManager = class
  private
    fRegistry: IComponentRegistry;
  public
    constructor Create(const registry: IComponentRegistry);
    function RegisterComponent<TComponentType>: TRegistration<TComponentType>; overload;
    function RegisterComponent(componentType: PTypeInfo): TRegistration; overload;
  end;


implementation

uses
  SysUtils,
  TypInfo,
  Spring.Collections.Extensions,
  Spring.Collections.Lists,
  Spring.Container.Resolvers,
  Spring.Container.ResourceStrings,
  Spring.Helpers,
  Spring.Reflection;


{$REGION 'TComponentRegistry'}

constructor TComponentRegistry.Create(const kernel: IKernel);
begin
  Guard.CheckNotNull(kernel, 'kernel');
  inherited Create;
  fKernel := kernel;
  fRttiContext := TRttiContext.Create;
  fModels := TCollections.CreateObjectList<TComponentModel>(True);
  fDefaultRegistrations := TCollections.CreateDictionary<PTypeInfo, TComponentModel>;
  fUnnamedRegistrations := TCollections.CreateDictionary<PTypeInfo, IList<TComponentModel>>;
  fServiceTypeMappings := TCollections.CreateDictionary<PTypeInfo, IList<TComponentModel>>;
  fServiceNameMappings := TCollections.CreateDictionary<string, TComponentModel>;
end;

destructor TComponentRegistry.Destroy;
begin
  fRttiContext.Free;
  inherited Destroy;
end;

function TComponentRegistry.BuildActivatorDelegate(elementTypeInfo: PTypeInfo;
  out componentType: TRttiType): TActivatorDelegate;
begin
  case elementTypeInfo.Kind of
    tkClass:
    begin
      componentType := fRttiContext.GetType(TypeInfo(TList<TObject>));
      Result :=
        function: TValue
        var
          list: TList<TObject>;
          value: TValue;
        begin
          list := TList<TObject>.Create;
          for value in fKernel.ServiceResolver.ResolveAll(elementTypeInfo) do
            list.Add(value.AsObject);
          Result := TValue.From<TList<TObject>>(list);
        end;
    end;
    tkInterface:
    begin
      componentType := fRttiContext.GetType(TypeInfo(TList<IInterface>));
      Result :=
        function: TValue
        var
          list: TList<IInterface>;
          value: TValue;
        begin
          list := TList<IInterface>.Create;
          for value in fKernel.ServiceResolver.ResolveAll(elementTypeInfo) do
            list.Add(value.AsInterface);
          Result := TValue.From<TList<IInterface>>(list);
        end;
    end
  else
    raise ERegistrationException.CreateResFmt(@SUnsupportedType, [componentType.Name]);
  end;
end;

procedure TComponentRegistry.CheckIsNonGuidInterface(serviceType: TRttiType);
begin
  if serviceType.IsInterface and not serviceType.AsInterface.HasGuid
    and not TType.IsDelegate(serviceType.Handle) then
  begin
    if serviceType.IsPublicType then
      raise ERegistrationException.CreateResFmt(@SMissingGuid, [serviceType.QualifiedName])
    else
      raise ERegistrationException.CreateResFmt(@SMissingGuid, [serviceType.Name]);
  end;
end;

procedure TComponentRegistry.Validate(componentType, serviceType: PTypeInfo;
  var serviceName: string);
var
  componentTypeObject: TRttiType;
  serviceTypeObject: TRttiType;
begin
  componentTypeObject := fRttiContext.GetType(componentType);
  serviceTypeObject := fRttiContext.GetType(serviceType);
  CheckIsNonGuidInterface(serviceTypeObject);
  if not TType.IsAssignable(componentType, serviceType)
    and not componentTypeObject.IsInterface then
    raise ERegistrationException.CreateResFmt(@SIncompatibleTypes, [
      GetTypeName(componentType), GetTypeName(serviceType)]);
  if serviceName = '' then
    serviceName := serviceTypeObject.DefaultName + '@' + componentTypeObject.DefaultName;
  if HasService(serviceName) then
    raise ERegistrationException.CreateResFmt(@SDuplicatedName, [serviceName]);
end;

procedure TComponentRegistry.UnregisterAll;
begin
  fServiceNameMappings.Clear;
  fServiceTypeMappings.Clear;
  fDefaultRegistrations.Clear;
  fModels.Clear;
end;

procedure TComponentRegistry.RegisterService(const model: TComponentModel;
  serviceType: PTypeInfo);
begin
  RegisterService(model, serviceType, '');
end;

procedure TComponentRegistry.RegisterService(const model: TComponentModel;
  serviceType: PTypeInfo; const name: string);
var
  models: IList<TComponentModel>;
  serviceName: string;
begin
  Guard.CheckNotNull(model, 'model');
  Guard.CheckNotNull(serviceType, 'serviceType');

  serviceName := name;
  Validate(model.ComponentTypeInfo, serviceType, serviceName);
  model.Services[serviceName] := serviceType;
  if not fServiceTypeMappings.TryGetValue(serviceType, models) then
  begin
    models := TCollections.CreateList<TComponentModel>(False);
    fServiceTypeMappings.Add(serviceType, models);
  end;
  models.Add(model);
  fServiceNameMappings.Add(serviceName, model);
  if name = '' then
  begin
    RegisterDefault(model, serviceType);
    RegisterUnnamed(model, serviceType);
  end;
end;

procedure TComponentRegistry.RegisterUnnamed(const model: TComponentModel;
  serviceType: PTypeInfo);
var
  models: IList<TComponentModel>;
begin
  if not fUnnamedRegistrations.TryGetValue(serviceType, models) then
  begin
    models := TCollections.CreateList<TComponentModel>(False);
    fUnnamedRegistrations.Add(serviceType, models);
  end;
  models.Add(model);
end;

procedure TComponentRegistry.RegisterDefault(const model: TComponentModel;
  serviceType: PTypeInfo);
begin
  if not model.HasService(serviceType) then
    raise ERegistrationException.CreateResFmt(@SMissingServiceType,
      [GetTypeName(serviceType)]);
  fDefaultRegistrations.AddOrSetValue(serviceType, model);
end;

{$IFDEF DELPHIXE_UP}
type
  TVirtualInterfaceHack = class(TInterfacedObject)
  private
    type
    {$POINTERMATH ON}
      PVTable = ^Pointer;
    {$POINTERMATH OFF}
    var VTable: PVTable;
  end;

procedure TComponentRegistry.InternalRegisterFactory(
  const model: TComponentModel; const invokeEvent: TVirtualInterfaceInvokeEvent);
var
  methods: TArray<TRttiMethod>;
  maxVirtualIndex: SmallInt;
  method: TRttiMethod;
begin
  methods := model.ComponentType.GetMethods;
  if not (TType.IsDelegate(model.ComponentTypeInfo) and (Length(methods) = 1)
    and Assigned(methods[0].ReturnType)) then
    raise ERegistrationException.CreateResFmt(@SUnsupportedFactoryType, [
      model.ComponentType.DefaultName]);

  maxVirtualIndex := 2;
  for method in methods do
    if maxVirtualIndex < method.VirtualIndex then
      maxVirtualIndex := method.VirtualIndex;

  model.ActivatorDelegate :=
    function: TValue
    var
      factory: TVirtualInterface;
      intf: IInterface;
    begin
      factory := TVirtualInterface.Create(model.ComponentTypeInfo, invokeEvent);
      if maxVirtualIndex > 3 then
        TVirtualInterfaceHack(factory).VTable[3] :=
          TVirtualInterfaceHack(factory).VTable[maxVirtualIndex];
      factory.QueryInterface(GetTypeData(model.ComponentTypeInfo).Guid, intf);
      TValue.Make(@intf, model.ComponentTypeInfo, Result);
    end;
end;

procedure TComponentRegistry.RegisterFactory(const model: TComponentModel);
var
  invokeEvent: TVirtualInterfaceInvokeEvent;
begin
  invokeEvent :=
    procedure(method: TRttiMethod; const args: TArray<TValue>; out result: TValue)
    var
      dependencyOverrides: TArray<TDependencyOverride>;
      resolverOverride: IResolverOverride;
      i: Integer;
    begin
      SetLength(dependencyOverrides, Length(args) - 1);
      for i := 1 to High(args) do
        dependencyOverrides[i - 1] := TDependencyOverride.Create(args[i].TypeInfo, args[i]);
      resolverOverride := TDependencyOverrides.Create(dependencyOverrides);
      result := fKernel.ServiceResolver.Resolve(method.ReturnType.Handle, resolverOverride)
    end;

  InternalRegisterFactory(model, invokeEvent);
end;

procedure TComponentRegistry.RegisterFactory(const model: TComponentModel;
  const name: string);
var
  invokeEvent: TVirtualInterfaceInvokeEvent;
begin
  invokeEvent :=
    procedure(method: TRttiMethod; const args: TArray<TValue>; out result: TValue)
    var
      dependencyOverrides: TArray<TDependencyOverride>;
      resolverOverride: IResolverOverride;
      i: Integer;
    begin
      SetLength(dependencyOverrides, Length(args) - 1);
      for i := 1 to High(args) do
        dependencyOverrides[i - 1] := TDependencyOverride.Create(args[i].TypeInfo, args[i]);
      resolverOverride := TDependencyOverrides.Create(dependencyOverrides);
      result := fKernel.ServiceResolver.Resolve(name, resolverOverride);
    end;

  InternalRegisterFactory(model, invokeEvent);
end;
{$ENDIF}

function TComponentRegistry.RegisterComponent(
  componentTypeInfo: PTypeInfo): TComponentModel;
var
  componentType: TRttiType;
  elementTypeInfo: PTypeInfo;
  activatorDelegate: TActivatorDelegate;
begin
  Guard.CheckNotNull(componentTypeInfo, 'componentTypeInfo');

  componentType := fRttiContext.GetType(componentTypeInfo);
  if componentType.IsDynamicArray then
  begin
    elementTypeInfo := componentType.AsDynamicArray.ElementType.Handle;
    activatorDelegate := BuildActivatorDelegate(elementTypeInfo, componentType);
  end;
  Result := TComponentModel.Create(fKernel, componentType);
  Result.ActivatorDelegate := activatorDelegate;
  fModels.Add(Result);
end;

function TComponentRegistry.FindOne(const name: string): TComponentModel;
begin
  fServiceNameMappings.TryGetValue(name, Result);
end;

function TComponentRegistry.FindOne(componentType: PTypeInfo): TComponentModel;
begin
  Guard.CheckNotNull(componentType, 'componentType');

  Result := fModels.FirstOrDefault(
    function(const model: TComponentModel): Boolean
    begin
      Result := model.ComponentTypeInfo = componentType;
    end);
end;

function TComponentRegistry.FindOne(serviceType: PTypeInfo;
  const argument: TValue): TComponentModel;
var
  name: string;
begin
  if argument.IsEmpty then
  begin
    if not HasService(serviceType) then
    begin
      if (serviceType.Kind in [tkClass, tkInterface]) and not TType.IsLazy(serviceType) then
        raise EResolveException.CreateResFmt(
          @SCannotResolveDependency, [serviceType.TypeName]);
      Result := nil;
    end
    else
    begin
      Result := FindDefault(serviceType);
      if not Assigned(Result) then
        raise EUnsatisfiedDependencyException.CreateResFmt(
          @SUnsatisfiedDependency, [serviceType.TypeName]);
    end;
  end
  else
  begin
    name := argument.AsString;
    Result := FindOne(name);
    if not Assigned(Result) then
      if TType.IsLazy(serviceType) then
        Exit
      else
        raise EResolveException.CreateResFmt(@SInvalidServiceName, [name]);
    if not Result.HasService(serviceType) then
      if not TType.IsLazy(serviceType) then
        raise EResolveException.CreateResFmt(
          @SCannotResolveDependency, [serviceType.TypeName])
      else
        Result := nil;
  end;
end;

function TComponentRegistry.FindDefault(
  serviceType: PTypeInfo): TComponentModel;
var
  models: IList<TComponentModel>;
begin
  Guard.CheckNotNull(serviceType, 'serviceType');

  if not fDefaultRegistrations.TryGetValue(serviceType, Result)
    and fServiceTypeMappings.TryGetValue(serviceType, models)
    and (models.Count = 1) then
  begin
    Result := models[0];
  end;
end;

function TComponentRegistry.FindAll: IEnumerable<TComponentModel>;
begin
  Result := fModels;
end;

function TComponentRegistry.FindAll(
  serviceType: PTypeInfo): IEnumerable<TComponentModel>;
var
  models: IList<TComponentModel>;
  unnamedModels: IList<TComponentModel>;
begin
  Guard.CheckNotNull(serviceType, 'serviceType');

  if fServiceTypeMappings.TryGetValue(serviceType, models) then
  begin
    if fUnnamedRegistrations.TryGetValue(serviceType, unnamedModels) then
      Result := TExceptIterator<TComponentModel>.Create(models, unnamedModels)
    else
      Result := models;
  end
  else
    Result := TCollections.CreateList<TComponentModel>(False);
end;

function TComponentRegistry.HasService(serviceType: PTypeInfo): Boolean;
begin
  Guard.CheckNotNull(serviceType, 'serviceType');

  Result := fServiceTypeMappings.ContainsKey(serviceType);
end;

function TComponentRegistry.HasService(const name: string): Boolean;
begin
  Result := fServiceNameMappings.ContainsKey(name);
end;

function TComponentRegistry.HasService(serviceType: PTypeInfo;
  const name: string): Boolean;
var
  model: TComponentModel;
begin
  Guard.CheckNotNull(serviceType, 'serviceType');

  Result := fServiceNameMappings.TryGetValue(name, model) and
    model.HasService(serviceType);
end;

function TComponentRegistry.HasDefault(serviceType: PTypeInfo): Boolean;
var
  models: IList<TComponentModel>;
begin
  Result := fDefaultRegistrations.ContainsKey(serviceType)
    or (fServiceTypeMappings.TryGetValue(serviceType, models)
    and (models.Count = 1));
end;

{$ENDREGION}


{$REGION 'TRegistration'}

constructor TRegistration.Create(const registry: IComponentRegistry;
  componentType: PTypeInfo);
begin
  Guard.CheckNotNull(registry, 'registry');
  Guard.CheckNotNull(componentType, 'componentType');
{$IFNDEF DELPHIXE_UP}
  fRegistry := registry as TComponentRegistry;
{$ELSE}
  fRegistry := registry;
{$ENDIF}
  fModel := fRegistry.RegisterComponent(componentType);
end;

function TRegistration.Implements(serviceType: PTypeInfo): TRegistration;
begin
  fRegistry.RegisterService(fModel, serviceType);
  Result := Self;
end;

function TRegistration.Implements(serviceType: PTypeInfo;
  const name: string): TRegistration;
begin
  fRegistry.RegisterService(fModel, serviceType, name);
  Result := Self;
end;

function TRegistration.DelegateTo(const delegate: TActivatorDelegate): TRegistration;
begin
  fModel.ActivatorDelegate := delegate;
  Result := Self;
end;

function TRegistration.InjectConstructor(
  const parameterTypes: array of PTypeInfo): TRegistration;
begin
  fModel.InjectConstructor(parameterTypes);
  Result := Self;
end;

function TRegistration.InjectProperty(
  const propertyName: string): TRegistration;
begin
  fModel.InjectProperty(propertyName);
  Result := Self;
end;

function TRegistration.InjectMethod(const methodName: string;
  const parameterTypes: array of PTypeInfo): TRegistration;
begin
  fModel.InjectMethod(methodName, parameterTypes);
  Result := Self;
end;

function TRegistration.InjectMethod(const methodName: string): TRegistration;
begin
  fModel.InjectMethod(methodName);
  Result := Self;
end;

function TRegistration.InjectField(const fieldName: string): TRegistration;
begin
  fModel.InjectField(fieldName);
  Result := Self;
end;

function TRegistration.InjectConstructor(
  const arguments: array of TValue): TRegistration;
begin
  fModel.InjectConstructor(arguments);
  Result := Self;
end;

function TRegistration.InjectProperty(const propertyName: string;
  const value: TValue): TRegistration;
begin
  fModel.InjectProperty(propertyName, value);
  Result := Self;
end;

function TRegistration.InjectMethod(const methodName: string;
  const arguments: array of TValue): TRegistration;
begin
  fModel.InjectMethod(methodName, arguments);
  Result := Self;
end;

function TRegistration.InjectField(const fieldName: string;
  const value: TValue): TRegistration;
begin
  fModel.InjectField(fieldName, value);
  Result := Self;
end;

function TRegistration.AsSingleton: TRegistration;
begin
  Result := AsSingleton(TRefCounting.Unknown);
end;

function TRegistration.AsSingleton(refCounting: TRefCounting): TRegistration;
begin
  if (refCounting = TRefCounting.True) and fModel.ComponentType.IsInstance
    and not Supports(fModel.ComponentType.AsInstance.MetaclassType, IInterface) then
    raise ERegistrationException.CreateResFmt(@SMissingInterface, [fModel.ComponentType.Name]);
  fModel.LifetimeType := TLifetimeType.Singleton;
  fModel.RefCounting := refCounting;
  Result := Self;
end;

function TRegistration.AsSingletonPerThread: TRegistration;
begin
  fModel.LifetimeType := TLifetimeType.SingletonPerThread;
  Result := Self;
end;

function TRegistration.AsTransient: TRegistration;
begin
  fModel.LifetimeType := TLifetimeType.Transient;
  Result := Self;
end;

function TRegistration.AsPooled(minPoolSize, maxPoolSize: Integer): TRegistration;
begin
  fModel.LifetimeType := TLifetimeType.Pooled;
  fModel.MinPoolsize := minPoolSize;
  fModel.MaxPoolsize := maxPoolSize;
  Result := Self;
end;

function TRegistration.AsDefault: TRegistration;
var
  serviceType: PTypeInfo;
begin
  for serviceType in fModel.Services.Values do
    fRegistry.RegisterDefault(fModel, serviceType);
  Result := Self;
end;

function TRegistration.AsDefault(serviceType: PTypeInfo): TRegistration;
begin
  fRegistry.RegisterDefault(fModel, serviceType);
  Result := Self;
end;

{$IFDEF DELPHIXE_UP}
function TRegistration.AsFactory: TRegistration;
begin
  fRegistry.RegisterFactory(fModel);
  Result := Self;
end;

function TRegistration.AsFactory(const name: string): TRegistration;
begin
  fRegistry.RegisterFactory(fModel, name);
  Result := Self;
end;
{$ENDIF}

{$ENDREGION}


{$REGION 'TRegistration<T>'}

constructor TRegistration<T>.Create(
  const registry: IComponentRegistry);
begin
  fRegistration := TRegistration.Create(registry, TypeInfo(T));
end;

function TRegistration<T>.Implements(serviceType: PTypeInfo): TRegistration<T>;
begin
  fRegistration.Implements(serviceType);
  Result := Self;
end;

function TRegistration<T>.Implements(serviceType: PTypeInfo;
  const name: string): TRegistration<T>;
begin
  fRegistration.Implements(serviceType, name);
  Result := Self;
end;

function TRegistration<T>.Implements<TServiceType>: TRegistration<T>;
begin
  Result := Implements(TypeInfo(TServiceType));
end;

function TRegistration<T>.Implements<TServiceType>(
  const name: string): TRegistration<T>;
begin
  Result := Implements(TypeInfo(TServiceType), name);
end;

function TRegistration<T>.DelegateTo(
  const delegate: TActivatorDelegate<T>): TRegistration<T>;
begin
  fRegistration.DelegateTo(
    function: TValue
    begin
      Result := TValue.From<T>(delegate());
    end);
  Result := Self;
end;

function TRegistration<T>.InjectConstructor(
  const parameterTypes: array of PTypeInfo): TRegistration<T>;
begin
  fRegistration.InjectConstructor(parameterTypes);
  Result := Self;
end;

function TRegistration<T>.InjectProperty(
  const propertyName: string): TRegistration<T>;
begin
  fRegistration.InjectProperty(propertyName);
  Result := Self;
end;

function TRegistration<T>.InjectMethod(const methodName: string;
  const parameterTypes: array of PTypeInfo): TRegistration<T>;
begin
  fRegistration.InjectMethod(methodName, parameterTypes);
  Result := Self;
end;

function TRegistration<T>.InjectMethod(
  const methodName: string): TRegistration<T>;
begin
  fRegistration.InjectMethod(methodName);
  Result := Self;
end;

function TRegistration<T>.InjectField(
  const fieldName: string): TRegistration<T>;
begin
  fRegistration.InjectField(fieldName);
  Result := Self;
end;

function TRegistration<T>.InjectConstructor(
  const arguments: array of TValue): TRegistration<T>;
begin
  fRegistration.InjectConstructor(arguments);
  Result := Self;
end;

function TRegistration<T>.InjectProperty(const propertyName: string;
  const value: TValue): TRegistration<T>;
begin
  fRegistration.InjectProperty(propertyName, value);
  Result := Self;
end;

function TRegistration<T>.InjectMethod(const methodName: string;
  const arguments: array of TValue): TRegistration<T>;
begin
  fRegistration.InjectMethod(methodName, arguments);
  Result := Self;
end;

function TRegistration<T>.InjectField(const fieldName: string;
  const value: TValue): TRegistration<T>;
begin
  fRegistration.InjectField(fieldName, value);
  Result := Self;
end;

function TRegistration<T>.AsSingleton: TRegistration<T>;
begin
  fRegistration.AsSingleton;
  Result := Self;
end;

function TRegistration<T>.AsSingleton(refCounting: TRefCounting): TRegistration<T>;
begin
  fRegistration.AsSingleton(refCounting);
  Result := Self;
end;

function TRegistration<T>.AsSingletonPerThread: TRegistration<T>;
begin
  fRegistration.AsSingletonPerThread;
  Result := Self;
end;

function TRegistration<T>.AsTransient: TRegistration<T>;
begin
  fRegistration.AsTransient;
  Result := Self;
end;

function TRegistration<T>.AsPooled(minPoolSize, maxPoolSize: Integer): TRegistration<T>;
begin
{$WARN SYMBOL_EXPERIMENTAL OFF}
  fRegistration.AsPooled(minPoolSize, maxPoolSize);
{$WARN SYMBOL_EXPERIMENTAL ON}
  Result := Self;
end;

function TRegistration<T>.AsDefault: TRegistration<T>;
begin
  fRegistration.AsDefault;
  Result := Self;
end;

function TRegistration<T>.AsDefault(serviceType: PTypeInfo): TRegistration<T>;
begin
  fRegistration.AsDefault(serviceType);
  Result := Self;
end;

function TRegistration<T>.AsDefault<TServiceType>: TRegistration<T>;
begin
  Result := AsDefault(TypeInfo(TServiceType));
end;

{$IFDEF DELPHIXE_UP}
function TRegistration<T>.AsFactory: TRegistration<T>;
begin
  fRegistration.AsFactory;
  Result := Self;
end;

function TRegistration<T>.AsFactory(const name: string): TRegistration<T>;
begin
  fRegistration.AsFactory(name);
  Result := Self;
end;
{$ENDIF}

{$ENDREGION}


{$REGION 'TRegistrationManager'}

constructor TRegistrationManager.Create(
  const registry: IComponentRegistry);
begin
  inherited Create;
  fRegistry := registry;
end;

function TRegistrationManager.RegisterComponent(
  componentType: PTypeInfo): TRegistration;
begin
  Guard.CheckNotNull(componentType, 'componentType');
  Result := TRegistration.Create(fRegistry, componentType);
end;

function TRegistrationManager.RegisterComponent<TComponentType>: TRegistration<TComponentType>;
begin
  Result := TRegistration<TComponentType>.Create(fRegistry);
end;

{$ENDREGION}


end.

