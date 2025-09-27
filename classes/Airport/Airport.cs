using Godot;
using Godot.Collections;
using System;
using System.Threading.Tasks;

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

    [Export]
    private Marker3D markerOne;
    [Export]
    private Marker3D markerTwo;

    [Export]
    private PackedScene gasRefillGateScene;

    [Export]
    private Array<Vector3> gateLocations = new Array<Vector3>();

    private GasRefillGate gateOne;
    private GasRefillGate gateTwo;

    public Vector3 landing_startPoint;
    public Vector3 landing_endPoint;
    public Vector3 landed_midPoint;
    public Vector3 takingOff_startPoint;
    public Vector3 takingOff_endPoint;

    [Export]
    private float refillDuration = .5f;
    [Export]
    private float tweenDuration_MoveToLandingStart = .1f;
    [Export]
    private float tweenDuration_MoveToLandingEnd = .3f;
    [Export]
    private float tweenDuration_MoveToLandedMidPoint = .4f;
    [Export]
    private float tweenDuration_MoveToTakingOffStart = .4f;
    [Export]
    private float tweenDuration_MoveToTakingOffEnd = .3f;

    public override void _Ready()
    {
        base._Ready();
        MarkerTower = GetNode<Marker3D>("%MarkerTower");
        airplane = GetNode<Airplane>("%Airplane");

        gasOrb.BodyEntered += OnBodyEntered;
        ToggleGasOrb(doesExist: false);

        CallDeferred("SpawnGates");
    }

    public override void _Process(double delta)
    {
        base._Process(delta);

        if (airplane != null && airplane.CurrentFuel <= minFuelForVisibility && !IsInstanceValid(gateOne) && !airplane.IsLanded && !airplane.IsLanding && !airplane.IsTakingOff)
        {
            // ToggleGasOrb(doesExist: true);
            CallDeferred("SpawnGates");
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

    private void SpawnGates()
    {
        if (IsInstanceValid(gateOne)) gateOne.QueueFree();
        if (IsInstanceValid(gateTwo)) gateTwo.QueueFree();

        gateOne = gasRefillGateScene.Instantiate<GasRefillGate>();
        gateTwo = gasRefillGateScene.Instantiate<GasRefillGate>();
        AddChild(gateOne);
        AddChild(gateTwo);
        gateOne.Position = gateLocations[0];
        gateTwo.Position = gateLocations[1];


        gateOne.primaryMarker = markerOne;
        gateOne.secondaryMarker = markerTwo;
        gateOne.Name = "GateOne";

        gateTwo.primaryMarker = markerTwo;
        gateTwo.secondaryMarker = markerOne;
        gateTwo.Name = "GateTwo";

        gateOne.oppositeGate = gateTwo;
        gateTwo.oppositeGate = gateOne;

        //gateOne.ToggleActivatable(true);
        //gateTwo.ToggleActivatable(true);
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

    public async Task HandleLandingProcess()
    {
        gateOne.QueueFree();
        gateTwo.QueueFree();
        gateOne = null;
        gateTwo = null;

        airplane.IsLanding = true;
        Tween tween = CreateTween().SetParallel(false); // .SetTrans(Tween.TransitionType.Back).SetEase(Tween.EaseType.In);
        tween.TweenProperty(airplane, "position", landing_startPoint, tweenDuration_MoveToLandingStart);
        tween.TweenProperty(airplane, "position", landing_endPoint, tweenDuration_MoveToLandingEnd);
        tween.TweenProperty(airplane, "position", landed_midPoint, tweenDuration_MoveToLandedMidPoint);
        airplane.IsLanding = false;
        airplane.IsLanded = true;
        await ToSignal(GetTree().CreateTimer(refillDuration), SceneTreeTimer.SignalName.Timeout);
        RefillPlane(airplane);
        airplane.IsLanded = false;
        airplane.IsTakingOff = true;
        tween = CreateTween().SetParallel(false); // .SetTrans(Tween.TransitionType.Back).SetEase(Tween.EaseType.Out);
        tween.TweenProperty(airplane, "position", takingOff_startPoint, tweenDuration_MoveToTakingOffStart);
        tween.TweenProperty(airplane, "position", takingOff_endPoint, tweenDuration_MoveToTakingOffEnd);
        await ToSignal(GetTree().CreateTimer(tweenDuration_MoveToTakingOffStart + tweenDuration_MoveToTakingOffEnd), SceneTreeTimer.SignalName.Timeout);
        airplane.IsTakingOff = false;
    }

}
