using System;
using System.Runtime.CompilerServices;
using Godot;


[GlobalClass]
public partial class Airplane : CharacterBody3D
{
	// Need to register input for Release_Water action
	// Need... Drift?
	// Longer Term: Need gas gauge to measure how long plane can remain flying (using speed boost impacts gas amount, so does holding more water?)
	// Longer Term: Water Gauge, to measure how much water can be dropped before needing to refill
	// Idea: Less water, faster speed due to lower weight
	// Idea: Less gas, faster speed due to lower weight
	[Export] public AirplaneSettings settings;

	[Signal] delegate void OutOfFuelEventHandler();

	private Node3D planeMesh;
	private RayCast3D raySea;
	private RayCast3D rayTerrain;
	public Marker3D MarkerBottom;
	public Marker3D MarkerWaterSpawnRight;
	public Marker3D MarkerWaterSpawnLeft;

	// Current state
	public float CurrentSpeed = 0.0f;
	public float CurrentPitch = 0.0f;
	public float CurrentRoll = 0.0f;
	public float CurrentThrust = 0.0f;
	public Vector2 CurrentDirection = Vector2.Zero;
	public bool IsParked = true;
	public bool IsBoosting = false;
	public bool IsOnWater = false;
	public bool IsRefillingWater = false;
	public bool IsTakingOff = false;
	public bool IsLanding = false;
	public bool IsLanded = false;
	public float ElevFromSea = 0.0f;
	public float ElevFromTerrain = 0.0f;
	private float _currentFuel = 0.0f;
	public float CurrentFuel
	{
		get => _currentFuel;
		set => _currentFuel = Mathf.Clamp(value, 0.0f, settings.MaxFuel);
	}
	private float _currentWater = 0.0f;
	public float CurrentWater
	{
		get => _currentWater;
		set => _currentWater = Mathf.Clamp(value, 0.0f, settings.MaxWater);
	}

	// Target state
	private float _targetSpeed = 0.0f;
	private float _targetThrottle = 0.0f;
	private float _targetPitch = 0.0f;
	private float _targetRoll = 0.0f;

	public override void _Ready()
	{
		base._Ready();
		planeMesh = GetNode<Node3D>("%AirplaneMesh");
		raySea = GetNode<RayCast3D>("%RaySea");
		rayTerrain = GetNode<RayCast3D>("%RayTerrain");
		MarkerBottom = GetNode<Marker3D>("%MarkerBottom");
		MarkerWaterSpawnLeft = GetNode<Marker3D>("%MarkerWaterSpawnLeft");
		MarkerWaterSpawnRight = GetNode<Marker3D>("%MarkerWaterSpawnRight");
		CurrentFuel = settings.MaxFuel;
		CurrentWater = settings.MaxWater;
		CurrentSpeed = 0.0f;
		CurrentThrust = 0.0f;
	}

	public override void _Input(InputEvent @event)
	{
		base._Input(@event);
		if (@event.IsActionPressed("land"))
		{
			CurrentFuel = 20f;
			GD.Print("Landing pressed");
		}
	}

	public override void _Process(double delta)
	{
		if (Input.IsActionPressed("spray") && CurrentWater > 0.0f)
		{
			SprayWater(delta);
		}
	}

	private void SprayWater(double delta)
	{
		if (CurrentWater <= 0.0f)
		{
			CurrentWater = 0.0f;
			return;
		}
		if (ElevFromSea < 1.0f) { return; }

		float waterConsumed = settings.WaterDropRate * (float)delta;
		float NextStepWater = CurrentWater - waterConsumed;
		int prevIterationWaterParticles = (int)Mathf.Floor(CurrentWater / settings.WaterParticleAmount);
		int nextIterationWaterParticles = (int)Mathf.Floor(NextStepWater / settings.WaterParticleAmount);

		// Spawn one particle every time the CurrentWater drops 5 units
		int particlesToSpawn = prevIterationWaterParticles - nextIterationWaterParticles;
		bool isLeftSpawn = nextIterationWaterParticles % 2 == 0;
		for (int i = 0; i < particlesToSpawn; i++)
		{
			SpawnWaterParticle(isLeftSpawn);
			isLeftSpawn = !isLeftSpawn;
		}
		CurrentWater = NextStepWater;
	}

	private void SpawnWaterParticle(bool isLeftSpawn)
	{
		RigidBody3D waterParticle = GD.Load<PackedScene>("res://instances/water_particle.tscn").Instantiate<RigidBody3D>();
		Marker3D marker = isLeftSpawn ? MarkerWaterSpawnLeft : MarkerWaterSpawnRight;
		waterParticle.GlobalTransform = marker.GlobalTransform;
		// waterParticle.LinearVelocity = Velocity;
		// waterParticle.LinearVelocity += -marker.Basis.Z * 2.0f;
		GetParent().AddChild(waterParticle);
	}

