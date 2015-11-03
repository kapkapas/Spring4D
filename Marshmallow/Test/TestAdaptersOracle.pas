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

unit TestAdaptersOracle;

interface

uses
  TestFramework,
  TestEntities,
  SysUtils,
  Windows,
  Spring.Persistence.Adapters.ADO,
  Spring.Persistence.Adapters.Oracle,
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Core.Session,
  Spring.Persistence.SQL.Generators.Oracle,
  Spring.TestUtils,
  TestAdaptersADO;

type
  TOracleConnectionAdapterTest = class(TBaseADOAdapterTest)
  private
    fConnectionAdapter: TOracleConnectionAdapter;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetQueryLanguage;
    procedure TestTransaction;
    procedure TestConnectException;
    procedure TestBeginTransactionException;
    procedure TestCreateStatement;
  end;

  TOracleSessionTest = class(TTestCase)
  private
    fConnection: IDBConnection;
    fManager: TSession;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure First;
    procedure Save_Delete;
    procedure Page;
  end;

  TOracleSQLGeneratorTest = class(TTestCase)
  private
    fSut: TOracleSQLGenerator;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure UseTOracleDBParams;
    procedure CreateParamCreatesTOracleDBParam;
    procedure WhenDataTypeNVARCHAR_ReplaceToNVARCHAR2;
    procedure GenerateCorrectCreateSequence;
  end;

implementation

uses
  ADODB,
  DB,
  TypInfo,
  Variants,
  Spring,
  Spring.Collections,
  Spring.Persistence.Core.ConnectionFactory,
  Spring.Persistence.Core.DatabaseManager,
  Spring.Persistence.Core.EntityCache,
  Spring.Persistence.Criteria.Interfaces,
  Spring.Persistence.Criteria.Properties,
  Spring.Persistence.Mapping.Attributes,
  Spring.Persistence.SQL.Params,
  Spring.Persistence.SQL.Types,
  Spring.Persistence.SQL.Commands,
  Spring.Persistence.SQL.Interfaces,
  Spring.Reflection;

const
  TBL_COMPANY = 'Vikarina.IMONES';

function CreateTestConnection: TADOConnection;
begin
  Result := TADOConnection.Create(nil);
  try
  Result.LoginPrompt := False;
  //Provider=OraOLEDB.Oracle;Data Source=SERVER1;User ID=SYSTEM;Password=master
    Result.ConnectionString := Format(
      'Provider=OraOLEDB.Oracle;Data Source=%0:S;Password=%1:S;User ID=%2:S'
    , ['SERVER1', 'master', 'SYSTEM']);
  Result.Open;
  except
    Result.Free;
    raise;
end;
end;

procedure DropTestTables;
var
  LConn: TADOConnection;
begin
  LConn := CreateTestConnection;
  try
    LConn.Execute('DROP TABLE ' + TBL_COMPANY);
  finally
    LConn.Free;
  end;
end;

procedure InsertCompany(AID: Integer; const ACompName: string);
var
  LConn: TADOConnection;
begin
  LConn := CreateTestConnection;
  try
    LConn.Execute(Format('INSERT INTO '+ TBL_COMPANY + ' (IMONE, IMPAV) VALUES (%0:D, %1:S)',
      [AID, QuotedStr(ACompName)]));
  finally
    LConn.Free;
  end;
end;

function GetTableCount(const ATablename: string): Variant;
var
  LConn: TADOConnection;
  LResults: _Recordset;
begin
  LConn := CreateTestConnection;
  try
    LResults := LConn.Execute(Format('SELECT COUNT(*) FROM %0:S', [ATablename]));

    if LResults.RecordCount > 0 then
      Result := LResults.Fields.Item[0].Value
    else
      Result := Unassigned;
  finally
    LConn.Free;
  end;
end;


{$REGION 'TOracleConnectionAdapterTest'}

procedure TOracleConnectionAdapterTest.TestBeginTransactionException;
begin
  ExpectedException := EADOAdapterException;
  fConnectionAdapter.BeginTransaction;
