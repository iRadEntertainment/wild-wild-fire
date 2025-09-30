using System.Text.RegularExpressions;
using Godot;


[GlobalClass]
public partial class GameCamera : Camera3D
{
	private Node Mng;
	private Node3D Game => Mng.Get("game").As<Node3D>();
	private Node3D Map => Mng.Get("map").As<Node3D>();
	private Airplane Airplane => Mng.Get("airplane").As<Airplane>();
	private Airport Airport => Mng.Get("airport").As<Airport>();
	private Marker3D MarkerMapCam => Game.Get("MarkerMapCam").As<Marker3D>();

	public enum CamModeType { FIXED, FOLLOW, BOTTOM, MAP, AIRPORT, FIRE, CINEMATIC };
	public CamModeType CamMode { get; set; } = CamModeType.FOLLOW;
	public Vector3 FirePosition { get; set; } = Vector3.Zero;
	[Export] private float smoothSpeed = 5.0f;
	[Export] private float mouseSensitivity = 0.005f;
	[Export] private float zoomSpeed = 1.0f;
	[Export] private float followSwaySensitivity = 0.003f;
	[Export] private Vector2 followSwayMax = new(0.8f, 0.5f);
	[Export] private float followSwayReturnSpeed = 1.2f;
	[Export] private float cinematicRotationRate = 0.35f;

	public Vector3 MapCenterTarget { get; set; } = Vector3.Zero;
	public Vector2 Mapsize { get; set; } = Vector2.One * 128.0f;
	private Node3D CinematicTarget;
	private float CinematicTargetDistance;
	private Vector2 _mapPanning = new();
	private Vector2 _fixedSway = new();
	private Vector2 _followSway = new();
	private float _ZoomRatio = 1.0f;



	public override void _Ready()
	{
		Mng = GetNode<Node>("/root/Mng");
	}


	public override void _Input(InputEvent inputEvent)
	{
		if (inputEvent.IsAction("cam_zoom_in") || inputEvent.IsAction("cam_zoom_out"))
		{
			if (Input.IsActionPressed("cam_zoom_in")) _ZoomRatio -= zoomSpeed;
			if (Input.IsActionPressed("cam_zoom_out")) _ZoomRatio += zoomSpeed;
			_ZoomRatio = Mathf.Clamp(_ZoomRatio, 0.2f, 4.0f);
		}

		if (CamMode == CamModeType.FIXED && inputEvent is InputEventMouseMotion mmFixed)
		{
			_fixedSway.X -= mmFixed.Relative.X * mouseSensitivity;
			_fixedSway.Y -= mmFixed.Relative.Y * mouseSensitivity;
			_fixedSway.Y = Mathf.Clamp(_fixedSway.Y, -1.35f, 1.35f); // ~±77°
		}

		if (CamMode == CamModeType.FOLLOW && inputEvent is InputEventMouseMotion mmFollow)
		{
			_followSway += new Vector2(-mmFollow.Relative.X, mmFollow.Relative.Y) * followSwaySensitivity * _ZoomRatio;
			_followSway = new Vector2(
				Mathf.Clamp(_followSway.X, -followSwayMax.X, followSwayMax.X),
				Mathf.Clamp(_followSway.Y, -followSwayMax.Y, followSwayMax.Y)
			);
		}
		if (CamMode == CamModeType.MAP && inputEvent is InputEventMouseMotion mmPan)
		{
			_mapPanning += (mmPan.Relative * 0.03f).Rotated(-MarkerMapCam.GlobalRotation.Y);
			_mapPanning = _mapPanning.Clamp(-Mapsize.X/2.0f, Mapsize.X/2.0f);
		}

	}


	public override void _Process(double delta)
	{
		switch (CamMode)
		{
			case CamModeType.FIXED: ProcessFixed(delta); break;
			case CamModeType.FOLLOW: ProcessFollow(delta); break;
			case CamModeType.BOTTOM: ProcessBottom(delta); break;
			case CamModeType.MAP: ProcessMap(delta); break;
			case CamModeType.AIRPORT: ProcessAirport(delta); break;
			case CamModeType.FIRE: ProcessFire(delta); break;
			case CamModeType.CINEMATIC: ProcessCinematic(delta); break;
		}
	}

