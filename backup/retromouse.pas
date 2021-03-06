// A Retromachine mouse interface unit.
// A hardware dependent unit
// -----------------------------------------------------------------------------
// --- This version for RPi4/Linux - pik33 @20190707
// -----------------------------------------------------------------------------


unit retromouse;

interface

uses sysutils,classes;

type TMousereport=array[0..3] of integer;

     PMouseData = ^TMouseData;
     TMouseData = record
                  Buttons:Word;
                  OffsetX:integer;
                  OffsetY:integer;
                  OffsetWheel:integer;
                  end;

     TRetroMouse = class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var mouse_report_buffer: array[0..1023] of integer;
    mouse_rb_start:integer=0;
    mouse_rb_end:integer=0;
    mouse_report_buffer_active:boolean=false;
    mouserecord:array[0..3] of integer;
    mouserecordb:array[0..7] of byte absolute mouserecord;
    mousetype:integer=0;
    mousepresent:integer; // todo: more than 1

mousereportthread:TRetroMouse;

function getmousereport:TMousereport;
procedure startmousereportbuffer;
procedure stopmousereportbuffer;


implementation

type md=record
        d1,d2:integer;
        c1,c2:word;
        b:integer;
        end;

var mousefile:integer;
    m:array[0..23] of byte;
    m2:md absolute m;

procedure stopmousereportbuffer;

begin
mouse_report_buffer_active:=false;
end;

procedure startmousereportbuffer;

begin
mouse_report_buffer_active:=true;
end;

function getmousereport:Tmousereport;

var ii:integer;

begin
if mouse_rb_end <>mouse_rb_start then begin
  for ii:=0 to 3 do result[ii]:=mouse_report_buffer[4*mouse_rb_start+ii];
  mouse_rb_start:=(mouse_rb_start+1) and $7F;
  end
else
  for ii:=0 to 3 do result[ii]:=$7FFFFFFF;
end;

constructor TRetroMouse.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


function initialize:integer;

var i:integer;
    name:string;
    rec:TSearchrec;

begin
result:=0;
// find a mouse event file
if findfirst('/dev/input/by-id/*event-mouse',faanyfile,rec)=0 then
  begin
  name:=rec.name;
  findclose(rec);
  end;
name:='/dev/input/by-id/'+name;
//writeln('name= ',name);

// Open the mouse file for reading
i:=0;
repeat
  mousefile:=fileopen(name,$40);
  inc(i);
  sleep(10);
until (mousefile>0) or (i>10);
if i>10 then result:=-1 // cannot open a mouse file
else
  begin
  mousereportthread:=TRetroMouse.create(true);
  mousereportthread.start;
  end;
end;



procedure TRetroMouse.execute;

var name:string;
    il:integer;

begin
repeat
  if mousepresent=0 then
    begin
    il:=fileread(mousefile,m[0],24);
 //   if il<>24 then
//      begin
 //     fileclose(mousefile);
//      mousepresent:=-1;
      //todo: try to reopen
//      end
 //   else
    //fill the buffer
      begin
 //     if mouse_report_buffer_active then
        begin
        if not ((mouse_rb_end=(mouse_rb_start-1)) or ((mouse_rb_end=127) and (mouse_rb_start=0))) then
          begin
          mouse_report_buffer[4*mouse_rb_end+0]:=m2.c1;
          mouse_report_buffer[4*mouse_rb_end+1]:=m2.c2;
          mouse_report_buffer[4*mouse_rb_end+2]:=m2.b;
          mouse_report_buffer[4*mouse_rb_end+3]:=0;
          mouse_rb_end:=(mouse_rb_end+1) and $7f;
          end;
        end;
      end;
    end;
  sleep(1);
  until terminated
end;


initialization
mousepresent:=initialize;
end.
