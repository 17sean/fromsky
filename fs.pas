program FromSky;
uses crt;

const
	Author = 'By 17sean';
	Game = 'From Sky';
	RecordFile = 'record.bin';

type
	GameMap = record
		HomeX, HomeY: integer;
		h, w: integer; { Height and Width } 
	end;

	GameMenuSub = record
		HomeX, HomeY: integer;
		contain: string;
	end;

	GameMenuSubs = array [1..4] of GameMenuSub;

	GameSide = (top, bottom);
	
	GameBird = record
		CurX, CurY, MaxTop, MaxBottom: integer;
		symb, dead: char;
		side: GameSide;
	end;

	GameProp = record
		HomeX, HomeY, CurX, CurY, MaxCurX: integer;
		empty: array [1..3] of integer;
		symb: char;
	end;


procedure InitAll(
		var map: GameMap;
	       	var MenuSubs: GameMenuSubs;
	       	var bird: GameBird;
		var prop: GameProp);
var
	i, j: integer;
begin
	map.h := 14;
	map.w := 36;
	map.HomeX := (ScreenWidth - 36) div 2;
	map.HomeY := (ScreenHeight - 14) div 2;

	MenuSubs[1].HomeX := map.HomeX + ((map.w - length('Menu')) div 2);
	MenuSubs[1].HomeY := map.HomeY + 4;
	MenuSubs[1].contain := 'Menu';
	MenuSubs[2].HomeX := map.HomeX + ((map.w - length('Start play')) div 2);
	MenuSubs[2].HomeY := map.HomeY + ((map.h + 1) div 2);
	MenuSubs[2].contain := 'Start play';
	MenuSubs[3].HomeX := map.HomeX + ((map.w - length('My record')) div 2);
	MenuSubs[3].HomeY := map.HomeY + ((map.h + 2) div 2);
	MenuSubs[3].contain := 'My record';
	MenuSubs[4].HomeX := map.HomeX + ((map.w - length('Exit')) div 2);
	MenuSubs[4].HomeY := map.HomeY + ((map.h + 4) div 2);
	MenuSubs[4].contain := 'Exit';

	bird.CurX := map.HomeX + 4;
	bird.CurY := map.HomeY + (map.h) div 2;
	bird.MaxTop := map.HomeY;
	bird.MaxBottom := map.HomeY + map.h;
	bird.symb := '>';
	bird.dead := '~';

	prop.HomeX := map.HomeX + map.w - 5;
	prop.HomeY := map.HomeY + 1;
	prop.CurX := prop.HomeX;
	prop.CurY := prop.HomeY;
	prop.MaxCurX := map.HomeX + 1;

	j := 4;
	for i := 1 to 3 do
	begin
		prop.empty[i] := prop.CurY + j;
		j := j + 1;
	end;
	prop.symb := '|';
end;

procedure CheckScreen(map: GameMap);
begin
	if (ScreenHeight < map.h + 2) or (ScreenWidth < map.w + 5) then
	begin
		writeln(ErrOutput,
		       	'Resize terminal > ', map.w+5, ' x ', map.h+2);
		halt(1);
	end;
	clrscr;
end;

procedure DrawMap(map: GameMap);
var
	i, j: integer;
	x, y: integer;
begin
	x := map.HomeX;
	y := map.HomeY;
	GotoXY(x, y);

	for i := 1 to map.h do
	begin
		for j := 1 to map.w do
		begin
			if i = 1 then
			begin
				if (j = 1) or (j = map.w) then
					write(' ')
				else
					write('_');
			end
			else if i = map.h then
			begin
				if (j = 1) or (j = map.w) then
					write('|')
				else
					write('_');
			end
			else
			begin
				if (j = 1) or (j = map.w) then
					write('|')
				else
					write(' ')
			end;
		end;

		y := y + 1;
		GotoXY(x, y);
	end;
end;

procedure StartMessage(map: GameMap);
var
	i, x, y: integer;
begin
	DrawMap(map);
	x := map.HomeX + ((map.w - length(Game)) div 2);
	y := map.HomeY + (map.h div 2);
	GotoXY(x, y);
	for i := 1 to length(Game) do
	begin
		write(Game[i]);
		delay(100);
	end;	
	delay(500);

	x := map.HomeX + (map.w - (length(Author) + 3));
       	y := map.HomeY + 2;
	GotoXY(x, y);
	for i := 1 to length(Author) do
	begin
		write(Author[i]);
		delay(200);
	end;
	delay(1000);
	clrscr;
end;

procedure DrawMenu(map: GameMap; MenuSubs: GameMenuSubs);
var
	i: integer;
begin
	DrawMap(map);
	for i := 1 to 3 do
	begin
		GotoXY(MenuSubs[i].HomeX, MenuSubs[i].HomeY);
		write(MenuSubs[i].contain);
	end;
end;

procedure DrawSubMenu(Map: GameMap; MenuSubs: GameMenuSubs);
var
	i: integer;
	rec: file of integer;
begin
	{$I-}
	DrawMap(map);
	GotoXY((ScreenWidth - 15) div 2, ScreenHeight div 2);
	assign(rec, RecordFile);
	reset(rec);
	if IOresult <> 0 then
		write('Seem no records')
	else
	begin
		read(rec, i);
		write('Record: ', i);
		close(rec);
	end;
	GotoXY(MenuSubs[4].HomeX, MenuSubs[4].HomeY);
	write(MenuSubs[4].contain);
end;

