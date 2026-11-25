//------------------------------------------------------------------------------
//
//  bin2pas
//  Convert binary data to Pascal unit
//  Copyright (C) 2026 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://github.com/jval1972/bin2pas
//------------------------------------------------------------------------------

unit b2p_core;

interface

uses
  SysUtils, Classes;

const
  B2PF_ZIP = 1;
  B2PF_PACKED = 2;

function b2p_pascalname(const s: string): string;

function b2p_data_to_decl(const buf: PByteArray; const sz: Integer; const name1: string; const flags: LongWord): string;

function b2p_data_to_unit(const buf: PByteArray; const sz: Integer; const varname1, unitname1: string; const flags: LongWord): string;

function b2p_create_unit(const finp: string; const fout: string = ''; const flags: LongWord = 0): Boolean;

const
  ABC_CHARS: set of Char = ['A'..'Z','a'..'z'];
  NUM_CHARS: set of Char = ['1'..'9','0'];

implementation

uses
  b2p_utils;

function b2p_pascalname(const s: string): string;
var
  i: Integer;
begin
  Result := '';
  if s = '' then
    Exit;

  if (s[1] in ABC_CHARS) or (s[1] = '_') then
    Result := s[1]
  else
    Result := '_' + IntToHex(Ord(s[1]), 2) + '_';

  for i := 2 to Length(s) do
  begin
    if (s[i] in ABC_CHARS) or (s[i] in NUM_CHARS) or (s[i] in ['.', '_']) then
      Result := Result + s[i]
    else if s[i] = '-' then
      Result := Result + '_'
    else
      Result := Result + '_' + IntToHex(Ord(s[i]), 2) + '_';
  end;

  Result := StringReplace(Result, '__', '_', [rfReplaceAll, rfIgnoreCase]);
end;

function b2p_byte2hex(const b: Byte): string;
begin
  Result := '$' + IntToHex(b, 2);
end;

