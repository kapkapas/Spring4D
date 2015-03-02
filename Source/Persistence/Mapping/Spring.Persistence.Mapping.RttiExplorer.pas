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

{$I Spring.inc}

unit Spring.Persistence.Mapping.RttiExplorer;

interface

uses
  Rtti,
  TypInfo,
  SysUtils,
  Spring.Persistence.Core.Reflection,
  Spring,
  Spring.Collections,
  Spring.Persistence.Core.EntityCache,
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Mapping.Attributes;

type
  TRttiCache = class
  private
    FFields: IDictionary<string,TRttiField>;
    FProperties: IDictionary<string,TRttiProperty>;
    FTypes: IDictionary<PTypeInfo,TRttiType>;
    FTypeFields: IDictionary<PTypeInfo,IList<TRttiField>>;
    FCtx: TRttiContext;
  protected
    function GetKey(AClass: TClass; const AName: string): string;
  public
    constructor Create; virtual;

    procedure Clear;
    procedure RebuildCache; virtual;

    function GetField(AClass: TClass; const AFieldName: string): TRttiField;
    function GetProperty(AClass: TClass; const APropertyName: string): TRttiProperty;
    function GetNamedObject(AClass: TClass; const AMemberName: string): TRttiNamedObject;
    function GetType(ATypeInfo: PTypeInfo): TRttiType; overload;
    function GetType(AClass: TClass): TRttiType; overload;
    function GetFieldsOfType(ATypeInfo: PTypeInfo): IList<TRttiField>;
  end;

  TRttiExplorer = class
  private
    class var FCtx: TRttiContext;
    class var FRttiCache: TRttiCache;
  protected
    class constructor Create;
    class destructor Destroy;
  private
    class function GetNamedObject(AClass: TClass; const APropertyName: string): TRttiNamedObject;
  public
    class procedure CopyFieldValues(const source, target: TObject);

    class function Clone(entity: TObject): TObject;
    class function CreateExternalType(AClass: TClass; const Args: array of TValue): TObject;
    class function GetAttributeOfClass(ARttiObject: TRttiObject; AClass: TClass): TCustomAttribute; overload;
    class function GetAttributeOfClass<T: TCustomAttribute>(ARttiObject: TRttiObject): T; overload;
    class function GetAutoGeneratedColumnMemberName(AClass: TClass): string;
    class function GetClassAttribute<T: TORMAttribute>(AClass: TClass; ARecursive: Boolean = False): T;
    class function GetClassFromClassInfo(AClassInfo: PTypeInfo): TClass;
    class function GetClassMembers<T: TORMAttribute>(AClass: TClass): IList<T>; overload;
    class function GetColumnIsIdentity(AClass: TClass; AColumn: ColumnAttribute): Boolean;
    class function GetColumns(AClass: TClass): IList<ColumnAttribute>; overload;
    class function GetEntities: IList<TClass>;
    class function GetEntityClass(classInfo: PTypeInfo): TClass;
    class function GetEntityRttiType(ATypeInfo: PTypeInfo): TRttiType;
    class function GetForeignKeyColumn(AClass: TClass; const ABaseTable : TableAttribute; const ABaseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute;
    class function GetLastGenericArgumentType(ATypeInfo: PTypeInfo): TRttiType;
    class function GetMemberValue(AEntity: TObject; const AMember: TRttiNamedObject): TValue; overload;
    class function GetMemberValue(AEntity: TObject; const AMemberName: string): TValue; overload;
    class function GetMemberValue(AEntity: TObject; const AMembername: string; out ARttiMember: TRttiNamedObject): TValue; overload;
    class function GetMemberValueDeep(AEntity: TObject; const AMemberName: string): TValue; overload;
    class function GetMemberValueDeep(const AInitialValue: TValue): TValue; overload;
    class function GetMethodSignature(AMethod: TRttiMethod): string;
    class function GetPrimaryKeyColumn(AClass: TClass): ColumnAttribute;
    class function GetQueryTextFromMethod(AMethod: TRttiMethod): string;
    class function GetRawPointer(const AInstance: TValue): Pointer;
    class function GetRelationsOf(AEntity: TObject; relationAttributeClass: TAttributeClass): IList<TObject>;
    class function GetSequence(AClass: TClass): SequenceAttribute;
    class function GetSubEntityFromMemberDeep(AEntity: TObject; ARttiMember: TRttiNamedObject): IList<TObject>;
    class function GetTable(AClass: TClass): TableAttribute; overload;
    class function GetTable(AClassInfo: PTypeInfo): TableAttribute; overload;
    class function GetUniqueConstraints(AClass: TClass): IList<UniqueConstraint>;
    class function HasColumns(AClass: TClass): Boolean;
    class function HasInstanceField(AClass: TClass): Boolean;
    class function HasSequence(AClass: TClass): Boolean;
    class function InheritsFrom(AObjectInfo: TClass; AFromObjectInfo: PTypeInfo): Boolean;
    class function TryGetColumnAsForeignKey(AColumn: ColumnAttribute; out AForeignKeyCol: ForeignJoinColumnAttribute): Boolean;
    class function TryGetMethod(ATypeInfo: PTypeInfo; const AMethodName: string; out AAddMethod: TRttiMethod; AParamCount: Integer = 1): Boolean;

    class property RttiCache: TRttiCache read FRttiCache;
  end;

implementation

uses
  Classes,
  Math,
  StrUtils,
  Spring.Persistence.Core.Exceptions,
  Spring.Persistence.Core.Utils,
  Spring.Reflection;


{$REGION 'TRttiExplorer'}

class constructor TRttiExplorer.Create;
begin
  FRttiCache := TRttiCache.Create;
  FRttiCache.RebuildCache;
end;

class destructor TRttiExplorer.Destroy;
begin
  FRttiCache.Free;
end;

class function TRttiExplorer.Clone(entity: TObject): TObject;
begin
  Assert(Assigned(entity));
  Result := TActivator.CreateInstance(entity.ClassType);
  CopyFieldValues(entity, Result);
end;

class procedure TRttiExplorer.CopyFieldValues(const source, target: TObject);
var
  field: TRttiField;
  value: TValue;
  sourceObject, targetObject: TObject;
begin
  Assert(Assigned(source) and Assigned(target));
  Assert(source.ClassType = target.ClassType);

  for field in TType.GetType(source.ClassInfo).GetFields do
  begin
    if field.FieldType.IsInstance then
    begin
      sourceObject := field.GetValue(source).AsObject;
      if not Assigned(sourceObject) then
        Continue;
      targetObject := field.GetValue(target).AsObject;
      if not Assigned(targetObject) then
        targetObject := TActivator.CreateInstance(sourceObject.ClassType);
      if targetObject is TPersistent then
        TPersistent(targetObject).Assign(sourceObject as TPersistent)
      else
        CopyFieldValues(sourceObject, targetObject);
      value := targetObject;
    end
    else
      value := field.GetValue(source);

    field.SetValue(target, value);
  end;
end;

class function TRttiExplorer.CreateExternalType(AClass: TClass;
  const Args: array of TValue): TObject;
var
  LMethod: TRttiMethod;
  LType: TRttiType;
begin
  Result := nil;
  LType := TRttiContext.Create.GetType(AClass);
  for LMethod in LType.GetMethods do
  begin
    if (LMethod.IsConstructor) and (Length(LMethod.GetParameters) = Length(Args)) then
    begin
      Result := LMethod.Invoke(LType.AsInstance.MetaclassType, Args).AsObject;
      Break;
    end;
  end;
end;

class function TRttiExplorer.GetAttributeOfClass(ARttiObject: TRttiObject;
  AClass: TClass): TCustomAttribute;
var
  LAttribute: TCustomAttribute;
begin
  for LAttribute in ARttiObject.GetAttributes do
  begin
    if LAttribute.InheritsFrom(AClass) then
    begin
      Exit(LAttribute);
    end;
  end;
  Result := nil;
end;

class function TRttiExplorer.GetAttributeOfClass<T>(
  ARttiObject: TRttiObject): T;
begin
  Result := T(GetAttributeOfClass(ARttiObject, TClass(T)));
end;

class function TRttiExplorer.GetAutoGeneratedColumnMemberName(AClass: TClass): string;
var
  LIds: IList<AutoGenerated>;
begin
  Result := '';

  LIds := GetClassMembers<AutoGenerated>(AClass);
  if LIds.Any then
  begin
    Result := LIds.First.MemberName;
  end;
end;

class function TRttiExplorer.GetClassAttribute<T>(AClass: TClass; ARecursive: Boolean): T;
var
  LAttr: TCustomAttribute;
  LTypeInfo: Pointer;
  LType: TRttiType;
  LClass: TClass;
begin
  LTypeInfo := TypeInfo(T);
  LClass := AClass;
  repeat
    LType := FRttiCache.GetType(LClass);
    for LAttr in LType.GetAttributes do
    begin
      if (LAttr.ClassInfo = LTypeInfo) then
      begin
        Exit(T(LAttr));
      end;
    end;

    if ARecursive then
      LClass := LClass.ClassParent
    else
      LClass := nil;
  until (LClass = nil);
  Result := nil;
end;

class function TRttiExplorer.GetClassFromClassInfo(AClassInfo: PTypeInfo): TClass;
var
  LType: TRttiType;
begin
  LType := FRttiCache.GetType(AClassInfo);
  Assert(LType.IsInstance);
  Result := LType.AsInstance.MetaclassType;
end;

class function TRttiExplorer.GetClassMembers<T>(AClass: TClass): IList<T>;
var
  LType: TRttiType;
  LField: TRttiField;
  LProp: TRttiProperty;
  LAttr: TCustomAttribute;
  LTypeInfo: Pointer;
begin
  Result := TCollections.CreateList<T>;
  LType := FRttiCache.GetType(AClass);
  LTypeInfo := TypeInfo(T);

  for LAttr in LType.GetAttributes do
  begin
    if LAttr is TORMAttribute then
    begin
      TORMAttribute(LAttr).MemberName := LType.Name;
      TORMAttribute(LAttr).EntityType := LType.Handle;
      TORMAttribute(LAttr).MemberKind := mkClass;
    end;
  end;

  for LField in LType.GetFields do
  begin
    for LAttr in LField.GetAttributes do
    begin
      if (LTypeInfo = LAttr.ClassInfo) or (InheritsFrom(LAttr.ClassType, LTypeInfo)) then
      begin
        TORMAttribute(LAttr).MemberKind := mkField;
        TORMAttribute(LAttr).MemberName := LField.Name;
        TORMAttribute(LAttr).EntityType := LType.Handle;
        TORMAttribute(LAttr).RttiMember := LField;
        Result.Add(T(LAttr));
      end;
    end;
  end;

  for LProp in LType.GetProperties do
  begin
    for LAttr in LProp.GetAttributes do
    begin
      if (LTypeInfo = LAttr.ClassInfo) or (InheritsFrom(LAttr.ClassType, LTypeInfo)) then
      begin
        TORMAttribute(LAttr).MemberKind := mkProperty;
        TORMAttribute(LAttr).MemberName := LProp.Name;
        TORMAttribute(LAttr).EntityType := LType.Handle;
        TORMAttribute(LAttr).RttiMember := LProp;
        Result.Add(T(LAttr));
      end;
    end;
  end;
end;

class function TRttiExplorer.GetColumnIsIdentity(AClass: TClass; AColumn: ColumnAttribute): Boolean;
begin
  Result := SameText(GetAutoGeneratedColumnMemberName(AClass), AColumn.MemberName);
end;

class function TRttiExplorer.GetColumns(AClass: TClass): IList<ColumnAttribute>;
begin
  Result := GetClassMembers<ColumnAttribute>(AClass);
end;

class function TRttiExplorer.TryGetMethod(ATypeInfo: PTypeInfo; const AMethodName: string
  ; out AAddMethod: TRttiMethod; AParamCount: Integer): Boolean;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LType := FCtx.GetType(ATypeInfo);
  for LMethod in LType.GetMethods do
  begin
    if SameText(LMethod.Name, AMethodName) and (Length(LMethod.GetParameters) = AParamCount) then
    begin
      AAddMethod := LMethod;
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TRttiExplorer.TryGetColumnAsForeignKey(AColumn: ColumnAttribute;
  out AForeignKeyCol: ForeignJoinColumnAttribute): Boolean;
var
  LNamedObject: TRttiNamedObject;
  LCustomAttribute: TCustomAttribute;
begin
  Result := False;
  LCustomAttribute := nil;

  LNamedObject := FRttiCache.GetNamedObject(AColumn.BaseEntityClass, AColumn.MemberName);
  if Assigned(LNamedObject) then
  begin
    LCustomAttribute := GetAttributeOfClass(LNamedObject, ForeignJoinColumnAttribute);
    Result := Assigned(LCustomAttribute);
  end;

  if Result then
    AForeignKeyCol := LCustomAttribute as ForeignJoinColumnAttribute;
end;

class function TRttiExplorer.GetEntities: IList<TClass>;
var
  LType: TRttiType;
  LClass: TClass;
  LEntity: EntityAttribute;
begin
  Result := TCollections.CreateList<TClass>;

  for LType in FCtx.GetTypes do
  begin
    if LType.IsInstance then
    begin
      LClass := LType.AsInstance.MetaclassType;
      LEntity := GetClassAttribute<EntityAttribute>(LClass);
      if Assigned(LEntity) then
      begin
        Result.Add(LClass);
      end;
    end;
  end;
end;

class function TRttiExplorer.GetEntityClass(classInfo: PTypeInfo): TClass;
var
  LRttiType: TRttiType;
begin
  LRttiType := GetEntityRttiType(classInfo);
  if not Assigned(LRttiType) then
    raise EORMUnsupportedType.CreateFmt('Unsupported type %s', [classInfo.NameFld.ToString]);

  Result := LRttiType.AsInstance.MetaclassType;
end;

class function TRttiExplorer.GetEntityRttiType(ATypeInfo: PTypeInfo): TRttiType;
var
  LRttiType: TRttiType;
  LCurrType: TRttiType;
  LEntityData: TEntityData;
begin
  LRttiType := FRttiCache.GetType(ATypeInfo);
  if LRttiType = nil then
    raise EORMUnsupportedType.CreateFmt('Cannot get type information from %s', [ATypeInfo.NameFld.ToString]);

  for LCurrType in LRttiType.GetGenericArguments do
  begin
    if LCurrType.IsInstance then
      Exit(LCurrType);
  end;

  if not LRttiType.IsInstance then
    raise EORMUnsupportedType.CreateFmt('%s is not an instance type.', [ATypeInfo.NameFld.ToString]);

  LEntityData := TEntityCache.Get(LRttiType.AsInstance.MetaclassType);
  if not LEntityData.IsTableEntity then
    raise EORMUnsupportedType.CreateFmt('Type %s lacks [Table] attribute', [ATypeInfo.NameFld.ToString]);

  if not LEntityData.HasPrimaryKey then
    raise EORMUnsupportedType.CreateFmt('Type %s lacks primary key [Column]', [ATypeInfo.NameFld.ToString]);

  Result := LRttiType;
end;

class function TRttiExplorer.GetForeignKeyColumn(AClass: TClass;
  const ABaseTable : TableAttribute;
  const ABaseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute;
var
  LForeignCol: ForeignJoinColumnAttribute;
begin
  for LForeignCol in TEntityCache.Get(AClass).ForeignColumns do
  begin
    if SameText(ABaseTablePrimaryKeyColumn.ColumnName, LForeignCol.ReferencedColumnName) and
       SameText(ABaseTable.TableName, LForeignCol.ReferencedTableName) then
    begin
      Exit(LForeignCol);
    end;
  end;
  Result := nil;
end;

class function TRttiExplorer.GetLastGenericArgumentType(ATypeInfo: PTypeInfo): TRttiType;
var
  LArgs: TArray<TRttiType>;
begin
  Result := FRttiCache.GetType(ATypeInfo);
  LArgs := Result.GetGenericArguments;
  if Length(LArgs) > 0 then
  begin
    Result := LArgs[High(LArgs)];
  end;
end;

class function TRttiExplorer.GetPrimaryKeyColumn(AClass: TClass): ColumnAttribute;
var
  LColumns: IList<ColumnAttribute>;
  LCol: ColumnAttribute;
begin
  LColumns := GetColumns(AClass);
  for LCol in LColumns do
  begin
    if (cpPrimaryKey in LCol.Properties) then
    begin
      Exit(LCol);
    end;
  end;
  Result := nil;
end;

class function TRttiExplorer.GetQueryTextFromMethod(
  AMethod: TRttiMethod): string;
var
  LAttr: TCustomAttribute;
  LQueryAttribute: QueryAttribute;
begin
  Result := '';
  for LAttr in AMethod.GetAttributes do
  begin
    if LAttr is QueryAttribute then
    begin
      LQueryAttribute := QueryAttribute(LAttr);
      Result := LQueryAttribute.QueryText;
      Exit;
    end;
  end;
end;

class function TRttiExplorer.GetRawPointer(const AInstance: TValue): Pointer;
begin
  if AInstance.IsObject then
    Result := AInstance.AsObject
  else
    Result := AInstance.GetReferenceToRawData;
end;

class function TRttiExplorer.GetRelationsOf(AEntity: TObject; relationAttributeClass: TAttributeClass): IList<TObject>;
var
  LType: TRttiType;
  LField: TRttiField;
  LProperty: TRttiProperty;
  LEntities: IList<TObject>;
begin
  Result := TCollections.CreateList<TObject>;

  LType := FRttiCache.GetType(AEntity.ClassType);
  for LField in LType.GetFields do
  begin
    if LField.HasCustomAttribute(relationAttributeClass) then
    begin
      LEntities := GetSubEntityFromMemberDeep(AEntity, LField);
      if LEntities.Any then
        Result.AddRange(LEntities);
    end;
  end;

  for LProperty in LType.GetProperties do
  begin
    if LProperty.HasCustomAttribute(relationAttributeClass) then
    begin
      LEntities := GetSubEntityFromMemberDeep(AEntity, LProperty);
      if LEntities.Any then
        Result.AddRange(LEntities);
    end;
  end;
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMember: TRttiNamedObject): TValue;
begin
  if AMember is TRttiProperty then
    Result := TRttiProperty(AMember).GetValue(AEntity)
  else if AMember is TRttiField then
    Result := TRttiField(AMember).GetValue(AEntity)
  else
    Result := TValue.Empty;
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMemberName: string): TValue;
var
  LMember: TRttiNamedObject;