end;

procedure TOracleConnectionAdapterTest.TestConnectException;
begin
  ExpectedException := EADOAdapterException;
  fConnectionAdapter.Connect;
end;

procedure TOracleConnectionAdapterTest.TestCreateStatement;
var
  statement: IDBStatement;
begin
  fConnectionAdapter.Connection.ConnectionObject := fMockConnectionObject;

  statement := fConnectionAdapter.CreateStatement;
  CheckNotNull(statement);

  // Ensure the mock alows the adapter to free properly
  SetupOpen;
end;

procedure TOracleConnectionAdapterTest.TestGetQueryLanguage;
begin
  CheckEquals(qlOracle, fConnectionAdapter.QueryLanguage);
end;

procedure TOracleConnectionAdapterTest.TestTransaction;
begin
  fConnectionAdapter.Connection.ConnectionObject := fMockConnectionObject;

  // Test connect exception
  CheckException(EADOAdapterException,
    procedure begin fConnectionAdapter.BeginTransaction end);

  SetupOpen;

  // Test commit - with exception
  SetupExecute(['SAVEPOINT T1', 'COMMIT']);
  with fConnectionAdapter.BeginTransaction do
  begin
    Commit;
    // Next commit is not allowed, simulates exception in the driver
    CheckException(EADOAdapterException,
      procedure begin Commit end);
  end;

  // Test rollback - with exception
  SetupExecute(['SAVEPOINT T2', 'ROLLBACK TO SAVEPOINT T2']);
  with fConnectionAdapter.BeginTransaction do
  begin
    Rollback;
    // Next rollback is not allowed, simulates exception in the driver
    CheckException(EADOAdapterException,
      procedure begin Rollback end);
  end;
end;

procedure TOracleConnectionAdapterTest.SetUp;
begin
  inherited;
  fConnectionAdapter := TOracleConnectionAdapter.Create(
    TADOConnection.Create(nil)); // We do not need real Oracle connection here
  fConnectionAdapter.AutoFreeConnection := True;
end;

procedure TOracleConnectionAdapterTest.TearDown;
begin
  fConnectionAdapter.Free;
  inherited;
end;

{$ENDREGION}


{$REGION 'TOracleSessionTest'}

procedure TOracleSessionTest.First;
var
  LCompany: TCompany;
begin
  //insert company
  InsertCompany(1, 'Oracle Company');
  LCompany := fManager.FindOne<TCompany>(1);
  try
    CheckTrue(Assigned(LCompany));
    CheckEquals(1, LCompany.ID);
    CheckEquals('Oracle Company', LCompany.Name);
  finally
    LCompany.Free;
  end;
end;

procedure TOracleSessionTest.Page;
var
  LCriteria: ICriteria<TCompany>;
  LItems: IList<TCompany>;
  Imone: IProperty;
  i: Integer;
begin
  for i := 1 to 20 do
  begin
    InsertCompany(i, Format('%D Company', [i]));
  end;
  Imone := TProperty<TCompany>.Create('IMONE');

  LCriteria := fManager.CreateCriteria<TCompany>;
  LCriteria.Add(Imone.GEq(1));
  LItems := LCriteria.Page(1, 10).Items;
  CheckEquals(10, LItems.Count);

  LItems := LCriteria.Page(2, 10).Items;
  CheckEquals(10, LItems.Count);
end;

procedure TOracleSessionTest.Save_Delete;
var
  LCompany: TCompany;
begin
  LCompany := TCompany.Create;
  try
    InsertCompany(1, 'Oracle Company');
    LCompany.Name := 'Inserted Company';
    LCompany.ID := 2;
    LCompany.Logo.LoadFromFile(PictureFilename);
    fManager.Save(LCompany);
    CheckEquals(2, GetTableCount(TBL_COMPANY));

    fManager.Delete(LCompany);
    CheckEquals(1, GetTableCount(TBL_COMPANY));
  finally
    LCompany.Free;
  end;
