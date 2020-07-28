program project1;

uses cthreads, retromalina, sysutils,sdl2,retro;

var i,j:integer;
  tttt:int64;
  bufor:array[0..15] of byte;
  r,fh:int64;
  fhp:^int64;
  rr,gg,bb:byte;
  testas:TAnimatedSprite; // bździągwa



begin
initmachine(256);
graphics(0);
cls(147);


outtextxyz(64,64,'READY',157,4,2);
testas:=balls;
sprite1zoom:=$00010001;
sprite1xy:=$01000100;
sprite1ptr:=cardinal(@testas);
for i:=0 to 16383 do
  begin
  rr:=testas[i] shr 16;
  gg:=testas[i] shr 8;
  bb:=testas[i];
  testas[i]:=bb shl 16+gg shl 8 +rr;
  end;

//fhp:=fopen('/home/pi/softsynth.ini','rb');
//r:=fread(@bufor,1,16,fhp);
//outtextxy(200,200,inttostr(fhp^),40);
sleep(2000);
if xres=2560 then
  begin

  t:=gettime;
  box(00,0,2560,1440,120);
  tttt:=gettime-t;
  outtextxyz(0,0,inttostr(tttt),200,4,4);

  t:=gettime;
  for i:=0 to 15 do
    for j:=0 to 15 do
      box(160*i,90*j, 160,90,i+16*j);
  tttt:=gettime-t;
  outtextxyz(0,0,inttostr(tttt),200,4,4);
  sleep(2000);
  box(0,0,2560,1440,0);

  box(320,120,1920,1200,147);
  outtextxyz(320,120,'20x25 border screen ',157,12,3) ;
  outtextxyz(320+384,480,'ATARI 800 XL',44,12,3);
  for i:=0 to 600 do
     begin
     box(320,120+96,600,48,147);
     outtextxyz(320,120+96,inttostr(ttt),157,12,3);
     waitvbl;
     end;

  box(320,120,1920,1200,147);
  outtextxyz(320,120,'40x25 border text screen ',157,6,3) ;
  for i:=0 to 600 do
     begin
     box(320,120+96,300,48,147);
     outtextxyz(320,120+96,inttostr(ttt),157,6,3);
     waitvbl;
     end;

  box(320,120,1920,1200,147);
  outtextxyz(320,120,'80x25 border text screen ',157,3,3) ;
  for i:=0 to 600 do
     begin
     box(320,120+96,200,48,147);
     outtextxyz(320,120+96,inttostr(ttt),157,3,3);
     waitvbl;
     end;

  box(320,80,1920,1280,147);
  outtextxyz(320,80,'120x40 border text screen ',157,2,2) ;
  for i:=0 to 600 do
     begin
     box(320,80+64,200,48,147);
     outtextxyz(320,80+64,inttostr(ttt),157,2,2);
     waitvbl;
     end;

  box(0,0,2560,1440,0);
  box(320,120,1920,1200,147);
  outtextxyz(320,120,'240x75 border text screen ',157,1,1) ;
  for i:=0 to 600 do
     begin
     box(320,120+32,200,48,147);
     outtextxyz(320,120+32,inttostr(ttt),157,1,1);
     waitvbl;
     end;
  end
else
  begin
 {
  t:=gettime;
  box(00,0,1920,1080,120);
  tttt:=gettime-t;
  outtextxyz(0,0,inttostr(tttt),200,4,4);
  sleep(2000);
  t:=gettime;
  for i:=0 to 15 do
    for j:=0 to 15 do
      box(120*i,67*j, 120,67,i+16*j);
  tttt:=gettime-t;
  outtextxyz(0,0,inttostr(tttt),200,4,4);
  sleep(2000);
  box(0,0,1920,1080,0);

  box(320,120,1280,800,147);
  outtextxyz(320,120,'20x25 border screen ',157,8,2) ;
  outtextxyz(320+256,320,'ATARI 800 XL',44,8,2);
  for i:=0 to 600 do
     begin
     box(320,120+64,600,48,147);
    outtextxyz(320,120+64,inttostr(ts),157,8,2);
     waitvbl;
     end;

  box(320,120,1280,800,147);
  outtextxyz(320,120,'40x25 border text screen ',157,4,2) ;
  for i:=0 to 600 do
     begin
     box(320,120+64,300,48,147);
     outtextxyz(320,120+64,inttostr(ttt),157,4,2);
     waitvbl;
     end;

  box(320,120,1280,800,147);
  outtextxyz(320,120,'80x25 border text screen ',157,2,2) ;
  for i:=0 to 600 do
     begin
     box(320,120+64,200,48,147);
     outtextxyz(320,120+64,inttostr(ttt),157,2,2);
     waitvbl;
     end;

 }
  box(320,120,1280,800,147);
  outtextxyz(320,120,'160x50 border text screen ',157,1,1) ;
  for i:=0 to 600 do
     begin
     box(320,120+32,200,48,147);
     outtextxyz(320,120+32,inttostr(ttt),157,1,1);
     waitvbl;
     end;



  box(320,120,1280,800,147);
  outtextxyz(320+64,120+32,'READY ',157,4,2) ;
  box(320+2*32,120+64,32,32,157);
    i:=$00010001 ;
    j:=0;
    sprite7zoom:=$00020002;
    sprite1zoom:=$00030003;
while keypressed do readkey;
repeat

  waitvbl;
  if (framecnt mod 3)=0 then begin

//   sprite1zoom+=i;
 // if sprite1zoom>$00100010 then i:=-65537;
//  if sprite1zoom<$00030003 then i:=$00010001;
  end;
  //  sprite1zoom:=sprite7zoom;
    j+=4096; if j>=65536 then j:=0;
  sprite1ptr:=cardinal(@testas)+j;
  box(300,300,200,100,0); outtextxyz(300,300,inttohex(lpeek(base+$60028)),40,2,2);

  until keypressed;


  end;

stopmachine;
end.

// dl: 01 hzoom 23 colors 4 border 5 scroll 6 graphics/text 7 border line - pallette# - scroll - border?? - addr

//i:=0;
//repeat waitvbl; box(i,i,100,50,0); outtextxyz(i,i,inttostr(sizeof(longint)),40,2,2); i+=1; until framecnt>600;
//sdl_pauseaudio(1);
//sdl_quit;
//for i:=0 to 8191 do bufor[i]:=round((16384+4096)*sin(100*pi*i/8192));
//for j:=32 to 120 do
 // begin
//  sdl_sound_init(193000);
//  sdl_pauseaudio(0);
