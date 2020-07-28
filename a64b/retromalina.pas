// *****************************************************************************
// The retromachine unit for Raspberry Pi/Linux
// Hardware platform dependent unit
// RPiOS a64 - 2020.06.08
// Piotr Kardasz
// pik33@o2.pl
// www.eksperymenty.edu.pl
// GPL 2.0 or higher
//******************************************************************************
//
// --- ALPHA, don't complain !!!
//
// Retromachine memory map @bytes
// BASE - this is dynamic, the memory will be get from the OS
// All addresses below relative to base
//
// 0000_0000  -  heap_start (about 0190_0000) - Ultibo area
// Heap start -  2EFF_FFFF retromachine program area, about 720 MB
//
//
// 0000_0000  -  2FF0_FFFF - 6502 area
//    0000_D400  -  2FF0_D418 SID
//    0000_D420  -  POKEY --- TODO
//
// 0001_0000  -  2FF5_FFFF - system data area
//    0001_0000  -  0004_FFFF pallette banks; 65536 entries
//    0005_0000  -  0005_1FFF font definition; 256 char @8x16 px
//    0005_2000  -  0005_9FFF static sprite defs 8x4k
//    0005_A000  -  0005_FFFF static display list area
//
// 0006_0000  -  0006_FFFF --- copper
//    0006_0000 - frame counter
//    0006_0004 - display start
//    0006_0008 - current graphics mode   ----TODO
//      0006_0009 - bytes per pixel
//    0006_000C - border color
//    0006_0010 - pallette bank           ----TODO
//    0006_0014 - horizontal pallette selector: bit 31 on, 30..20 add to $60010, 11:0 pixel num. ----TODO
//    0006_0018 - display list start addr  ----TODO
//    0006_001C - horizontal scroll right register ----TODO
//    0006_0020 - x res
//    0006_0024 - y res
//    0006_0028 - KBD. 28 - ASCII 29 modifiers, 2A raw code 2B key released
//    0006_002C - mouse. 6002c,d x 6002e,f y
//    0006_0030 - mouse keys, 0006_0032 - mouse wheel; 127 up 129 down
//    0006_0034 - current dl position ----TODO
//    0006_0040 - 2FF6_007C sprite control long 0 31..16 y pos  15..0 x pos
//                                         long 1 30..16 y zoom 15..0 x zoom
//    0006_0080 - 0006_009C dynamic sprite data pointer
//    0006_00A0 - text cursor position
//    0006_00A4 - text color
//    0006_00A8 - background color
//    0006_00AC - text size and pitch
//    0006_00B0 - text x res
//    0006_00B4 - text y res
//    0006_00B8 - native x resolution
//    0006_00BC - native y resolution

//    0006_0100 - 0006_01FF - blitter  TODO
//    0006_0200 - 0006_02FF - paula    TODO
//    0006_0300 - 0006_0?FF - FM synth TODO


//    0006_0F00 - system data area
//    0006_0F00 - CPU clock
//    0006_0F04 - CPU temperature
//    0006_0FF8 - kbd report

//    0007_0000  -  2FFF_FFFF - retromachine system area
//    3F00_0000  -  3FFF_FFFF - virtual framebuffer area  in 1 GB version (for 4 GB RPi4)


// TODO planned retromachine graphic modes:

// -- in 2560 family:



// 00..15 Propeller retromachine compatible - TODO
// 16 - 1792x1120 @ 8bpp
// 17 - 896x560 @ 16 bpp
// 18 - 448x280 @ 32 bpp
// 19 - native borderless @ 8 bpp /xres, yres defined @ 60020,60024
// 20..23 - 16 bpp modes
// 24..27 - 32 bpp modes
// 28 ..31 text modes - ?
// bit 7 set = double buffered


// DL modes

//xxxxDDMM
// xxxx = 0001 for RPi Retromachine
// MM: 00: hi, 01 med 10 low 11 native borderless
// DD: 00 8bpp 01 16 bpp 10 32 bpp 11 border

// new dl 20200614

//zoom2-colors2-border1-scroll1-gr/txt1-borderline1-pallette#8-scroll4-pixels12


// ----------------------------   This is still alpha quality code


unit retromalina;

{$mode objfpc}{$H+}
{$WARN 4055 off : Conversion between ordinals and pointers is not portable}
interface

uses unix,baseunix,sysutils,classes,retro,sdl2, retrokeyboard,raymarch;


var base_:array[0..$3FFFFFFF] of byte;        // system area base
    base:uint64;
    mainscreen:uint64;  // mainscreen area
      desired,obtained:TSDL_AudioSpec;                // zmienne do inicjacji audio



const _pallette=        $10000;
      _systemfont=      $50000;
      _sprite0def=      $52000;
      _sprite1def=      $53000;
      _sprite2def=      $54000;
      _sprite3def=      $55000;
      _sprite4def=      $56000;
      _sprite5def=      $57000;
      _sprite6def=      $58000;
      _sprite7def=      $59000;
      _framecnt=        $60000;
      _displaystart=    $60004;
      _graphicmode=     $60008;
      _bpp=             $60009;
      _bordercolor=     $6000C;
      _pallettebank=    $60010;
      _palletteselector=$60014;
      _dlstart=         $60018;
      _hscroll=         $6001C;
      _xres=            $60020;
      _yres=            $60024;
      _keybd=           $60028;
      _mousexy=         $6002C;
      _mousekey=        $60030;
      _dlpos=           $60034;
      _reserved01=      $60038;
      _reserved02=      $6003C;
      _spritebase=      $60040;
      _sprite0xy=       $60040;
      _sprite0zoom=     $60044;
      _sprite1xy=       $60048;
      _sprite1zoom=     $6004C;
      _sprite2xy=       $60050;
      _sprite2zoom=     $60054;
      _sprite3xy=       $60058;
      _sprite3zoom=     $6005C;
      _sprite4xy=       $60060;
      _sprite4zoom=     $60064;
      _sprite5xy=       $60068;
      _sprite5zoom=     $6006C;
      _sprite6xy=       $60070;
      _sprite6zoom=     $60074;
      _sprite7xy=       $60078;
      _sprite7zoom=     $6007C;
      _sprite0ptr=      $60080;
      _sprite1ptr=      $60084;
      _sprite2ptr=      $60088;
      _sprite3ptr=      $6008C;
      _sprite4ptr=      $60090;
      _sprite5ptr=      $60094;
      _sprite6ptr=      $60098;
      _sprite7ptr=      $6009C;
      _textcursor=      $600A0;
      _tcx=             $600A0;
      _tcy=             $600A2;
      _textcolor=       $600A4;
      _bkcolor=         $600A8;
      _textsize=        $600AC;
      _nativex=         $600B0;
      _nativey=         $600B4;
      _displaystarthi=  $600B8;
      _kbd_report=      $60FF8;



type

     // Retromachine main thread

     TRetro = class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

     Tmouse= class(TThread)
     private
     protected
       procedure Execute; override;
     public
      Constructor Create(CreateSuspended : boolean);
     end;

     TKeyboard= class(TThread)
     private
     protected
       procedure Execute; override;
     public
      Constructor Create(CreateSuspended : boolean);
     end;

