unit b2p_options;

interface

type
  ttype_t = (tString255, tInteger, tBoolean, tGroup);

  default_t = record
    name: string;
    helptext: string;
    location: pointer;
    setable: boolean;
    defaultsvalue: string;
    defaultivalue: integer;
    minivalue: integer;
    maxivalue: integer;
    defaultbvalue: boolean;
    _type: ttype_t;
  end;
  Pdefault_t = ^default_t;

var
  optUseCompression: Boolean = True;
  optUsePackedArrays: Boolean = False;

const
  NUMDEFAULTS = 3;

  defaults: array[0..NUMDEFAULTS - 1] of default_t = (
    (name: 'CODE_GENERATION';
     helptext: '';
     location: nil;
     setable: False;
     defaultsvalue: '';
     defaultivalue: 0;
     minivalue: 0;
     maxivalue: 0;
     defaultbvalue: False;
     _type: tGroup),

    (name: 'optUseCompression';
     helptext: 'Compress data before converting';
     location: @optUseCompression;
     setable: True;
     defaultsvalue: '';
     defaultivalue: 1;
     minivalue: 0;
     maxivalue: 0;
     defaultbvalue: True;
     _type: tBoolean),

    (name: 'optUsePackedArrays';
     helptext: 'Use packed array for data';
     location: @optUsePackedArrays;
     setable: True;
     defaultsvalue: '';
     defaultivalue: 1;
     minivalue: 0;
     maxivalue: 0;
     defaultbvalue: False;
     _type: tBoolean)

  );

procedure LoadDefaults(const fname: string);

procedure SaveDefaults(const fname: string);

implementation

uses
  Classes, SysUtils, b2p_utils;

function M_CheckParm(const parm: string): integer;
var
  i: integer;
begin
  for i := 1 to ParamCount do
    if LowerCase(parm) = LowerCase(ParamStr(i)) then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

procedure LoadDefaultsFromCommandLine;
var
  i: integer;
  pd: Pdefault_t;
  p: integer;
begin
  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if defaults[i].setable then
    begin
      p := M_CheckParm('-' + pd.name);
      if p > 0 then
        if p < ParamCount then
        begin
          if pd._type = tInteger then
          begin
            PInteger(pd.location)^ := StrToIntDef(ParamStr(p + 1), pd.defaultivalue);
            if pd.minivalue < pd.maxivalue then
            begin
              if PInteger(pd.location)^ < pd.minivalue then
                PInteger(pd.location)^ := pd.minivalue
              else if PInteger(pd.location)^ > pd.maxivalue then
                PInteger(pd.location)^ := pd.maxivalue;
            end;
          end
          else if pd._type = tBoolean then
             PBoolean(pd.location)^ := StrToIntDef(ParamStr(p + 1), pd.defaultivalue) <> 0
          else if pd._type = tString255 then
             PString255(pd.location)^ := ParamStr(p + 1);
        end;
    end;
    inc(pd);
  end;
end;

procedure LoadDefaults(const fname: string);
var
  i: integer;
  j: integer;
  idx: integer;
  pd: Pdefault_t;
  s: TStringList;
  n: string;
begin
  // set everything to base values
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tInteger then
      PInteger(defaults[i].location)^ := defaults[i].defaultivalue
    else if defaults[i]._type = tBoolean then
      PBoolean(defaults[i].location)^ := defaults[i].defaultbvalue
    else if defaults[i]._type = tString255 then
      PString255(defaults[i].location)^ := defaults[i].defaultsvalue;

  if FileExists(fname) then
  begin
    s := TStringList.Create;
    try
      // read the file in, overriding any set defaults
      s.LoadFromFile(fname);

      for i := 0 to s.Count - 1 do
      begin
        idx := -1;
        n := LowerCase(s.Names[i]);
        for j := 0 to NUMDEFAULTS - 1 do
          if LowerCase(defaults[j].name) = n then
          begin
            idx := j;
            break;
          end;

        if idx > -1 then
        begin
          pd := @defaults[idx];
          if pd._type = tInteger then
          begin
            PInteger(pd.location)^ := StrToIntDef(s.Values[n], pd.defaultivalue);
            if pd.minivalue < pd.maxivalue then
            begin
              if PInteger(pd.location)^ < pd.minivalue then
                PInteger(pd.location)^ := pd.minivalue
              else if PInteger(pd.location)^ > pd.maxivalue then
                PInteger(pd.location)^ := pd.maxivalue;
            end;
          end
          else if pd._type = tBoolean then
             PBoolean(pd.location)^ := StrToIntDef(s.Values[n], pd.defaultivalue) <> 0
          else if pd._type = tString255 then
             PString255(pd.location)^ := s.Values[n];
        end;
      end;
    finally
      s.Free;
    end;
  end;

  LoadDefaultsFromCommandLine;
end;

procedure SaveDefaults(const fname: string);
var
  i: integer;
  pd: Pdefault_t;
  s: TStringList;
begin
  s := TStringList.Create;
  try
    pd := @defaults[0];
    for i := 0 to NUMDEFAULTS - 1 do
    begin
      if pd._type = tInteger then
        s.Add(pd.name + '=' + IntToStr(PInteger(pd.location)^))
      else if pd._type = tString255 then
        s.Add(pd.name + '=' + PString255(pd.location)^)
      else if pd._type = tBoolean then
      begin
        if PBoolean(pd.location)^ then
          s.Add(pd.name + '=1')
        else
          s.Add(pd.name + '=0');
      end
      else if pd._type = tGroup then
      begin
        if i <> 0 then
          s.Add('');
        s.Add('[' + pd.name + ']');
      end;
      inc(pd);
    end;
    s.SaveToFile(fname);
  finally
    s.Free;
  end;
end;

end.

