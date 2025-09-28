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
    private Node3D defaultPlaneParent;

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

    [Export]
    private LandingPath landingPathOne;
    [Export]
    private LandingPath landingPathTwo;

    public Vector3 pathStartPoint;
    public Vector3 pathMidPoint;
    public Vector3 pathEndPoint;

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
        defaultPlaneParent = airplane.GetParent<Node3D>();

        gasOrb.BodyEntered += OnBodyEntered;
        ToggleGasOrb(doesExist: false);

        CallDeferred("Setup");
        // CallDeferred("SpawnGates");
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

    private void Setup()
    {
        SpawnGates();

        pathStartPoint = gateLocations[0];
        pathMidPoint = markerOne.Position.Lerp(markerTwo.Position, .5f);
        pathEndPoint = gateLocations[1];

        Vector3 pathStartOutVec = new Vector3(0, 0, 6);
        Vector3 pathMidInVec = new Vector3(0, 0, -15);
        Vector3 pathMidOutVec = new Vector3(0, 0, 6);
        Vector3 pathEndInVec = new Vector3(0, 0, -8);

        landingPathOne.SetupPath(pathStartPoint, Vector3.Zero, pathStartOutVec);
        landingPathOne.SetupPath(pathMidPoint, pathMidInVec, pathMidOutVec);
        landingPathOne.SetupPath(pathEndPoint, pathEndInVec, Vector3.Zero);

        landingPathTwo.SetupPath(pathEndPoint, Vector3.Zero, -pathStartOutVec);
        landingPathTwo.SetupPath(pathMidPoint, -pathMidInVec, -pathMidOutVec);
        landingPathTwo.SetupPath(pathStartPoint, -pathEndInVec, Vector3.Zero);
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

        // landingPathOne.Position = gateOne.Position;
        // landingPathTwo.Position = gateTwo.Position;
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

    public async Task HandleLandingProcess(GasRefillGate activatedGate)
    {
        GD.Print($"Beginning Landing Process");
        Vector3 startRotation = Vector3.Zero;

        // Remove Gates to prevent looping
        gateOne.QueueFree();
        gateTwo.QueueFree();
        gateOne = null;
        gateTwo = null;

        LandingPath currentPath = landingPathOne;
        if (activatedGate == gateTwo)
        {
            currentPath = landingPathTwo;
        }
        currentPath.pathFollow.Set("progress_ratio", 0);
        // If reversePath is true, reparent to landingPathTwo, else reparent to landingPathOne


        airplane.GlobalPosition = activatedGate.GlobalPosition;
        airplane.Reparent(currentPath.pathFollow);
        airplane.IsLanding = true;
        airplane.Rotation = startRotation;
        await ToSignal(GetTree(), SceneTree.SignalName.PhysicsFrame); // Wait for reparent, hopefully

        Tween tween = CreateTween().SetParallel(false); // .SetTrans(Tween.TransitionType.Expo).SetEase(Tween.EaseType.Out);
        tween.TweenProperty(currentPath.pathFollow, "progress_ratio", .5, tweenDuration_MoveToLandingEnd);
        await ToSignal(GetTree().CreateTimer(tweenDuration_MoveToLandingEnd), SceneTreeTimer.SignalName.Timeout);

        airplane.IsLanding = false;
        airplane.IsLanded = true;
        // await ToSignal(GetTree().CreateTimer(10), SceneTreeTimer.SignalName.Timeout);
        await ToSignal(GetTree().CreateTimer(refillDuration), SceneTreeTimer.SignalName.Timeout);
        RefillPlane(airplane);
        airplane.IsLanded = false;
        airplane.IsTakingOff = true;

        tween = CreateTween().SetParallel(false); // .SetTrans(Tween.TransitionType.Expo).SetEase(Tween.EaseType.Out);
        tween.TweenProperty(currentPath.pathFollow, "progress_ratio", 1, tweenDuration_MoveToTakingOffEnd);

        await ToSignal(GetTree().CreateTimer(tweenDuration_MoveToTakingOffEnd), SceneTreeTimer.SignalName.Timeout);

        await ToSignal(GetTree(), SceneTree.SignalName.PhysicsFrame); // Wait for reparent, hopefully
        airplane.Reparent(defaultPlaneParent);
        airplane.IsTakingOff = false;
    }

}
