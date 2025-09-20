using Godot;
using System;

public partial class PlaneController : CharacterBody3D
{
	[Export]
	public float Speed = 5.0f;

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

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
		Vector2 inputDir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
