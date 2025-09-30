using Godot;


[GlobalClass]
public partial class AirplaneSettings : Resource
{
    [ExportSubgroup("Tanks")]
    [Export(PropertyHint.Range, "0.0, 200.0, 1.0")] public float MaxWater { get; set; } = 100.0f;
    [Export(PropertyHint.Range, "0.0, 200.0, 1.0")] public float MaxFuel { get; set; } = 100.0f;
    [Export(PropertyHint.Range, "0.0, 40.0, 1.0")] public float RefillFuelRate { get; set; } = 20.0f;
    [Export(PropertyHint.Range, "0.0, 5.0, 0.01")] public float FuelConsumptionRate { get; set; } = 1.0f;
    [Export(PropertyHint.Range, "10.0, 200.0, 1.0")] public float RefillWaterRate { get; set; } = 50.0f;
    [Export(PropertyHint.Range, "0.0, 40.0, 0.1")] public float WaterDropRate { get; set; } = 20.0f;
    [Export(PropertyHint.Range, "0.0, 10.0, 1.0")] public float WaterParticleAmount { get; set; } = 5.0f;
    [Export(PropertyHint.Range, "0.0, 1.0, 0.01")] public float FuelWarning { get; set; } = 0.15f;
    [Export(PropertyHint.Range, "0.0, 1.0, 0.01")] public float WaterWarning { get; set; } = 0.1f;


    [ExportSubgroup("Handling")]
    [Export(PropertyHint.Range, "1.0, 5.0, 0.01")] public float BoostMultiplier { get; set; } = 1.5f;
    [Export(PropertyHint.Range, "10.0, 50.0, 1.0")] public float MaxElevation { get; set; } = 30.0f;
    [Export(PropertyHint.Range, "0.1, 10.0, 0.01")] public float MaxSpeed { get; set; } = 5.0f;
    [Export(PropertyHint.Range, "0.1, 10.0, 0.01")] public float MinFlySpeed { get; set; } = 2.0f;
    [Export(PropertyHint.Range, "0.1, 3.0, 0.01")] public float ThrustAcceleration { get; set; } = 1.3f;
    [Export(PropertyHint.Range, "0.0, 2.0, 0.01")] public float RollSpeed { get; set; } = 1.2f;
    [Export(PropertyHint.Range, "0.0, 1.57, 0.01")] public float MaxRollAngle { get; set; } = 0.5236f;
    [Export(PropertyHint.Range, "0.0, 2.0, 0.01")] public float PitchSpeed { get; set; } = 1.2f;
    [Export(PropertyHint.Range, "0.0, 1.57, 0.01")] public float MaxPitchAngle { get; set; } = 0.5236f;
    [Export(PropertyHint.Range, "1.0, 6.0, 0.01")] public float TurnSensitivity { get; set; } = 2.5f;
    [Export(PropertyHint.Range, "1.0, 6.0, 0.01")] public float ClimbSensitivity { get; set; } =3.5f;
    [Export(PropertyHint.Range, "0.0, 2.0, 0.01")] public float SeaStartPitchCorrection { get; set; } = 0.5f;
}