begin
  Result := GetMemberValue(AEntity, AMemberName, LMember);
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMembername: string;
  out ARttiMember: TRttiNamedObject): TValue;
begin
  ARttiMember := FRttiCache.GetNamedObject(AEntity.ClassType, AMembername);
  Result := GetMemberValue(AEntity, ARttiMember);
end;

class function TRttiExplorer.GetMemberValueDeep(
  const AInitialValue: TValue): TValue;
begin
  Result := AInitialValue;
  if IsNullable(Result.TypeInfo) then
  begin
    if not AInitialValue.TryGetNullableValue(Result) then
      Result := TValue.Empty;
  end
  else if TType.IsLazyType(Result.TypeInfo) then
    if not TUtils.TryGetLazyTypeValue(AInitialValue, Result) then
      Result := TValue.Empty;
end;

class function TRttiExplorer.GetMemberValueDeep(AEntity: TObject;
  const AMemberName: string): TValue;
var
  LMember: TRttiNamedObject;
begin
  Result := GetMemberValue(AEntity, AMemberName, LMember);

  if Result.IsEmpty then
    Exit;

  Result := GetMemberValueDeep(Result);
end;

class function TRttiExplorer.GetMethodSignature(AMethod: TRttiMethod): string;
begin
  Result := AMethod.ToString;
