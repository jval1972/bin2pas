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

unit frm_message;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmMessage = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    Button1: TButton;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure FRMMessage(const x: string);

implementation

{$R *.dfm}

procedure TfrmMessage.FormCreate(Sender: TObject);
begin
  Caption := Application.Title;
end;

procedure FRMMessage(const x: string);
var
  s: TStringList;
  f: TfrmMessage;
begin
  s := TStringList.Create;
  s.Text := x;
  while s.Count < 6 do
    s.Add('');
  f := TfrmMessage.Create(nil);
  try
    f.Label1.Caption := s.Strings[0];
    f.Label2.Caption := s.Strings[1];
    f.Label3.Caption := s.Strings[2];
    f.Label4.Caption := s.Strings[3];
    f.Label5.Caption := s.Strings[4];
    f.Label6.Caption := s.Strings[5];
    f.ShowModal;
  finally
    f.Free;
  end;
  s.Free;
end;

end.