procedure ControlMenu(map: GameMap; MenuSubs: GameMenuSubs);
type
	MenuCurrent = record
		symb: char;
		status: integer;
		page: integer;
	end;
var
	cur: MenuCurrent;
	ch: char;
begin
	cur.symb := #62;
	cur.page := 3;
	cur.status := 2;
	while true do
	begin
		case cur.page of
			1:
				exit;
			2:
			begin
				DrawSubMenu(map, MenuSubs);
				cur.status := 4;
				GotoXY(
					MenuSubs[cur.status].HomeX-2,
				       	MenuSubs[cur.status].HomeY);
				write(cur.symb);
				ch := ReadKey;
				case ch of
					#13:
						cur.page := cur.status-1;
					#27:
					begin
						clrscr;
						halt;
					end;
				end;
				write(#8, ' ');
			end;

			3:
			begin
				DrawMenu(map, MenuSubs);
				if cur.status = 4 then
					cur.status := 2;
				GotoXY(
					MenuSubs[cur.status].HomeX-2,
				       	MenuSubs[cur.status].HomeY);
				write(cur.symb);
				ch := ReadKey;
				case ch of
					#119:
						if cur.status = 3 then
							cur.status := 
								cur.status-1;
					#115:
						if cur.status = 2 then
							cur.status :=
					       			cur.status+1;
					#13:
						cur.page := cur.status-1;
					#27:
					begin
						clrscr;
						halt;
					end;
				end;
				write(#8, ' ');
			end;
		end;
	end;
end;

procedure StartMenu(var map: GameMap; var bird: GameBird; var prop: GameProp);
var
	MenuSubs: GameMenuSubs;
begin
	InitAll(map, MenuSubs, bird, prop);
	CheckScreen(map);
	StartMessage(map);
	ControlMenu(map, MenuSubs); 
	clrscr;
end;

procedure LoseEvent;
begin
	GotoXY((ScreenWidth - 10) div 2, ScreenHeight div 2);
	write('You lose...');
	delay(2000);
	clrscr;
	halt;
end;

procedure WinEvent;
begin

end;

procedure HideBird(bird: GameBird);
begin
	GotoXY(bird.CurX, bird.CurY);
	write(' ');
end;

procedure ShowBird(bird: GameBird);
begin
	GotoXY(bird.CurX, bird.CurY);
	write(bird.symb);
end;

procedure MoveBird(var bird: GameBird);
begin
	case bird.side of
		top:
		begin
			if bird.CurY - 1 = bird.MaxTop then
				exit;
			HideBird(bird);
			bird.CurY := bird.CurY - 1;
			ShowBird(bird);
		end;
		bottom:
		begin
			HideBird(bird);
			bird.CurY := bird.CurY + 1;
			ShowBird(bird);	
		end;
	end;
end;

function IsEmpty(prop: GameProp; i: integer): boolean;
var
	j: integer;
begin
	for j := 1 to 3 do
	begin
		if prop.empty[j] = i then
		begin
			IsEmpty := true;
			exit;
		end;
	end;
	IsEmpty := false;
end;

procedure HideProp(prop: GameProp); { todo change for sravnit koordinati }
var
	i, CurX, CurY: integer;
begin
	CurX := prop.CurX;
	CurY := prop.CurY;
	GotoXY(CurX, prop.CurY);
	for i := 1 to 12 do
	begin
		if not IsEmpty(prop, i) then
			write(' ');
		CurY := CurY + 1;
		GotoXY(CurX, CurY);
	end;
end;

procedure ShowProp(prop: GameProp);
var
	i, CurX, CurY: integer;
begin
	CurX := prop.CurX;
	CurY := prop.CurY;
	GotoXY(CurX, CurY);
	for i := 1 to 12 do
	begin
		if not IsEmpty(prop, i) then
			write(prop.symb);
		CurY := CurY + 1;
		GotoXY(CurX, CurY);
	end;
end;

procedure MoveProp(var prop: GameProp);
begin
	HideProp(prop);
	if prop.CurX = prop.MaxCurX then
		prop.CurX := prop.HomeX
	else
		prop.CurX := prop.CurX - 1;
	ShowProp(prop);
	
end;

procedure CollisionCheck(bird: GameBird; prop: GameProp);
var
	i: integer;
begin
	if (bird.CurY + 1 = bird.MaxBottom) then
	begin
		GotoXY(bird.CurX, bird.CurY);
		write(bird.dead);
		Delay(500);
		LoseEvent;
	end;
	if (bird.CurX = prop.CurX) and (not IsEmpty(prop, bird.CurY)) then
	begin
		for i := 1 to 3 do
			write(prop.empty[i], #9);
		write(bird.CurY);
		GotoXY(bird.CurX, bird.CurY);
		write(bird.dead);
		Delay(500);
		LoseEvent;
	end;


end;

var
	map: GameMap;
	bird: GameBird;
	prop: GameProp;
	ch: char;
begin
	randomize;
	StartMenu(map, bird, prop);
	DrawMap(map);
	ShowBird(bird);
	ShowProp(prop);

	while true do
	begin
		ch := #0;
		if KeyPressed then
			ch := ReadKey;	
		if ch = 'w' then
		begin
			bird.side := top;
			MoveBird(bird);
		end
		else if ch = #27 then
		begin
			clrscr;
			halt
		end
		else
		begin
			bird.side := bottom;
			MoveBird(bird);
		end;
		CollisionCheck(bird, prop);	
		delay(200);
		MoveProp(prop);
	end;
end.
