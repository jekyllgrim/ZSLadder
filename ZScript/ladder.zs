class LadderObject : Actor
{
	PlayerPawn attached;
	private double bottom, top;

	Default
	{
		//$Title "Func ladder"
		//$Category "Interactive objects"
		//$Arg0 "Height"
		//$Arg0Type 24
		//$Arg1 "Radius (half of width)"
		//$Arg1Type 23
		//$Angled

		+SOLID
		+NOGRAVITY
		Radius 32;
		Height 128;
	}

	/*override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (args[0] == 0)
		{
			args[0] = Height;
		}
		if (args[1] == 0)
		{
			args[1] = Radius;
		}
		if (!A_SetSize(args[1] * 0.5, args[0]))
		{
			Console.Printf("\cgWarning:\c- Func ladder at position (%.2f, %.2f, %.2f) didn't fit and was removed");
			Destroy();
			return;
		}
	}*/

	override bool CanCollideWith(Actor other, bool passive)
	{
		if (passive && other && (!tracer || tracer != other) && other.player)
		{
			return true;
		}
		return false;
	}

	override void CollidedWith(Actor other, bool passive)
	{
		if (passive && other && (!tracer || tracer != other) && other.player)
		{
			AttachPlayer(other.player.mo);
		}
	}

	void DropPlayer()
	{
		if (attached)
		{
			attached.bFly = attached.bNoGravity = false;
			attached.vel.z = Clamp(attached.vel.z, -10, 0);
			attached = null;
		}
	}

	void AttachPlayer (PlayerPawn who)
	{
		if (!attached)
		{
			attached = who;
			tracer = who;
			attached.A_Stop();
			attached.SetOrigin((self.pos.xy, attached.pos.z), true);
			Console.Printf("player attached to ladder");
		}
		attached.bFly = attached.bNoGravity = true;
		Vector3 ppos = attached.pos;
		Vector2 attachLimits = (pos.z + 4, pos.z + height - 4);
		if (attached.pos.z > attachLimits.x && attached.pos.z < attachLimits.y)
		{
			ppos.xy = self.pos.xy;
		}
		ppos.z = Clamp(ppos.z, self.pos.z - height, self.pos.z + height);
		attached.SetOrigin(ppos, true);
		Console.Printf("player is attached to ladder. Pos: %.1f, %.1f, %.1f | top: %.1f | bottom: %.1f", attached.pos.x, attached.pos.y, attached.pos.z, top, bottom);
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
				Console.Printf("player moved outside of ladder: dropping");
				DropPlayer();
			}
		}
		if (tracer)
		{
			if (Level.Vec2Diff(tracer.pos.xy, pos.xy).Length() > (radius + tracer.radius) * 1.5)
			{
				Console.Printf("previously attached player moved outside of ladder: forgetting");
				DropPlayer();
				tracer = null;
			}
		}
		
		if (attached && (attached.player.cmd.buttons & BT_USE) && !(attached.player.oldbuttons & BT_USE))
		{
			Console.Printf("player pressed Use: dropping");
			DropPlayer();
		}
		else if (tracer && tracer.player && (tracer.player.cmd.buttons & BT_USE) && !(tracer.player.oldbuttons & BT_USE))
		{
			Console.Printf("previously attached player pressed Use: re-attaching");
			AttachPlayer(tracer.player.mo);
		}
	}
}
