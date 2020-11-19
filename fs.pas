program FromSky;
uses fs_engine;

var
	map: GameMap;
	bird: GameBird;
	prop: GameProp;
	flew, recordflew, speed: integer;
	fpattern, pattern: PPattern;
begin
	randomize;
	StartMenu(map, bird, prop, flew, recordflew, speed, fpattern);
	StartOperations(map, bird, prop, fpattern, pattern);
	while true do
	begin
		HandleArrowKey(bird);
		CollisionCheck(bird, prop, pattern, flew, recordflew);
		MoveProp(prop, fpattern, pattern, flew, speed);
	end;
end.
