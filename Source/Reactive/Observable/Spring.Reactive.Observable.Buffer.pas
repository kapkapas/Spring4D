{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2017 Spring4D Team                           }
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

unit Spring.Reactive.Observable.Buffer;

interface

uses
  Spring,
  Spring.Collections,
  Spring.Reactive,
  Spring.Reactive.Concurrency.AsyncLock,
  Spring.Reactive.Internal.Producer,
  Spring.Reactive.Internal.Sink;

type
  TBuffer<TSource> = class
  public type
    TCount = class(TProducer<IList<TSource>>)
    private
      fSource: IObservable<TSource>;
      fCount: Integer;
      fSkip: Integer;

      type
        TSink = class(TSink<IList<TSource>>, IObserver<TSource>)
        private
          fQueue: IQueue<IList<TSource>>;
          fCount: Integer;
          fSkip: Integer;
          fn: Integer;
          procedure CreateWindow;
        public
          constructor Create(const parent: TCount;
            const observer: IObserver<IList<TSource>>; const cancel: IDisposable);
          function Run(const source: IObservable<TSource>): IDisposable;
          procedure OnNext(const value: TSource);
          procedure OnError(const error: Exception);
          procedure OnCompleted;
        end;
    protected
      function CreateSink(const observer: IObserver<IList<TSource>>;
        const cancel: IDisposable): TObject; override;
      function Run(const sink: TObject): IDisposable; override;
    public
      constructor Create(const source: IObservable<TSource>; count, skip: Integer);
    end;