end;

procedure TOracleSessionTest.SetUp;
begin
  inherited;
  fConnection := TConnectionFactory.GetInstance(dtOracle, CreateTestConnection);
  fConnection.AutoFreeConnection := True;
  fManager := TSession.Create(fConnection);

  fConnection.AddExecutionListener(
    procedure(const command: string; const params: IEnumerable<TDBParam>)
    var
      i: Integer;
      param: TDBParam;
    begin
      Status(command);
      i := 0;
      for param in params do
      begin
        Status(Format('%2:D Param %0:S = %1:S', [param.Name, VarToStrDef(param.ToVariant, 'NULL'), i]));
        Inc(i);
      end;
      Status('-----');
    end);

  CreateTestTables(fConnection, [TCompany]);
end;

procedure TOracleSessionTest.TearDown;
begin
  DropTestTables;
  fManager.Free;
  fConnection := nil;
  inherited;
end;

{$ENDREGION}


{$REGION 'TOracleSQLGeneratorTest'}

procedure TOracleSQLGeneratorTest.CreateParamCreatesTOracleDBParam;
var
  field: TSQLInsertField;
  table: TSQLTable;
  param: TDBParam;
begin
  table := TSQLTable.CreateFromClass(TCustomer);
  field := TSQLInsertField.Create('MiddleName', table,
    TType.GetType<TCustomer>.GetProperty('MiddleName').GetCustomAttribute<ColumnAttribute>,
    ':MiddleName');
  param := fSut.CreateParam(field, TValue.Empty);
  CheckIs(param, TOracleDBParam);
  CheckEquals(Ord(ftWideString), Ord(param.ParamType),
    'ParamType should be ftWidestring but was: ' + GetEnumName(System.TypeInfo(TFieldType), Ord(param.ParamType)));
  table.Free;
  field.Free;
  param.Free;
end;

procedure TOracleSQLGeneratorTest.GenerateCorrectCreateSequence;
var
  command: TCreateSequenceCommand;
  actual, expected: string;
begin
  //issue #84
  command := TCreateSequenceCommand.Create(TEntityCache.Get(TUIBCompany).Sequence);

  actual := fSut.GenerateCreateSequence(command);
  expected := 'BEGIN  EXECUTE IMMEDIATE ''CREATE SEQUENCE "GNR_IMONESID"  '+
    'MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE''; END;';
  CheckEquals(expected, actual);
  command.Free;
end;

procedure TOracleSQLGeneratorTest.SetUp;
begin
  inherited;
  fSut := TOracleSQLGenerator.Create;
end;

procedure TOracleSQLGeneratorTest.TearDown;
begin
  inherited;
  fSut.Free;
end;

procedure TOracleSQLGeneratorTest.UseTOracleDBParams;
begin
  CheckEquals(TOracleDBParam, fSut.GetParamClass);
end;

procedure TOracleSQLGeneratorTest.WhenDataTypeNVARCHAR_ReplaceToNVARCHAR2;
var
  field: TSQLCreateField;
  table: TSQLTable;
  actual, expected: string;
begin
  table := TSQLTable.CreateFromClass(TCustomer);
  field := TSQLCreateField.Create('MiddleName', table);
  field.SetFromAttribute(TType.GetType<TCustomer>.GetProperty(
    'MiddleName').GetCustomAttribute<ColumnAttribute>);

  actual := fSut.GetSQLDataTypeName(field);
  expected := 'NVARCHAR2(50)';
  CheckEquals(expected, actual);
  table.Free;
  field.Free;
end;

{$ENDREGION}


initialization
  RegisterTests('Spring.Persistence.Adapters', [
    TOracleSQLGeneratorTest.Suite,
    TOracleConnectionAdapterTest.Suite
  ]);
  if LoadLibrary('oci.dll') <> 0 then
  begin
    RegisterTests('Spring.Persistence.Adapters', [
      TOracleSessionTest.Suite
    ]);
  end;

end.
