unit raymarch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure raymarch(screen:pointer);

implementation

procedure raymarch(screen:pointer);

begin

camerax:=0;
cameray:=1;
cameraz:=0;

spherex:=0;
spherey:=1;
spherez:=1;
spherer:=1;

for y:=0 to 1079 do
  begin
  for x:=0 to 1919 do
    begin

    pointx:=camerax;
    pointy:=cameray;
    pointz:=cameraz;

    dp:=pointy*pointy;
    dk:=(spherex-pointx)*(spherex-pointx)+(spherey-pointy)* (spherey-pointy)+ (spherez-pointz)* (spherez-pointz);
    if dp<dk then d:=dp else d:=dk;

    end;
  end;

end;


end.