//    TTimeSliding = class(TProducer<IList<TSource>>)
//    private
//      fSource: IObservable<TSource>;
//      fTimeSpan: TTimeSpan;
//      fTimeShift: TTimeSpan;
//      fScheduler: IScheduler;
//
//      type
//        TSink = class(TSink<IList<TSource>>, IObserver<TSource>)
//        private
//          fTimeShift: TTimeSpan;
//          fScheduler: IScheduler;
//          fQueue: IQueue<IList<TSource>>;
//          fTimerD: ISerialDisposable;
//          fTotalTime: TTimeSpan;
//          fNextShift: TTimeSpan;
//          fNextSpan: TTimeSpan;
//        private
//          procedure CreateWindow;
//          procedure CreateTimer;
//        public
//          constructor Create(const parent: TTimeSliding;
//            const observer: IObserver<IList<TSource>>; const cancel: IDisposable);
//          function Run(const parent: TTimeSliding): IDisposable;
//          procedure OnNext(const value: TSource);
//          procedure OnError(const error: Exception);
//          procedure OnCompleted;
//        end;
//    protected
//      function Run(const observer: IObserver<IList<TSource>>; const cancel: IDisposable;
//        const setSink: Action<IDisposable>): IDisposable; override;
//    public
//      constructor Create(const source: IObservable<TSource>;
//        const timeSpan, timeShift: TTimeSpan; const scheduler: IScheduler);
//    end;

    TTimeHopping = class(TProducer<IList<TSource>>)
    private
      fSource: IObservable<TSource>;
      fTimeSpan: TTimeSpan;
      fScheduler: IScheduler;

      type
        TSink = class(TSink<IList<TSource>>, IObserver<TSource>)
        private
          fList: IList<TSource>;
          procedure Tick;
        public
          function Run(const parent: TTimeHopping): IDisposable;
          procedure OnNext(const value: TSource);
          procedure OnError(const error: Exception);
          procedure OnCompleted;
        end;
    protected
      function CreateSink(const observer: IObserver<IList<TSource>>;
        const cancel: IDisposable): TObject; override;
      function Run(const sink: TObject): IDisposable; override;
    public
      constructor Create(const source: IObservable<TSource>;
        const timeSpan: TTimeSpan; const scheduler: IScheduler);
    end;
  end;

  TBuffer<TSource, TBufferClosing> = class(TProducer<IList<TSource>>)
  public type
    TSelector = class(TProducer<IList<TSource>>)
    private
      fSource: IObservable<TSource>;
      fBufferClosingSelector: Func<IObservable<TBufferClosing>>;

      type
        TSink = class(TSink<IList<TSource>>, IObserver<TSource>)
        private
          fBufferGate: TAsyncLock;
          fBufferClosingSubscription: ISerialDisposable;
          fBufferClosingSelector: Func<IObservable<TBufferClosing>>;
          fBuffer: IList<TSource>;
          procedure CreateBufferClose;
          procedure CloseBuffer(const closingSubscription: IDisposable);

          type
            TBufferClosingObserver = class(TDisposableObject, IObserver<TBufferClosing>)
            private
              fParent: TSink;
              fDisposable: IDisposable;
            public
              constructor Create(const parent: TSink; const disposable: IDisposable);
              destructor Destroy; override;
              procedure OnNext(const value: TBufferClosing);
              procedure OnError(const error: Exception);
              procedure OnCompleted;
            end;
        public
          constructor Create(const parent: TSelector;
            const observer: IObserver<IList<TSource>>; const cancel: IDisposable);
          function Run(const source: IObservable<TSource>): IDisposable;
          procedure OnNext(const value: TSource);
          procedure OnError(const error: Exception);
          procedure OnCompleted;
        end;
    protected
      function CreateSink(const observer: IObserver<IList<TSource>>;
        const cancel: IDisposable): TObject; override;
      function Run(const sink: TObject): IDisposable; override;
    public
      constructor Create(const source: IObservable<TSource>;
        const bufferClosingSelector: Func<IObservable<TBufferClosing>>);
    end;

    TBoundaries = class(TProducer<IList<TSource>>)
    private
      fSource: IObservable<TSource>;
      fBufferBoundaries: IObservable<TBufferClosing>;

      type
        TSink = class(TSink<IList<TSource>>, IObserver<TSource>)
        private
          fBuffer: IList<TSource>;

          type
            TBufferClosingObserver = class(TDisposableObject, IObserver<TBufferClosing>)
            private
              fParent: TSink;
            public
              constructor Create(const parent: TSink);
              destructor Destroy; override;
              procedure OnNext(const value: TBufferClosing);
              procedure OnError(const error: Exception);
              procedure OnCompleted;
            end;
        public
          function Run(const parent: TBoundaries): IDisposable;
          procedure OnNext(const value: TSource);
          procedure OnError(const error: Exception);
          procedure OnCompleted;
        end;
    protected
      function CreateSink(const observer: IObserver<IList<TSource>>;
        const cancel: IDisposable): TObject; override;
      function Run(const sink: TObject): IDisposable; override;
    public
      constructor Create(const source: IObservable<TSource>;
        const bufferBoundaries: IObservable<TBufferClosing>);
    end;
  end;

implementation

uses
  Spring.Reactive.Disposables;


{$REGION 'TBuffer<TSource>.TCount'}

constructor TBuffer<TSource>.TCount.Create(const source: IObservable<TSource>;
  count, skip: Integer);
begin
  inherited Create;
  fSource := source;
  fCount := count;
  fSkip := skip;
end;

function TBuffer<TSource>.TCount.CreateSink(
  const observer: IObserver<IList<TSource>>; const cancel: IDisposable): TObject;
begin
  Result := TSink.Create(Self, observer, cancel);
end;

function TBuffer<TSource>.TCount.Run(const sink: TObject): IDisposable;
begin
  Result := TSink(sink).Run(fSource);
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource>.TCount.TSink'}

constructor TBuffer<TSource>.TCount.TSink.Create(const parent: TCount;
  const observer: IObserver<IList<TSource>>; const cancel: IDisposable);
begin
  inherited Create(observer, cancel);
  fQueue := TCollections.CreateQueue<IList<TSource>>;
  fCount := parent.fCount;
  fSkip := parent.fSkip;
end;

function TBuffer<TSource>.TCount.TSink.Run(
  const source: IObservable<TSource>): IDisposable;
begin
  fn := 0;

  CreateWindow;
  Result := source.Subscribe(Self);
end;

procedure TBuffer<TSource>.TCount.TSink.CreateWindow;
var
  s: IList<TSource>;
begin
  s := TCollections.CreateList<TSource>;
  fQueue.Enqueue(s);