	public override void _PhysicsProcess(double delta)
	{
		GetElevations();
		if (IsLanded || IsLanding || IsTakingOff) {	return; }
		if (IsParked)
		{
			IsParked = !Input.IsActionJustPressed("throttle_up");
			return;
		}
		
		ProcessNormalFlight(delta);
		CheckWaterLevelRefill(delta);
		ProcessFuelConsumption(delta);
		CheckOutOfFuel(delta);
		UpdatePlaneTransform(delta);
	}

	private void ProcessNormalFlight(double delta)
	{
		Vector2 inputDir = Input.GetVector("steer_left", "steer_right", "pitch_up", "pitch_down");
		float thrustInput = Input.GetAxis("throttle_down", "throttle_up");
		IsBoosting = Input.IsActionPressed("boost");
		float boostMult = IsBoosting ? 1.0f : settings.BoostMultiplier;
		CurrentThrust += thrustInput * settings.ThrustAcceleration * boostMult * (float)delta;
		CurrentThrust = Mathf.Clamp(CurrentThrust, 0.0f, 1.0f);

		// Update target values based on input
		_targetRoll = -inputDir.X * settings.MaxRollAngle;
		_targetPitch = inputDir.Y * settings.MaxPitchAngle;
		if (ElevFromSea < settings.SeaStartPitchCorrection)
		{
			float _allowedPitch = Mathf.Lerp(0.0f, -settings.MaxPitchAngle, ElevFromSea / settings.SeaStartPitchCorrection);
			_targetPitch = Mathf.Max(_targetPitch, _allowedPitch);
		}
		_targetSpeed = Mathf.Lerp(
			settings.MinFlySpeed,
			IsRefillingWater ? settings.MinFlySpeed * 1.1f : settings.MaxSpeed,
			CurrentThrust
			);
	}

	private void CheckOutOfFuel(double delta)
	{
		if (CurrentFuel > 0.0f) { return; }
		
		_targetPitch = settings.MaxPitchAngle;
		_targetSpeed = settings.MinFlySpeed;
	}


	private void UpdatePlaneTransform(double delta)
{
	// Interpolate current values towards target values
	CurrentRoll = Mathf.Lerp(CurrentRoll, _targetRoll, settings.RollSpeed * (float)delta);
	CurrentPitch = Mathf.Lerp(CurrentPitch, _targetPitch, settings.PitchSpeed * (float)delta);
	CurrentSpeed = Mathf.Lerp(CurrentSpeed, _targetSpeed, settings.ThrustAcceleration * (float)delta);

	// Update mesh rotation (only pitch and roll)
	planeMesh.Rotation = new Vector3(CurrentPitch, 0, CurrentRoll);

	// Calculate turn rate based on roll angle and rotate the main node on Y axis
	float turnRate = CurrentRoll * settings.TurnSensitivity * (float)delta;
	RotateY(turnRate);


	// Get the forward direction and apply vertical offset
	Vector3 forward = -Transform.Basis.Z;
	Vector3 movement = forward * CurrentSpeed;

	float verticalMovement = CurrentPitch * settings.ClimbSensitivity;
	movement.Y += verticalMovement;

	Velocity = movement;
	MoveAndSlide();
	float directionAngle = -Transform.Basis.Z.AngleTo(Vector3.Forward);
	CurrentDirection = Vector2.FromAngle(directionAngle);
}

	private void GetElevations()
	{
		ElevFromSea = -1.0f;
		if (raySea.IsColliding())
		{
			ElevFromSea = raySea.GetCollisionPoint().DistanceTo(raySea.GlobalPosition);
		}
		ElevFromTerrain = -1.0f;
		if (rayTerrain.IsColliding())
		{
			ElevFromTerrain = rayTerrain.GetCollisionPoint().DistanceTo(rayTerrain.GlobalPosition);
		}
		IsOnWater = ElevFromSea < 0.1f;
	}

	private void ProcessFuelConsumption(double delta)
	{
		CurrentFuel -= settings.FuelConsumptionRate * CurrentSpeed * (float)delta;
		if (CurrentFuel <= 0.0f)
		{
			CurrentFuel = 0.0f;
			EmitSignal("OutOfFuel");
		}
	}

	private void CheckWaterLevelRefill(double delta)
	{
		IsRefillingWater = (CurrentWater < settings.MaxWater) && IsOnWater;
		if (IsRefillingWater)
		{
			CurrentWater += settings.RefillWaterRate * (float)delta;
		}
		if (IsOnWater)
		{
			_targetSpeed = settings.MinFlySpeed;
		}
	}
	private void ProcessLanding(double delta)
	{
		// TODO: Implement landing logic
		// The airport will have two Node3Ds (marker_land_front, marker_land_back)
		// If the plane enters an Area3D of the airport, it will check if it is aligned enough with the landing strip
		// If so it will land on the first of the two markers and reach a full stop at the other marker
		// opposite of the landing approach side.
	}

	private void ProcessTakeoff(double delta)
	{
		// TODO: Implement takeoff logic
	}
}