type fb_var_screeninfo=record

	 xres:cardinal;			               //* visible resolution
	 yres:cardinal;
	 xres_virtual:cardinal;		               //* virtual resolution
	 yres_virtual:cardinal;
	 xoffset:cardinal;		   	       //* offset from virtual to visible
	 yoffset:cardinal;			       //* resolution

	 bits_per_pixel:cardinal;		       //* guess what
	 grayscale:cardinal;		               //* 0 = color, 1 = grayscale,
				    	               //* >1 = FOURCC
	 red:   array[0..2] of cardinal;   //* bitfield in fb mem if true color,
	 green: array[0..2] of cardinal;   //* else only length is significant
	 blue:  array[0..2] of cardinal;
	 transp:array[0..2] of cardinal;   //* transparency

	 nonstd:cardinal;			       //* != 0 Non standard pixel format

	 activate:cardinal;			       //* see FB_ACTIVATE_*

	 height:cardinal;			       //* height of picture in mm
	 width:cardinal;			       //* width of picture in mm

	 accel_flags:cardinal;	   	               //* (OBSOLETE) see fb_info.flags

//* Timing: All values in pixclocks, except pixclock (of course)

	 pixclock:cardinal;			       //* pixel clock in ps (pico seconds)
	 left_margin:cardinal;	  	               //* time from sync to picture
	 right_margin:cardinal;		               //* time from picture to sync
	 upper_margin:cardinal;		               //* time from sync to picture
	 lower_margin:cardinal;
	 hsync_len:cardinal;		               //* length of horizontal sync
	 vsync_len:cardinal;		               //* length of vertical sync
	 sync:cardinal;		          	       //* see FB_SYNC_*
	 vmode:cardinal;			       //* see FB_VMODE_*
	 rotate:cardinal;			       //* angle we rotate counter clockwise
	 colorspace:cardinal;		               //* colorspace for FOURCC-based modes
	 reserved:array[0..3] of cardinal;	       //* Reserved for future compatibility
         end;


type fb_fix_screeninfo=record
  	id:array[0..15] of char;        //* identification string eg "TT Builtin"
  	smem_start:PtrUint ;    	//* Start of frame buffer mem
  					//* (physical address)
  	smem_len:cardinal;		//* Length of frame buffer mem
  	atype:cardinal;			//* see FB_TYPE_*
  	type_aux:cardinal;		//* Interleave for interleaved Planes
  	visual:cardinal;		//* see FB_VISUAL_*
  	xpanstep:word;		//* zero if no hardware panning
  	ypanstep:word;		//* zero if no hardware panning
  	ywrapstep:word;		//* zero if no hardware ywrap
  	line_length:cardinal;		//* length of a line in bytes
  	mmio_start:PtrUint;	        //* Start of Memory Mapped I/O
  					//* (physical address)
  	mmio_len:cardinal;		//* Length of Memory Mapped I/O
  	accel:cardinal;			//* Indicate to driver which
  					//*  specific chip/card we have
        capabilities:word;		//* see FB_CAP_*
        reserved:array[0..1] of word;	//* Reserved for future compatibility
        end;

const
FBIOGET_VSCREENINFO=	$4600;
FBIOPUT_VSCREENINFO=	$4601;
FBIOGET_FSCREENINFO=	$4602;
FBIOGETCMAP=		$4604;
FBIOPUTCMAP=		$4605;
FBIOPAN_DISPLAY=	$4606;
FBIOGET_CON2FBMAP=	$460F;
FBIOPUT_CON2FBMAP=	$4610;
FBIOBLANK=		$4611;
FBIO_ALLOC=             $4613;
FBIO_FREE=              $4614;
FBIOGET_GLYPH=          $4615;
FBIOGET_HWCINFO=        $4616;
FBIOPUT_MODEINFO=       $4617;
FBIOGET_DISPINFO=       $4618;
FBIO_WAITFORVSYNC=	$40044620;

KDSETMODE=              $4B3A;

var fh,filetype:integer;                // this needs cleaning...
    thread:TRetro;

    i,j,k,l,fh2,lines:integer;

    psystem,psystem2:pointer;
    p2:pointer;

    textcursoron:boolean=false;
    running,vblank1:integer;
    tim, t,ttt, ts: int64;


    mp3time:int64;

     vinfo:fb_var_screeninfo;
     finfo:fb_fix_screeninfo;
         fbfd:integer;
    kbfd:integer;
    KD_TEXT:integer=		$00;
    KD_GRAPHICS:integer=        $01;

