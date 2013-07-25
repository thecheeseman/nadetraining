/*
    This is ripped from Lev's 1.5 jump save mod.
    I take no credit for any of this -- it was just
    quicker than writing my own.
*/

main()
{
	self thread _MeleeKey();
	self thread _UseKey();
	
	self endon("end_saveposition_threads");
	{
		wait 1;

		self iprintln("double-tap^2 [{+melee}] ^7: to save position");
		wait 3;
		self iprintln("double-tap^1 [{+activate}] ^7: to load saved position");
	}
}
_MeleeKey()
{
	self endon("end_saveposition_threads");

	for(;;)
	{
		if(self meleeButtonPressed())
		{
			catch_next = false;

			for(i=0; i<=0.30; i+=0.01)
			{
				if(catch_next && self meleeButtonPressed() && self isOnGround())
				{
					self thread savePos();
					wait 1;
					break;
				}
				else if(!(self meleeButtonPressed()))
					catch_next = true;

				wait 0.01;
			}
		}

		wait 0.05;
	}
}

_UseKey()
{
	self endon("end_saveposition_threads");

	for(;;)
	{
		if(self useButtonPressed())
		{
			catch_next = false;

			for(i=0; i<=0.30; i+=0.01)
			{
				if(catch_next && self useButtonPressed())
				{
					self thread checksave();
					wait 1;
					break;
				}
				else if(!(self useButtonPressed()))
					catch_next = true;

				wait 0.01;
			}
		}

		wait 0.05;
	}
}
savePos()
{
	self.saved_origin = self.origin;
	self.saved_angles = self.angles;
	self iprintln("^2P^7osition ^2(^7" + (int)self.saved_origin[0] + "^7, ^7" + (int)self.saved_origin[1] + "^7, ^7" + (int)self.saved_origin[2] + "^2)^7 saved.");
}

checksave()
{
	if (getcvar("scr_lev_position_check"))
		{
		loadPossave();		
		}
		else
		{
		loadPos();
		}
}

loadPos()
{
	thread positions();
	if(!isDefined(self.saved_origin))
		{
		self iprintln("^1T^7here is no previous position to load.");
		return;
		}
	else
		{
		self setPlayerAngles(self.saved_angles); // angles need to come first
		self setOrigin(self.saved_origin);
		self iprintln("^1P^7revious position ^1(^7" + (int)self.saved_origin[0] + "^7, ^7" + (int)self.saved_origin[1] + "^7, ^7" + (int)self.saved_origin[2] + "^1)^7 loaded.");
		}
}

loadPossave()
{
	thread positions();
	if(!isDefined(self.saved_origin))
	{
		self iprintln("^1T^7here is no previous position to load.");
		return;
	}
	else
		if(self positions(70))
			{
			self iprintlnbold("A player is currently standing on that location!");
			self iprintlnbold("Try again in a few sec.");
			return;
			}

		else
			{
			self setPlayerAngles(self.saved_angles); // angles need to come first
			self setOrigin(self.saved_origin);
			self iprintln("^1P^7revious position ^1(^7" + (int)self.saved_origin[0] + "^7, ^7" + (int)self.saved_origin[1] + "^7, ^7" + (int)self.saved_origin[2] + "^1)^7 loaded.");
			}
}

positions(range)
{
	if(!range)
		return true;

	// Get all players and pick out the ones that are playing
	allplayers = getentarray("player", "classname");
	players = [];
	for(i = 0; i < allplayers.size; i++)
	{
		if(allplayers[i].sessionstate == "playing")
			players[players.size] = allplayers[i];
	}

	// Get the players that are in range
	sortedplayers = sortByDist(players, self);

	// Need at least 2 players (myself + one team mate)
	if(sortedplayers.size<2)
		return false;

	// First player will be myself so check against second player
	distance = distance(self.saved_origin, sortedplayers[1].origin);
	if( distance <= range )
		return true;
	else
		return false;
}

sortByDist(points, startpoint, maxdist, mindist)
{
	if(!isdefined(points))
		return undefined;
	if(!isdefineD(startpoint))
		return undefined;

	if(!isdefined(mindist))
		mindist = -1000000;
	if(!isdefined(maxdist))
		maxdist = 1000000; // almost 16 miles, should cover everything.

	sortedpoints = [];

	max = points.size-1;
	for(i = 0; i < max; i++)
	{
		nextdist = 1000000;
		next = undefined;

		for(j = 0; j < points.size; j++)
		{
			thisdist = distance(startpoint.origin, points[j].origin);
			if(thisdist <= nextdist && thisdist <= maxdist && thisdist >= mindist)
			{
				next = j;
				nextdist = thisdist;
			}
		}

		if(!isdefined(next))
			break; // didn't find one that fit the range, stop trying

		sortedpoints[i] = points[next];

		// shorten the list, fewer compares
		points[next] = points[points.size-1]; // replace the closest point with the end of the list
		points[points.size-1] = undefined; // cut off the end of the list
	}

	sortedpoints[sortedpoints.size] = points[0]; // the last point in the list

	return sortedpoints;
}