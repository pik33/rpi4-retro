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
//
// 0000_0000  -  heap_start (about 0190_0000) - Ultibo area
// Heap start -  2EFF_FFFF retromachine program area, about 720 MB
//
// BASE=$2FF0_0000 - this can change or become dynamic
//
// 2FF0_0000  -  2FF0_FFFF - 6502 area
//    2FF0_D400  -  2FF0_D418 SID
//    2FF0_D420  -  POKEY --- TODO
//
// 2FF1_0000  -  2FF5_FFFF - system data area
//    2FF1_0000  -  2FF4_FFFF pallette banks; 65536 entries
//    2FF5_0000  -  2FF5_1FFF font definition; 256 char @8x16 px
//    2FF5_2000  -  2FF5_9FFF static sprite defs 8x4k
//    2FF5_A000  -  2FF5_FFFF reserved for future OS/BASIC
//
// 2FF6_0000  -  2FF6_FFFF --- copper
//    2FF6_0000 - frame counter
//    2FF6_0004 - display start
//    2FF6_0008 - current graphics mode   ----TODO
//      2FF6_0009 - bytes per pixel
//    2FF6_000C - border color
//    2FF6_0010 - pallette bank           ----TODO
//    2FF6_0014 - horizontal pallette selector: bit 31 on, 30..20 add to $60010, 11:0 pixel num. ----TODO
//    2FF6_0018 - display list start addr  ----TODO
//                DL entry: 00xx_YYLLL_MM - display LLL lines in mode MM
//                            xx: 00 - do nothing
//                                01 - raster interrupt
//                                10 - set pallette bank YY
//                                11 - set horizontal scroll at YY
//                          10xx_AAAAAAA - set display address to xxAAAAAAA
//                          11xx_AAAAAAA - goto address xxAAAAAAA
//    2FF6_001C - horizontal scroll right register ----TODO
//    2FF6_0020 - x res
//    2FF6_0024 - y res
//    2FF6_0028 - KBD. 28 - ASCII 29 modifiers, 2A raw code 2B key released
//    2FF6_002C - mouse. 6002c,d x 6002e,f y
//    2FF6_0030 - mouse keys, 2FF6_0032 - mouse wheel; 127 up 129 down
//    2FF6_0034 - current dl position ----TODO
//    2FF6_0040 - 2FF6_007C sprite control long 0 31..16 y pos  15..0 x pos
//                                         long 1 30..16 y zoom 15..0 x zoom
//    2FF6_0080 - 2FF6_009C dynamic sprite data pointer
//    2FF6_00A0 - text cursor position
//    2FF6_00A4 - text color
//    2FF6_00A8 - background color
//    2FF6_00AC - text size and pitch
//    2FF6_00B0 - double buffer screen #1 address
//    2FF6_00B4 - double buffer screen #2 address
//    2FF6_00B8 - native x resolution
//    2FF6_00BC - native y resolution
//    2FF6_00C0 - initial DL area


//
//    2FF6_0100 - 2FF6_01FF - blitter
//    2FF6_0200 - 2FF6_02FF - paula
//    2FF6_0300 - 2FF6_0?FF - FM synth


//    2FF6_0F00 - system data area
//    2FF6_0F00 - CPU clock
//    2FF6_0F04 - CPU temperature
//    2FF6_0FF8 - kbd report

//    2FF7_0000  -  2FFF_FFFF - retromachine system area
//    3000_0000  -  30FF_FFFF - virtual framebuffer area
//    3100_0000  -  3AFF_FFFF - Ultibo system memory area
//    3B00_0000  -  3EFF_FFFF - GPU memory
//    3F00_0000  -  3FFF_FFFF - RPi real hardware registers


// TODO planned retromachine graphic modes:
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


// ----------------------------   This is still alpha quality code


unit retromalina;

{$mode objfpc}{$H+}

interface

uses unix,baseunix,sysutils,classes,retro;


