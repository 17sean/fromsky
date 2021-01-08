unit fs_engine;
interface

type
	GameMap = record
		HomeX, HomeY: integer;
		h, w: integer; { Height and Width } 
	end;
	
	GameSide = (top, bottom);

	GameBird = record
		CurX, CurY, MaxTop, MaxBottom: integer;
		symb, dead: char;
		side: GameSide;
	end;

	GameProp = record
		HomeX, HomeY, CurX, CurY, MaxCurX: integer;
		symb: char;
	end;

	PPattern = ^GamePattern;
	GamePattern = record
		data: integer;
		next: PPattern;
	end;

procedure StartMenu(
		    var map: GameMap;
	       	var bird: GameBird;
	       	var prop: GameProp;
	       	var flew, recordflew, speed: integer;
		    var fpattern: PPattern);

procedure StartOperations(
			map: GameMap;
		    bird: GameBird;
			prop: GameProp;
		    fpattern: PPattern;
		    var pattern: PPattern);

procedure HandleArrowKey(var bird: GameBird);

procedure CollisionCheck(
			bird: GameBird;
		    prop: GameProp;
			pattern: PPattern;
		    flew, recordflew: integer);

procedure MoveProp(
		    var prop: GameProp;
	       	var fpattern, pattern: PPattern;
	       	var flew, speed: integer);

implementation
uses crt;

const
	Author = 'By 17sean';
	Game = 'From Sky';
	RecordFileName = 'record.bin';
	PatternFileName = 'patterns.txt';

type
	GameMenuSub = record
		HomeX, HomeY: integer;
		contain: string;
	end;

	GameMenuSubs = array [1..4] of GameMenuSub;

procedure InitAll(
		    var map: GameMap;
	       	var MenuSubs: GameMenuSubs;
	       	var bird: GameBird;
		    var prop: GameProp;
		    var flew, recordflew, speed: integer;
		    var fpattern: PPattern);
var
	RecordFile: file of integer;
	PatternFile: text;
	tmp: PPattern;
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
	bird.CurY := map.HomeY + 6;
	bird.MaxTop := map.HomeY;
	bird.MaxBottom := map.HomeY + map.h;
	bird.symb := '>';
	bird.dead := '~';

	prop.HomeX := map.HomeX + map.w - 5;
	prop.HomeY := map.HomeY + 1;
	prop.CurX := prop.HomeX;
	prop.CurY := prop.HomeY;
	prop.MaxCurX := map.HomeX + 1;	
	prop.symb := '|';

	{$I-}
	assign(RecordFile, RecordFileName);
	reset(RecordFile);
	if IOresult <> 0 then
	begin
		rewrite(RecordFile);
		write(RecordFile, 0);
		recordflew := 0;
	end
	else
		read(RecordFile, recordflew);
	close(RecordFile);
	flew := 0;
	speed := 200;

	assign(PatternFile, PatternFileName);
	reset(PatternFile);
	if IOResult <> 0 then
	begin
		write(ErrOutput, 'Error, couldn''t open ', PatternFileName);
		halt(1);
	end;
	fpattern := nil;
	while not Eof(PatternFile) do
	begin
		new(tmp);
		readln(PatternFile, tmp^.data);
		if (tmp^.data = 0) or (tmp^.data > 10) then
		begin
			dispose(tmp);
			break;
		end;
		tmp^.data := tmp^.data + map.HomeY;
		tmp^.next := fpattern;
		fpattern := tmp;
	end;
	close(PatternFile);
	{$I+}
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
	x, y, i, j: integer;
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

procedure DrawSubMenu(
		    Map: GameMap;
	       	MenuSubs: GameMenuSubs;
	       	recordflew: integer);
begin
	DrawMap(map);
	if recordflew = 0 then
	begin
		GotoXY((
			ScreenWidth - length('Seems no records')) div 2,
		       	ScreenHeight div 2);
		write('Seems no records');
	end
	else
	begin	
		GotoXY((ScreenWidth - 12) div 2, ScreenHeight div 2);
		write('Record: ', recordflew, 'm');
	end;
	GotoXY(MenuSubs[4].HomeX, MenuSubs[4].HomeY);
	write(MenuSubs[4].contain);
end;

procedure ControlMenu(
		map: GameMap;
	       	MenuSubs: GameMenuSubs;
	       	recordflew: integer);
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
				DrawSubMenu(map, MenuSubs, recordflew);
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

