unit b2p_core;

interface

uses
  SysUtils, Classes;

function b2p_data_to_decl(const buf: PByteArray; const sz: Integer; const name: string): string;

function b2p_data_to_unit(const buf: PByteArray; const sz: Integer; const varname, unitname: string): string;

function b2p_create_unit(const finp: string; const fout: string = ''): Boolean;

implementation

function b2p_byte2hex(const b: Byte): string;
begin
  Result := '$' + IntToHex(b, 2);
end;

function b2p_data_to_decl(const buf: PByteArray; const sz: Integer; const name: string): string;
var
  i: Integer;
  size, realsize: Integer;
  ret: string;

  procedure _add(const s: string);
  var
    len: Integer;
    ii: Integer;
  begin
    len := Length(s);
    if size + len >= realsize then
    begin
      realsize := ((realsize * 5 div 4) + len + 257) and not $FF;
      SetLength(ret, realsize);
    end;

    for ii := 1 to len do
    begin
      Inc(size);
      ret[size] := s[ii];
    end;
  end;

begin
  if sz = 0 then
  begin
    Result := '';
    Exit;
  end;

  Result := 'const'#13#10;

  if sz = 1 then
  begin
    Result := Result +
                Format('  %s_SIZE = 1;'#13#10,
                  [UpperCase(name)]);
    Result := Result +
                Format('  %s: array[0..0] of Byte = ( %s );'#13#10,
                  [name, b2p_byte2hex(buf[0])]);
    Exit;
  end;

  if sz = 2 then
  begin
    Result := Result +
                Format('  %s_SIZE = 2;'#13#10, [UpperCase(name)]);
    Result := Result +
                Format('  %s: array[0..1] of Byte = ( %s, %s );'#13#10,
                  [name, b2p_byte2hex(buf[0]), b2p_byte2hex(buf[1])]);
    Exit;
  end;

  if sz = 3 then
  begin
    Result := Result +
                Format('  %s_SIZE = 3;'#13#10, [UpperCase(name)]);
    Result := Result +
                Format('  %s: array[0..2] of Byte = ( %s, %s, %s );'#13#10,
                  [name, b2p_byte2hex(buf[0]), b2p_byte2hex(buf[1]), b2p_byte2hex(buf[2])]);
    Exit;
  end;

  Result := Result +
              Format('  %s_SIZE = %d;'#13#10,
                [UpperCase(name), sz]);
  Result := Result +
              Format('  %s: array[0..%s_SIZE - 1] of Byte = ('#13#10'    ',
                [name, UpperCase(name)]);

  ret := '          ';
  realsize := Length(ret);
  size := 0;

  for i := 0 to sz - 1 do
  begin
    _add(b2p_byte2hex(buf[i]));

    if i < sz - 1 then
      _add(', ')
    else
    begin
      _add(#13#10'  );'#13#10#13#10);
      Break;
    end;

    if (i + 1) mod 16 = 0 then
    begin
      Dec(size); // Remove last space
      _add(#13#10'    ');
    end;
  end;

  SetLength(ret, size);

  Result := Result + ret;
end;

function b2p_data_to_unit(const buf: PByteArray; const sz: Integer; const varname, unitname: string): string;
begin
  Result := 'unit ' + unitname + ';'#13#10#13#10;
  Result := Result + 'interface'#13#10#13#10;
  Result := Result + b2p_data_to_decl(buf, sz, varname);
  Result := Result + 'implementation'#13#10#13#10;
  Result := Result + 'end.'#13#10;
end;

function b2p_create_unit(const finp: string; const fout: string = ''): Boolean;
var
  fs: TFileStream;
  sl: TStringList;
  buf: PByteArray;
  varname, unitname, outname: string;
  p: Integer;
begin
  Result := False;

  if not FileExists(finp) then
    Exit;

  varname := ExtractFileName(finp);
  p := Pos('.', varname);
  if p > 0 then
    SetLength(varname, p - 1);
  if varname = '' then
    Exit;

  unitname := ExtractFileName(fout);
  p := Pos('.', unitname);
  if p > 0 then
    SetLength(unitname, p - 1);
  if unitname = '' then
    unitname := varname;

  if unitname = varname then
    varname := '_' + varname;

  outname := fout;
  if fout = '' then
    outname := IncludeTrailingPathDelimiter(ExtractFilePath(finp)) + unitname + '.pas';

  fs := TFileStream.Create(finp, fmOpenRead);
  try
    GetMem(buf, fs.Size);
    fs.Read(buf^, fs.Size);

    sl := TStringList.Create;
    try
      sl.Text := b2p_data_to_unit(buf, fs.Size, varname, unitname);
      sl.SaveToFile(outname);
    finally
      sl.Free;
    end;

    FreeMem(buf);
  finally
    fs.Free;
  end;

  Result := True;
end;

end.
