unit MsgForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ImgList, StdCtrls, Buttons;

const
  msbEdit=0;
  msbOK=1;
  msbCancel=2;
  msbDel=3;

type
  TMessageForm = class(TForm)
    TextLB: TLabel;
    ImgLst: TImageList;
    BtnPn: TPanel;
    procedure BtnClick(sender : TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function ShowMSG(sender : TComponent; text:string;btns:array of integer):integer;

implementation

uses ShadowForm;

{$R *.dfm}

procedure TMessageForm.BtnClick(sender : TObject);
begin
  self.Tag:=StrToInt(copy((sender as TSpeedButton).name,4,MaxInt));
  self.close;
end;

function ShowMSG(sender : TComponent; text:string;btns:array of integer):integer;
const wd=80;
var
  Form: TMessageForm;
  i   : integer;
  btn : TSpeedButton;
begin
  Form:=TMessageForm.Create(application);
  Form.TextLB.Caption:=text;
  Form.Caption:='Сообщение';
  for I := 0 to high(btns) do
    begin
      btn:=TSpeedButton.Create(Form.BtnPn);
      btn.Flat:=true;
      btn.Height:=wd;
      btn.Width:=wd;
      Form.ImgLst.GetBitmap(btns[i],btn.Glyph);
      btn.Top:=10;
      btn.Left:=(wd+10)*i+round((Form.btnpn.ClientWidth-(wd*(high(btns)+1)+10*high(btns)))/2);
      btn.Name:='btn'+inttostr(btns[i]);
      btn.OnClick:=Form.BtnClick;
      btn.Layout:=blGlyphTop;
      btn.Font.Size:=10;
      btn.Font.Style:=[fsbold];
     { case btns[i] of
        msbEdit   : btn.Caption:='Изменить';
        msbOK     : btn.Caption:='Прниять';
        msbCancel : btn.Caption:='Отмена';
      end; }
      Form.btnpn.InsertControl(btn);
    end;
  Form.Tag:=0;
  ShadowShow(sender);
  Form.ShowModal;
  ShadowHide(sender);
  result:=Form.Tag;
  Form.Free;
end;

end.
