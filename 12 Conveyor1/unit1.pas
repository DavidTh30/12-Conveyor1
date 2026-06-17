unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, StdCtrls,
  ExtCtrls, EpikTimer, BGRABitmap,BGRABitmapTypes, Math, LCLIntf, BGRAPath;

  type
  RandomFlow = record
    Angle:Integer;
    Thickness:Tpoint;
  end;

  type
  Animation = record
    Life:Boolean;
    Visible:Boolean;
    EnableLifeTime:Boolean;
    Index:Integer;
    AnimatType:Integer;
    Frame_Speed: Integer;
    Remain_Speed:Integer;
    TotalFrame: Integer;
    Actual_Frame: Integer;
    MovingSpeed:Tpoint;
    Angle:Extended;
    Position:Tpoint;
    Flow_:RandomFlow;
    PathPosition, PathSpeed, PathLength: single;
    TotalLifeTime: integer;
    ActualLifeTime: integer;
    RemainLifeTime: integer;
    Bitmap_: array of Integer;
  end;
  type
  Inform = record
    Previous: Float;
    TimePerFrame: Float;
    LinePerFrame: Integer;
    FramePerSec: Integer;
    ActualElapsed: Float;
    LineLeftover: Integer;
    Speed_frame:Extended;
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Label3: TLabel;
    PaintBox2: TPaintBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure Main_Loop();
    Function TransparentBMP_ToBuffer(filename: string): TBGRABitmap;
    Function ManualTransparentBMP_ToBuffer(filename: string; Transparent:TBGRAPixel): TBGRABitmap;
    procedure SetUpValue();
  end;

var
  Form1: TForm1;
  timer_: TEpikTimer;
  Run_:Boolean;
  Background_, bmp, bmp2: TBGRABitmap;
  Grid_:Tpoint;
  c: TBGRAPixel;
  Trect_:Trect;
  Positioning:integer;
  RotageObject: array of Animation;
  BitmapAnimation: array of TBGRABitmap;
  Information:Inform;
  TotalRotageObject, TotalBitmapAnimation:integer;

  pts: array of TPointF;
  FPath: TBGRAPath;
  FPathCursor: TBGRAPathCursor;
  FPathPos: single;
  Style_: TSplineStyle;
  TotalPoints:integer;
  Closed_: boolean;

implementation

{$R *.lfm}

{ TForm1 }
Procedure TForm1.SetUpValue();
var
  i, i2:integer;
begin

  FPathPos := 0;
  setlength(pts,7);
  pts[0] := PointF(72,324);
  pts[1] := pointF(117,323);
  pts[2] := pointF(188,297);
  pts[3] := pointF(188,136);
  pts[4] := pointF(188,69);
  pts[5] := pointF(240,37);
  pts[6] := pointF(281,37);

  //if Inside then Style_ := ssInsideWithEnds else
  //if Crossing then Style_ := ssCrossingWithEnds else
  //if Outside then Style_ := ssOutside else
  //if Rounded then Style_ := ssRoundOutside else
  //if VertexToSide then Style_ := ssVertexToSide;
  Style_ := ssInsideWithEnds;
  Closed_:=False;
  TotalPoints := length(pts);

  if FPath = nil then
  begin
    FPath := TBGRAPath.Create;
    if Closed_ then
      FPath.closedSpline(slice(pts,TotalPoints), Style_)
    else
      FPath.openedSpline(slice(pts,TotalPoints), Style_);
  end;

  if FPathCursor = nil then
  begin
    FPathCursor := FPath.CreateCursor;
    FPathCursor.LoopPath:= true;
    FPathCursor.Position := FPathPos*FPathCursor.PathLength;
  end;


  Information.Speed_frame:=0.02;
  timer_ := TEpikTimer.Create(nil);
  Run_:=False;
  TotalBitmapAnimation:=4;
  setlength(BitmapAnimation,TotalBitmapAnimation);
  c := ColorToBGRA(rgb(255,255,255));

  //Load your bitmap here
  for i:=0 to TotalBitmapAnimation-1 do
    BitmapAnimation[i] := ManualTransparentBMP_ToBuffer('Fluff'+IntToStr(i+1)+'.png',c);

  TotalRotageObject:=250;
  Randomize;
  setlength(RotageObject,TotalRotageObject);
  for i := 0 to TotalRotageObject-1 do  //20 object
  begin
    RotageObject[i].Life:=False;
    RotageObject[i].Visible:=True;
    RotageObject[i].Index:=i;
    RotageObject[i].Actual_Frame:=0;
    RotageObject[i].AnimatType:=2;
    RotageObject[i].Frame_Speed:=7;
    RotageObject[i].Remain_Speed:=RotageObject[i].Frame_Speed;
    RotageObject[i].MovingSpeed:=Point(0,0);
    RotageObject[i].Position:=Point(15,15);//Point((i*30)+10,50);
    RotageObject[i].Angle:=0;
    RotageObject[i].TotalFrame:=1;
    setlength(RotageObject[i].Bitmap_,RotageObject[i].TotalFrame);
    for i2:=0 to RotageObject[i].TotalFrame-1 do
      RotageObject[i].Bitmap_[i2] := Random(TotalBitmapAnimation);
    RotageObject[i].PathPosition:=0;
    RotageObject[i].PathSpeed:=3;
    RotageObject[i].PathLength:=FPathCursor.PathLength;
    RotageObject[i].Flow_.Thickness:=Point(2,2);
    RotageObject[i].Flow_.Angle:=10;
  end;

  FPathCursor.Position:=0;
