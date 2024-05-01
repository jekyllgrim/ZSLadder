// Base ladder model:
class LadderObjectMid : Actor
{
	const LADDERHEIGHT = 64.0;

	Default
	{
		//$Title "Ladder model (mid)"
		//$Category "Interactive objects"
		//$Angled

		//$Arg0 "Adjust to pixelratio"
		//$Arg0Type 11
		//$Arg0Enum { 0 = "Disabled"; 1 = "Enabled"; }
		//$Arg0Tooltip "If enabled, the scale of the model will automatically adjust to the current\npixelratio as set in MAPINFO (Note, this will NOT be reflected in map editor!)"
		//$Arg0Default 1

		+NOINTERACTION
		+NOBLOCKMAP
		Radius 8;
		Height LADDERHEIGHT;
	}

	States {
	Spawn:
		AMRK A -1 NoDelay
		{
			// auto-adjust for pixelratio:
			if (args[0] != 0)
			{
				scale.y *= (Level.pixelStretch / 1.2);
			}
		}
		stop;
	}
}

// Top of the ladder model:
class LadderObjectTop : LadderObjectMid
{
	Default
	{
		//$Title "Ladder model (top)"
		//$Category "Interactive objects"
		//$Angled
		Height 32;
	}
}

// This actor automatically spawns ladder models
// to fill the specified height:
class LadderObjectAuto : LadderObjectMid
{
	Default
	{
		//$Title "Ladder model (auto-extending)"
		//$Category "Interactive objects"
		//$Angled

		//$Arg0 "Total ladder height"
		//$Arg0Type 24
		//$Arg0Default 128

		//$Arg1 "Spawn top model"
		//$Arg1Type 11
		//$Arg1Enum { 0 = "Disabled"; 1 = "Enabled"; }
		//$Arg1Default 1

		Radius 24;
		Height LADDERHEIGHT;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_SetSize(radius, args[0]);

		double div = height / LADDERHEIGHT;
		int steps = floor(div);
		double elementScale = div / steps;
		for (int i = 0; i < steps; i++)
		{
			let l = Spawn('LadderObjectMid', pos);
			if (l)
			{
				l.args[0] = true;
				l.angle = angle;
				l.scale.y *= elementScale;
			}
			SetZ(pos.z + LADDERHEIGHT * elementScale);
		}
		if (args[1] != 0)
		{
			let l = Spawn('LadderObjectTop', pos);
			if (l)
			{
				l.args[0] = true;
				l.angle = angle;
				l.scale.y *= elementScale;
			}
		}
		Destroy();
	}
}

// The actual ladder functionality:
class FuncLadder : Actor
{
	protected PlayerPawn attached;
	protected double bottom, top;
	protected bool topProtection;
	protected bool dropProtection;

	Default
	{
		//$Title "Func ladder"
		//$Category "Interactive objects"
		//$Angled

		//$Arg0 "Height"
		//$Arg0Type 24
		//$Arg0Default 128
		
		//$Arg1 "Radius"
		//$Arg1Type 23
		//$Arg1Tooltip "Set this to x0.5 of the desired width of the ladder"
		//$Arg1Default 20

		//$Arg2 "Top climb protection"
		//$Arg2Type 11
		//$Arg2Enum { 0 = "Disabled"; 1 = "Enabled"; }
		//$Arg2Tooltip "If enabled, protects against falling when the player is stepping onto the ladder\nfrom above (the player won't be able to miss the ladder unless they explicitly jump over it.)"
		//$Arg2Default 1

		//$arg3 "Drop protection"
		//$arg3Type 11
		//$arg3Enum { 0 = "Disabled"; 1 = "Enabled"; }
		//$arg3Tooltip "If enabled, nullifies the player's horizontal velocity when they\npress Use to drop from the ladder, so they can't fly away from it."
		//$arg3Default 1

		+NOINTERACTION
		+NOBLOCKMAP
		Radius 32;
		Height 128;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_SetSize(args[1], args[0]);
		topProtection = args[2];
		dropProtection = args[3];
	}