end;

procedure TBuffer<TSource>.TCount.TSink.OnNext(const value: TSource);
var
  s: IList<TSource>;
  c: Integer;
begin
  for s in fQueue do
    s.Add(value);

  c := fn - fCount + 1;
  if (c >= 0) and (c mod fSkip = 0) then
  begin
    s := fQueue.Dequeue;
    if s.Count > 0 then
      Observer.OnNext(s);
  end;

  Inc(fn);
  if fn mod fSkip = 0 then
    CreateWindow;
end;

procedure TBuffer<TSource>.TCount.TSink.OnError(const error: Exception);
begin
  while fQueue.Count > 0 do
    fQueue.Dequeue.Clear;

  Observer.OnError(error);
  Dispose;
end;

procedure TBuffer<TSource>.TCount.TSink.OnCompleted;
var
  s: IList<TSource>;
begin
  while fQueue.Count > 0 do
  begin
    s := fQueue.Dequeue;
    if s.Count > 0 then
      Observer.OnNext(s);
  end;

  Observer.OnCompleted;
  Dispose;
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource>.TTimeSliding'}

//constructor TBuffer<TSource>.TTimeSliding.Create(
//  const source: IObservable<TSource>; const timeSpan, timeShift: TTimeSpan;
//  const scheduler: IScheduler);
//begin
//  inherited Create;
//  fSource := source;
//  fTimeSpan := timeSpan;
//  fTimeShift := timeShift;
//  fScheduler := scheduler;
//end;
//
//function TBuffer<TSource>.TTimeSliding.Run(
//  const observer: IObserver<IList<TSource>>; const cancel: IDisposable;
//  const setSink: Action<IDisposable>): IDisposable;
//var
//  sink: TSink;
//begin
//  sink := TSink.Create(Self, observer, cancel);
//  setSink(sink);
//  Result := sink.Run(Self);
//end;

{$ENDREGION}


{$REGION 'TBuffer<TSource>.TTimeSliding.TSink'}

//constructor TBuffer<TSource>.TTimeSliding.TSink.Create(
//  const parent: TTimeSliding; const observer: IObserver<IList<TSource>>;
//  const cancel: IDisposable);
//begin
//  inherited Create(observer, cancel);
//  fTimeShift := parent.fTimeShift;
//  fScheduler := parent.fScheduler;
//end;
//
//function TBuffer<TSource>.TTimeSliding.TSink.Run(
//  const parent: TTimeSliding): IDisposable;
//var
//  subscription: IDisposable;
//begin
//  fTotalTime := TTimeSpan.Zero;
//  fNextShift := parent.fTimeShift;
//  fNextSpan := parent.fTimeSpan;
//
//  CreateWindow;
//  CreateTimer;
//
//  subscription := parent.fSource.Subscribe(Self);
//  Result := TStableCompositeDisposable.Create(fTimerD, subscription);
//end;
//
//procedure TBuffer<TSource>.TTimeSliding.TSink.CreateWindow;
//var
//  s: IList<TSource>;
//begin
//  s := TCollections.CreateList<TSource>;
//  fQueue.Enqueue(s);
//end;
//
//procedure TBuffer<TSource>.TTimeSliding.TSink.CreateTimer;
//begin
//
//end;
//
//procedure TBuffer<TSource>.TTimeSliding.TSink.OnNext(const value: TSource);
//begin
//
//end;
//
//procedure TBuffer<TSource>.TTimeSliding.TSink.OnError(const error: Exception);
//begin
//
//end;
//
//procedure TBuffer<TSource>.TTimeSliding.TSink.OnCompleted;
//begin
//
//end;

{$ENDREGION}


{$REGION 'TBuffer<TSource>.TTimeHopping'}

constructor TBuffer<TSource>.TTimeHopping.Create(
  const source: IObservable<TSource>; const timeSpan: TTimeSpan;
  const scheduler: IScheduler);
begin
  inherited Create;
  fSource := source;
  fTimeSpan := timeSpan;
  fScheduler := scheduler;
end;

