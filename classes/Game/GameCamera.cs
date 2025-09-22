using Godot;


[GlobalClass]
public partial class GameCamera : Camera3D
{
	private Node Mng;
	private Node3D Game => Mng.Get("game").As<Node3D>();
	private Node3D Map => Mng.Get("map").As<Node3D>();
	private Airplane Airplane => Mng.Get("airplane").As<Airplane>();
	private Airport Airport => Mng.Get("airport").As<Airport>();

	enum CamMode { FIXED, FOLLOW, BOTTOM, MAP, AIRPORT, FIRE };
	private CamMode camMode = CamMode.FOLLOW;
	[Export] private float smoothSpeed = 5.0f;
	private Vector2 fixedSway = new();
	private Vector2 followSway = new();


	public override void _Ready()
	{
		Mng = GetNode<Node>("/root/Mng");
	}


	public override void _Input(InputEvent inputEvent)
	{
		if (inputEvent is InputEventKey keyEvent && keyEvent.IsPressed())
		{
			switch (keyEvent.Keycode)
			{
				case Key.Key1: camMode = CamMode.FIXED; break;
				case Key.Key2: camMode = CamMode.FOLLOW; followSway = Vector2.Zero; break;
				case Key.Key3: camMode = CamMode.BOTTOM; break;
				case Key.Key4: camMode = CamMode.MAP; break;
				case Key.Key5: camMode = CamMode.AIRPORT; break;
				case Key.Key6: camMode = CamMode.FIRE; break;
			}
		}
		
	}


	public override void _Process(double delta)
	{
		// if (Level == null) return;
		switch (camMode)
		{
			case CamMode.FIXED: ProcessFixed(delta); break;
			case CamMode.FOLLOW: ProcessFollow(delta); break;
			case CamMode.BOTTOM: ProcessBottom(delta); break;
			case CamMode.MAP: ProcessMap(delta); break;
			case CamMode.AIRPORT: ProcessAirport(delta); break;
			case CamMode.FIRE: ProcessFire(delta); break;
		}
	}

	private readonly Vector3 fixedOffset = new(0.0f, 2.8f, 4.2f);
	private void ProcessFixed(double delta)
	{
		Vector3 finalPosition = Airplane.GlobalPosition + fixedOffset;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(Airplane.GlobalPosition);
	}
	private void ProcessFollow(double delta)
	{
		Vector3 offset = fixedOffset.Rotated(Vector3.Up, Airplane.GlobalRotation.Y);
		Vector3 finalPosition = Airplane.GlobalPosition + offset;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(Airplane.GlobalPosition);
	}
	private void ProcessBottom(double delta)
	{
		Transform3D target = Airplane.MarkerBottom.GlobalTransform;
		Quaternion currentRot = GlobalTransform.Basis.GetRotationQuaternion();
		Quaternion targetRot = target.Basis.GetRotationQuaternion();

		Quaternion newRot = currentRot.Slerp(targetRot, (float)(smoothSpeed * delta));
		Basis newBasis = new Basis(newRot);

		// Keep the current position, apply the new rotation
		GlobalTransform = new Transform3D(newBasis, target.Origin);
	}
	private void ProcessMap(double delta)
	{
		Vector3 finalPosition = Game.Get("MarkerMapCam").As<Marker3D>().GlobalPosition;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(Vector3.Zero); // Can be changed if we want to add panning and zoom
	}
	private void ProcessAirport(double delta)
	{
		Vector3 finalPosition = Airport.MarkerTower.GlobalPosition;
		GlobalPosition = Airport.MarkerTower.GlobalPosition;
		LookAt(Airplane.GlobalPosition);
	}

	private void ProcessFire(double delta)
	{
		Vector3 firePosition = Map.GlobalPosition; //to be replaced with the fire spawn
		Vector3 diffPosition = (Airplane.GlobalPosition - firePosition).Normalized() * 4.0f; // meters away from plane
		Vector3 finalPosition = Airplane.GlobalPosition + diffPosition;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(firePosition);
	}
}
