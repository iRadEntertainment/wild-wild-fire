using Godot;
using System;

[GlobalClass]
public partial class Airport : Node3D
{
    public Marker3D MarkerTower;

    public override void _Ready()
    {
        base._Ready();
        MarkerTower = GetNode<Marker3D>("%MarkerTower");
    }

}
