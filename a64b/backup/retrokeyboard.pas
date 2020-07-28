// A Retromachine keyboard interface unit.
// A hardware dependent unit
// -----------------------------------------------------------------------------
// --- This version for RPi4/Linux - pik33 @20190707
// -----------------------------------------------------------------------------

unit retrokeyboard;

interface

uses Classes, SysUtils;

type TRetroKbd = class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

const

// ----- Keyboard translation table ----------------

kbdcodes:array[0..127] of array[0..3] of Char = (
      {0}   (#0, #0, #0, #0),       {Reserved}
      {1}   (#155, #155, #0, #0),   {Keyboard Escape}
      {2}   ('1', '!', #4, #0),     {Keyboard 1 or !}
      {3}   ('2', '@', #5, #0),     {Keyboard 2 or @}
      {4}   ('3', '#', #6, #0),     {Keyboard 3 or #}
      {5}   ('4', '$', #7, #0),     {Keyboard 4 or $}
      {6}   ('5', '%', #8, #0),     {Keyboard 5 or %}
      {7}   ('6', '^', #9, #0),     {Keyboard 6 or ^}
      {8}   ('7', '&', #10, #0),    {Keyboard 7 or &}
      {9}   ('8', '*', #11, #0),    {Keyboard 8 or *}
      {10}  ('9', '(', #12, #0),    {Keyboard 9 or (}
      {11}  ('0', ')', #13, #0),    {Keyboard 0 or )}
      {12}  ('-', '_', #0, #0),     {Keyboard - or _}
      {13}  ('=', '+', #0, #0),     {Keyboard = or +}
      {14}  (#136, #136, #0, #0),   {Keyboard Backspace}
      {15}  (#137, #137, #0, #0),   {Keyboard Tab}
      {16}  ('q', 'Q', #0, #0),     {Keyboard q or Q}
      {17}  ('w', 'W', #0, #0),     {Keyboard w or W}
      {18}  ('e', 'E', #24, #15),   {Keyboard e or E}
      {19}  ('r', 'R', #0, #0),     {Keyboard r or R}
      {20}  ('t', 'T', #0, #0),     {Keyboard t or T}
      {21}  ('y', 'Y', #0, #0),     {Keyboard y or Y}
      {22}  ('u', 'U', #0, #0),     {Keyboard u or U}
      {23}  ('i', 'I', #0, #0),     {Keyboard i or I}
      {24}  ('o', 'O', #30, #21),   {Keyboard o or O}
      {25}  ('p', 'P', #0, #0),     {Keyboard p or P}
      {26}  ('[', '{', #0, #0),     {Keyboard [ or Left Brace}
      {27}  (']', '}', #0, #0),     {Keyboard ] or Right Brace}
      {28}  (#141, #141, #0, #0),   {Keyboard Enter}
      {29}  (#0, #0, #0, #0),       {Keyboard RCtl}
      {30}  ('a', 'A', #23, #14),   {Keyboard a or A}
      {31}  ('s', 'S', #27, #18),   {Keyboard s or S}
      {32}  ('d', 'D', #0, #0),     {Keyboard d or D}
      {33}  ('f', 'F', #0, #0),     {Keyboard f or F}
      {34}  ('g', 'G', #0, #0),     {Keyboard g or G}
      {35}  ('h', 'H', #0, #0),     {Keyboard h or H}
      {36}  ('j', 'J', #0, #0),     {Keyboard j or J}
      {37}  ('k', 'K', #0, #0),     {Keyboard k or K}
      {38}  ('l', 'L', #31, #22),   {Keyboard l or L}
      {39}  (';', ':', #0, #0),     {Keyboard ; or :}
      {40}  ('''', '"', #0, #0),    {Keyboard ' or "}
      {41}  ('`', '~', #3, #0),     {Keyboard ` or ~}
      {42}  (#0, #0, #0, #0),       {Keyboard RShift}
      {43}  ('\', '|', #0, #0),     {Keyboard \ or |}
      {44}  ('z', 'Z', #29, #20),   {Keyboard z or Z}
      {45}  ('x', 'X', #28, #19),   {Keyboard x or X}
      {46}  ('c', 'C', #25, #16),   {Keyboard c or C}
      {47}  ('v', 'V', #0, #0),     {Keyboard v or V}
      {48}  ('b', 'B', #0, #0),     {Keyboard b or B}
      {49}  ('n', 'N', #26, #17),   {Keyboard n or N}
      {50}  ('m', 'M', #0, #0),     {Keyboard m or M}
      {51}  (',', '<', #0, #0),     {Keyboard , or <}
      {52}  ('.', '>', #0, #0),     {Keyboard . or >}
      {53}  ('/', '?', #0, #0),     {Keyboard / or ?}
      {54}  (#0, #0, #0, #0),       {Keyboard RShift}
      {55}  ('*', '*', #0, #0),     {Keypad *}
      {56}  (#0, #0, #0, #0),       {Keyboard RAlt}
      {57}  (' ', ' ', #0, #0),     {Keyboard Spacebar}
      {58}  (#185, #185, #0, #0),   {Keyboard Caps Lock}
      {59}  (#186, #0, #0, #0),     {Keyboard F1}
      {60}  (#187, #0, #0, #0),     {Keyboard F2}
      {61}  (#188, #0, #0, #0),     {Keyboard F3}
      {62}  (#189, #0, #0, #0),     {Keyboard F4}
      {63}  (#190, #0, #0, #0),     {Keyboard F5}
      {64}  (#191, #0, #0, #0),     {Keyboard F6}
      {65}  (#192, #0, #0, #0),     {Keyboard F7}
      {66}  (#193, #0, #0, #0),     {Keyboard F8}
      {67}  (#194, #0, #0, #0),     {Keyboard F9}
      {68}  (#195, #0, #0, #0),     {Keyboard F10}
      {69}  (#210, #0, #0, #0),     {Keyboard Num Lock}
      {70}  (#199, #0, #0, #0),     {Keyboard Scroll Lock}
      {71}  ('7', '7', #0, #0),     {Keypad 7 and Home}
      {72}  ('8', '8', #0, #0),     {Keypad 8 and Up Arrow}
      {73}  ('9', '9', #0, #0),     {Keypad 9 and PageUp}
      {74}  ('-', '-', #0, #0),     {Keypad -}
      {75}  ('4', '4', #0, #0),     {Keypad 4 and Left Arrow}
      {76}  ('5', '5', #0, #0),     {Keypad 5}
      {77}  ('6', '6', #0, #0),     {Keypad 6 and Right Arrow}
      {78}  ('+', '+', #0, #0),     {Keypad +}
      {79}  ('1', '1', #0, #0),     {Keypad 1 and End}
      {80}  ('2', '2', #0, #0),     {Keypad 2 and Down Arrow}
      {81}  ('3', '3', #0, #0),     {Keypad 3 and PageDn}
      {82}  ('0', '0', #0, #0),     {Keypad 0 and Insert}
      {83}  ('.', #127, #0, #0),    {Keypad . and Delete}
      {84}  (#0, #0, #0, #0),       {???}
      {85}  (#0, #0, #0, #0),       {???}
      {86}  (#0, #0, #0, #0),       {???}
      {87}  (#196, #0, #0, #0),     {Keyboard F11}
      {88}  (#197, #0, #0, #0),     {Keyboard F12}
      {89}  (#0, #0, #0, #0),       {???}
      {90}  (#0, #0, #0, #0),       {???}
      {91}  (#0, #0, #0, #0),       {???}
      {92}  (#0, #0, #0, #0),       {???}
      {93}  (#0, #0, #0, #0),       {???}
      {94}  (#0, #0, #0, #0),       {???}
      {95}  (#0, #0, #0, #0),       {???}
      {96}  (#141,#141, #0, #0),    {Keypad Enter}
      {97}  (#0, #0, #0, #0),       {Keyboard LCtl}
      {98}  ('/', '/', #0, #0),     {Keypad /}
      {99}  (#198, #0, #0, #0),     {Keyboard Print Screen}
      {100} (#0, #0, #0, #0),       {Keyboard LAlt}
      {101} (#0, #0, #0, #0),       {???}
      {102}  (#202, #0, #0, #0),    {Keyboard Home}
      {103}  (#209, #0, #0, #0),    {Keyboard Up Arrow}
      {104}  (#203, #0, #0, #0),    {Keyboard PageUp}
      {105}  (#207, #0, #0, #0),    {Keyboard Left Arrow}
      {106}  (#206, #0, #0, #0),    {Keyboard Right Arrow}
      {107}  (#204, #0, #0, #0),    {Keyboard End}
      {108}  (#208, #0, #0, #0),    {Keyboard Down Arrow}
      {109}  (#205, #0, #0, #0),    {Keyboard PageDn}
      {110}  (#201, #0, #0, #0),    {Keyboard Insert}
      {111}  (#127, #127, #0, #0),  {Keyboard Delete}
      {112}  (#0, #0, #0, #0),      {???}
      {113}  (#0, #0, #0, #0),      {???}
      {114}  (#0, #0, #0, #0),      {???}
      {115}  (#0, #0, #0, #0),      {???}
      {116}  (#0, #0, #0, #0),      {???}
      {117}  (#0, #0, #0, #0),      {???}
      {118}  (#0, #0, #0, #0),      {???}
      {119}  (#200, #0, #0, #0),    {Keyboard Pause}
      {120}  (#0, #0, #0, #0),      {???}
      {121}  (#0, #0, #0, #0),      {???}
      {122}  (#0, #0, #0, #0),      {???}
      {123}  (#0, #0, #0, #0),      {???}
      {124}  (#0, #0, #0, #0),      {???}
      {125} (#0, #0, #0, #0),       {Keyboard RWin}
      {126} (#0, #0, #0, #0),       {Keyboard LWin}
      {127} (#0, #0, #0, #0)        {Keyboard Menu}
      );

  key_enter=141;
  key_escape=155;
  key_backspace=136;
  key_tab=137;
  key_f1=186;
  key_f2=187;
  key_f3=188;
  key_f4=189;
  key_f5=190;
  key_f6=191;
  key_f7=192;
  key_f8=193;
  key_f9=194;
  key_f10=195;
  key_f11=196;
  key_f12=197;
  key_rightarrow=206;
  key_leftarrow=207;
  key_downarrow=208;
  key_uparrow=209;


type TKeyboardreport=array[0..3] of integer; // event, scan, char, reserved. Event: 0 release 1 press 2 repeat

var report_buffer: array[0..512] of integer;
    rb_start:integer=0;
    rb_end:integer=0;
    report_buffer_active:boolean=false;
    kbdpresent:integer; // todo: more than 1 kbd.
    reportthread:TRetroKbd;

function getkeyboardreport:TKeyboardreport;
procedure startreportbuffer;
procedure stopreportbuffer;
function translatescantochar(scan,shift:byte):char;


implementation

uses retromalina;

type md=record
        d1,d2:ptruint;
        c1,c2:word;
        b:integer;
        end;

var kbdfile:int64;
    m:array[0..23] of byte;
    m2:md absolute m;


procedure stopreportbuffer;

begin
report_buffer_active:=false;
end;

procedure startreportbuffer;

begin
report_buffer_active:=true;
end;

function getkeyboardreport:TKeyboardreport;

var ii:integer;

begin
if rb_end <>rb_start then begin
  for ii:=0 to 3 do result[ii]:=report_buffer[4*rb_start+ii];
  rb_start:=(rb_start+1) and $7F;
  end
else
  for ii:=0 to 3 do result[ii]:=$7FFFFFFF;
end;

function translatescantochar(scan,shift:byte):char;

begin
if shift=0 then result:=kbdcodes[scan,0]
else if shift=1 then result:=kbdcodes[scan,1]
else if shift=2 then result:=kbdcodes[scan,2]
else if shift=3 then result:=kbdcodes[scan,3]
else result:=kbdcodes[scan,0];
end;


function initialize:integer;

var i:integer;
    name:string;
    rec:TSearchrec;

begin
result:=0;
// find a keyboard event file
if findfirst('/dev/input/by-id/*event-kbd',faanyfile,rec)=0 then
  begin
  name:=rec.name;
  findclose(rec);
  end;
name:='/dev/input/by-id/'+name;
//writeln('name= ',name);

// Open the keyboard file for reading
i:=0;
repeat
  kbdfile:=fileopen2(name,'rb');
  inc(i);
  sleep(10);
until (kbdfile>0) or (i>10);
if i>10 then result:=-1 // cannot open a keyboard file
else
  begin
  reportthread:=TRetroKbd.create(true);
  reportthread.start;
  end;
end;


constructor TRetroKbd.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TRetroKbd.execute;

var name:string;
    il:integer;

begin
repeat
  if kbdpresent=0 then
    begin
    il:=fileread2(kbdfile,@m[0],24);
    if il<>16 then
      begin
      fileclose(kbdfile);
      kbdpresent:=-1;
      //todo: try to reopen
      end
    else
    //fill the buffer
      begin
      if report_buffer_active then
        begin
        if not ((rb_end=(rb_start-1)) or ((rb_end=127) and (rb_start=0))) then
          begin
          report_buffer[4*rb_end+0]:=m2.c1;
          report_buffer[4*rb_end+1]:=m2.c2;
          report_buffer[4*rb_end+2]:=m2.b;
          report_buffer[4*rb_end+3]:=0;
          rb_end:=(rb_end+1) and $7f;
          end;
        end;
      end;
    end;
  sleep(1);
  until terminated
end;


initialization
kbdpresent:=initialize;


end.
