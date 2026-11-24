unit b2p_utils;

interface

uses
  Windows, SysUtils, Classes, zlib;

procedure memcpy(const dest0: pointer; const src0: pointer; count0: integer);

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