	void LookForAttachment()
	{
		let bt = BlockThingsIterator.Create(self, radius);
		while (bt.Next())
		{
			let t = bt.thing;
			if (!t || t == self) continue;
			if (t && t.player && t != tracer && 
				Distance2D(t) <= radius + t.radius &&
				t.pos.z >= pos.z && t.pos.z <= pos.z + height + t.height)
			{
				AttachPlayer(t.player.mo);
			}
		}
	}

	void AttachPlayer (PlayerPawn who)
	{
		if (!attached)
		{
			attached = who;
			if (tracer == attached)
			{
				attached.A_Stop();
				attached.SetOrigin((self.pos.xy, attached.pos.z), true);
			}
			else
			{
				tracer = attached;
			}
			//Console.Printf("player attached to ladder");
		}
		attached.bFly = attached.bNoGravity = true;
		Vector3 ppos = attached.pos;
		Vector2 attachLimits = (pos.z + 4, pos.z + height - 4);
		double playerZ = attached.pos.z;
		if (playerZ > attachLimits.x && playerZ < attachLimits.y)
		{
			ppos.xy = self.pos.xy;
		}
		// Don't let player walk through the ladder:
		if (playerZ >= pos.z)
		{
			Vector2 selfClamp = Actor.RotateVector(self.pos.xy, -self.angle);
			Vector2 attachClamp = Actor.RotateVector(ppos.xy, -self.angle);
			// Don't let walk through its back when at the bottom:
			if (playerZ <= attachLimits.x)
			{
				attachClamp.x = Clamp(attachClamp.x, selfClamp.x, selfClamp.x + 256);
				ppos.xy = Actor.RotateVector(attachClamp, self.angle);
			}
			// Don't let walk through its front when at the top
			// (prevent falling when dropping onto it):
			else if (topProtection && playerZ >=attachLimits.y)
			{
				attachClamp.x = Clamp(attachClamp.x, selfClamp.x - 256, selfClamp.x);
				ppos.xy = Actor.RotateVector(attachClamp, self.angle);
			}
		}
		ppos.z = Clamp(ppos.z, self.pos.z - height, self.pos.z + height);
		attached.SetOrigin(ppos, true);
		//Console.Printf("player is attached to ladder. Pos: %.1f, %.1f, %.1f | top: %.1f | bottom: %.1f", attached.pos.x, attached.pos.y, playerZ, top, bottom);
	}

	void DropPlayer(bool manual = false)
	{
		if (attached)
		{
			attached.bFly = attached.bNoGravity = false;
			attached.vel.z = Clamp(attached.vel.z, -10, 0);
			if (manual && dropProtection)
			{
				attached.vel.xy = (0,0);
			}
			attached = null;
		}
	}

	override void Tick()
	{
		Super.Tick();
		bottom = pos.z;
		top = bottom + height + (attached? attached.height : 0);

		LookForAttachment();

		if (attached)
		{
			if (attached.pos.z >= bottom && attached.pos.z <= top)
			{
				AttachPlayer(attached);
			}
			else
			{
				//Console.Printf("player moved outside of ladder: dropping");
				DropPlayer();
			}
		}
		if (tracer)
		{
			if (Level.Vec2Diff(tracer.pos.xy, pos.xy).Length() > (radius + tracer.radius) * 1.5)
			{
				//Console.Printf("previously attached player moved outside of ladder: forgetting");
				DropPlayer();
				tracer = null;
			}
		}
		
		if (attached && (attached.player.cmd.buttons & BT_USE) && !(attached.player.oldbuttons & BT_USE))
		{
			//Console.Printf("player pressed Use: dropping");
			DropPlayer(true);
		}
		else if (tracer && tracer.player && (tracer.player.cmd.buttons & BT_USE) && !(tracer.player.oldbuttons & BT_USE))
		{
			//Console.Printf("previously attached player pressed Use: re-attaching");
			AttachPlayer(tracer.player.mo);
		}
	}
}
