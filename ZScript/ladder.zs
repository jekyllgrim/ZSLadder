class LadderObjectMid : Actor
{
	Default
	{
		//$Title "Ladder model (mid)"
		//$Category "Interactive objects"
		//$Angled
		+NOINTERACTION
		+NOBLOCKMAP
		Radius 8;
		Height 64;
	}

	States {
	Spawn:
		AMRK A -1 NoDelay
		{
			scale.y = 1.2 / Level.pixelStretch;
		}
		stop;
	}
}

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
		//$Arg2Tooltip "If enabled, protects against falling when the player is stepping onto the ladder from above (the player won't be able to miss the ladder unless they explicitly jump over it.)"
		//$Arg2Default 1

		//$arg3 "Drop protection"
		//$arg3Type 11
		//$arg3Enum { 0 = "Disabled"; 1 = "Enabled"; }
		//$arg3Tooltip "If enabled, when the player presses Use to drop from the ladder, nullifies their velocity first so they can't fly away from the ladder."
		//$arg3Default 1

		+SOLID
		+NOGRAVITY
		Radius 32;
		Height 128;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		topProtection = args[2];
		dropProtection = args[3];
		A_SetSize(args[1], args[0]);
	}

	override bool CanCollideWith(Actor other, bool passive)
	{
		if (passive && other && (!tracer || tracer != other) && other.player)
		{
			AttachPlayer(other.player.mo);
		}
		return false;
	}

	/*override void CollidedWith(Actor other, bool passive)
	{
		if (passive && other && (!tracer || tracer != other) && other.player)
		{
			AttachPlayer(other.player.mo);
		}
	}*/

	void AttachPlayer (PlayerPawn who)
	{
		if (!attached)
		{
			attached = who;
			//tracer = who;
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
			if (playerZ >= attachLimits.x && playerZ <= pos.z + height + attached.height)
			{
				attachClamp.x = Clamp(attachClamp.x, selfClamp.x - 256, selfClamp.x);
			}
			// Don't let walk through its front when at the top
			// (prevent falling when dropping onto it):
			else if (topProtection)
			{
				attachClamp.x = Clamp(attachClamp.x, selfClamp.x, selfClamp.x + 256);
			}
			ppos.xy = Actor.RotateVector(attachClamp, self.angle);
		}
		ppos.z = Clamp(ppos.z, self.pos.z - height, self.pos.z + height);
		attached.SetOrigin(ppos, true);
		//Console.Printf("player is attached to ladder. Pos: %.1f, %.1f, %.1f | top: %.1f | bottom: %.1f", attached.pos.x, attached.pos.y, playerZ, top, bottom);
	}

	void DropPlayer()
	{
		if (attached)
		{
			attached.bFly = attached.bNoGravity = false;
			attached.vel.z = Clamp(attached.vel.z, -10, 0);
			if (dropProtection)
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
			DropPlayer();
		}
		else if (tracer && tracer.player && (tracer.player.cmd.buttons & BT_USE) && !(tracer.player.oldbuttons & BT_USE))
		{
			//Console.Printf("previously attached player pressed Use: re-attaching");
			AttachPlayer(tracer.player.mo);
		}
	}
}