var base_:array[0..$FFFFF] of byte;        // system area base
    base:cardinal;
    mainscreen:cardinal;  // mainscreen area


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
      _audiodma=        $600C0;
      _dblbufscn1=      $60400;
      _dblbufscn2=      $60404;
      _nativex=         $60408;
      _nativey=         $6040C;
      _initialdl=       $60410;
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
  	smem_start:cardinal;    	//* Start of frame buffer mem
  					//* (physical address)
  	smem_len:cardinal;		//* Length of frame buffer mem
  	atype:cardinal;			//* see FB_TYPE_*
  	type_aux:cardinal;		//* Interleave for interleaved Planes
  	visual:cardinal;		//* see FB_VISUAL_*
  	xpanstep:word;		//* zero if no hardware panning
  	ypanstep:word;		//* zero if no hardware panning
  	ywrapstep:word;		//* zero if no hardware ywrap
  	line_length:cardinal;		//* length of a line in bytes
  	mmio_start:cardinal;	        //* Start of Memory Mapped I/O
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
    tim, t, ts: int64;


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
    audiodma1:       array[0..7] of cardinal absolute base_[_audiodma];
    audiodma2:       array[0..7] of cardinal absolute base_[_audiodma+32];
    dblbufscn1:      cardinal absolute base_[_dblbufscn1];
    dblbufscn2:      cardinal absolute base_[_dblbufscn2];
    nativex:         cardinal absolute base_[_nativex];
    nativey:         cardinal absolute base_[_nativey];

    kbdreport:       array[0..7] of byte absolute base_[_kbd_report];


    error:integer;
    framesize:integer;
    backgroundaddr:integer;
    screenaddr:integer;
    redrawing:integer;
    windowsdone:boolean=false;
    drive:string;

    mp3frames:integer=0;
    debug1,debug2,debug3:cardinal;
       mmm:integer;

           screensize:integer;
     fbresult:integer;




// prototypes

procedure initmachine(mode:integer);
procedure stopmachine;

procedure graphics(mode:integer);
procedure setpallette(pallette:TPallette;bank:integer);
procedure cls(c:integer);
procedure putpixel(x,y,color:integer);
procedure putchar(x,y:integer;ch:char;col:integer);
procedure outtextxy(x,y:integer; t:string;c:integer);
procedure blit(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);
procedure box(x,y,l,h,c:integer);
procedure box2(x1,y1,x2,y2,color:integer);


function gettime:int64;
procedure poke(addr:uint64;b:byte);
procedure dpoke(addr:uint64;w:word);
procedure lpoke(addr:uint64;c:uint64);
procedure slpoke(addr:uint64;i:integer);
function peek(addr:uint64):byte;
function dpeek(addr:uint64):word;
function lpeek(addr:uint64):uint64;
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

function remapram(from,too,size:cardinal):cardinal;
function readwheel: shortint; inline;
procedure unhidecolor(c,bank:cardinal);
procedure scrconvertnative(src,screen:pointer);
procedure scrconvertnative2(src,screen:pointer);
procedure print(line:string);
procedure println(line:string);
procedure printscreen;


function removeramlimits(address,length:uint64;params:integer):integer; cdecl; external 'libramlimit';
{$linklib 'ramlimit'}

implementation


procedure scrconvert(src,screen:pointer); forward;
procedure sprite(screen:pointer); forward;
procedure sprite2(screen:pointer); forward;

procedure scrconvertnative3(src,screen:pointer); forward;

var testscreen1, testscreen2:array[0..1920*1200-1] of cardinal;

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
for i:=0 to 100000 do lpoke(cardinal(p2)+4*i,$00FF00);
running:=1;
repeat
  begin
  vblank1:=0;
  t:=gettime;
  if fbresult=0 then scrconvertnative(pointer(mainscreen+$800000),p2)    // classic driver
  else
    begin
    scrconvertnative2(pointer(mainscreen+$800000),@testscreen1);                // new driver
    sprite2(@testscreen1);
    end;
  tim:=gettime-t;

  screenaddr:=mainscreen+$800000;

  t:=gettime;
  if fbresult=0 then sprite(p2);// else sprite2(p2);
  ts:=gettime-t;
  vblank1:=1;
  framecnt+=1;

  vinfo.yoffset := 0;
  dummy := 0;

  if fbresult=0 then fpioctl(fbfd, FBIOPAN_DISPLAY, @vinfo);
  fpioctl(fbfd, FBIO_WAITFORVSYNC, @dummy);

  if fbresult<>0 then  move(testscreen1, p2^,4*1920*1080);

  vblank1:=0;
  t:=gettime;

  if fbresult=0 then scrconvertnative(pointer(mainscreen+$b00000),p2+(xres+64)*(yres{+32}))
  else
    begin
    scrconvertnative2(pointer(mainscreen+$b00000),@testscreen2);
    sprite2(@testscreen2);

    end;
  tim:=gettime-t;

  screenaddr:=mainscreen+$b00000;

  t:=gettime;
  if fbresult=0 then sprite(p2+(xres+64)*(yres));// else   sprite2(p2);
  ts:=gettime-t;
  vblank1:=1;
  framecnt+=1;

  if fbresult=0 then vinfo.yoffset := yres else vinfo.yoffset := 0; ;
  dummy := 0;

  if fbresult=0 then fpioctl(fbfd, FBIOPAN_DISPLAY, @vinfo);

  fpioctl(fbfd, FBIO_WAITFORVSYNC, @dummy);
  if fbresult<>0 then move(testscreen2, p2^,4*1920*1080);

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