// system variables

    systempallette:array[0..255] of TPallette absolute base_[_pallette];
    systemfont:TFont   absolute base_[_systemfont];
    sprite0def:TSprite absolute base_[_sprite0def];
    sprite1def:TSprite absolute base_[_sprite1def];
    sprite2def:TSprite absolute base_[_sprite2def];
    sprite3def:TSprite absolute base_[_sprite3def];
    sprite4def:TSprite absolute base_[_sprite4def];
    sprite5def:TSprite absolute base_[_sprite5def];
    sprite6def:TSprite absolute base_[_sprite6def];
    sprite7def:TSprite absolute base_[_sprite7def];

    framecnt:        cardinal absolute base_[_framecnt];
    displaystart:    cardinal absolute base_[_displaystart];
    graphicmode:     cardinal absolute base_[_graphicmode];
    bpp:             byte     absolute base_[_bpp];
    bordercolor:     cardinal absolute base_[_bordercolor];
    pallettebank:    cardinal absolute base_[_pallettebank];
    palletteselector:cardinal absolute base_[_palletteselector];
    dlstart:         cardinal absolute base_[_dlstart];
    hscroll:         cardinal absolute base_[_hscroll];
    xres:            integer  absolute base_[_xres];
    yres:            integer  absolute base_[_yres];
    key_charcode:    byte     absolute base_[_keybd];
    key_modifiers:   byte     absolute base_[_keybd+1];
    key_scancode:    byte     absolute base_[_keybd+2];
    key_release :    byte     absolute base_[_keybd+3];
    mousexy:         cardinal absolute base_[_mousexy];
    mousex:          word     absolute base_[_mousexy];
    mousey:          word     absolute base_[_mousexy+2];
    mousek:          byte     absolute base_[_mousekey];
    mouseclick:      byte     absolute base_[_mousekey+1];
    mousewheel:      byte     absolute base_[_mousekey+2];
    mousedblclick:   byte     absolute base_[_mousekey+3];
    dlpos:           cardinal absolute base_[_dlpos];
    sprite0xy:       cardinal absolute base_[_sprite0xy];
    sprite0x:        smallint absolute base_[_sprite0xy];
    sprite0y:        smallint absolute base_[_sprite0xy+2];
    sprite0zoom:     cardinal absolute base_[_sprite0zoom];
    sprite0zoomx:    word     absolute base_[_sprite0zoom];
    sprite0zoomy:    word     absolute base_[_sprite0zoom+2];
    sprite1xy:       cardinal absolute base_[_sprite1xy];
    sprite1x:        smallint absolute base_[_sprite1xy];
    sprite1y:        smallint absolute base_[_sprite1xy+2];
    sprite1zoom:     cardinal absolute base_[_sprite1zoom];
    sprite1zoomx:    word     absolute base_[_sprite1zoom];
    sprite1zoomy:    word     absolute base_[_sprite1zoom+2];
    sprite2xy:       cardinal absolute base_[_sprite2xy];
    sprite2x:        smallint absolute base_[_sprite2xy];
    sprite2y:        smallint absolute base_[_sprite2xy+2];
    sprite2zoom:     cardinal absolute base_[_sprite2zoom];
    sprite2zoomx:    word     absolute base_[_sprite2zoom];
    sprite2zoomy:    word     absolute base_[_sprite2zoom+2];
    sprite3xy:       cardinal absolute base_[_sprite3xy];
    sprite3x:        smallint absolute base_[_sprite3xy];
    sprite3y:        smallint absolute base_[_sprite3xy+2];
    sprite3zoom:     cardinal absolute base_[_sprite3zoom];
    sprite3zoomx:    word     absolute base_[_sprite3zoom];
    sprite3zoomy:    word     absolute base_[_sprite3zoom+2];
    sprite4xy:       cardinal absolute base_[_sprite4xy];
    sprite4x:        smallint absolute base_[_sprite4xy];
    sprite4y:        smallint absolute base_[_sprite4xy+2];
    sprite4zoom:     cardinal absolute base_[_sprite4zoom];
    sprite4zoomx:    word     absolute base_[_sprite4zoom];
    sprite4zoomy:    word     absolute base_[_sprite4zoom+2];
    sprite5xy:       cardinal absolute base_[_sprite5xy];
    sprite5x:        smallint absolute base_[_sprite5xy];
    sprite5y:        smallint absolute base_[_sprite5xy+2];
    sprite5zoom:     cardinal absolute base_[_sprite5zoom];
    sprite5zoomx:    word     absolute base_[_sprite5zoom];
    sprite5zoomy:    word     absolute base_[_sprite5zoom+2];
    sprite6xy:       cardinal absolute base_[_sprite6xy];
    sprite6x:        smallint absolute base_[_sprite6xy];
    sprite6y:        smallint absolute base_[_sprite6xy+2];
    sprite6zoom:     cardinal absolute base_[_sprite6zoom];
    sprite6zoomx:    word     absolute base_[_sprite6zoom];
    sprite6zoomy:    word     absolute base_[_sprite6zoom+2];
    sprite7xy:       cardinal absolute base_[_sprite7xy];
    sprite7x:        smallint  absolute base_[_sprite7xy];
    sprite7y:        smallint absolute base_[_sprite7xy+2];
    sprite7zoom:     cardinal absolute base_[_sprite7zoom];
    sprite7zoomx:    word     absolute base_[_sprite7zoom];
    sprite7zoomy:    word     absolute base_[_sprite7zoom+2];

    sprite0ptr:      cardinal absolute base_[_sprite0ptr];
    sprite1ptr:      cardinal absolute base_[_sprite1ptr];
    sprite2ptr:      cardinal absolute base_[_sprite2ptr];
    sprite3ptr:      cardinal absolute base_[_sprite3ptr];
    sprite4ptr:      cardinal absolute base_[_sprite4ptr];
    sprite5ptr:      cardinal absolute base_[_sprite5ptr];
    sprite6ptr:      cardinal absolute base_[_sprite6ptr];
    sprite7ptr:      cardinal absolute base_[_sprite7ptr];

    spritepointers:  array[0..7] of cardinal absolute base_[_sprite0ptr];

    textcursor:      cardinal absolute base_[_textcursor];
    tcx:             word     absolute base_[_textcursor];
    tcy:             word     absolute base_[_textcursor+2];
    textcolor:       cardinal absolute base_[_textcolor];
    bkcolor:         cardinal absolute base_[_bkcolor];
    textsizex:       byte     absolute base_[_textsize];
    textsizey:       byte     absolute base_[_textsize+1];
    textpitch:       byte     absolute base_[_textsize+2];
//    audiodma1:       array[0..7] of cardinal absolute base_[_audiodma];
//    audiodma2:       array[0..7] of cardinal absolute base_[_audiodma+32];
//    dblbufscn1:      cardinal absolute base_[_dblbufscn1];
//    dblbufscn2:      cardinal absolute base_[_dblbufscn2];
    nativex:         cardinal absolute base_[_nativex];
    nativey:         cardinal absolute base_[_nativey];
    displaystarthi:  cardinal absolute base_[_displaystarthi];

   kbdreport:       array[0..7] of byte absolute base_[_kbd_report];


    error:integer;
    framesize:integer;
    backgroundaddr:uint64;
    screenaddr:uint64;
    redrawing:uint64;
    windowsdone:boolean=false;
    drive:string;


    debug1,debug2,debug3:cardinal;
       mmm:integer;

           screensize:integer;
     fbresult:integer;
     amouse:tmouse ;
    akeyboard:tkeyboard ;



// prototypes

procedure initmachine(mode:integer);
procedure stopmachine;

procedure graphics(mode:integer);
procedure setpallette(pallette:TPallette;bank:integer);
procedure cls(c:integer);
procedure putpixel(x,y,color:integer);
procedure putchar(x,y:integer;ch:char;col:integer);
procedure outtextxy(x,y:integer; t:string;c:integer);
procedure blit(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:int64);
procedure box(x,y,l,h,c:int64);
procedure box2(x1,y1,x2,y2,color:integer);


function gettime:int64;
procedure poke(addr:uint64;b:byte);
procedure dpoke(addr:uint64;w:word);
procedure lpoke(addr:uint64;c:uint32);
procedure slpoke(addr:uint64;i:integer);
function peek(addr:uint64):byte;
function dpeek(addr:uint64):word;
function lpeek(addr:uint64):cardinal;
function slpeek(addr:uint64):integer;
procedure sethidecolor(c,bank,mask:cardinal);
procedure fcircle(x0,y0,r,c:integer);
procedure circle(x0,y0,r,c:integer);
procedure line(x,y,dx,dy,c:integer);
procedure line2(x1,y1,x2,y2,c:integer);
procedure putcharz(x,y:integer;ch:char;col,xz,yz:integer);
procedure outtextxyz(x,y:integer; t:string;c,xz,yz:integer);
procedure outtextxys(x,y:integer; t:string;c,s:integer);
procedure outtextxyzs(x,y:integer; t:string;c,xz,yz,s:integer);
procedure scrollup;
function getpixel(x,y:integer):integer; inline;
function getkey:integer; inline;
function readkey:integer; inline;
function getreleasedkey:integer; inline;
function readreleasedkey:integer; inline;
function keypressed:boolean;
function click:boolean;
function dblclick:boolean;
procedure waitvbl;


function readwheel: shortint; inline;
procedure unhidecolor(c,bank:cardinal);
procedure scrconvertnative(src,screen:pointer);


procedure print(line:string);
procedure println(line:string);
procedure printscreen;

// ---- libc functions

function mprotect(address:pointer;length:uint64;params:integer):integer; cdecl; external 'libc';
function fopen(name,mode:PChar):ptruint; cdecl; external 'libc';
function fread(bufor:pointer;size,number:int64;fh:ptruint):ptrint; cdecl; external 'libc';
function fclose(fh:ptruint):ptrint; cdecl; external 'libc';
function fileopen2(n,m:string):ptrint;
function fileread2(fh:ptruint;buffer:pointer;il:ptruint):ptrint;
function fileclose2(fh:ptrint):ptrint;

{$linklib 'c'}


function sdl_sound_init(Q:integer):integer;

