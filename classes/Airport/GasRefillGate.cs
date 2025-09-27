using Godot;
using System;


[GlobalClass]
public partial class GasRefillGate : Area3D
{
	
	public Marker3D primaryMarker;
	public Marker3D secondaryMarker;
	public GasRefillGate oppositeGate;

	private Airplane plane;
	private Airport airport;

	// DONE - Setup ability for gates to receive collisions
	// DONE - Setup means to determine which gate we're colliding with (starting point)
	// DONE - Setup means to determine which marker is closest (landing point)
	// DONE - Change plane's IsLanding to true
	// Tween plane from gate to primaryMarker
	// Tween plane from primaryMarker to midpoint
	// Change plane's IsLanding to false
	// Change plane's IsLanded to true
	// Refill Gas
	// Change plane's IsLanded to false
	// Change plane's IsTakingOff to true
	// Tween plane from midpoint to secondaryMarker
	// Tween plane from secondaryMarker to oppositeGate
	// Change plane's IsTakingOff to false

	public override void _Ready()
	{
		base._Ready();
		BodyEntered += OnBodyEntered;

		airport = GetParent<Airport>();
		GD.Print($"Running Ready");
		// GD.Print($"GasRefillGate.cs: PrimaryMarker: {airport.landing_endPoint} SecondaryMarker: {airport.takingOff_startPoint} MidPoint: {airport.landed_midPoint}");

		// ToggleActivatable(false);
	}

	
	public override void _Process(double delta)
	{
	}

	public void OnBodyEntered(Node3D body)
	{
        Airplane airplane = body as Airplane;
		plane = airplane;
		GD.Print($"Entered Gate");
        if (plane != null || !plane.IsTakingOff || !plane.IsLanding || !plane.IsLanded)
        {
            airport.landing_startPoint = GlobalPosition;
            airport.landing_endPoint = primaryMarker.GlobalPosition;
            airport.takingOff_startPoint = secondaryMarker.GlobalPosition;
            airport.takingOff_endPoint = oppositeGate.GlobalPosition;
            airport.landed_midPoint = airport.landing_endPoint.Lerp(airport.takingOff_startPoint, .5f);
            airport.HandleLandingProcess();
        }
    }



	public void ToggleActivatable(bool activatable)
	{
		//if (activatable)
		//{
		//	// DisableMode = DisableModeEnum.KeepActive;
		//	CollisionLayer = 8;
		//	CollisionMask = 8;
		//}
		//else
		//{
		//	// DisableMode = DisableModeEnum.Remove;
		//	CollisionLayer = 1;
		//	CollisionMask = 1;
		//}

		Monitorable = activatable;
		Monitoring = activatable;
	}

}
