using Godot;
using System;

public partial class PlaneController : CharacterBody3D
{
	[Export]
	public float Speed = 5.0f;
    [Export]
    private float turnSpeed = .1f;
    [Export]
    private Node3D planeMesh;
    [Export]
    private float frictionalOffset = .5f;

	[Signal]
	public delegate void PlaneSpawnedEventHandler(Node3D plane);

    public override void _Ready()
    {
        base._Ready();
		EmitSignal(SignalName.PlaneSpawned);
        Velocity = new Vector3(0, 0, -Speed);
    }


	public override void _PhysicsProcess(double delta)
	{
        // Need forward velocity at a constant rate
        // Need to rotate in correct direction when pressing left or right
        // Need to start a speed boost when holding boost action
        // Need to register input for Release_Water action
        // Need... Drift?
        // Longer Term: Need gas gauge to measure how long plane can remain flying (using speed boost impacts gas amount, so does holding more water?)
        // Longer Term: Water Gauge, to measure how much water can be dropped before needing to refill
        // Idea: Less water, faster speed due to lower weight
        // Idea: Less gas, faster speed due to lower weight

        // Get the input direction and handle the movement/deceleration.
        // As good practice, you should replace UI actions with custom gameplay actions.
        

        Vector3 velocity = Velocity;
        Vector3 rotation = planeMesh.Rotation;
        
        // velocity.Z = -Speed; // inputDir.Y * Speed;

        // Get the input direction and handle the movement/deceleration.
        // As good practice, you should replace UI actions with custom gameplay actions.
        Vector2 inputDir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
        Quaternion rot = Quaternion.FromEuler(new Vector3(0, -inputDir.X * turnSpeed, 0));
        Quaternion result = Quaternion.FromEuler(planeMesh.Rotation) * rot;
        planeMesh.Quaternion = result;

        Vector3 forward = planeMesh.Transform.Basis * new Vector3(0, 0, -1);
        velocity = forward * Speed; 

        Velocity = velocity;
		MoveAndSlide();


        // DebugDraw3D.DrawArrowRay(origin: GlobalPosition, direction: velocity, length: 10, color: Colors.Red, arrow_size: .5f, is_absolute_size: true, duration: 10);
        DebugDrawManager.ClearAll();
        // mainCamera.MoveCamera(velocity);
    }
}