end;

class function TRttiExplorer.GetNamedObject(AClass: TClass;
  const APropertyName: string): TRttiNamedObject;
var
  LType: TRttiType;
begin
  LType := FCtx.GetType(AClass);
  Result := LType.GetField(APropertyName);
  if not Assigned(Result) then
    Result := LType.GetProperty(APropertyName);
end;

class function TRttiExplorer.HasInstanceField(AClass: TClass): Boolean;
var
  LField: TRttiField;
  LProp: TRttiProperty;
begin
  //enumerate fields
  for LField in FCtx.GetType(AClass).GetFields do
  begin
    if (LField.FieldType.IsInstance) then
    begin
      Exit(True);
    end;
  end;

  for LProp in FCtx.GetType(AClass).GetProperties do
  begin
    if (LProp.PropertyType.IsInstance) then
    begin
      Exit(True);
    end;
  end;

  Result := False;
end;

class function TRttiExplorer.GetSequence(AClass: TClass): SequenceAttribute;
begin
  Result := GetClassAttribute<SequenceAttribute>(AClass, True);
end;

class function TRttiExplorer.GetSubEntityFromMemberDeep(AEntity: TObject; ARttiMember: TRttiNamedObject): IList<TObject>;
var
  LMemberValue: TValue;
  LDeepValue: TValue;
  LObjectList: IObjectList;
  LCurrent: TObject;
