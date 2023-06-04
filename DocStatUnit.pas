unit DocStatUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DocListUnit, StdCtrls, Grids, Buttons, ExtCtrls;

type
  TDocStatForm = class(TForm)
    SG: TStringGrid;
    NameLB: TLabel;
    NoteLB: TLabel;
    BtnPn: TPanel;
    CancelBtn: TSpeedButton;
    UpBtn: TSpeedButton;
    DownBtn: TSpeedButton;
    procedure FormShow(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ShowWindow (sender: TComponent; doc:TListRec);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DocStatForm: TDocStatForm;

implementation

{$R *.dfm}

uses ShadowForm, MsgForm;

procedure TDocStatForm.CancelBtnClick(Sender: TObject);
begin
  self.Close;
end;

procedure TDocStatForm.DownBtnClick(Sender: TObject);
begin
  if ((Sender as TSpeedButton).name='DownBtn')and(SG.Selection.Top<SG.RowCount-1) then
    SG.Selection:=TGridRect(rect(0,Sg.Selection.Top+1,SG.ColCount-1,Sg.Selection.Top+1));
  if ((Sender as TSpeedButton).name='UpBtn')and(Sg.Selection.Top>1) then
    SG.Selection:=TGridRect(rect(0,Sg.Selection.Top-1,SG.ColCount-1,Sg.Selection.Top-1));
  if Sg.Selection.Top>=SG.TopRow+SG.VisibleRowCount then SG.TopRow:=SG.TopRow+1;
  if Sg.Selection.Top<SG.TopRow then SG.TopRow:=SG.TopRow-1;
end;

procedure TDocStatForm.FormShow(Sender: TObject);
begin
  DownBtn.Margins.Left:=round((BtnPn.ClientWidth-(CancelBtn.Left+CancelBtn.Width-DownBtn.Left))/2);
end;

procedure TDocStatForm.ShowWindow (sender: TComponent; doc:TListRec);
var
  str : string;
  i   : integer;
begin
  ShadowShow(sender);
  SG.Cells[0,0]:=' Дата';
  SG.Cells[1,0]:=' Время';
  SG.Cells[2,0]:=' Пользователь';
  SG.Cells[3,0]:=' Действие';
  SG.ColWidths[3]:=SG.ClientWidth-Sg.ColWidths[0]-Sg.ColWidths[1]-Sg.ColWidths[2]-20;
  str:=DocTypeLst[doc.typedoc];
  str:=str+' №'+FormatFloat('000000',doc.Num)+' от '+ FormatDateTime('dd mmm yy (ddd)',doc.Date);
  str:=AnsiUpperCase(str);
  NameLB.Caption:=str;
  NoteLB.Visible:=Length(doc.note)>0;
  NoteLB.Caption:=doc.note;
  if doc.StatCount>0 then
    begin
      SG.RowCount:=doc.StatCount+1;
      for I := 0 to doc.StatCount - 1 do
        begin
          SG.Cells[0,i+1]:=FormatDateTime('dd mmm yy (ddd)',doc.StatItems[i].time);
          SG.Cells[1,i+1]:=FormatDateTime('hh:mm',doc.StatItems[i].time);
          SG.Cells[2,i+1]:=doc.StatItems[i].user.name;
          SG.Cells[3,i+1]:=DocStatLst[doc.StatItems[i].stat];
        end;
      SG.Enabled:=true;
    end else
    begin
      SG.RowCount:=2;
      SG.Rows[1].Clear;
      SG.Enabled:=false;
    end;
  self.ShowModal;
  SG.Selection:=TGridRect(rect(0,1,SG.ColCount-1,1));
  ShadowHide(sender);
end;


end.