end;

Function TForm1.ManualTransparentBMP_ToBuffer(filename: string; Transparent:TBGRAPixel): TBGRABitmap;
var
  OriginalBMP: TBGRABitmap;
begin
  OriginalBMP := TBGRABitmap.Create(filename);
  OriginalBMP.ReplaceColor(Transparent,BGRAPixelTransparent);
  ManualTransparentBMP_ToBuffer := TBGRABitmap.Create(OriginalBMP.Width,OriginalBMP.Height);       //result
  ManualTransparentBMP_ToBuffer.PutImage(0,0,OriginalBMP,dmSet,255);
  OriginalBMP.Free;
end;

Function TForm1.TransparentBMP_ToBuffer(filename: string): TBGRABitmap;
var
  OriginalBMP: TBGRABitmap;
  //Trect_:Trect;
begin
  OriginalBMP := TBGRABitmap.Create(filename);
  OriginalBMP.ReplaceColor(OriginalBMP.GetPixel(0,0),BGRAPixelTransparent);
  TransparentBMP_ToBuffer := TBGRABitmap.Create(OriginalBMP.Width,OriginalBMP.Height);       //result
  TransparentBMP_ToBuffer.PutImage(0,0,OriginalBMP,dmSet,255);
  //TransparentBMP_ToBuffer.Rectangle(OriginalBMP.Width,0,OriginalBMP.Width,OriginalBMP.Height,BGRABlack,BGRA(0,0,0,64),dmDrawWithTransparency);

  //Trect_.TopLeft.x:=0;
  //Trect_.TopLeft.y:=0;
  //Trect_.BottomRight.x:=round(OriginalBMP.Width/2);
  //Trect_.BottomRight.y:=round(OriginalBMP.Height/2);
  //TransparentBMP_ToBuffer.PutImagePart(0,0,OriginalBMP,IT,dmSet,255); //TransparentBMP_ToBuffer.PutImagePart(0,0,OriginalBMP,IT,dmDrawWithTransparency);
  OriginalBMP.Free;
end;

procedure TForm1.Main_Loop();
var
  i,i2:Integer;
  Frame_, Line_, Line_Frame:integer;
  OP,AD,DE:Extended;
  New_pt, pt:TPointF;
  //Tangent: TPointF;