begin
  Result := TCollections.CreateList<TObject>;

  LMemberValue := GetMemberValue(AEntity, ARttiMember);
  if LMemberValue.IsEmpty then
    Exit;
    
  LDeepValue := GetMemberValueDeep(LMemberValue);
  if LDeepValue.IsEmpty then
    Exit;
  
  if TUtils.IsEnumerable(LDeepValue, LObjectList) then
  begin
    for LCurrent in LObjectList do
    begin
      Result.Add(LCurrent);
    end;                       
    LDeepValue := TValue.Empty;
  end;

  if (LDeepValue.IsObject) and (LDeepValue.AsObject <> nil) then
    Result.Add(LDeepValue.AsObject);
end;

class function TRttiExplorer.GetTable(AClassInfo: PTypeInfo): TableAttribute;
var
  LClass: TClass;
begin
  LClass := GetClassFromClassInfo(AClassInfo);
  Result := GetTable(LClass);
end;

class function TRttiExplorer.GetTable(AClass: TClass): TableAttribute;
begin
  Result := GetClassAttribute<TableAttribute>(AClass, True);
end;

class function TRttiExplorer.GetUniqueConstraints(AClass: TClass): IList<UniqueConstraint>;
begin
  Result := GetClassMembers<UniqueConstraint>(AClass);