base:=cardinal(@base_);
mainscreen:=cardinal(fpmmap(nil,$1000000,prot_read or prot_write or prot_exec,map_shared or map_anonymous,0,0));

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
vinfo.yres_virtual:=vinfo.yres*2;
fbresult:=fpioctl(fbfd, FBIOPUT_VSCREENINFO, @vinfo); // todo check and exit

sleep(300);
kbfd := fileopen('/dev/tty1', fmOpenWrite);     // 2 for debug
if (kbfd > 0) then fpioctl(kbfd, KDSETMODE, @KD_GRAPHICS);

fpioctl(fbfd, FBIOGET_FSCREENINFO, @finfo);
screensize := finfo.smem_len;
p2:=fpmmap(nil,screensize, PROT_READ or PROT_WRITE, MAP_SHARED, fbfd, 0);

  for i:=0 to 100000 do lpoke(cardinal(p2)+4*i,$FFFFFF);

//  thread:=tretro.create(true);
//  thread.start;

bordercolor:=0;
displaystart:=mainscreen;                 // vitual framebuffer address
framecnt:=0;                              // frame counter

// init pallette, font and mouse cursor

//systemfont:=vgafont;
systemfont:=st4font;
sprite7def:=mysz;
sprite7zoom:=$00010001;
setpallette(ataripallette,0);
for i:=$10000 to $10000+1023 do if (i mod 4) = 0 then lpoke(base+i,lpeek(base+i) or $FF000000);
// init sprite data pointers
for i:=0 to 7 do spritepointers[i]:=base+_sprite0def+4096*i;

// init sid variables



//removeramlimits(integer(@sprite));
//removeramlimits(integer(@sprite2));

mousex:=xres div 2;
mousey:=yres div 2;
mousewheel:=128;




// start frame refreshing thread
thread:=tretro.create(true);
thread.start;

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
repeat until running=0;

//windows.terminate;
if (kbfd >= 0) then
  begin
  fpioctl(kbfd, KDSETMODE, @KD_TEXT);
// close kb file
  fileclose(kbfd);
  end;
fpmunmap(p2,screensize);
fpmunmap(pointer(mainscreen),$1000000);
end;

// -----  Screen convert procedures

procedure scrconvert(src,screen:pointer);

// --- rev 21070111

var a,b,c:integer;
    e:integer;

label p1,p0,p002,p10,p11,p12,p999;

begin
a:=displaystart;
c:=integer(src);//$30800000;  // map start
e:=bordercolor;
b:=base+_pallette;
                           {
                asm

                stmfd r13!,{r0-r12,r14}   //Push registers
                ldr r1,c
                ldr r2,screen
                ldr r3,b
                mov r5,r2

                //upper border

                add r5,#307200
                ldr r4,e
                mov r6,r4
                mov r7,r4
                mov r8,r4
                mov r9,r4
                mov r10,r4
                mov r12,r4
                mov r14,r4


p10:            stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                cmp r2,r5
                blt p10

                mov r0,#1120

p11:            add r5,#256

                //left border

p0:             stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}


                                    //active screen
                add r5,#7168

p1:
                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p1

                                  //right border
                add r5,#256
                ldr r4,e
                mov r6,r4
                mov r7,r4
                mov r8,r4
                mov r9,r4
                mov r10,r4
                mov r12,r4
                mov r14,r4


p002:           stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                subs r0,#1
                bne p11
                                  //lower border
                add r5,#307200

p12:            stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p12
p999:           ldmfd r13!,{r0-r12,r14}
                end;
                                }

end;


procedure scrconvertnative(src,screen:pointer);

// --- rev 21070608

var a,b,c:cardinal;
    e:integer;
    nx,ny:cardinal;

label p1,p0,p002,p10,p11,p12,p999;

begin
a:=displaystart;
c:=integer(src);//$30800000;  // map start
e:=bordercolor;
b:=base+_pallette;
ny:=yres;//nativey;
nx:=xres*4;//nativex*4;
                          {
                asm

                stmfd r13!,{r0-r12,r14}   //Push registers
                ldr r1,c
                ldr r2,screen
                ldr r3,b
                mov r5,r2
                sub r2,#256
                sub r5,#256

                //upper border


                ldr r0,ny

p11:            ldr r4,nx                                   //active screen
                add r5,r4 //#7168
                 add r2,#256
                 add r5,#256

p1:
                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p1

                subs r0,#1
                bne p11


p999:           ldmfd r13!,{r0-r12,r14}
                end;

                           }
end;

procedure scrconvertnative2(src,screen:pointer);

// --- rev 21070608

