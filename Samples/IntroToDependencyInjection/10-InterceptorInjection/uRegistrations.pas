unit uRegistrations;

interface

uses
  Spring.Container,
  Spring.Container.Common;

procedure RegisterTypes(const container: TContainer);

implementation

uses
  uInterceptors,
  uOrderEntry,
  uOrderProcessor,
  uOrderValidator;

procedure RegisterTypes(const container: TContainer);
begin
  container.RegisterType<TLoggingAspect>;
  container.RegisterType<TTransactionAspect>;
  container.RegisterType<TOrderEntry>
    .InterceptedBy<TLoggingAspect>
    .InterceptedBy<TTransactionAspect>(TWhere.First);
  container.RegisterType<TOrderValidator>
    .InterceptedBy<TLoggingAspect>;
  container.RegisterType<TOrderProcessor>;

  container.Build;
end;

end.