var bufor:array[0..8191] of smallint;
    b2:array[0..16383] of byte absolute bufor;

type
    TMousereport=array[0..3] of integer;
    type md=record
        d1,d2:ptruint;
        c1,c2:word;
        b:integer;
        end;

implementation

// ---- more pascal-like wrappers for libc fopen and fread

function fileopen2(n,m:string):ptrint;

begin
result:=ptrint(fopen(pchar(n),pchar(m)));
end;

function fileread2(fh:ptruint;buffer:pointer;il:ptruint):ptrint;

begin
result:=fread(buffer,1,il,fh);
end;

function fileclose2(fh:ptrint):ptrint;
begin
result:=fclose(fh);
end;

function removeramlimits(address,length:uint64;params:integer):integer;

begin
result:=mprotect(pointer(address and $FFFFFFFFFFFFF000),length,params);
end;

procedure AudioCallback(userdata:pointer; audio:Pbyte; length:longint); cdecl;

begin
for i:=0 to length-1 do audio[i]:=b2[i];
//box(100,100,100,100,0); outtextxyz(100,100,inttostr(length),40,2,2);
end;

function sdl_sound_init(q:integer):integer;

// Zainicjuj bibliotekę sdl_sound

begin
Result:=0;

if SDL_Init(SDL_INIT_AUDIO) <> 0 then
  begin
  Result:=-1; // sdl_audio nie da się zainicjować
  exit;
  end;

desired.freq := q;                                     // sample rate
desired.format := AUDIO_S16;                               // 16-bit samples
desired.samples := 4096;                                   // sample na 1 callback
desired.channels := 2;                                     // stereo
desired.callback := @AudioCallback;
desired.userdata := nil;                                   // niepotrzebne poki co

if (SDL_OpenAudio(@desired, @obtained) < 0) then
  begin
    Result:=-2;   // nie da się otworzyć urządzenia
  end;
end;

procedure sprite(screen:pointer); forward;

// ---- TMouse thread methods --------------------------------------------------

constructor TMouse.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TMouse.Execute;

var il,i:integer;
    x,y,w:integer;
    m:array[0..2] of integer;
    buttons:integer=0;
    offsetx,offsety,wheel:integer;

    mm2:array[0..23] of byte;
    mm:md absolute mm2;


    mousefile:int64;
    name:string;
    rec:TSearchrec;

begin

if findfirst('/dev/input/by-id/*event-mouse',faanyfile,rec)=0 then
  begin
  name:=rec.name;
  findclose(rec);
  name:='/dev/input/by-id/'+name;
//  mousefile:=fileopen2(name,'rb');
  end;

// Open the mouse file for reading

mousefile:=fileopen2(name,'rb');

repeat

 il:=fileread2(mousefile,@mm2[0],24);       //TODO: reopen a mouse file if failed

 if il<24 then
   begin
   repeat
     if findfirst('/dev/input/by-id/*event-mouse',faanyfile,rec)=0 then
       begin
       name:=rec.name;
       findclose(rec);
       name:='/dev/input/by-id/'+name;
       mousefile:=fileopen2(name,'rb');
       sleep(100);
       end
     else sleep(100);
   until mousefile>0;
  end;



 m[0]:=mm.c1;
 m[1]:=mm.c2;
 m[2]:=mm.b;

 offsetx:=0; offsety:=0; wheel:=0;

  if m[0]=2 then
    begin
    if m[1]=0 then offsetx:=m[2] else offsetx:=0;
    if m[1]=1 then offsety:=m[2] else offsety:=0;
    if m[1]=8 then wheel:=m[2] else wheel:=0;
    end;
  if m[0]=1 then
    begin
    if m[1]=272 then if m[2]=1 then buttons:=buttons or 1 else buttons:=buttons and $FE;
    if m[1]=273 then if m[2]=1 then buttons:=buttons or 2 else buttons:=buttons and $FD;
    if m[1]=274 then if m[2]=1 then buttons:=buttons or 4 else buttons:=buttons and $FB;
    end;



  x:=mousex+offsetx;
  if x<0 then x:=0;
  if x>(xres-1) then x:=xres-1;
  mousex:=x;
  y:=mousey+offsety;
  if y<0 then y:=0;
  if y>(yres-1) then y:=yres-1;
  mousey:=y;
  mousek:=Buttons and 255;
  if wheel<-1 then wheel:=-1;
  if wheel>1 then wheel:=1;
  w:=mousewheel+Wheel;
  if w<127 then w:=127;
  if w>129 then w:=129;
  mousewheel:=w;
  sprite7xy:=mousexy
until terminated;
end;

// ---- TKeyboard thread methods --------------------------------------------------

constructor TKeyboard.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


procedure TKeyboard.Execute;

// At every vblank the thread tests if there is a report from the keyboard
// If yes, the kbd codes are poked to the system variables
// $60028 - translated code
// $60029 - modifiers
// $6002A - raw code
// This thread also tracks mouse clicks

const m:integer=0;
      c:integer=0;
      dblclick:integer=0;
      dblcnt:integer=0;
      clickcnt:integer=0;
      click:integer=0;

var ch:TKeyboardReport;
    i:integer;


begin
for i:=0 to 3 do kbdreport[i]:=0;
repeat
  waitvbl;
 // sprite7xy:=mousexy;//+$00280040;           //sprite coordinates are fullscreen
                                             //while mouse is on active screen only

  if mousedblclick=2 then begin dblclick:=0; dblcnt:=0; mousedblclick:=0; end;
  if (dblclick=0) and (mousek=1) then begin dblclick:=1; dblcnt:=0; end;
  if (dblclick=1) and (mousek=0) then begin dblclick:=2; dblcnt:=0; end;
  if (dblclick=2) and (mousek=1) then begin dblclick:=3; dblcnt:=0; end;
  if (dblclick=3) and (mousek=0) then begin dblclick:=4; dblcnt:=0; end;

  inc(dblcnt); if dblcnt>10 then begin dblcnt:=10; dblclick:=0; end;
  if dblclick=4 then mousedblclick:=1 {else mousedblclick:=0};

  if peek(base+$60031)=2 then begin click:=2; clickcnt:=10; end;
  if (mousek=1) and (click=0) then begin click:=1; clickcnt:=0; end;
  inc(clickcnt); if clickcnt>10 then  begin clickcnt:=10; click:=2; end;
  if (mousek=0) then click:=0;
  if click=1 then mouseclick:=1 else mouseclick:=0;

