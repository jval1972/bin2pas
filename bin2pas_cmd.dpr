program bin2pas_cmd;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  b2p_core in 'b2p_core.pas',
  b2p_utils in 'b2p_utils.pas',
  b2p_options in 'b2p_options.pas';

const
  s_iniFile = 'bin2pas_cmd.ini';

function myfindfiles(const mask: string): TStringList;
var
  sr: TSearchRec;
  path: string;
begin
  Result := TStringList.Create;
  path := ExtractFilePath(mask);
  if FindFirst(mask, faAnyFile and not faDirectory, sr) = 0 then
  begin
    Result.Add(path + sr.Name);
    while FindNext(sr) = 0 do
      Result.Add(path + sr.Name);
    FindClose(sr);
  end;
end;

var
  i, j: integer;
  l, l2: TStringList;
  s: string;
  flags: LongWord;
begin
  writeln('Binary to Pascal source converter v.1.0 (Command line version)');
  writeln('2026, Jim Valavanis');

  LoadDefaults(ExtractFilePath(ParamStr(0)) + s_iniFile);

  l := TStringList.Create;

  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if FileExists(s) then
      l.Add(s)
    else if DirectoryExists(s) and (s <> '') then
    begin
      if s[Length(s)] <> '\' then
        s := s + '\';
      l2 := myfindfiles(s + '*.*');
      for j := 0 to l2.Count - 1 do
      begin
        s := l2.Strings[j];
        l.Add(s)
      end;
      l2.Free;
    end
    else if (Pos('*', s) > 0) or (Pos('?', s) > 0) then
    begin
      l2 := myfindfiles(s);
      for j := 0 to l2.Count - 1 do
      begin
        s := l2.Strings[j];
        l.Add(s);
      end;
      l2.Free;
    end;
  end;

  if l.Count = 0 then
  begin
    writeln;
    writeln('Please specify in command line the files you want to convert to Pascal source');
    writeln;
    writeln('Usage is:');
    writeln('  bin2pas_cmd [-Option1 value] File1 File2 [...] Dir1 Dir2 [...] Mask1 Mask2 [...]');
    writeln;
    writeln('Options:');
    for i := 0 to NUMDEFAULTS - 1 do
      if defaults[i].setable then
        Writeln('  -', defaults[i].name, defaults[i].helptext: 36 - Length(defaults[i].name) + Length(defaults[i].helptext));
    writeln;
    writeln('You can also use wildcards or directory names.');
  end
  else
  begin
    if l.Count > 1 then
      writeln('Converting ', l.Count, ' files:');

    flags := 0;
    if optUseCompression then
      flags := flags or B2PF_ZIP;
    if optUsePackedArrays then
      flags := flags or B2PF_PACKED;

    for i := 0 to l.Count - 1 do
    begin
      s := l.Strings[i];
      write('Converting ' + ExtractFileName(s) + '...');
      if b2p_create_unit(s, '', flags) then
        writeln('...Done!')
      else
        writeln('...Failed!')
    end;
  end;
  l.Free;

  SaveDefaults(ExtractFilePath(ParamStr(0)) + s_iniFile);
end.