end;

class function TRttiExplorer.HasColumns(AClass: TClass): Boolean;
var
  LList: IList<ColumnAttribute>;
begin
  LList := GetColumns(AClass);
  Result := LList.Any;
end;

class function TRttiExplorer.HasSequence(AClass: TClass): Boolean;
begin
  Result := (GetSequence(AClass) <> System.Default(SequenceAttribute) );
end;

class function TRttiExplorer.InheritsFrom(AObjectInfo: TClass;
  AFromObjectInfo: PTypeInfo): Boolean;
var
  LClass: TClass;
begin
  if Assigned(AObjectInfo) then
  begin
    Result := AObjectInfo.ClassInfo = AFromObjectInfo;
  end
  else
  begin
    Exit(False);
  end;
  if not Result then
  begin
    LClass := AObjectInfo.ClassParent;
    if Assigned(LClass) then
      Result := InheritsFrom(LClass, AFromObjectInfo);
  end;
end;

{$ENDREGION}


{$REGION 'TRttiCache'}

constructor TRttiCache.Create;
begin
  inherited Create;
  FFields := TCollections.CreateDictionary<string,TRttiField>;
  FProperties := TCollections.CreateDictionary<string,TRttiProperty>;
  FTypes := TCollections.CreateDictionary<PTypeInfo,TRttiType>;
  FTypeFields := TCollections.CreateDictionary<PTypeInfo,IList<TRttiField>>;