// now the kbdrecord

 ch:=getkeyboardreport;

 if ch[0]<>$7FFFFF then
   begin
   if ch[0]=1 then
     begin
     if ch[2]>0 then
       begin
       key_scancode:=ch[1];

    // 29 rctl | 42 rsh | 125 rwin | 56 ralt | 97 lctl | 126 lwin | 100 lalt | 54 lshift
    // mbits= RW RA RC RS LW LA LC LS

       if key_scancode=54 then key_modifiers:=key_modifiers or 1;
       if key_scancode=97 then key_modifiers:=key_modifiers or 2;
       if key_scancode=100 then key_modifiers:=key_modifiers or 4;
       if key_scancode=126 then key_modifiers:=key_modifiers or 8;
       if key_scancode=42 then key_modifiers:=key_modifiers or 16;
       if key_scancode=29 then key_modifiers:=key_modifiers or 32;
       if key_scancode=56 then key_modifiers:=key_modifiers or 64;
       if key_scancode=127 then key_modifiers:=key_modifiers or 128;
       end
     else // ch[2]=0 ->release
       begin
       key_release:=ch[1];
       if key_release=54 then key_modifiers:=key_modifiers and  %11111110;
       if key_release=97 then key_modifiers:=key_modifiers and  %11111101;
       if key_release=100 then key_modifiers:=key_modifiers and %11111011;
       if key_release=126 then key_modifiers:=key_modifiers and %11110111;
       if key_release=42 then key_modifiers:=key_modifiers and  %11101111;
       if key_release=29 then key_modifiers:=key_modifiers and  %11011111;
       if key_release=56 then key_modifiers:=key_modifiers and  %10111111;
       if key_release=127 then key_modifiers:=key_modifiers and %01111111;
       end;
     end;
   end;

 m:=key_modifiers;
 c:=byte(translatescantochar(key_scancode,0));
 if (m and $11)<>0 then c:=byte(translatescantochar(key_scancode,1));
 if (m and $41)=$40 then c:=byte(translatescantochar(key_scancode,2));
 if (m and $41)=$41 then c:=byte(translatescantochar(key_scancode,3));
 key_charcode:=byte(c);
 until terminated;
end;




//var testscreen1, testscreen2:array[0..1920*1200-1] of cardinal;

// ---- TRetro thread methods --------------------------------------------------

// ----------------------------------------------------------------------
// constructor: create the thread for the retromachine
// ----------------------------------------------------------------------

constructor TRetro.Create(CreateSuspended : boolean);

begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

// ----------------------------------------------------------------------
// THIS IS THE MAIN RETROMACHINE THREAD
// - convert retromachine screen to raspberry screen
// - display sprites
// ----------------------------------------------------------------------

procedure TRetro.Execute;

// --- rev 21070111

var i,dummy:integer;

begin
ThreadSetPriority(GetCurrentThreadId,-15);
running:=1;
repeat
  begin
  vblank1:=0;
  t:=gettime;
  scrconvertnative(pointer(mainscreen),p2);    // classic driver
  ttt:=gettime-t;
    t:=gettime;
  sprite(p2);
     ts:=gettime-t;
  vblank1:=1;
  framecnt+=1;

  dummy := 0;
  vinfo.yoffset := 0;
  fpioctl(fbfd, FBIOPAN_DISPLAY, @vinfo);
  fpioctl(fbfd, FBIO_WAITFORVSYNC, @dummy);


  vblank1:=0;
 // box(100,100,100,100,framecnt);

  scrconvertnative(pointer(mainscreen),p2+4*(xres+64)*(yres)) ;
   sprite(p2+4*(xres+64)*(yres));

  vblank1:=1;
  framecnt+=1;


  dummy := 0;
  vinfo.yoffset := yres;
  fpioctl(fbfd, FBIOPAN_DISPLAY, @vinfo);
  fpioctl(fbfd, FBIO_WAITFORVSYNC, @dummy);


  end;
until terminated;
running:=0;
end;


// ---- Retromachine procedures ------------------------------------------------

// ----------------------------------------------------------------------
// initmachine: start the machine
// ----------------------------------------------------------------------

procedure initmachine(mode:integer);

// -- rev 20180423

var i:integer;
    mousedata:TSprite;


begin

base:=uint64(@base_);
mainscreen:=base+$3f000000;//uint64(fpmmap(nil,$1000000,prot_read or prot_write or prot_exec,map_shared or map_anonymous,0,0));

backgroundaddr:=mainscreen;
screenaddr:=mainscreen+$800000;
redrawing:=mainscreen+$800000;

// clean all system area
for i:=base to base+$FFFFF do poke(i,0);


fbfd := fileopen('/dev/fb0', fmOpenReadWrite or $40);
fpioctl(fbfd, FBIOGET_VSCREENINFO, @vinfo);

nativex:=vinfo.xres;
nativey:=vinfo.yres;

if (nativex>=1024) and (nativey>=720) then
  begin
  xres:=nativex;
  yres:=nativey;
  end
else
  begin
  xres:=round(2*nativex);
  yres:=round(2*nativey);
  end;


vinfo.bits_per_pixel:=32;
vinfo.xres:=xres;
vinfo.yres:=yres;
vinfo.xres_virtual:=vinfo.xres+64;
vinfo.yres_virtual:=vinfo.yres*2+1;
fbresult:=fpioctl(fbfd, FBIOPUT_VSCREENINFO, @vinfo); // todo check and exit

sleep(300);
kbfd := fileopen('/dev/tty1', fmOpenWrite);     // 2 for debug
if (kbfd > 0) then fpioctl(kbfd, KDSETMODE, @KD_GRAPHICS);

fbresult:=fpioctl(fbfd, FBIOGET_FSCREENINFO, @finfo);
screensize := finfo.smem_len;
p2:=fpmmap(nil,screensize, PROT_READ or PROT_WRITE, MAP_SHARED, fbfd, 0);

//for i:=0 to (1984*1080)-1 do lpoke(ptruint(p2)+4*i,$0);

//for i:=1984*1080 to 2*(1984*1080)-1 do lpoke(ptruint(p2)+4*i,$FF00);

//  thread:=tretro.create(true);
//  thread.start;

bordercolor:=0;
displaystart:=mainscreen and $FFFFFFFF;                 // vitual framebuffer address
displaystarthi:=mainscreen shr 32;
framecnt:=0;                              // frame counter


//init all sprites

for i:=0 to 7 do spritepointers[i]:=$52000+100*i;
sprite0xy:=$08000800;
sprite1xy:=$08000800;
sprite2xy:=$08000800;
sprite3xy:=$08000800;
sprite4xy:=$08000800;
sprite5xy:=$08000800;
sprite6xy:=$08000800;
sprite0zoom:=$00010001;
sprite1zoom:=$00010001;
sprite2zoom:=$00010001;
sprite3zoom:=$00010001;
sprite4zoom:=$00010001;
sprite5zoom:=$00010001;
sprite6zoom:=$00010001;


// init pallette, font and mouse cursor

//systemfont:=vgafont;
systemfont:=st4font;
sprite7def:=mysz;
sprite7zoom:=$00200020;
sprite7x:=1000;
sprite7y:=500;
setpallette(ataripallette,0);
for i:=$10000 to $10000+1023 do if (i mod 4) = 0 then lpoke(base+i,lpeek(base+i) or $FF000000);
// init sprite data pointers
for i:=0 to 7 do spritepointers[i]:=base+_sprite0def+4096*i;

// init sid variables



removeramlimits(uint64(@sprite),16384,7);

mousex:=xres div 2;
mousey:=yres div 2;
mousewheel:=128;




// start frame refreshing thread
thread:=tretro.create(true);
thread.start;

mousedata:=mysz;
for i:=0 to 1023 do if mousedata[i]<>0 then mousedata[i]:=mousedata[i] or $FF000000;
amouse:=tmouse.create(true);
amouse.start;

akeyboard:=tkeyboard.create(true);
akeyboard.start;

startreportbuffer;

// start windows --- TODO - remove this from here!!!
poke(base+$1000,mmm);

end;


//  ---------------------------------------------------------------------
//   stopmachine: stop the retromachine
//   rev. 20170111
//  ---------------------------------------------------------------------

