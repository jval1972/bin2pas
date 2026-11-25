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

unit b2p_utils;

interface

uses
  Windows, SysUtils, Classes, zlib;

type
  String255 = string[255];
  PString255 = ^String255;

procedure memcpy(const dest0: pointer; const src0: pointer; count0: integer);

function CopyFile(const sname, dname: string): boolean;

procedure backupfile(const fn: string);

procedure CompressStream(Source, Dest: TStream; Level: TCompressionLevel = clDefault);

procedure DecompressStream(Source, Dest: TStream);

function I_VersionBuilt(fname: string = ''): string;

type
  TAttachableMemoryStream = class(TStream)
  protected
    FSize: integer;
    FPosition: integer;
    FMemory: pointer;
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Attach(const amemory: pointer; const asize: integer); virtual;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

procedure memcpy(const dest0: pointer; const src0: pointer; count0: integer);
begin
  Move(src0^, dest0^, count0);
end;

function CopyFile(const sname, dname: string): boolean;
var
  FromF, ToF: file;
  NumRead, NumWritten: Integer;
  Buf: array[1..8192] of Char;
  adir: string;
begin
  Result := False;

  if (Trim(sname) = '') or (Trim(dname) = '') then
    Exit;

  if FileExists(sname) then
  begin
    {$I-}
    AssignFile(FromF, sname);
    Reset(FromF, 1);
    adir := Trim(ExtractFilePath(dname));
    if adir <> '' then
      if not DirectoryExists(adir) then
        ForceDirectories(adir);
    AssignFile(ToF, dname);
    Rewrite(ToF, 1);
    repeat
      BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
      BlockWrite(ToF, Buf, NumRead, NumWritten);
    until (NumRead = 0) or (NumWritten <> NumRead);
    CloseFile(FromF);
    CloseFile(ToF);
    {$I+}
    Result := IOResult = 0;
  end;
end;

procedure backupfile(const fn: string);
var
  fbck: string;
  fname: string;
begin
  fname := Trim(fn);

  if fname = '' then
    Exit;

  if not FileExists(fname) then
    Exit;

  fbck := fname + '_' + FormatDateTime('yyyymmdd', Now);
  if FileExists(fbck) then
    fbck := fbck + '_latest';
  CopyFile(fname, fbck);
end;

procedure CompressStream(Source, Dest: TStream; Level: TCompressionLevel = clDefault);
var
  Compressor: TCompressionStream;
begin
  Compressor := TCompressionStream.Create(Level, Dest);
  try
    Compressor.CopyFrom(Source, 0);
  finally
    // Flushes remaining compressed bytes to Dest; does not free Dest
    Compressor.Free;
  end;
end;

procedure DecompressStream(Source, Dest: TStream);
var
  Decompressor: TDecompressionStream;
begin
  Decompressor := TDecompressionStream.Create(Source);
  try
    Dest.CopyFrom(Decompressor, 0);
  finally
    Decompressor.Free;
  end;
end;

function I_VersionBuilt(fname: string = ''): string;
var
  vsize: LongWord;
  zero: LongWord;
  buffer: PByteArray;
  res: pointer;
  len: LongWord;
  i: integer;
begin
  if fname = '' then
    fname := ParamStr(0);
  vsize := GetFileVersionInfoSize(PChar(fname), zero);
  if vsize = 0 then
  begin
    Result := '';
    exit;
  end;

  GetMem(buffer, vsize + 1);
  GetFileVersionInfo(PChar(fname), 0, vsize, buffer);
  VerQueryValue(buffer, '\StringFileInfo\040904E4\FileVersion', res, len);
  Result := '';
  for i := 0 to len - 1 do
  begin
    if PChar(res)^ = #0 then
      break;
    Result := Result + PChar(res)^;
    res := pointer(LongWord(res) + 1);
  end;
  FreeMem(buffer, vsize + 1);
end;

constructor TAttachableMemoryStream.Create;
begin
  Inherited Create;
  FSize := 0;
  FPosition := 0;
  FMemory := nil;
end;

destructor TAttachableMemoryStream.Destroy;
begin
  Inherited Destroy;
end;

function TAttachableMemoryStream.GetSize: Int64;
begin
  Result := FSize;
end;

procedure TAttachableMemoryStream.SetSize(NewSize: Longint);
begin
  FSize := NewSize;
end;

procedure TAttachableMemoryStream.Attach(const amemory: pointer; const asize: integer);
begin
  FMemory := amemory;
  FSize := asize;
  FPosition := 0;
end;

function TAttachableMemoryStream.Read(var Buffer; Count: Longint): Longint;
begin
  if Count + FPosition > FSize then
    Result := FSize - FPosition
  else
    Result := Count;

  if Result <= 0 then
  begin
    Result := 0;
    Exit;
  end;

  memcpy(@Buffer, pointer(integer(FMemory) + FPosition), Result);
  FPosition := FPosition + Result;
end;

function TAttachableMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
  if Count + FPosition > FSize then
    Result := FSize - FPosition
  else
    Result := Count;

  if Result <= 0 then
    Exit;

  memcpy(pointer(integer(FMemory) + FPosition), @Buffer, Result);
  FPosition := FPosition + Result;
end;

function TAttachableMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning:
      Result := Offset;
    soCurrent:
      Result := FPosition + Offset;
    soEnd:
      Result := FSize - Offset;
  else
    Result := 0;
  end;
  FPosition := Result;
end;

end.