end;

procedure TRttiCache.Clear;
begin
  FFields.Clear;
  FProperties.Clear;
  FTypes.Clear;
  FTypeFields.Clear;
end;

function TRttiCache.GetField(AClass: TClass; const AFieldName: string): TRttiField;
begin
  if not FFields.TryGetValue(GetKey(AClass, AFieldName), Result) then
    Result := nil;
end;

function TRttiCache.GetFieldsOfType(ATypeInfo: PTypeInfo): IList<TRttiField>;
begin
  if not FTypeFields.TryGetValue(ATypeInfo, Result) then
    Result := TCollections.CreateList<TRttiField>;
end;

function TRttiCache.GetKey(AClass: TClass; const AName: string): string;
begin
  Result := AClass.UnitName + '.' + AClass.ClassName + '$' + AName;
end;

function TRttiCache.GetNamedObject(AClass: TClass; const AMemberName: string): TRttiNamedObject;
begin
  Result := GetProperty(AClass, AMemberName);
  if Result <> nil then
    Exit;
  Result := GetField(AClass, AMemberName);
  if Result <> nil then
    Exit;
  Result := TRttiExplorer.GetNamedObject(AClass, AMemberName);
end;

function TRttiCache.GetProperty(AClass: TClass; const APropertyName: string): TRttiProperty;
begin
  if not FProperties.TryGetValue(GetKey(AClass, APropertyName), Result) then
    Result := nil;
