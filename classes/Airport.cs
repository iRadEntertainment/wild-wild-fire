using Godot;
using System;

[GlobalClass]
public partial class Airport : Node3D
{
    [Export]
    private Area3D gasOrb;

    [Export]
    private float refillAmount = 100;

    [Export]
    private float minFuelForVisibility = .4f;

    public Marker3D MarkerTower;
    private Airplane airplane;

    public override void _Ready()
    {
        base._Ready();
        MarkerTower = GetNode<Marker3D>("%MarkerTower");
        airplane = GetNode<Airplane>("%Airplane");

        GD.Print($"Airport.cs: Running Ready");

        gasOrb.BodyEntered += OnBodyEntered;
        ToggleGasOrb(doesExist: false);

        
    }

    public override void _Process(double delta)
    {
        base._Process(delta);

        if(airplane != null && airplane.CurrentFuel <= minFuelForVisibility)
        {
            ToggleGasOrb(doesExist: true);
        }
    }

    public void OnBodyEntered(Node3D body)
    {
        GD.Print($"Airport.cs: Entered Gas Orb - Body Entered");
        Airplane plane = body as Airplane;

        if (plane != null)
        {
            GD.Print($"Airport.cs: Call Plane Refill");
            RefillPlane(plane);
            ToggleGasOrb(doesExist: false);
        }
    }

    public void RefillPlane(Airplane plane)
    {
        plane.CurrentFuel += refillAmount;
        GD.Print($"Airport.cs: Plane Fuel Amount: {plane.CurrentFuel}");

    }

    private void ToggleGasOrb(bool doesExist)
    {
        gasOrb.Visible = doesExist;
        gasOrb.Monitoring = doesExist;
    }

}