procedure stopmachine;

begin
thread.terminate;
sleep(100);
repeat sleep(1) until running=0;

//windows.terminate;
if (kbfd >= 0) then
  begin
  fpioctl(kbfd, KDSETMODE, @KD_TEXT);
// close kb file
  fileclose(kbfd);
  end;
fpmunmap(p2,screensize);
fileclose(fbfd);
//fpmunmap(pointer(mainscreen),$1000000);
end;

// -----  Screen convert procedures

procedure scrconvertnative(src,screen:pointer);

// --- rev 21070608

var b:ptruint;
    dxstart,nx,ny:uint64;
{$MACRO ON}
{$define stupidadd:=b:=b;}
label p1,p2;

begin

b:=base+_pallette;
ny:=yres;
nx:=(xres*4)+256;
dxstart:=base+lpeek(base+$60018);


                asm

                ldr x0,screen
                ldr x1,ny
                ldr x2,nx
                mov x3,#0
                ldr x5,src
                add x5,x5,#64
                ldr x6,b

p2:             add x4,x2,x0
                sub x5,x5,#64

p1:             ldrb w3,[x5],#1
                ldr w7,[x6,x3,lsl #2]
                str w7,[x0],#4
                cmp x0,x4
                b.lt p1

                subs x1,x1,#1
                b.ne p2
                end;


end;


procedure scrconvertdl(src,screen:pointer);

// --- rev 21070608

var b:ptruint;
    dxstart,nx,ny:uint64;

label p1,p2;

begin

b:=base+_pallette;
ny:=yres;
nx:=(xres*4)+256;
dxstart:=base+lpeek(base+$60018);

                asm
                ldr x0,screen
                ldr x1,ny
                ldr x2,nx
                mov x3,#0
                ldr x5,src
                add x5,x5,#64
                ldr x6,b

p2:             add x4,x2,x0
                sub x5,x5,#64

p1:             ldrb w3,[x5],#1
                ldr w7,[x6,x3,lsl #2]
                str w7,[x0],#4
                cmp x0,x4
                b.lt p1

                subs x1,x1,#1
                b.ne p2
                end;


end;

procedure sprite(screen:pointer);

// A sprite procedure
// --- rev 21070111

label p101,p102,p103,p104,p105,p106,p107,p108,p109,p999,p901,p902;


var spritebase:uint64;
    nx:uint64;
    yr:uint64;
    scrl:uint64;
    base2:uint64;

begin
base2:=base+$60080;
yr:=yres;
spritebase:=base+_spritebase;
nx:=xres*4+256;
scrl:=uint64(screen)+(xres+64)*yres*4;

               asm

               ldr x15,base2             // pointer to the 1st sprite
               ldr x16,nx                // pitch in x16
               ldr x11,screen
               ldr x18,scrl

                mov x12,#0
                                        // sprite
               ldr x0,spritebase
p103:          ldr w1,[x0],#4
               lsl x2,x1, #48          // sprite 0 position
               asr x3,x1, #16          // y pos
               asr x2,x2, #46          // x pos*4     TODO use UBFM

               ldr x14,yr              // if ypos>yr, goto p107
               cmp x3,x14
               b.ge p107

               cmp w2,#8192            // switch off the sprite if x>2048
               b.lt p104               // draw a sprite
p107:          add x12,x12,#1          // next sprite
               add x0,x0,#4
               cmp x12,#8
               b.ge p999               // if all sprites, exit
               b   p103

p104:          mov x4,x16               //--- start drawing
               mul x3,x3,x4             //  ypos:=ypos*pitch
               add x3,x3,x2             // x3+=xpos*4; x3:= pointer to sprite start on screen


              // ldr x4,screen
               add x3,x3,x11              // pointer to upper left sprite pixel in r3
               mov x4,x15                // sprite def addr
//             .long 0x8b0c0884
              add x4,x4,x12,lsl #2  //- add sprite #
               ldr w4,[x4]               // sprite def ptr in x4

               ldr w1,[x0],#4
               lsl x2,x1,#48
               lsr x2,x2,#48         // xzoom
               lsr x1,x1,#16         // yzoom

               mov x7,x2
               lsl x8,x2, #7        // xzoom * 128 (128=4*32)
               lsl x9,x1, #5        // y zoom * 32
               mov x10,x1           // y zoom counter
               mov x6,#32

p101:
             //  ldr x14,screen
               cmp x3,x11
               b.ge p109
               add x3,x3,x8
                b p106

p109:          ldr w5,[x4],#4  // get a pixel
               cmp w5,#0
               b.ne p102       // if not 0, draw
               lsr x17,x8,#5
               add x3,x3,x17
               mov x7,x2
               subs x6,x6,#1
               b.ne p101
               b p106


p102:          str w5,[x3],#4  // inner loop
               subs x7,x7,#1
               b.ne p102

p105:          mov x7,x2
               subs x6,x6,#1
               b.ne p109       // outer loop -x

p106:          mov x17,x16
               add x3,x3,x17  // add pitch
               sub x3,x3,x8   // sub width

          //     ldr x14,scrl
               cmp x3,x18
               b.ge p108      // if out of screen, abort drawing

               subs x10,x10,#1
               b.eq p901
               sub x4,x4,#128
               b p902
 p901:              add x10,x10,x1
 p902:              mov x6,#32
               subs x9,x9,#1
               b.ne p101

p108:


               add x12,x12,#1
               cmp x12,#8
               b.ne p103
 p999:
               end;
end;

// ------  Helper procedures


function gettime:int64; inline;

var
  tv: TTimeVal;
  tz: TTimeZone;

begin
  fpgettimeofday(@tv, @tz);
  Result := tv.tv_sec * 1000000 + tv.tv_usec;
end;



procedure waitvbl;

begin
repeat sleep(1) until vblank1=0;
repeat sleep(1) until vblank1=1;
end;

function waitscreen:integer;

begin
repeat sleep(1) until vblank1=1;
end;

//  ---------------------------------------------------------------------
//   BASIC type poke/peek procedures
//   works @ byte addresses
//   rev. 20161124
// ----------------------------------------------------------------------

procedure poke(addr:uint64;b:byte); //inline;

begin
PByte(addr)^:=b;
end;

procedure dpoke(addr:uint64;w:word); //inline;

begin
PWord(addr and $FFFFFFFFFFFFFFFE)^:=w;
end;

procedure lpoke(addr:uint64;c:uint32); //inline;

begin
Puint32(addr and $FFFFFFFFFFFFFFFC)^:=c;
end;

procedure slpoke(addr:uint64;i:integer); //inline;

begin
PInteger(addr and $FFFFFFFFFFFFFFFC)^:=i;
end;

function peek(addr:uint64):byte; //inline;

begin
peek:=Pbyte(addr)^;
end;

function dpeek(addr:uint64):word;// inline;

begin
dpeek:=PWord(addr and $FFFFFFFFFFFFFFFE)^;
end;

function lpeek(addr:uint64):cardinal;// inline;

begin
lpeek:=PCardinal(addr and $FFFFFFFFFFFFFFFC)^;
end;

function slpeek(addr:uint64):integer; // inline;

begin
slpeek:=PInteger(addr and $FFFFFFFFFFFFFFFC)^;
end;

// ------- Keyboard and mouse procedures

function keypressed:boolean;

begin
if peek(base+$60028)<>0 then result:=true else result:=false;
end;

function readkey:integer; inline;

begin
result:=lpeek(base+$60028) and $FFFFFF;
poke(base+$60028,0);
poke(base+$60029,0);
poke(base+$6002a,0);
end;

function getkey:integer; inline;

begin
result:=lpeek(base+$60028) and $FFFFFF;
end;

function readreleasedkey:integer; inline;

begin
result:=peek(base+$6002B);
poke(base+$6002B,0);
end;

function getreleasedkey:integer; inline;

begin
result:=peek(base+$6002B);
end;

function click:boolean; inline;

begin
if mouseclick=1 then  result:=true else result:=false;
if mouseclick=1 then  mouseclick:=2;
end;


function dblclick:boolean; inline;

begin
if mousedblclick=1 then result:=true else result:=false;
if mousedblclick=1 then mousedblclick:=2;
end;

function readwheel: shortint; inline;

begin
result:=mousewheel-128;
mousewheel:=128
end;

//------------------------------------------------------------------------------
// ----- Graphics mode setting ------------
//------------------------------------------------------------------------------

procedure graphics(mode:integer);

// rev 20200620

// Graphics mode set:
// 0 - 2560x1440
// 1 - 1920x1080
// 2 - 1280x720
// 3 - 960x540
// 4 - 640x360
// 5 - 480x270
// 6 - 320x180
// 7 - 240x135
// 8 - 1920x1200 bordered @2560x1440
// 9 - 1280x800 bordered @ 1920x1080
//10 - 960x600  bordered @ 2560x1440 /x2
//11 - 640x400  bordered @ 1920x1200 /x2
//12 - 480x300
//13 - 320x200

// 0000_0000  -  2FF0_FFFF - 6502 area
//    0000_D400  -  2FF0_D418 SID
//    0000_D420  -  POKEY --- TODO
//
// 0001_0000  -  2FF5_FFFF - system data area
//    0001_0000  -  0004_FFFF pallette banks; 65536 entries
//    0005_0000  -  0005_1FFF font definition; 256 char @8x16 px
//    0005_2000  -  0005_9FFF static sprite defs 8x4k
//    0005_A000  -  0005_FFFF static display list area
//
// 0006_0000  -  0006_FFFF --- copper
//    0006_0000 - frame counter
//    0006_0004 - display start
//    0006_0008 - current graphics mode   ----TODO
//      0006_000a - bytes per pixel
//    0006_000C - border color
//    0006_0010 - pallette bank           ----TODO
//    0006_0014 - horizontal pallette selector: bit 31 on, 30..20 add to $60010, 11:0 pixel num. ----TODO
//    0006_0018 - display list start addr  ----TODO
//    0006_001C - horizontal scroll right register ----TODO
//    0006_0020 - x res
//    0006_0024 - y res
//    0006_0028 - KBD. 28 - ASCII 29 modifiers, 2A raw code 2B key released
//    0006_002C - mouse. 6002c,d x 6002e,f y
//    0006_0030 - mouse keys, 0006_0032 - mouse wheel; 127 up 129 down
//    0006_0034 - current dl position ----TODO
//    0006_0040 - 2FF6_007C sprite control long 0 31..16 y pos  15..0 x pos
//                                         long 1 30..16 y zoom 15..0 x zoom
//    0006_0080 - 0006_009C dynamic sprite data pointer
//    0006_00A0 - text cursor position
//    0006_00A4 - text color
//    0006_00A8 - background color
//    0006_00AC - text size and pitch
//    0006_00B0 - text x res
//    0006_00B4 - text y res                                                             A0000000
//    0006_00B8 - native x resolution
//    0006_00BC - native y resolution

 //zoom2-colors2-border1-scroll1-gr/txt1-borderline1-pallette#8-scroll4-pixels12        2560-0-0-00000000
begin
if mode=0 then
  begin
  if nativex=2560 then
    begin
    for i:=0 to 1439 do
      begin
      lpoke(base+$5a000+8*i,$A0000000);
      lpoke(base+$5a000+8*i+4,i*2560);
      end;
    i:=1440;
    lpoke(base+$5a000+8*i,$A0000000);
    lpoke(base+$5a000+8*i+4,i*2560);
    lpoke (base+$60018,$5A000);
    dpoke (base+$60008,0);
    dpoke(base+$6000a,256);
    end


  else mode:=1;
  end;
end;

procedure blit(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:int64);

// --- TODO - write in asm, add advanced blitting modes
// --- rev 21070111

var i,j:integer;
    b1,b2:integer;

begin
//if lpeek(base+$60008)<16 then
  begin
  from:=from+x;
  too:=too+x2;
  for i:=0 to lines-1 do
    begin
    b2:=too+bpl2*(i+y2);
    b1:=from+bpl1*(i+y);
    for j:=0 to length-1 do
      poke(b2+j,peek(b1+j));
    end;
  end;
// TODO: use DMA; write for other color depths
end;


procedure setpallette(pallette:TPallette; bank:integer);

var fh:integer;

begin
systempallette[bank]:=pallette;
end;

procedure SetColorEx(c,bank,color:cardinal);

begin
systempallette[bank,c]:=color;
end;

procedure SetColor(c,color:cardinal);

var bank:integer;

begin
bank:=c div 256; c:= c mod 256;
systempallette[bank,c]:=color;
end;

procedure sethidecolor(c,bank,mask:cardinal);

begin
systempallette[bank,c]+=(mask shl 24);
end;

procedure unhidecolor(c,bank:cardinal);

begin
systempallette[bank,c]:=systempallette[bank,c] and $FFFFFF;
end;

procedure cls(c:integer);

// --- rev 20170111

var i,l:integer;
    c3: cardinal;


begin
box(0,0,xres,yres,c);
end;

//  ---------------------------------------------------------------------
//   putpixel (x,y,color)
//   put color pixel on screen at position (x,y)
//   rev. 20170111
//  ---------------------------------------------------------------------

procedure putpixel(x,y,color:integer); // inline;

label p999;

var adr:ptruint;

begin
if (x<0) or (x>=xres) or (y<0) or (y>yres) then goto p999;
adr:=(ptruint(displaystarthi) shl 32)+ displaystart+x+xres*y;
poke(adr,color);
p999:
end;


//  ---------------------------------------------------------------------
//   getpixel (x,y)
//   asm procedure - get color pixel on screen at position (x,y)
//   rev. 20170111
//  ---------------------------------------------------------------------

function getpixel(x,y:integer):integer; inline;

var adr:ptruint;

begin
  if (x<0) or (x>=xres) or (y<0) or (y>yres) then result:=0
else
  begin
  adr:=(ptruint(displaystarthi) shl 32)+ displaystart+x+xres*y;
  result:=peek(adr);
  end;
end;


//  ---------------------------------------------------------------------
//   box(x,y,l,h,color)
//   asm procedure - draw a filled rectangle, upper left at position (x,y)
//   length l, height h
//   rev. 20170111
//  ---------------------------------------------------------------------


procedure box(x,y,l,h,c:int64);

label p101,p102,p999;

var screenptr:ptruint;
    xr:int64;

begin

screenptr:=displaystart+(uint64(displaystarthi) shl 32);
xr:=xres;
if x<0 then begin l:=l+x; x:=0; if l<1 then goto p999; end;
if x>=xres then goto p999;
if y<0 then begin h:=h+y; y:=0; if h<1 then goto p999; end;
if y>=yres then goto p999;
if x+l>=xres then l:=xres-x;
if y+h>=yres then h:=yres-y;


             asm

              ldr x2,y
              ldr x7,xr
              mov x3,x7
              ldr x1,x
              mul x3,x3,x2
              ldr x4,l
              add x3,x3,x1
              ldr x0,screenptr
              add x0,x0,x3
              ldrb w3,c
              ldr x6,h

p102:         mov x5,x4
p101:         strb w3,[x0],#1  // inner loop
              subs x5,x5,#1
              b.ne p101
              add x0,x0,x7
              sub x0,x0,x4
              subs x6,x6,#1
              b.ne p102


             end;

p999:
end;

//  ---------------------------------------------------------------------
//   box2(x1,y1,x2,y2,color)
//   Draw a filled rectangle, upper left at position (x1,y1)
//   lower right at position (x2,y2)
//   wrapper for box procedure
//   rev. 2015.10.17
//  ---------------------------------------------------------------------

procedure box2(x1,y1,x2,y2,color:integer);

begin
if x1>x2 then begin i:=x2; x2:=x1; x1:=i; end;
if y1>y2 then begin i:=y2; y2:=y1; y1:=i; end;
if (x1<>x2) and (y1<>y2) then  box(x1,y1,x2-x1+1, y2-y1+1,color);
end;


procedure line2(x1,y1,x2,y2,c:integer);

var d,dx,dy,ai,bi,xi,yi,x,y:integer;

begin
x:=x1;
y:=y1;
if (x1<x2) then
  begin
  xi:=1;
  dx:=x2-x1;
  end
else
  begin
   xi:=-1;
   dx:=x1-x2;
  end;
if (y1<y2) then
  begin
  yi:=1;
  dy:=y2-y1;
  end
else
  begin
  yi:=-1;
  dy:=y1-y2;
  end;

putpixel(x,y,c);
if (dx>dy) then
  begin
  ai:=(dy-dx)*2;
  bi:=dy*2;
  d:= bi-dx;
  while (x<>x2) do
    begin
    if (d>=0) then
      begin
      x+=xi;
      y+=yi;
      d+=ai;
      end
    else
      begin
      d+=bi;
      x+=xi;
      end;
    putpixel(x,y,c);
    end;
  end
else
  begin
  ai:=(dx-dy)*2;
  bi:=dx*2;
  d:=bi-dy;
  while (y<>y2) do
    begin
    if (d>=0) then
      begin
      x+=xi;
      y+=yi;
      d+=ai;
      end
    else
      begin
      d+=bi;
      y+=yi;
      end;
    putpixel(x, y,c);
    end;
  end;
end;

procedure line(x,y,dx,dy,c:integer);

begin
line2(x,y,x+dx,y+dy,c);
end;

procedure circle(x0,y0,r,c:integer);

var d,x,y,da,db:integer;

begin
d:=5-4*r;
x:=0;
y:=r;
da:=(-2*r+5)*4;
db:=3*4;
while (x<=y) do
  begin
  putpixel(x0-x,y0-y,c);
  putpixel(x0-x,y0+y,c);
  putpixel(x0+x,y0-y,c);
  putpixel(x0+x,y0+y,c);
  putpixel(x0-y,y0-x,c);
  putpixel(x0-y,y0+x,c);
  putpixel(x0+y,y0-x,c);
  putpixel(x0+y,y0+x,c);
  if d>0 then
    begin
    d+=da;
    y-=1;
    x+=1;
    da+=4*4;
    db+=2*4;
    end
  else
    begin
    d+=db;
    x+=1;
    da+=2*4;
    db+=2*4;
    end;
  end;
end;


procedure fcircle(x0,y0,r,c:integer);

var d,x,y,da,db:integer;

begin
d:=5-4*r;
x:=0;
y:=r;
da:=(-2*r+5)*4;
db:=3*4;
while (x<=y) do
  begin
  line2(x0-x,y0-y,x0+x,y0-y,c);
  line2(x0-x,y0+y,x0+x,y0+y,c);
  line2(x0-y,y0-x,x0+y,y0-x,c);
  line2(x0-y,y0+x,x0+y,y0+x,c);
  if d>0 then
    begin
    d+=da;
    y-=1;
    x+=1;
    da+=4*4;
    db+=2*4;
    end
  else
    begin
    d+=db;
    x+=1;
    da+=2*4;
    db+=2*4;
    end;
  end;
end;


//  ---------------------------------------------------------------------
//   putchar(x,y,ch,color)
//   Draw a 8x16 character at position (x1,y1)
//   STUB, will be replaced by asm procedure
//   rev. 2015.10.14
//  ---------------------------------------------------------------------

procedure putchar(x,y:integer;ch:char;col:integer);

// --- TODO: translate to asm, use system variables
// --- rev 20170111
var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      putpixel(x+j,y+i,col);
    end;
  end;
end;

procedure putcharz(x,y:integer;ch:char;col,xz,yz:integer);

// --- TODO: translate to asm, use system variables

var i,j,k,l:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      for k:=0 to yz-1 do
        for l:=0 to xz-1 do
           putpixel(x+j*xz+l,y+i*yz+k,col);
    end;
  end;
end;

procedure outtextxy(x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(x+8*i-8,y,t[i],c);
end;

procedure outtextxyz(x,y:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(x+8*xz*i,y,t[i+1],c,xz,yz);
end;

procedure outtextxys(x,y:integer; t:string;c,s:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(x+s*i-s,y,t[i],c);
end;

procedure outtextxyzs(x,y:integer; t:string;c,xz,yz,s:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(x+s*xz*i,y,t[i+1],c,xz,yz);
end;

procedure scrollup;

var i:integer;

begin
  blit(displaystart,0,32,displaystart,0,0,xres,yres-32,xres,xres);
  box(0,yres-32,xres,32,147);
end;

procedure print(line:string);

var i:integer;

begin
for i:=1 to length(line) do
  begin
  box(16*dpeek(base+$600a0),32*dpeek(base+$600a2),16,32,147);
  putcharz(16*dpeek(base+$600a0),32*dpeek(base+$600a2),line[i],156,2,2);
  dpoke(base+$600a0,dpeek(base+$600a0)+1);
  if dpeek(base+$600a0)>111 then
    begin
    dpoke(base+$600a0,0);
    dpoke(base+$600a2,dpeek(base+$600a2)+1);
    if dpeek(base+$600a2)>34 then
      begin
      scrollup;
      dpoke(base+$600a2,34);
      end;
    end;
  end;
end;

procedure println(line:string);

begin
print(line);
dpoke(base+$600a2,dpeek(base+$600a2)+1);
if dpeek(base+$600a2)>34 then
  begin
  scrollup;
  dpoke(base+$600a2,34);
  end;
end;

procedure printscreen;

begin
box(0,0,100,100,44);
fh:=filecreate(drive+'screen');
outtextxy(0,0,inttostr(fh),0);
outtextxy(0,16,drive+'screen'+timetostr(now),0);
filewrite(fh,p2^,(xres+64)*yres*4);
fileclose(fh);
end;

end.

