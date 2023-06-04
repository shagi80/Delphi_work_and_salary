unit ListView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, ComCtrls, ImgList, StdCtrls;

type
  TListViewForm = class(TForm)
    BtnPn: TPanel;
    CanelBtn: TSpeedButton;
    ImgLst: TImageList;
    CaptionLB: TLabel;
    Cap2LB: TLabel;
    DownBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    SB: TScrollBox;
    LV: TListView;
    procedure DownBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CanelBtnClick(Sender: TObject);
    procedure LVSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    function  ShowView(sender:TComponent):integer;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ListViewForm: TListViewForm;

implementation

{$R *.dfm}

uses ShadowForm, GlobalUnit;

var
  selind : integer;

procedure TListViewForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')then SB.VertScrollBar.Position:=SB.VertScrollBar.Position+ScrollSpeed;
  if ((Sender as TSpeedButton).name='UpBtn')then SB.VertScrollBar.Position:=SB.VertScrollBar.Position-ScrollSpeed;
end;

procedure TListViewForm.FormShow(Sender: TObject);
begin
  DownBtn.Margins.Left:=round((BtnPn.ClientWidth-(CanelBtn.Left+CanelBtn.Width-DownBtn.Left))/2);
  self.Left:=round((screen.Width-self.Width)/2);
  self.top:=round((screen.Height-self.Height)/2)-30;
end;

procedure TListViewForm.LVSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  pind : ^integer;
begin
  //Запоминаем значение поля DATA выбранного элемента в переменную модуля
  //и закрываем окно с мод результататом "ОК"
  pind:=item.Data;
  if pind<>nil then selind:=pind^ else selind:=-1;
  self.ModalResult:=mrOK;
end;

//Основная процедура. Возвращает значение типа INTEGER записанное
//в поле DATA выбранного элемента списка или -1 если ничего не выбранно
function TListViewForm.ShowView(sender:TComponent):integer;
begin
  result:=-1;
  lv.Items.BeginUpdate;
  if LV.Items.Count>8 then
    begin
      self.Width:=round(screen.Width*0.9);
      self.Height:=round(screen.Height*0.9);
    end else
    begin
      self.Width:=round(screen.Width*0.5);
      self.Height:=round(screen.Height*0.75);
    end;
  lv.Height:=lv.items.Item[LV.Items.Count-1].Top+200;
  lv.Items.EndUpdate;
  ShadowShow(sender);
  if self.ShowModal=mrOK then result:=selind;
  ShadowHide(sender);
end;

procedure TListViewForm.CanelBtnClick(Sender: TObject);
begin
  self.ModalResult:=mrCancel;
end;

end.