var a,b,c:cardinal;
    e:integer;
    nx,ny:cardinal;

label p1,p0,p002,p10,p11,p12,p999;

begin
a:=displaystart;
c:=integer(src);//$30800000;  // map start
e:=bordercolor;
b:=base+_pallette;
ny:=yres;//nativey;
nx:=xres*4;//nativex*4;
                            {
                asm

                stmfd r13!,{r0-r12,r14}   //Push registers
                ldr r1,c
                ldr r2,screen
                ldr r3,b
                mov r5,r2
            //    sub r2,#256
            //    sub r5,#256

                //upper border


                ldr r0,ny

p11:            ldr r4,nx                                   //active screen
                add r5,r4 //#7168
          //       add r2,#256
           //      add r5,#256

p1:
                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p1

                subs r0,#1
                bne p11


p999:           ldmfd r13!,{r0-r12,r14}
                end;

                            }
end;


procedure scrconvertnative3(src,screen:pointer);

// --- rev 21070608

var a,b,c:cardinal;
    e:integer;
    nx,ny:cardinal;
    x,y:integer;

label p1,p0,p002,p10,p11,p12,p999;

begin
a:=xres*yres-1;

for x:=0 to a do
 begin
 PCardinal(screen)^:=systempallette[0,Pbyte(src)^];
 screen+=4; src+=1;
  end;
end;




procedure scrconvertdl(screen:pointer);

// --- rev 21070111

var a,b:integer;
    e:integer;
    c,command, pixels, lines, dl:cardinal;

const scr:cardinal=0;

label p001;

begin
a:=displaystart;
e:=bordercolor;
c:=scr;
b:=base+_pallette;
dl:=lpeek(base+$60034);
scr:=mainscreen;
 // rev 20170607

// DL graphic mode

//xxxxDDMM
// xxxx = 0001 for RPi Retromachine
// MM: 00: hi, 01 med 10 low 11 native borderless
// DD: 00 8bpp 01 16 bpp 10 32 bpp 11 border

//    2F06_0018 - display list start addr  ----TODO
//                DL entry: 00xx_YYLLL_MM - display LLL lines in mode MM
//                            xx: 00 - do nothing
//                                01 - raster interrupt
//                                10 - set pallette bank YY
//                                11 - set horizontal scroll at YY
//                          01xx_AAAAAAA - wait for vsync, then start DL @xxAAAAAA
//                          10xx_AAAAAAA - set display address to xxAAAAAAA
//                          11xx_AAAAAAA - goto address xxAAAAAAA

//    2F06_0034 - current dl position ----TODO

//    2F06_0008 - current graphics mode   ----TODO
//      2F06_0009 - bytes per pixel
//    2F06_000C - border color
//    2F06_0010 - pallette bank           ----TODO
//    2F06_0014 - horizontal pallette selector: bit 31 on, 30..20 add to $60010, 11:0 pixel num. ----TODO
//    2F06_0018 - display list start addr  ----TODO
//                DL entry: 00xx_YYLLL_MM - display LLL lines in mode MM
//                            xx: 00 - do nothing
//                                01 - raster interrupt
//                                10 - set pallette bank YY
//                                11 - set horizontal scroll at YY
//                          10xx_AAAAAAA - set display address to xxAAAAAAA
//                          11xx_AAAAAAA - goto address xxAAAAAAA
//    2F06_001C - horizontal scroll right register ----TODO
//    2F06_0020 - x res
//    2F06_0024 - y res


command:=lpeek(dl);
if (command and $C0000000) = 0 then // display
  begin
  if command and $FF=$1C then       // border
    begin
    lines:=(command and $000FFF00) shr 8;
    pixels:=lines*1920*4;    // border modes are always signalling 1920x1200
                             {
                             asm
                push {r0-r9}
                ldr r1,e
                ldr r0,c
                mov r2,r1
                mov r3,r1
                mov r4,r1
                mov r5,r1
                mov r6,r1
                mov r7,r1
                mov r8,r1
                mov r8,r1
                ldr r9,pixels
                add r9,r0
p001:           stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                stm r0!,{r1,r2,r3,r4,r5,r6,r7,r8}
                cmp r0,r9
                blt p001
                pop {r0-r9}
                end;          }
    end
  else if command and $FF=$10 then       // hi res bordered 8bpp
    begin
    end
  else if command and $FF=$13 then       // native bordreless 8bpp
    begin
    end
  end;
{
                asm

                stmfd r13!,{r0-r12,r14}   //Push registers
                ldr r1,c
                ldr r2,screen
                ldr r3,b
                mov r5,r2

                //upper border

                add r5,#307200
                ldr r4,e
                mov r6,r4
                mov r7,r4
                mov r8,r4
                mov r9,r4
                mov r10,r4
                mov r12,r4
                mov r14,r4


p10:            stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                cmp r2,r5
                blt p10

                mov r0,#1120

p11:            add r5,#256

                //left border

p0:             stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}


                                    //active screen
                add r5,#7168