end;

function TRttiCache.GetType(AClass: TClass): TRttiType;
begin
  Result := nil;
  if Assigned(AClass) then
  begin
    Result := GetType(AClass.ClassInfo);
    if Result = nil then
      Result := FCtx.GetType(AClass);
  end;
end;

function TRttiCache.GetType(ATypeInfo: PTypeInfo): TRttiType;
begin
  if not FTypes.TryGetValue(ATypeInfo, Result) then
    Result := FCtx.GetType(ATypeInfo);
end;

procedure TRttiCache.RebuildCache;
var
  LType: TRttiType;
  LClass: TClass;
  LProp: TRttiProperty;
  LField: TRttiField;
  LFields: IList<TRttiField>;
begin
  Clear;

  for LType in FCtx.GetTypes do
  begin
    // Honza: For some reason one PTypeInfo can map to multiple types on mobile
    //        we'll use the later. (Types like IEvent, TAction, TEnumerator etc.
    //        have the same TypeInfo but are defined per unit multiple times
    //        in extended RTTI.)
    FTypes.AddOrSetValue(LType.Handle, LType);

    if LType.IsInstance then
    begin
      LClass := LType.AsInstance.MetaclassType;

      if TRttiExplorer.HasColumns(LClass) then
      begin
        LFields := TCollections.CreateList<TRttiField>;
        for LField in LType.GetFields do
        begin
          FFields.Add(GetKey(LClass, LField.Name), LField);
          LFields.Add(LField);
        end;
        FTypeFields.Add(LType.Handle, LFields);

        for LProp in LType.GetProperties do
          FProperties.Add(GetKey(LClass, LProp.Name), LProp);
      end;
    end;
  end;
end;

{$ENDREGION}


end.