function b2p_data_to_decl(const buf: PByteArray; const sz: Integer; const name1: string; const flags: LongWord): string;
var
  i: Integer;
  size, realsize: Integer;
  name: string;
  ret: string;
  pa: string;

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

  name := b2p_pascalname(name1);

  if flags and B2PF_PACKED <> 0 then
    pa := 'packed '
  else
    pa := '';

  Result := 'const'#13#10;

  if sz = 1 then
  begin
    Result := Result +
                Format('  %s_SIZE = 1;'#13#10,
                  [UpperCase(name)]);
    Result := Result +
                Format('  %s: %sarray[0..0] of Byte = ( %s );'#13#10,
                  [UpperCase(name), pa, b2p_byte2hex(buf[0])]);
    Exit;
  end;

  if sz = 2 then
  begin
    Result := Result +
                Format('  %s_SIZE = 2;'#13#10, [UpperCase(name)]);
    Result := Result +
                Format('  %s: %sarray[0..1] of Byte = ( %s, %s );'#13#10,
                  [UpperCase(name), pa, b2p_byte2hex(buf[0]), b2p_byte2hex(buf[1])]);
    Exit;
  end;

  if sz = 3 then
  begin
    Result := Result +
                Format('  %s_SIZE = 3;'#13#10, [UpperCase(name)]);
    Result := Result +
                Format('  %s: %sarray[0..2] of Byte = ( %s, %s, %s );'#13#10,
                  [UpperCase(name), pa, b2p_byte2hex(buf[0]), b2p_byte2hex(buf[1]), b2p_byte2hex(buf[2])]);
    Exit;
  end;

  Result := Result +
              Format('  %s_SIZE = %d;'#13#10,
                [UpperCase(name), sz]);
  Result := Result +
              Format('  %s: %sarray[0..%s_SIZE - 1] of Byte = ('#13#10'    ',
                [UpperCase(name), pa, UpperCase(name)]);

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

function b2p_data_to_unit(const buf: PByteArray; const sz: Integer; const varname1, unitname1: string; const flags: LongWord): string;
var
  varname, unitname, zvarname: string;
  bs: TAttachableMemoryStream;
  cs: TMemoryStream;
  zsize: Integer;
  sret: string;
  pa: string;
begin
  varname := b2p_pascalname(varname1);
  unitname := b2p_pascalname(unitname1);
  if varname = unitname then
    varname := '_' + varname;

  Result := '// Created with bin2pas v.' + I_VersionBuilt + #13#10#13#10;
  Result := Result + 'unit ' + unitname + ';'#13#10#13#10;
  Result := Result + 'interface'#13#10#13#10;

  if flags and B2PF_PACKED <> 0 then
    pa := 'packed '
  else
    pa := '';

  if flags and B2PF_ZIP <> 0 then
  begin
    bs := TAttachableMemoryStream.Create;
    bs.Attach(buf, sz);
    cs := TMemoryStream.Create;
    CompressStream(bs, cs);

    Result := Result + 'const'#13#10;
    Result := Result +
                Format('  %s_SIZE = %d;'#13#10#13#10,
                  [UpperCase(varname), sz]);
    Result := Result + 'var'#13#10;
    Result := Result +
                Format('  %s: %sarray[0..%s_SIZE - 1] of Byte;'#13#10#13#10,
                  [UpperCase(varname), pa, UpperCase(varname)]);

    zvarname := varname;
    if zvarname[1] = '_' then
      zvarname := 'Z' + zvarname
    else
      zvarname := 'Z_' + zvarname;
    zsize := cs.Size;
    Result := Result + b2p_data_to_decl(cs.Memory, zsize, zvarname, flags);
    cs.Free;
    bs.Free;
  end
  else
    Result := Result + b2p_data_to_decl(buf, sz, varname, flags);

  Result := Result + 'implementation'#13#10#13#10;

  if flags and B2PF_ZIP <> 0 then
  begin
    sret := 'uses'#13#10'  Classes, zlib;'#13#10#13#10;
    sret := sret + 'const'#13#10;
    sret := sret + '  BUFFERSIZE = 8192;'#13#10#13#10;
    sret := sret + 'var'#13#10'  Source, Dest: TMemoryStream;'#13#10;
    sret := sret + '  Decompressor: TDecompressionStream;'#13#10;
    sret := sret + Format('  Buffer: %sarray[0..BUFFERSIZE - 1] of Byte;'#13#10, [pa]);
    sret := sret + '  BytesRead: Integer;'#13#10#13#10;
    sret := sret + 'initialization'#13#10#13#10;
    sret := sret + '  Source := TMemoryStream.Create;'#13#10;
    sret := sret + Format('  Source.WriteBuffer(%s, %s_SIZE);'#13#10#13#10, [UpperCase(zvarname), UpperCase(zvarname)]);
    sret := sret + Format('  Assert(Source.Size = %s_SIZE);'#13#10, [UpperCase(zvarname)]);
    sret := sret + '  Source.Position := 0;'#13#10#13#10;
    sret := sret + '  Dest := TMemoryStream.Create;'#13#10#13#10;
    sret := sret + '  Decompressor := TDecompressionStream.Create(Source);'#13#10;
    sret := sret + '  try'#13#10;
    sret := sret + '    repeat'#13#10;
    sret := sret + '      BytesRead := Decompressor.Read(Buffer, SizeOf(Buffer));'#13#10;
    sret := sret + '      if BytesRead > 0 then'#13#10;
    sret := sret + '        Dest.WriteBuffer(Buffer, BytesRead);'#13#10;
    sret := sret + '    until BytesRead = 0;'#13#10;
    sret := sret + '  finally'#13#10;
    sret := sret + '    Decompressor.Free;'#13#10;
    sret := sret + '  end;'#13#10#13#10;
    sret := sret + Format('  Assert(Dest.Size = %s_SIZE);'#13#10, [UpperCase(varname)]);
    sret := sret + '  Dest.Position := 0;'#13#10#13#10;
    sret := sret + Format('  Dest.Read(%s, %s_SIZE);'#13#10, [UpperCase(varname), UpperCase(varname)]);
    sret := sret + '  Dest.Free;'#13#10;
    sret := sret + '  Source.Free;'#13#10#13#10'end.'#13#10;

    Result := Result + sret;
  end
  else
    Result := Result + 'end.'#13#10;
end;

function b2p_create_unit(const finp: string; const fout: string = ''; const flags: LongWord = 0): Boolean;
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

  unitname := b2p_pascalname(unitname);
  varname := b2p_pascalname(varname);
  
  if unitname = varname then
    varname := '_' + varname;

  outname := IncludeTrailingPathDelimiter(ExtractFilePath(finp)) + unitname + '.pas';

  // Prevent same file for input & output
  if UpperCase(outname) = UpperCase(finp) then
  begin
    unitname := unitname + '_unit';
    outname := IncludeTrailingPathDelimiter(ExtractFilePath(finp)) + unitname + '.pas';
  end;

  fs := TFileStream.Create(finp, fmOpenRead);
  try
    GetMem(buf, fs.Size);
    fs.Read(buf^, fs.Size);

    sl := TStringList.Create;
    try
      sl.Text := b2p_data_to_unit(buf, fs.Size, varname, unitname, flags);
      backupfile(outname);
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
