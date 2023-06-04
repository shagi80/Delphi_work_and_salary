unit ShadowForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TShadow = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShadowShow(sender:TComponent);
procedure ShadowHide(sender:TComponent);

implementation

{$R *.dfm}

var
  Shadow: TShadow;
  vis   : boolean;

procedure ShadowShow(sender:TComponent);
begin
  if (not vis) then Shadow:=TShadow.Create(sender);
  vis:=true;
  Shadow.Show;
end;

procedure ShadowHide(sender:TComponent);
begin
  if Shadow.Owner=Sender then
    begin
      vis:=false;
      Shadow.Free;
    end else
    if (sender as Tform).Showing then (sender as Tform).Show;
end;

end.
