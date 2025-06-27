unit Logging;

interface

uses
  System.Classes, System.SysUtils;

type
  TLogPriority = (lpInformation, lpWarning, lpError, lpCritical);

  TLogPriorityHelper = record helper for TLogPriority
  public
    function ToString: string;
  end;

  TAddLogNotification = procedure(Msg: string; Priority: TLogPriority) of object;

  TLogger = class
  private
    FLogList: TStringList;
    FOnChange: TNotifyEvent;
    FOnAddLog: TAddLogNotification;
    FCapacity: Integer;
    procedure OnListChanged(Sender: TObject);
    procedure SetCapacity(const Value: Integer);
    procedure CutToCapacity;
  protected
    procedure AddLogString(Msg: string; Priority: TLogPriority);
  public
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: TLogger;
    class procedure Log(Msg: string; Priority: TLogPriority = lpInformation); overload;
    class procedure Log(Msg: string; Details: array of string; Priority: TLogPriority = lpInformation); overload;
    procedure Clear;
    function GetLogging: TStringList;
    procedure SaveToFile(AFileName: TFileName);
    property Capacity: Integer read FCapacity write SetCapacity default 1000;
    property OnLog: TAddLogNotification read FOnAddLog write FOnAddLog;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

var
  Logger: TLogger;

resourcestring
  sCapacityLess0 = 'Capacity must be > 0.';

{ TLogPriorityHelper }

function TLogPriorityHelper.ToString: string;
begin
    case Self of
      lpInformation:  Result := 'Information';
      lpWarning:      Result := 'Warning';
      lpError:        Result := 'Error';
      lpCritical:     Result := 'Critical';
    else
      Result := 'unkown';
    end;
end;


{ TLogger }

procedure TLogger.Clear;
begin
  FLogList.Clear;
end;

constructor TLogger.Create;
begin
  inherited;
  FCapacity := 1000;
  FLogList := TStringList.Create;
  FLogList.OnChange := OnListChanged;
end;

procedure TLogger.CutToCapacity;
begin
  while FLogList.Count > FCapacity do
    FLogList.Delete(0);
end;

destructor TLogger.Destroy;
begin
  FLogList.Free;
  inherited;
end;

class function TLogger.GetInstance: TLogger;
begin
  if Logger = nil then Logger := TLogger.Create;
  Result := Logger;
end;

function TLogger.GetLogging: TStringList;
begin
  Result := FLogList;
end;

class procedure TLogger.Log(Msg: string; Priority: TLogPriority);
var
  lLogString: string;
begin
  lLogString := DateTimeToStr(now) + #9 + Priority.ToString + #9 + Msg;
  GetInstance.AddLogString(lLogString, Priority);
end;

class procedure TLogger.Log(Msg: string; Details: array of string; Priority: TLogPriority = lpInformation);
var
  lLogString, lSubString: string;
begin
  lLogString := Msg;
  for lSubString in Details do
    lLogString := lLogString + #9 + lSubString;
  Log(lLogString, Priority);
end;

procedure TLogger.OnListChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TLogger.AddLogString(Msg: string; Priority: TLogPriority);
begin
  FLogList.Add(Msg);
  CutToCapacity;
  if Assigned(FOnAddLog) then FOnAddLog(Msg, Priority);
end;

procedure TLogger.SaveToFile(AFileName: TFileName);
begin
  FLogList.SaveToFile(AFileName);
end;

procedure TLogger.SetCapacity(const Value: Integer);
begin
  if Value < 1 then raise Exception.Create(sCapacityLess0);
  FCapacity := Value;
  CutToCapacity;
end;

initialization

finalization
  { Free Globals }
  Logger.Free;

end.
