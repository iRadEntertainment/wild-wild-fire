using Godot;
using System;


[GlobalClass]
public partial class GasRefillGate : Area3D
{
	private Airplane plane;
	private Airport airport;

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
            airport.HandleLandingProcess(this);
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