p1:
                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                ldm r1!,{r4,r9}

                mov r6,r4,lsr #8
                mov r7,r4,lsr #16
                mov r8,r4,lsr #24
                mov r10,r9,lsr #8
                mov r12,r9,lsr #16
                mov r14,r9,lsr #24

                and r4,#0xFF
                and r6,#0xFF
                and r7,#0xFF
                and r9,#0xFF
                and r10,#0xFF
                and r12,#0xFF

                ldr r4,[r3,r4,lsl #2]
                ldr r6,[r3,r6,lsl #2]
                ldr r7,[r3,r7,lsl #2]
                ldr r8,[r3,r8,lsl #2]
                ldr r9,[r3,r9,lsl #2]
                ldr r10,[r3,r10,lsl #2]
                ldr r12,[r3,r12,lsl #2]
                ldr r14,[r3,r14,lsl #2]

                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p1

                                  //right border
                add r5,#256
                ldr r4,e
                mov r6,r4
                mov r7,r4
                mov r8,r4
                mov r9,r4
                mov r10,r4
                mov r12,r4
                mov r14,r4


p002:           stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                subs r0,#1
                bne p11
                                  //lower border
                add r5,#307200

p12:            stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}
                stm r2!,{r4,r6,r7,r8,r9,r10,r12,r14}

                cmp r2,r5
                blt p12
p999:           ldmfd r13!,{r0-r12,r14}
                end;
}
end;

procedure sprite(screen:pointer);

// A sprite procedure
// --- rev 21070111

label p101,p102,p103,p104,p105,p106,p107,p108,p109,p999;
label a7680,affff,affff0000,spritedata;

//var a7680:cardinal=0;
//      affff:cardinal=0;
//      affff0000:cardinal=0;
 //     spritedata:cardinal=0;

var spritebase:integer;
    nx:cardinal;
    yr:cardinal;
    scrl:cardinal;
    base2:cardinal;

begin
base2:=base+$60080;
yr:=yres;
spritebase:=base+_spritebase;
nx:=xres*4+256;
scrl:=integer(screen)+(xres+64)*yres*4;
                     {
               asm
               stmfd r13!,{r0-r12,r14}     //Push registers
               ldr r0,base2
               str r0,spritedata
               ldr r12,nx
               str r12,a7680
               mov r12,#0
                                       //sprite
               ldr r0,spritebase
 p103:         ldr r1,[r0],#4
               mov r2,r1, lsl #16      // sprite 0 position
               mov r3,r1, asr #16
               asr r2,#14              // x pos*4

               ldr r14,yr
               cmp r3,r14
               bge p107

               cmp r2,#8192            // switch off the sprite if x>2048
               blt p104
p107:          add r12,#1
               add r0,#4
               cmp r12,#8
               bge p999
               b   p103

p104:          ldr r4,a7680
               mul r3,r3,r4
               add r3,r2              // sprite pos


               ldr r4,screen
               add r3,r4              // pointer to upper left sprite pixel in r3
               ldr r4,spritedata
               add r4,r4,r12,lsl #2
               ldr r4,[r4]

               ldr r1,[r0],#4
               mov r2,r1,lsl #16
               lsr r2,#16             // xzoom
               lsr r1,#16             // yzoom
               cmp r1,#8
               movgt r1,#8            // zoom control, maybe switch it off?
               cmp r2,#8
               movgt r2,#8
               cmp r1,#1
               movle r1,#1
               cmp r2,#1
               movle r2,#1
               mov r7,r2
               mov r8,r2,lsl #7        // xzoom * 128 (128=4*32)
               mov r9,r1,lsl #5        //y zoom * 32
               mov r10,r1              //y zoom counter
               mov r6,#32

               push {r0}

p101:
               ldr r14,screen
               cmp r3,r14
               bge p109
               add r3,r8
               b p106

p109:          ldr r5,[r4],#4
               cmp r5,#0
               bne p102
               add r3,r3,r8,lsr #5
               mov r7,r2
               subs r6,#1
               bne p101
               b p106

p102:          ldr r0,[r3]
         //      cmp r12,r0,lsr #28
         //      strge r5,[r3],#4
               str r5,[r3],#4
               addlt r3,#4
               subs r7,#1
               bne p102

p105:          mov r7,r2
               subs r6,#1
               bne p109

p106:          ldr r0,a7680
               add r3,r0
               sub r3,r8

               ldr r14,scrl
               cmp r3,r14
               bge p108

               subs r10,#1
               subne r4,#128
               addeq r10,r1
               mov r6,#32
               subs r9,#1
               bne p101

p108:          pop {r0}


               add r12,#1
               cmp r12,#8
               bne p103
               b p999

affff:         .long 0xFFFF
affff0000:     .long 0xFFFF0000
a7680:         .long 7680
spritedata:    .long base+0x60080

p999:          ldmfd r13!,{r0-r12,r14}
               end;   }
end;

procedure sprite2(screen:pointer);

// A sprite procedure
// --- rev 21070111

label p101,p102,p103,p104,p105,p106,p107,p108,p109,p999;
label a7680,affff,affff0000,spritedata;

//var a7680:cardinal=0;
//      affff:cardinal=0;
//      affff0000:cardinal=0;
 //     spritedata:cardinal=0;

var spritebase:integer;
    nx:cardinal;
    yr:cardinal;
    scrl:cardinal;
    base2:cardinal;

begin
base2:=base+$60080;
yr:=yres;
spritebase:=base+_spritebase;
nx:=xres*4;
scrl:=integer(screen)+(xres)*yres*4;
                    {
               asm
               stmfd r13!,{r0-r12,r14}     //Push registers
               ldr r0,base2
               str r0,spritedata
               ldr r12,nx
               str r12,a7680
               mov r12,#0
                                       //sprite
               ldr r0,spritebase
 p103:         ldr r1,[r0],#4
               mov r2,r1, lsl #16      // sprite 0 position
               mov r3,r1, asr #16
               asr r2,#14              // x pos*4

               ldr r14,yr
               cmp r3,r14
               bge p107

               cmp r2,#8192            // switch off the sprite if x>2048
               blt p104
p107:          add r12,#1
               add r0,#4
               cmp r12,#8
               bge p999
               b   p103

p104:          ldr r4,a7680
               mul r3,r3,r4
               add r3,r2              // sprite pos


               ldr r4,screen
               add r3,r4              // pointer to upper left sprite pixel in r3
               ldr r4,spritedata
               add r4,r4,r12,lsl #2
               ldr r4,[r4]

               ldr r1,[r0],#4
               mov r2,r1,lsl #16
               lsr r2,#16             // xzoom
               lsr r1,#16             // yzoom
               cmp r1,#8
               movgt r1,#8            // zoom control, maybe switch it off?
               cmp r2,#8
               movgt r2,#8
               cmp r1,#1
               movle r1,#1
               cmp r2,#1
               movle r2,#1
               mov r7,r2
               mov r8,r2,lsl #7        // xzoom * 128 (128=4*32)
               mov r9,r1,lsl #5        //y zoom * 32
               mov r10,r1              //y zoom counter
               mov r6,#32

               push {r0}

p101:
               ldr r14,screen
               cmp r3,r14
               bge p109
               add r3,r8
               b p106

p109:          ldr r5,[r4],#4
               cmp r5,#0
               bne p102
               add r3,r3,r8,lsr #5
               mov r7,r2
               subs r6,#1
               bne p101
               b p106

p102:          ldr r0,[r3]
         //      cmp r12,r0,lsr #28
         //      strge r5,[r3],#4
               str r5,[r3],#4
               addlt r3,#4
               subs r7,#1
               bne p102

p105:          mov r7,r2
               subs r6,#1
               bne p109

p106:          ldr r0,a7680
               add r3,r0
               sub r3,r8

               ldr r14,scrl
               cmp r3,r14
               bge p108

               subs r10,#1
               subne r4,#128
               addeq r10,r1
               mov r6,#32
               subs r9,#1
               bne p101

p108:          pop {r0}


               add r12,#1
               cmp r12,#8
               bne p103
               b p999

affff:         .long 0xFFFF
affff0000:     .long 0xFFFF0000
a7680:         .long 7680
spritedata:    .long base+0x60080

p999:          ldmfd r13!,{r0-r12,r14}
               end;  }
end;

// ------  Helper procedures

function Do_SysCall(sysnr,param1,param2,param3:   int64    ):integer; external name 'FPC_SYSCALL3';

function fpmprotect(addr,size,prot:uint64):longint;

begin
 result:=Do_SysCall(227,addr,size,prot);
end;

procedure removeramlimits(addr:uint64);

//var Entry:TPageTableEntry;
   var dummy:longint;

begin
dummy:=fpmprotect((addr and $FFFFF000),$4000,PROT_READ or PROT_WRITE or PROT_EXEC);
end;

function remapram(from,too,size:cardinal):cardinal;

//var Entry:TPageTableEntry;
//    s,len:integer;

begin
//s:=size;
//repeat
//  Entry:=PageTableGetEntry(from);
//  len:=entry.Size;
//  entry.virtualaddress:=too;
//  Entry.Flags:=$3b2;
//  PageTableSetEntry(Entry);
//  too+=len;
//  from+=len;
//  s-=len;
//until s<=0;
//CleanDataCacheRange(from, size);
//InvalidateDataCacheRange(too, size);
end;



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

procedure poke(addr:uint64;b:byte); inline;

begin
PByte(addr)^:=b;
end;

procedure dpoke(addr:uint64;w:word); inline;

begin
PWord(addr and $FFFFFFFE)^:=w;
end;

procedure lpoke(addr:uint64;c:uint64); inline;

begin
Puint64(addr and $FFFFFFFC)^:=c;
end;

procedure slpoke(addr:uint64;i:integer); inline;

begin
PInteger(addr and $FFFFFFFC)^:=i;
end;

function peek(addr:uint64):byte; inline;

begin
peek:=Pbyte(addr)^;
end;

function dpeek(addr:uint64):word; inline;

begin
dpeek:=PWord(addr and $FFFFFFFE)^;
end;

function lpeek(addr:uint64):uint64; inline;

begin
lpeek:=Puint64(addr and $FFFFFFFC)^;
end;

function slpeek(addr:uint64):integer;  inline;

begin
slpeek:=PInteger(addr and $FFFFFFFC)^;
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

// rev 20170607

// Graphics mode set:
// 16 - HiRes 8bpp
// 17 - MedRes 16 bpp
// 18 - LoRes 32 bpp
// 19 - native, borderless, 8 bpp

// DL graphic mode

//xxxxDDMM
// xxxx = 0001 for RPi Retromachine
// MM: 00: hi, 01 med 10 low 11 native borderless
// DD: 00 8bpp 01 16 bpp 10 32 bpp 11 border

//    2F06_0018 - display list start addr  ----TODO
//                DL entry: 00xx_YYLLL_MM - display LLL lines in mode MM
//                            xx: 00 - do nothing
//                                01 - raster interrupt
//                                10 - set pallette bank YY
//                                11 - set horizontal scroll at YY
//                          01xx_AAAAAAA - wait for vsync, then start DL @xxAAAAAA
//                          10xx_AAAAAAA - set display address to xxAAAAAAA
//                          11xx_AAAAAAA - goto address xxAAAAAAA

//    2F06_0034 - current dl position ----TODO

//    2F06_0008 - current graphics mode   ----TODO
//      2F06_0009 - bytes per pixel
//    2F06_000C - border color
//    2F06_0010 - pallette bank           ----TODO
//    2F06_0014 - horizontal pallette selector: bit 31 on, 30..20 add to $60010, 11:0 pixel num. ----TODO
//    2F06_0018 - display list start addr  ----TODO
//                DL entry: 00xx_YYLLL_MM - display LLL lines in mode MM
//                            xx: 00 - do nothing
//                                01 - raster interrupt
//                                10 - set pallette bank YY
//                                11 - set horizontal scroll at YY
//                          10xx_AAAAAAA - set display address to xxAAAAAAA
//                          11xx_AAAAAAA - goto address xxAAAAAAA
//    2F06_001C - horizontal scroll right register ----TODO
//    2F06_0020 - x res
//    2F06_0024 - y res
begin
if mode=16 then
  begin
  poke(base+$60008,16);
  poke(base+$60009,8);
  lpoke(base+$60010,0);
  lpoke(base+$60014,0);
  lpoke(base+$60020,1792);
  lpoke(base+$60024,1120);
  lpoke (base+$60018,base+$60410);
  lpoke (base+$60034,base+$60410);
  lpoke (base+$60410,$0000281C);  // upper border 40 lines
  lpoke (base+$60414,$00046000);  // main display 1120 lines @ hi/8bpp
  lpoke (base+$60418,$0000281C);  // lower border 40 lines
  lpoke (base+$6041C,base+$60410+$40000000);  // wait vsync and restart DL
  end
else if mode=17 then
  begin
  end
else if mode=18 then
  begin
  end
else if mode=19 then
  begin
  poke(base+$60008,16);
  poke(base+$60009,8);
  lpoke(base+$60010,0);
  lpoke(base+$60014,0);
  lpoke(base+$60020,nativex);
  lpoke(base+$60024,nativey);
  lpoke (base+$60018,base+$60410);
  lpoke (base+$60034,base+$60410);
  lpoke (base+$60414,(nativey shl 8)+3);      // main display nativey lines @ hi/8bpp
  lpoke (base+$6041C,base+$60410+$40000000);  // wait vsync and restart DL
  end
else if mode=144 then        // double buffered high 8 bit
  begin
  poke(base+$60008,144);
  poke(base+$60009,8);
  lpoke(base+$60010,0);
  lpoke(base+$60014,0);
  lpoke(base+$60020,1792);
  lpoke(base+$60024,1120);

  lpoke (base+$60018,base+$60410);
  lpoke (base+$60034,base+$60410);
  lpoke (base+$60410,$B0800000);  // display start @ 30800000
  lpoke (base+$60414,$0000281C);  // upper border 40 lines
  lpoke (base+$60418,$00046000);  // main display 1120 lines @ hi/8bpp
  lpoke (base+$6041c,$0000281C);  // lower border 40 lines
  lpoke (base+$60420,$B0b00000);  // display start @ 30b00000
  lpoke (base+$60424,base+$60428+$40000000);  // wait vsync and restart DL @ 60428
  lpoke (base+$60428,$0000281C);  // upper border
  lpoke (base+$6042c,$00046000);  // main display 1120 lines @ hi/8bpp
  lpoke (base+$60430,$0000281C);  // lower border 40 lines
  lpoke (base+$60434,$B0800000);  // display start @ 30800000
  lpoke (base+$60438,base+$60414+$40000000);  // wait vsync and restart DL @ 60414
  end
else if mode=147 then          // double buffered native 8bit
  begin
  poke(base+$60008,147);
  poke(base+$60009,8);
  lpoke(base+$60010,0);
  lpoke(base+$60014,0);
  lpoke(base+$60020,nativex);
  lpoke(base+$60024,nativey);
  lpoke (base+$60018,base+$60410);
  lpoke (base+$60034,base+$60410);
  lpoke (base+$60410,$B0800000);  // display start @ 30800000
  lpoke (base+$60414,(nativey shl 8)+3);  // display the screen
  lpoke (base+$60418,$B0b00000);  // display start @ 30a00000
  lpoke (base+$6041c,base+$60420+$40000000);  // wait vsync and restart DL @ 60420
  lpoke (base+$60420,(nativey shl 8)+3);
  lpoke (base+$60424,$B0800000);  // display start @ 30b00000
  lpoke (base+$60428,base+$60414+$40000000);  // wait vsync and restart DL @ 60414
  end
end;

procedure blit(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);

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

var c2, i,l:integer;
    c3: cardinal;
    screenstart:integer;

begin
c:=c mod 256;
l:=(xres*yres) div 4 ;
c3:=c+(c shl 8) + (c shl 16) + (c shl 24);
for i:=0 to l do lpoke(displaystart+4*i,c3);
end;

//  ---------------------------------------------------------------------
//   putpixel (x,y,color)
//   put color pixel on screen at position (x,y)
//   rev. 20170111
//  ---------------------------------------------------------------------

procedure putpixel(x,y,color:integer); inline;

label p999;

var adr:integer;

begin
if (x<0) or (x>=xres) or (y<0) or (y>yres) then goto p999;
adr:=displaystart+x+xres*y;
poke(adr,color);
p999:
end;


//  ---------------------------------------------------------------------
//   getpixel (x,y)
//   asm procedure - get color pixel on screen at position (x,y)
//   rev. 20170111
//  ---------------------------------------------------------------------

function getpixel(x,y:integer):integer; inline;

var adr:integer;

begin
  if (x<0) or (x>=xres) or (y<0) or (y>yres) then result:=0
else
  begin
  adr:=displaystart+x+xres*y;
  result:=peek(adr);
  end;
end;


//  ---------------------------------------------------------------------
//   box(x,y,l,h,color)
//   asm procedure - draw a filled rectangle, upper left at position (x,y)
//   length l, height h
//   rev. 20170111
//  ---------------------------------------------------------------------


procedure box(x,y,l,h,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xr:integer;

begin

screenptr:=displaystart;
xr:=xres;
if x<0 then begin l:=l+x; x:=0; if l<1 then goto p999; end;
if x>=xres then goto p999;
if y<0 then begin h:=h+y; y:=0; if h<1 then goto p999; end;
if y>=yres then goto p999;
if x+l>=xres then l:=xres-x;
if y+h>=yres then h:=yres-y;

// TODO: asm a64

for i:=x to x+l-1 do
  for j:=y to y+h-1 do
    putpixel(x,y,c);


              {
             asm
             push {r0-r7}
             ldr r2,y
             ldr r7,xr
             mov r3,r7
             ldr r1,x
             mul r3,r3,r2
             ldr r4,l
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,h

p102:        mov r5,r4
p101:        strb r3,[r0],#1  // inner loop
             subs r5,#1
             bne p101
             add r0,r7
             sub r0,r4
             subs r6,#1
             bne p102

             pop {r0-r7}
             end;
                    }
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