function TBuffer<TSource>.TTimeHopping.CreateSink(
  const observer: IObserver<Ilist<TSource>>; const cancel: IDisposable): TObject;
begin
  Result := TSink.Create(observer, cancel);
end;

function TBuffer<TSource>.TTimeHopping.Run(const sink: TObject): IDisposable;
begin
  Result := TSink(sink).Run(Self);
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource>.TTimeHopping.TSink'}

function TBuffer<TSource>.TTimeHopping.TSink.Run(
  const parent: TTimeHopping): IDisposable;
var
  d: IDisposable;
  s: IDisposable;
begin
  fList := TCollections.CreateList<TSource>;

  d := (parent.fScheduler as ISchedulerPeriodic).SchedulePeriodic(parent.fTimeSpan, Tick); // TODO: check if Self capturing is needed
  s := parent.fSource.Subscribe(Self);

  Result := TStableCompositeDisposable.Create(d, s);
end;

procedure TBuffer<TSource>.TTimeHopping.TSink.Tick;
begin
  MonitorEnter(Self);
  try
    Observer.OnNext(fList);
    fList := TCollections.CreateList<TSource>;
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource>.TTimeHopping.TSink.OnNext(const value: TSource);
begin
  MonitorEnter(Self);
  try
    fList.Add(value);
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource>.TTimeHopping.TSink.OnError(const error: Exception);
begin
  MonitorEnter(Self);
  try
    fList.Clear;

    Observer.OnError(error);
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource>.TTimeHopping.TSink.OnCompleted;
begin
  MonitorEnter(Self);
  try
    Observer.OnNext(fList);
    Observer.OnCompleted;
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TSelector'}

constructor TBuffer<TSource, TBufferClosing>.TSelector.Create(
  const source: IObservable<TSource>;
  const bufferClosingSelector: Func<IObservable<TBufferClosing>>);
begin
  inherited Create;
  fSource := source;
  fBufferClosingSelector := bufferClosingSelector;
end;

function TBuffer<TSource, TBufferClosing>.TSelector.CreateSink(
  const observer: IObserver<IList<TSource>>;
  const cancel: IDisposable): TObject;
begin
  Result := TSink.Create(Self, observer, cancel);
end;

function TBuffer<TSource, TBufferClosing>.TSelector.Run(
  const sink: TObject): IDisposable;
begin
  Result := TSink(sink).Run(fSource);
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TSelector.TSink'}

constructor TBuffer<TSource, TBufferClosing>.TSelector.TSink.Create(
  const parent: TSelector; const observer: IObserver<IList<TSource>>;
  const cancel: IDisposable);
begin
  inherited Create(observer, cancel);
  fBufferGate := TAsyncLock.Create;
  fBufferClosingSubscription := TSerialDisposable.Create;
  fBufferClosingSelector := parent.fBufferClosingSelector;
end;

function TBuffer<TSource, TBufferClosing>.TSelector.TSink.Run(
  const source: IObservable<TSource>): IDisposable;
var
  groupDisposable: ICompositeDisposable;
begin
  fBuffer := TCollections.CreateList<TSource>;

  groupDisposable := TCompositeDisposable.Create([
    fBufferClosingSubscription, source.Subscribe(Self)]);

  fBufferGate.Wait(CreateBufferClose);

  Result := groupDisposable;
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.CreateBufferClose;
var
  bufferClose: IObservable<TBufferClosing>;
  closingSubscription: ISingleAssignmentDisposable;
begin
  try
    bufferClose := fBufferClosingSelector();
  except
    on e: Exception do
    begin
      MonitorEnter(Self);
      try
        Observer.OnError(e);
        Dispose;
      finally
        MonitorExit(Self);
      end;
    end;
  end;

  closingSubscription := TSingleAssignmentDisposable.Create;
  fBufferClosingSubscription.Disposable := closingSubscription;
  closingSubscription.Disposable := bufferClose.Subscribe(
    TBufferClosingObserver.Create(Self, closingSubscription) as IObserver<TBufferClosing>);
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.CloseBuffer(
  const closingSubscription: IDisposable);
var
  res: IList<TSource>;
