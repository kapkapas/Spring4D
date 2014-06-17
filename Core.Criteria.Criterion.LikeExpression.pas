unit Core.Criteria.Criterion.LikeExpression;

interface

uses
  Core.Criteria.Criterion.SimpleExpression
  ,Core.Interfaces
  ,SQL.Types
  ,Rtti
  ,SQL.Params
  ,SQL.Commands
  ,SQL.Interfaces
  ,Spring.Collections
  ;

type
  TLikeExpression = class(TSimpleExpression)
  private
    FMatchMode: TMatchMode;
  public
    constructor Create(const APropertyName: string; const AValue: TValue; AOperator: TWhereOperator; const AMatchMode: TMatchMode); reintroduce; overload;

    function ToSqlString(AParams: IList<TDBParam>; ACommand: TDMLCommand; AGenerator: ISQLGenerator; AAddToCommand: Boolean): string; override;
  end;

implementation

uses
  SysUtils
  ;

{ TLikeExpression }

constructor TLikeExpression.Create(const APropertyName: string; const AValue: TValue; AOperator: TWhereOperator; const AMatchMode: TMatchMode);
begin
  inherited Create(APropertyName, AValue, AOperator);
  FMatchMode := AMatchMode;
end;

function TLikeExpression.ToSqlString(AParams: IList<TDBParam>; ACommand: TDMLCommand; AGenerator: ISQLGenerator; AAddToCommand: Boolean): string;
var
  LWhere: TSQLWhereField;
begin
  Assert(ACommand is TWhereCommand);

  Result := Format('%S %S %S', [PropertyName, WhereOpNames[GetWhereOperator], GetMatchModeString(FMatchMode, Value.AsString)]);

  LWhere := TSQLWhereField.Create(Result, GetCriterionTable(ACommand) );
  LWhere.MatchMode := GetMatchMode;
  LWhere.WhereOperator := GetWhereOperator;

  if AAddToCommand then
    TWhereCommand(ACommand).WhereFields.Add(LWhere)
  else
    LWhere.Free;
end;

end.