begin
  if Not Run_ then
  begin
    Run_:=True;
    Information.Previous:=0;
    Frame_:=0;
    Line_:=0;
    timer_.Clear;
    timer_.Start;

    while Run_ do
    begin
      Line_Frame:=0;
      application.ProcessMessages; //Work one program only   Case 1.

      //Run your program here  => Finish up your brackground

      bmp.PutImage(0,0,Background_,dmDrawWithTransparency);


      //Run your program here  => Finish up your Object
      ////bmp.ArrowEndAsClassic;
      //if Assigned(FPath) then
      //begin
      //  for i := 0 to TotalPoints-1 do
      //    bmp.FillEllipseAntialias(pts[i].x,pts[i].y,5,5,BGRA(255,100,100,100));
      //  FPath.stroke(bmp, BGRABlack, 2);
      //  //bmp.DrawPolyLineAntialiasAutocycle(FPath.ToPoints(0.1),BGRABlack,2);
      //end;

      //Create you random flow here
      if random(2) =1 then
      begin
        i2:=random(TotalRotageObject-1-4);
        for i:=i2 to i2+4 do
          if (random(2)=1) and (not RotageObject[i].Life) then RotageObject[i].Life:=True;
      end;

      for i:=0 to TotalRotageObject-1 do
      begin
        if (RotageObject[i].Life) then
        begin

          if (RotageObject[i].AnimatType=2) then
          begin
            FPathCursor.Position:=RotageObject[i].PathPosition;
            RotageObject[i].Position.x:=round(FPathCursor.CurrentCoordinate.x);
            RotageObject[i].Position.y:=round(FPathCursor.CurrentCoordinate.y);

            pt := FPathCursor.CurrentCoordinate;
            FPathCursor.MoveForward(RotageObject[i].PathSpeed, True); //Jump = True   Not jump = False
            New_pt:= FPathCursor.CurrentCoordinate;

            OP:=0; AD:=0; DE:=0;
            OP:=pt.y-New_pt.y;
            AD:=New_pt.x-pt.x;
            DE:=(ArcTan2((OP),(AD)))*(180.0/pi);    //RadToDeg(ArcTan2((OP),(AD)));
            DE:=DE+Random(RotageObject[i].Flow_.Angle);
            RotageObject[i].Angle:=DE*(-1);

            RotageObject[i].PathPosition:=FPathCursor.Position;
            if RotageObject[i].PathPosition + RotageObject[i].PathSpeed > 423 then RotageObject[i].Life:=False;
          end;

          if RotageObject[i].Visible then bmp.PutImageAngle(RotageObject[i].Position.x+random(RotageObject[i].Flow_.Thickness.x),
                            RotageObject[i].Position.y+random(RotageObject[i].Flow_.Thickness.y),
                            BitmapAnimation[RotageObject[i].Bitmap_[RotageObject[i].Actual_Frame]],
                            RotageObject[i].Angle,
                           (BitmapAnimation[RotageObject[i].Bitmap_[RotageObject[i].Actual_Frame]].Width / 2),
                           (BitmapAnimation[RotageObject[i].Bitmap_[RotageObject[i].Actual_Frame]].Height / 2));

          RotageObject[i].Remain_Speed:=RotageObject[i].Remain_Speed-1;

          if RotageObject[i].Remain_Speed<=0 then
          begin
            RotageObject[i].Remain_Speed:=RotageObject[i].Frame_Speed;
            RotageObject[i].Actual_Frame:=RotageObject[i].Actual_Frame+1;
            if RotageObject[i].Actual_Frame>RotageObject[i].TotalFrame-1 then
            begin
              RotageObject[i].Actual_Frame:=0;
            end;
          end;
        end;
      end;


      i2:=0;
      for i:=0 to TotalRotageObject-1 do if not RotageObject[i].Life then begin RotageObject[i].PathPosition:=0; end else i2:=i2+1;

      //Any text information here  => Finish up your text status
      c := ColorToBGRA(rgb(0,105,208));
      bmp.FontName := 'Times New Roman';
      bmp.FontAntialias:= true;
      bmp.FontHeight:=12;
      bmp.FontStyle:=[fsBold];
      bmp.TextOut(450,(bmp.FontFullHeight*0)+5,'Total life ='+IntToStr(i2),c);
      bmp.TextOut(450,(bmp.FontFullHeight*1)+5,'Total Length ='+IntToStr(round(FPathCursor.PathLength)),c); //Raw material=423

      //Render here   => Finish up your rander
      bmp.Draw(PaintBox2.Canvas,0,0,True);

      //Clear your hardware here

      while ((timer_.Elapsed -Information.Previous <= Information.Speed_frame) and
             (timer_.Elapsed < 1) and (Run_)) do //and (timer_.Elapsed < 1) do
      begin
        //application.ProcessMessages; //Share CUP  Case 2

        //Detect hardware here

        Line_:=Line_+1;
        Line_Frame:=Line_Frame+1;

        //Run_:=not Run_; //For run only 1 cycle
      end;

      //Other status here
      Information.TimePerFrame:=(timer_.Elapsed -Information.Previous)*1000;
      Information.Previous:=timer_.Elapsed;
      Frame_:=Frame_+1;
      if timer_.Elapsed >= 1 then
      begin
        timer_.Stop;
        Information.ActualElapsed:=timer_.Elapsed*1000;
        Information.FramePerSec:=Frame_;
        Information.LineLeftover:=Line_;
        Information.LinePerFrame:=Line_Frame;

        Information.Previous:=0;
        Frame_:=0;
        Line_:=0;
        timer_.Clear;
        timer_.Start;
      end;

      //You can move your render to here. (!It is up to you)

    end;

    If not Run_ then  timer_.Stop;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, i2, i3 : Integer;

