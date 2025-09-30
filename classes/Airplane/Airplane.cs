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

	[Signal] delegate void FuelWarningEventHandler();
	[Signal] delegate void WaterWarningEventHandler();
	[Signal] delegate void OutOfFuelEventHandler();
	[Signal] delegate void TakeOffEventHandler();
	[Signal] delegate void CollidedWithTerrainEventHandler();

	private Area3D AreaHitbox;
	private Node3D planeMesh;
	private RayCast3D raySea;
	private RayCast3D rayTerrain;
	public Marker3D MarkerBottom;
	private Marker3D MarkerWaterSpawnRight;
	private Marker3D MarkerWaterSpawnLeft;

	// Current state
	public float CurrentSpeed { get; set; } = 0.0f;
	public float CurrentPitch { get; set; } = 0.0f;
	public float CurrentRoll { get; set; } = 0.0f;
	public float CurrentThrust { get; set; } = 0.0f;
	public Vector2 CurrentDirection { get; set; } = Vector2.Zero;
	public bool CanInput { get; set; } = false;
	public bool IsParked { get; set; } = true;
	public bool IsBoosting { get; set; } = false;
	public bool IsOnWater { get; set; } = false;
	public bool IsRefillingWater { get; set; } = false;
	public bool IsTakingOff { get; set; } = false;
	public bool IsLanding { get; set; } = false;
	public bool IsLanded { get; set; } = false;
	public bool IsOutOfFuel { get; set; } = false;
	public float ElevFromSea { get; set; } = 0.0f;
	public float ElevFromTerrain { get; set; } = 0.0f;
	public bool HasFuelWarning { get; set; } = false;
	public bool HasWaterWarning { get; set; } = true;
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
	public bool ConsumeFuel = true;
	public bool ConsumeWater = true;

	// Target state
	private float _targetSpeed = 0.0f;
	private float _targetThrottle = 0.0f;
	private float _targetPitch = 0.0f;
	private float _targetRoll = 0.0f;

	public override void _Ready()
	{
		base._Ready();
		AreaHitbox = GetNode<Area3D>("%AreaHitbox");
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
		AreaHitbox.BodyEntered += OnBodyEntered;
	}


	private void OnBodyEntered(Node3D body)
	{
		EmitSignal(SignalName.CollidedWithTerrain);
	}

	public override void _Input(InputEvent @event)
	{
		if (!CanInput) { return; }
		base._Input(@event);
		if (@event.IsActionPressed("land"))
		{
			GD.Print("Landing pressed");
		}
	}

	public override void _Process(double delta)
	{
		if (!CanInput) { return; }
		if (Input.IsActionPressed("spray") && CurrentWater > 0.0f)
		{
			SprayWater(delta);
		}
	}

	private void SprayWater(double delta)
	{
		if (CurrentWater <= 0.0f && ConsumeWater)
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

		if (ConsumeWater)
		{
			CurrentWater = NextStepWater;
		}
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
		if (IsLanded || IsLanding || IsTakingOff) { return; }
		if (IsParked && CanInput)
		{
			IsParked = !Input.IsActionJustPressed("throttle_up");
			if (!IsParked) { EmitSignal(SignalName.TakeOff); }
			return;
		}

		ProcessNormalFlight(delta);
		if (ConsumeFuel) { ProcessFuelConsumption(delta); }
		CheckFuel(delta);
		CheckWater(delta);
		CheckWaterLevelRefill(delta);
		UpdatePlaneTransform(delta);
	}

	private void ProcessNormalFlight(double delta)
	{
		if (!CanInput) { return; }
		Vector2 inputDir = Input.GetVector("steer_left", "steer_right", "pitch_down", "pitch_up");
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

	private void CheckFuel(double delta)
	{
		if (CurrentFuel <= settings.MaxFuel * settings.FuelWarning && !HasFuelWarning)
		{
			HasFuelWarning = true;
			EmitSignal(SignalName.FuelWarning);
		}

		if (HasFuelWarning && CurrentFuel > settings.MaxFuel * settings.FuelWarning)
		{
			HasFuelWarning = false;
		}

		if (CurrentFuel <= 0.0f)
		{
			_targetPitch = -settings.MaxPitchAngle;
			_targetSpeed = settings.MinFlySpeed;
		}

	}


	private void UpdatePlaneTransform(double delta)
	{
		if (IsParked) { return; }
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
		if (CurrentFuel < 0.0f)
		{
			CurrentFuel = 0.0f;
			EmitSignal("OutOfFuel");
		}
		IsOutOfFuel = CurrentFuel == 0.0f;
	}

	private void CheckWater(double delta)
	{
		if (CurrentWater <= settings.MaxWater * settings.WaterWarning && !HasWaterWarning)
		{
			HasWaterWarning = true;
			EmitSignal(SignalName.WaterWarning);
		}

		if (HasWaterWarning && CurrentWater > settings.MaxWater * settings.WaterWarning)
		{
			HasWaterWarning = false;
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
			_targetSpeed = !IsOutOfFuel ? settings.MinFlySpeed : 0.0f;
		}
	}
}