	private readonly Vector3 fixedOffset = new(0.0f, 2.8f, 4.2f);
	private void ProcessFixed(double delta)
	{
		Vector3 baseOffset = fixedOffset * _ZoomRatio;
		Vector3 yawedOffset = baseOffset.Rotated(Vector3.Up, _fixedSway.X);
		Vector3 yawedRight = Vector3.Right.Rotated(Vector3.Up, _fixedSway.X);
		Vector3 rotatedOffset = yawedOffset.Rotated(yawedRight, _fixedSway.Y);

		Vector3 finalPosition = Airplane.GlobalPosition + rotatedOffset;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(Airplane.GlobalPosition);
	}
	private void ProcessFollow(double delta)
	{
		_followSway = _followSway.Lerp(Vector2.Zero, followSwayReturnSpeed * (float)delta);
		Vector3 offset = fixedOffset.Rotated(Vector3.Up, Airplane.GlobalRotation.Y) * _ZoomRatio;
		Vector3 right = Vector3.Right.Rotated(Vector3.Up, Airplane.GlobalRotation.Y);
		Vector3 swayOffset = right * _followSway.X + Vector3.Up * _followSway.Y;
		Vector3 finalPosition = Airplane.GlobalPosition + offset + swayOffset;
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

		GlobalTransform = new Transform3D(newBasis, target.Origin);
	}
	private void ProcessMap(double delta)
	{
		Vector3 _panOffset = new(_mapPanning.X, 0.0f, _mapPanning.Y);
		Vector3 finalPosition = MarkerMapCam.GlobalPosition;
		finalPosition *= _ZoomRatio / 4.0f;
		finalPosition += _panOffset;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(MapCenterTarget + _panOffset);
	}
	private void ProcessAirport(double delta)
	{
		Vector3 finalPosition = Airport.MarkerTower.GlobalPosition;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(Airplane.GlobalPosition);
	}

	private void ProcessFire(double delta)
	{
		Vector3 diffPosition = (Airplane.GlobalPosition - FirePosition).Normalized() * 4.0f * _ZoomRatio; // meters away from plane
		Vector3 finalPosition = Airplane.GlobalPosition + diffPosition;
		GlobalPosition = GlobalPosition.Lerp(finalPosition, smoothSpeed * (float)delta);
		LookAt(FirePosition);
	}

	private float _cinematicRotation = 0.0f;
	private void ProcessCinematic(double delta)
	{
		_cinematicRotation += (float)delta * cinematicRotationRate;
		Transform3D finalTransform = new();

		finalTransform.Origin = (fixedOffset.Normalized() * CinematicTargetDistance * _ZoomRatio).Rotated(Vector3.Up, _cinematicRotation);
		finalTransform = finalTransform.LookingAt(Vector3.Zero);

		if (CinematicTarget != null)
		{
			finalTransform.Origin += CinematicTarget.GlobalPosition;
			finalTransform = finalTransform.LookingAt(CinematicTarget.GlobalPosition);
		}
		GlobalPosition = GlobalPosition.Lerp(finalTransform.Origin, smoothSpeed * (float)delta);
		Quaternion = finalTransform.Basis.GetRotationQuaternion();
	}


	public void SetCamera(int type)
	{
		switch (type)
		{
			case 0: CamMode = CamModeType.FIXED; break;
			case 1: CamMode = CamModeType.FOLLOW; break;
			case 2: CamMode = CamModeType.BOTTOM; break;
			case 3: CamMode = CamModeType.MAP; break;
			case 4: CamMode = CamModeType.AIRPORT; break;
			case 5: CamMode = CamModeType.FIRE; break;
			case 6: CamMode = CamModeType.CINEMATIC; break;
		}
	}

	public void SetCameraCinematic(Node3D target, float camDistance = 10.0f)
	{
		if (target == null) { return; };
		_cinematicRotation = 0.0f;
		CinematicTarget = target;
		CinematicTargetDistance = camDistance;
		// CamMode = CamModeType.CINEMATIC;
	}

}