begin
  closingSubscription.Dispose;

  MonitorEnter(Self);
  try
    res := fBuffer;
    fBuffer := TCollections.CreateList<TSource>;
    Observer.OnNext(res);
  finally
    MonitorExit(Self);
  end;

  fBufferGate.Wait(CreateBufferClose);
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.OnNext(const value: TSource);
begin
  MonitorEnter(Self);
  try
    fBuffer.Add(value);
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.OnError(const error: Exception);
begin
  MonitorEnter(Self);
  try
    fBuffer.Clear;
    Observer.OnError(error);
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.OnCompleted;
begin
  MonitorEnter(Self);
  try
    Observer.OnNext(fBuffer);
    Observer.OnCompleted;
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver'}

constructor TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver.Create(
  const parent: TSink; const disposable: IDisposable);
begin
  inherited Create;
  fParent := parent;
  fParent._AddRef;
  fDisposable := disposable;
end;

destructor TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver.Destroy;
begin
  fParent._Release;
  inherited;
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver.OnNext(
  const value: TBufferClosing);
begin
  fParent.CloseBuffer(fDisposable);
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver.OnError(
  const error: Exception);
begin
  fParent.OnError(error);
end;

procedure TBuffer<TSource, TBufferClosing>.TSelector.TSink.TBufferClosingObserver.OnCompleted;
begin
  fParent.CloseBuffer(fDisposable);
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TBoundaries'}

constructor TBuffer<TSource, TBufferClosing>.TBoundaries.Create(
  const source: IObservable<TSource>;
  const bufferBoundaries: IObservable<TBufferClosing>);
begin
  inherited Create;
  fSource := source;
  fBufferBoundaries := bufferBoundaries;
end;

function TBuffer<TSource, TBufferClosing>.TBoundaries.CreateSink(
  const observer: IObserver<IList<TSource>>;
  const cancel: IDisposable): TObject;
begin
  Result := TSink.Create(observer, cancel);
end;

function TBuffer<TSource, TBufferClosing>.TBoundaries.Run(
  const sink: TObject): IDisposable;
begin
  Result := TSink(sink).Run(Self);
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TBoundaries.TSink'}

function TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.Run(const parent: TBoundaries): IDisposable;
var
  sourceSubscription: IDisposable;
  boundariesSubscription: IDisposable;
  d: ICompositeDisposable;
begin
  fBuffer := TCollections.CreateList<TSource>;

  sourceSubscription := parent.fSource.Subscribe(Self);
  boundariesSubscription := parent.fBufferBoundaries.Subscribe(
    TBufferClosingObserver.Create(Self) as IObserver<TBufferClosing>);

  Result := TStableCompositeDisposable.Create(sourceSubscription, boundariesSubscription);
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.OnNext(const value: TSource);
begin
  MonitorEnter(Self);
  try
    fBuffer.Add(value);
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.OnError(
  const error: Exception);
begin
  MonitorEnter(Self);
  try
    fBuffer.Clear;
    Observer.OnError(error);
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.OnCompleted;
begin
  MonitorEnter(Self);
  try
    Observer.OnNext(fBuffer);
    Observer.OnCompleted;
    Dispose;
  finally
    MonitorExit(Self);
  end;
end;

{$ENDREGION}


{$REGION 'TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver'}

constructor TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver.Create(
  const parent: TSink);
begin
  inherited Create;
  fParent := parent;
  fParent._AddRef;
end;

destructor TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver.Destroy;
begin
  fParent._Release;
  inherited;
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver.OnNext(
  const value: TBufferClosing);
var
  res: IList<TSource>;
begin
  MonitorEnter(fParent);
  try
    res := fParent.fBuffer;
    fParent.fBuffer := TCollections.CreateList<TSource>;
    fParent.Observer.OnNext(res);
  finally
    MonitorExit(fParent);
  end;
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver.OnError(
  const error: Exception);
begin
  fParent.OnError(error);
end;

procedure TBuffer<TSource, TBufferClosing>.TBoundaries.TSink.TBufferClosingObserver.OnCompleted;
begin
  fParent.OnCompleted;
end;

{$ENDREGION}


end.