begin
  SetUpValue();

  Grid_.X:=26;
  Grid_.y:=15;

  if Grid_.X<0 then Grid_.X:=0;
  if Grid_.Y<0 then Grid_.Y:=0;

  Background_ := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00FFFFFF));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00FFFFFF));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp2 := TBGRABitmap.Create(Round(PaintBox2.Width/(Grid_.X+1))+1,PaintBox2.Height, ColorToBGRA($00CCCCCC));//ColorToBGRA($00CCCCCC)//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))

  Background_.Canvas2D.lineWidth:=1;
  Background_.Canvas2D.strokeStyle ('rgb(55,255,55)');
  Background_.Canvas2D.stroke();

  Background_.JoinStyle := pjsBevel;
  Background_.PenStyle := psSolid;

  c := ColorToBGRA(rgb(50,50,50));

  i2:=Round(PaintBox2.Width/(Grid_.X+1));
  i3:=0;
  for i := 0 to Grid_.X do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(i3,0), PointF(i3,PaintBox2.Height)],c,1);
  end;

  i2:=Round(PaintBox2.Height/(Grid_.Y+1));
  i3:=0;
  for i := 0 to Grid_.Y do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(0,i3), PointF(PaintBox2.Width,i3)],c,1);
  end;

  c := ColorToBGRA(rgb(255,255,255));
  Background_ := ManualTransparentBMP_ToBuffer('OverView_.png',c);

  Trect_.TopLeft.x:=0;
  Trect_.TopLeft.y:=0;
  Trect_.BottomRight.x:=bmp2.Width;
  Trect_.BottomRight.y:=bmp2.Height;
  bmp2.PutImagePart(0,0,Background_,Trect_,dmDrawWithTransparency);
  //bmp2.DrawPolyLineAntialias([PointF(0,0), PointF(0,bmp2.Height)],c,1);

  Positioning:=(PaintBox2.Width mod (Trect_.BottomRight.x-1));

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Main_Loop();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Information.Speed_frame:=0.02;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Information.Speed_frame:=0.029;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Run_:=False;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Information.Speed_frame:=0.1;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Run_:=False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  i:integer;
begin
  timer_.Free;
  Background_.Free;
  bmp.Free;
  bmp2.Free;
  for i:=0 to TotalBitmapAnimation-1 do  FreeAndNil(BitmapAnimation[i]);
  FreeAndNil(FPathCursor);
  FreeAndNil(FPath);
end;


end.

