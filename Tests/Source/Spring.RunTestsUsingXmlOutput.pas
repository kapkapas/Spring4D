{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2013 Spring4D Team                           }
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

unit Spring.RunTestsUsingXmlOutput;

interface

{$i Spring.Tests.inc}

{$ifdef XMLOUTPUT}
procedure RunRegisteredTestCases();
{$endif XMLOUTPUT}

implementation

{$ifdef XMLOUTPUT}
uses
  SysUtils,
  TestFramework,
  FinalBuilder.XMLTestRunner,
  Spring.TestUtils;

var
  OutputFile: string = 'Spring.Tests.Reports.xml';
  ConfigFile: string;

procedure RunRegisteredTestCases();
begin
  if ConfigFile <> '' then
  begin
    RegisteredTests.LoadConfiguration(ConfigFile, False, True);
    WriteLn('Loaded config file ' + ConfigFile);
  end;
  if ParamCount > 0 then
    OutputFile := ParamStr(1);
  WriteLn('Writing output to ' + OutputFile);
  WriteLn(Format('Running %d of %d test cases', [RegisteredTests.CountEnabledTestCases, RegisteredTests.CountTestCases]));
  ProcessTestResult(FinalBuilder.XMLTestRunner.RunRegisteredTests(OutputFile));
end;
{$endif XMLOUTPUT}

end.
