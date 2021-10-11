unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, OpenGL, ComCtrls, StdCtrls, Buttons, ExtDlgs;

type
  TRenderPanel = record
    DC:HDC;
    HRC:HGLRC;
    ps:TPaintStruct;
  end;

  TfrmBmpHView = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter2: TSplitter;
    Panel4: TPanel;
    Panel5: TPanel;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    Panel6: TPanel;
    Panel7: TPanel;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    Timer1: TTimer;
    Label1: TLabel;
    TrackBar1: TTrackBar;
    Label2: TLabel;
    TrackBar2: TTrackBar;
    Label3: TLabel;
    TrackBar3: TTrackBar;
    TrackBar4: TTrackBar;
    Label4: TLabel;
    bmp1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    SpeedButton1: TSpeedButton;
    OpenPictureDialog1: TOpenPictureDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure Panel3Resize(Sender: TObject);
    procedure TrackBar3Change(Sender: TObject);
    procedure TrackBar4Change(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure bmp1Click(Sender: TObject);
  private
    MyPanels:Array[1..4] of TRenderPanel;
    h,w:Integer;
    vx:Array of Array of Extended;//массив вершин
    nx:Array of Array of Array[1..3] of Extended;//массив нормалей
    cx:Array of Array of Array[1..3] of GLfloat;//массив цветов
    bmp:TBitmap;
    procedure InitOpenGL;
    procedure SetDCPixelFormat(DC:HDC);
    procedure CalcNormals(x1,y1,z1,x2,y2,z2,x3,y3,z3:Extended; var nx,ny,nz:Extended);
  end;

var
  frmBmpHView: TfrmBmpHView;

implementation

{$R *.dfm}

procedure TfrmBmpHView.InitOpenGL;
var
  i:Integer;
begin
  for i:=1 to 4 do
  begin
    case i of
    1: MyPanels[i].DC:=GetDC(Panel4.Handle);
    2: MyPanels[i].DC:=GetDC(Panel6.Handle);
    3: MyPanels[i].DC:=GetDC(Panel5.Handle);
    4: MyPanels[i].DC:=GetDC(Panel7.Handle);
    end;
    SetDCPixelFormat(MyPanels[i].DC);
    MyPanels[i].HRC:=wglCreateContext(MyPanels[i].DC);
    wglMakeCurrent(MyPanels[i].DC,MyPanels[i].HRC);
    glEnable(GL_DEPTH_TEST);
    glClearColor(0,0,0,1);
  end;
end;

procedure TfrmBmpHView.SetDCPixelFormat(DC:HDC);
var
  pfd:TPixelFormatDescriptor;
  nPixelFormat:Integer;
begin
  FillChar(pfd,SizeOf(pfd),0);
  pfd.dwFlags:=PFD_DOUBLEBUFFER or
               PFD_DRAW_TO_WINDOW or
               PFD_SUPPORT_OPENGL;
  nPixelFormat:=ChoosePixelFormat(DC,@pfd);
  SetPixelFormat(DC,nPixelFormat,@pfd);
end;


procedure TfrmBmpHView.FormCreate(Sender: TObject);
begin
  bmp:=TBitmap.Create;
  InitOpenGL;
  Left:=0;
  Top:=0;
  Width:=Screen.Width;
  Height:=Screen.Height;
  WindowState:=wsMaximized;
  Timer1.Enabled:=True;
end;

procedure TfrmBmpHView.FormDestroy(Sender: TObject);
var
  i:Integer;
begin
  Timer1.Enabled:=False;
  wglMakeCurrent(0,0);
  bmp.Destroy;
  Finalize(vx);
  Finalize(cx);
  Finalize(nx);
  for i:=1 to 4 do
  begin
    wglDeleteContext(MyPanels[i].HRC);
    case i of
    1: ReleaseDC(MyPanels[i].DC,Panel4.Handle);
    2: ReleaseDC(MyPanels[i].DC,Panel6.Handle);
    3: ReleaseDC(MyPanels[i].DC,Panel5.Handle);
    4: ReleaseDC(MyPanels[i].DC,Panel7.Handle);
    end;
    DeleteDC(MyPanels[i].DC);
  end;
end;

procedure TfrmBmpHView.CalcNormals(x1,y1,z1,x2,y2,z2,x3,y3,z3:Extended;
                                   var nx,ny,nz:Extended);
var
  wrki: Double;
  vx1,vy1,vz1,vx2,vy2,vz2: Double;
begin
  vx1:=x1-x2;
  vy1:=y1-y2;
  vz1:=z1-z2;
  vx2:=x2-x3;
  vy2:=y2-y3;
  vz2:=z2-z3;
  wrki:=sqrt(sqr(vy1*vz2-vz1*vy2)+sqr(vz1*vx2-vx1*vz2)+sqr(vx1*vy2-vy1*vx2));
  nx:=-(vy1 * vz2 - vz1 * vy2)/wrki;
  ny:=-(vz1 * vx2 - vx1 * vz2)/wrki;
  nz:=-(vx1 * vy2 - vy1 * vx2)/wrki;
end;

procedure TfrmBmpHView.Timer1Timer(Sender: TObject);
var
  i,j,k,dw,dh,dv:Integer;
  ps:TPaintStruct;
begin
  dw:=0;
  dh:=0;
  dv:=0;
  if (w>0) and (h>0) then
  begin
    dw:=w div 2;
    dh:=h div 2;
    dv:=25 div 2;
  end;
  for i:=1 to 4 do
  begin
    case i of
    1: BeginPaint(Panel4.Handle,ps);
    2: BeginPaint(Panel6.Handle,ps);
    3: BeginPaint(Panel5.Handle,ps);
    4: BeginPaint(Panel7.Handle,ps);
    end;
    wglMakeCurrent(MyPanels[i].DC,MyPanels[i].HRC);
    case i of
    1: glViewport(0,0,Panel4.Width,Panel4.Height);
    2: glViewport(0,0,Panel6.Width,Panel6.Height);
    3: glViewport(0,0,Panel5.Width,Panel5.Height);
    4: glViewport(0,0,Panel7.Width,Panel7.Height);
    end;
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    case i of
    1: gluPerspective(30,Panel4.Width/Panel4.Height,1,10000);
    2: gluPerspective(30,Panel6.Width/Panel6.Height,1,10000);
    3: gluPerspective(30,Panel5.Width/Panel5.Height,1,10000);
    4: gluPerspective(30,Panel7.Width/Panel7.Height,1,10000);
    end;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    glLoadIdentity;
    glTranslatef(0,0,-TrackBar2.Position);
    glRotatef(TrackBar4.Position,1,0,0);
    glRotatef(TrackBar3.Position,0,1,0);
    try
      if (w>5) and (h>5) then
        case i of
        1: begin
             glDisable(GL_LIGHTING);
             glDisable(GL_LIGHT0);
             glColor3f(1,1,1);
             glBegin(GL_LINES);
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);
                 glColor3f(cx[j,k+1,1],cx[j,k+1,2],cx[j,k+1,3]);
                 glVertex3f(j-dw,vx[j,k+1]-dv,k+1-dh);
               end;
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);
                 glColor3f(cx[j+1,k,1],cx[j+1,k,2],cx[j+1,k,3]);
                 glVertex3f(j+1-dw,vx[j+1,k]-dv,k-dh);
               end;
             glEnd;
           end;
        2: begin
             glEnable(GL_LIGHTING);
             glEnable(GL_LIGHT0);
             glColor3f(1,1,1);
             glBegin(GL_TRIANGLES);
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glNormal3f(nx[j,k,1],nx[j,k,2],nx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glNormal3f(nx[j+1,k,1],nx[j+1,k,2],nx[j+1,k,3]);
                 glVertex3f(j-dw+1,vx[j+1,k]-dv,k-dh);

                 glNormal3f(nx[j+1,k+1,1],nx[j+1,k+1,2],nx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glNormal3f(nx[j,k,1],nx[j,k,2],nx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glNormal3f(nx[j,k+1,1],nx[j,k+1,2],nx[j,k+1,3]);
                 glVertex3f(j-dw,vx[j,k+1]-dv,k-dh+1);

                 glNormal3f(nx[j+1,k+1,1],nx[j+1,k+1,2],nx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             glEnd;
           end;
        3: begin
             glEnable(GL_LIGHTING);
             glEnable(GL_LIGHT0);
             glEnable(GL_COLOR_MATERIAL);
             glColor3f(1,1,1);
             glBegin(GL_TRIANGLES);
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glNormal3f(nx[j,k,1],nx[j,k,2],nx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glColor3f(cx[j+1,k,1],cx[j+1,k,2],cx[j+1,k,3]);
                 glNormal3f(nx[j+1,k,1],nx[j+1,k,2],nx[j+1,k,3]);
                 glVertex3f(j-dw+1,vx[j+1,k]-dv,k-dh);

                 glColor3f(cx[j+1,k+1,1],cx[j+1,k+1,2],cx[j+1,k+1,3]);
                 glNormal3f(nx[j+1,k+1,1],nx[j+1,k+1,2],nx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glNormal3f(nx[j,k,1],nx[j,k,2],nx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glColor3f(cx[j,k+1,1],cx[j,k+1,2],cx[j,k+1,3]);
                 glNormal3f(nx[j,k+1,1],nx[j,k+1,2],nx[j,k+1,3]);
                 glVertex3f(j-dw,vx[j,k+1]-dv,k-dh+1);

                 glColor3f(cx[j+1,k+1,1],cx[j+1,k+1,2],cx[j+1,k+1,3]);
                 glNormal3f(nx[j+1,k+1,1],nx[j+1,k+1,2],nx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             glEnd;
             glDisable(GL_COLOR_MATERIAL);
           end;
        4: begin
             glBegin(GL_TRIANGLES);
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glColor3f(cx[j+1,k,1],cx[j+1,k,2],cx[j+1,k,3]);
                 glVertex3f(j-dw+1,vx[j+1,k]-dv,k-dh);

                 glColor3f(cx[j+1,k+1,1],cx[j+1,k+1,2],cx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             for j:=2 to w-2 do
               for k:=2 to h-2 do
               begin
                 glColor3f(cx[j,k,1],cx[j,k,2],cx[j,k,3]);
                 glVertex3f(j-dw,vx[j,k]-dv,k-dh);

                 glColor3f(cx[j,k+1,1],cx[j,k+1,2],cx[j,k+1,3]);
                 glVertex3f(j-dw,vx[j,k+1]-dv,k-dh+1);

                 glColor3f(cx[j+1,k+1,1],cx[j+1,k+1,2],cx[j+1,k+1,3]);
                 glVertex3f(j-dw+1,vx[j+1,k+1]-dv,k-dh+1);
               end;
             glEnd;
             glDisable(GL_COLOR_MATERIAL);
           end;
        end;
    except
      w:=0;
      h:=0;
      MessageBox(Handle,'Ошибка при прорисовке изображения',
                        'Ошибка',MB_OK or MB_ICONERROR);
    end;
    case i of
    1: EndPaint(Panel4.Handle,ps);
    2: EndPaint(Panel6.Handle,ps);
    3: EndPaint(Panel5.Handle,ps);
    4: EndPaint(Panel7.Handle,ps);
    end;
    SwapBuffers(MyPanels[i].DC);
  end;
end;

procedure TfrmBmpHView.TrackBar1Change(Sender: TObject);
begin
  Label1.Caption:='Время перерисовки ('+IntToStr(TrackBar1.Position)+' мс):';
  Timer1.Interval:=TrackBar1.Position;
end;

procedure TfrmBmpHView.TrackBar2Change(Sender: TObject);
begin
  Label2.Caption:='Дистанция ('+IntToStr(TrackBar2.Position)+'):';
end;

procedure TfrmBmpHView.Panel3Resize(Sender: TObject);
begin
  Panel3.Height:=ClientHeight div 2;
  Panel4.Width:=Panel3.Width div 2;
  Panel5.Width:=Panel3.Width div 2;
end;

procedure TfrmBmpHView.TrackBar3Change(Sender: TObject);
begin
  Label3.Caption:='Поворот по Y ('+IntToStr(TrackBar3.Position)+'):';  
end;

procedure TfrmBmpHView.TrackBar4Change(Sender: TObject);
begin
  Label4.Caption:='Поворот по X ('+IntToStr(TrackBar4.Position)+'):'; 
end;

procedure TfrmBmpHView.N3Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmBmpHView.N2Click(Sender: TObject);
begin
  MessageBox(Handle,PAnsiChar('BmpHViewer'+#13#10+
                    'Разработчик: Макаров М.М.'+#13#10+
                    'Дата создания: 18.04.2005'),
                    'О программе',
                    MB_OK or MB_ICONINFORMATION);
end;

procedure TfrmBmpHView.bmp1Click(Sender: TObject);
var
  i,j,k:Integer;
begin
  try
    if OpenPictureDialog1.Execute then
      if FileExists(OpenPictureDialog1.FileName) then
      begin
        bmp.Width:=0;
        bmp.Height:=0;
        bmp.LoadFromFile(OpenPictureDialog1.FileName);
        w:=bmp.Width;
        h:=bmp.Height;
        SetLength(vx,w);
        SetLength(nx,w);
        SetLength(cx,w);
        for i:=0 to w-1 do
        begin
          SetLength(vx[i],h);
          SetLength(nx[i],h);
          SetLength(cx[i],h);
        end;
        for i:=0 to w-1 do
          for j:=0 to h-1 do
          begin
            vx[i,j]:=(GetRValue(bmp.Canvas.Pixels[i,j])+
                     GetGValue(bmp.Canvas.Pixels[i,j])+
                     GetBValue(bmp.Canvas.Pixels[i,j]))/3/10;
            cx[i,j,1]:=GetRValue(bmp.Canvas.Pixels[i,j])/255;
            cx[i,j,2]:=GetGValue(bmp.Canvas.Pixels[i,j])/255;
            cx[i,j,3]:=GetBValue(bmp.Canvas.Pixels[i,j])/255;
          end;
        for i:=0 to w-1 do
          for j:=0 to h-1 do
            for k:=1 to 3 do
              nx[i,j,k]:=1;
        for i:=0 to w-2 do
          for j:=0 to h-2 do
            CalcNormals(i,vx[i,j],j,
                        i+1,vx[i+1,j],j,
                        i+1,vx[i+1,j+1],j+1,
                        nx[i,j,1],nx[i,j,2],nx[i,j,3]);
      end else
        MessageBox(Handle,
                   PAnsiChar('Файл '+OpenPictureDialog1.FileName+' не найден'),
                   'Ошибка',MB_OK or MB_ICONERROR);
  except
    MessageBox(Handle,
               PAnsiChar('Ошибка во время загрузки файла '+
                 OpenPictureDialog1.FileName),
               'Ошибка',MB_OK or MB_ICONERROR);
  end;
end;

end.
