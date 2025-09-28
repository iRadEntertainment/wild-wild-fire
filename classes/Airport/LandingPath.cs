using Godot;
using System;
using System.IO;

[GlobalClass]
public partial class LandingPath : Marker3D
{
    private Path3D path;
    public PathFollow3D pathFollow;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
        path = GetChild<Path3D>(0);
        pathFollow = path.GetChild<PathFollow3D>(0);
        path.Curve = new Curve3D();
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

    public void SetupPath(Vector3 pointLoc, Vector3 inVector, Vector3 outVector)
    {
        GD.Print($"LandingPath.cs: PointLoc:{pointLoc} InVector: {inVector} OutVector: {outVector}");
        path.Curve.AddPoint(pointLoc, inVector, outVector);
    }
}