procedure RecordCheck(flew, recordflew: integer);
var
	RecordFile: file of integer;
begin
	if flew > recordflew then
	begin
		assign(RecordFile, RecordFileName);
		rewrite(RecordFile);
		write(RecordFile, flew);
		close(RecordFile);
	end;
end;

procedure LoseEvent(flew, recordflew: integer);
begin
	GotoXY((ScreenWidth - 10) div 2, ScreenHeight div 2);
	write('You lose...');
	RecordCheck(flew, recordflew);
	delay(2000);
	clrscr;
	halt;
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

function RandomPattern(fpattern: PPattern): PPattern;
var
	i: integer;
begin
	RandomPattern := fpattern;
	for i := 1 to random(10)+1 do
	begin
		if RandomPattern^.next = nil then
			RandomPattern := fpattern
		else
			RandomPattern := RandomPattern^.next;
	end;
end;

function IsEmpty(prop: GameProp; pattern: PPattern; emptyY: integer)
								: boolean;
var
	i: integer;
begin
	for i := 0 to 2 do
	begin
		if pattern^.data + i = emptyY then
		begin
			IsEmpty := true;
			exit;
		end;
	end;
	IsEmpty := false;
end;

procedure HideProp(prop: GameProp; pattern: PPattern);
var
	i: integer;
begin
	for i := 0 to 11 do
	begin
		GotoXY(prop.CurX, prop.CurY+i);
		if not IsEmpty(prop, pattern, prop.CurY+i) then
			write(' ');
	end;
end;

procedure ShowProp(prop: GameProp; pattern: PPattern);
var
	i: integer;
begin
	for i := 0 to 11 do
	begin
		GotoXY(prop.CurX, prop.CurY+i);
		if not IsEmpty(prop, pattern, prop.CurY+i) then
			write(prop.symb);
	end;
end;

procedure ShowFlew(flew: integer);
begin
	GotoXY((ScreenWidth - 8) div 2, 2);
	write('Flew: ', flew, 'm');
end;

procedure SpeedChanger(flew: integer; var speed: integer);
begin
	if flew mod 50 = 0 then
		speed := round(speed * 0.9);
end;

procedure StartMenu(
		var map: GameMap;
	       	var bird: GameBird;
	       	var prop: GameProp;
	       	var flew, recordflew, speed: integer;
		var fpattern: PPattern);
var
	MenuSubs: GameMenuSubs;
begin
	InitAll(map, MenuSubs, bird, prop, flew,
	       	recordflew, speed, fpattern);
	CheckScreen(map);
	StartMessage(map);
	ControlMenu(map, MenuSubs, recordflew); 
	clrscr;
end;

procedure StartOperations(
			map: GameMap;
		       	bird: GameBird;
			prop: GameProp;
		       	fpattern: PPattern;
		       	var pattern: PPattern);
begin
	DrawMap(map);
	ShowBird(bird);
	pattern := RandomPattern(fpattern);
	ShowProp(prop, pattern);
end;

procedure HandleArrowKey(var bird: GameBird);
var
	ch: char;
begin
	ch := #0;
	if KeyPressed then
		ch := ReadKey;	
	if ch in ['w', 'W'] then
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
end;

procedure CollisionCheck(
			bird: GameBird;
		       	prop: GameProp;
			pattern: PPattern;
		       	flew, recordflew: integer);
begin
	if (bird.CurY + 1 = bird.MaxBottom) or
       	((bird.CurX = prop.CurX) and
       	(not IsEmpty(prop, pattern, bird.CurY))) then
	begin
		GotoXY(bird.CurX, bird.CurY);
		write(bird.dead);
		Delay(500);
		LoseEvent(flew, recordflew);
	end;
end;

procedure MoveProp(
		var prop: GameProp;
	       	var fpattern, pattern: PPattern;
	       	var flew, speed: integer);
begin
	Delay(speed);
	HideProp(prop, pattern);
	if prop.CurX = prop.MaxCurX then
	begin
		prop.CurX := prop.HomeX;
		pattern := RandomPattern(fpattern);
	end
	else
		prop.CurX := prop.CurX - 1;
	ShowProp(prop, pattern);
	flew := flew + 1;
	ShowFlew(flew);
	SpeedChanger(flew, speed);
end;

end.
