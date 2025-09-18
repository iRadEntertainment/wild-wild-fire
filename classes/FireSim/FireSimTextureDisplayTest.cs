using Godot;
using System;


[GlobalClass]
public partial class FireSimTextureDisplayTest : TextureRect
{
    [Export]
    private FireSimulation fireCells;
    [Export]
    private bool runTexturedMap = true;

    [ExportGroup("Universal Values")]
    [Export]
    private Vector2I startingPos;
    [Export]
    private int preSimSteps = 100;

    [ExportGroup("Random Map Values")]
    [Export]
    private Vector2I mapSize = new Vector2I(256, 256);

    [ExportGroup("Textured Map Values")]
    [Export]
    private Texture2D burnableMap;
    [Export]
    private Texture2D externalMoistureMap;
    [Export]
    private Texture2D internalMoistureMap;


    private int ticksPassed = 0;


    public override void _Ready()
    {
        CallDeferred("StartFire");
    }

    public void StartFire()
    {
        if (runTexturedMap)
        {
            fireCells.InitTexturedMap(burnableMap, internalMoistureMap, externalMoistureMap, startingPos, preSimSteps);
        }
        else 
        {
            fireCells.InitRandomMap(mapSize, startingPos, preSimSteps);
        }
        
        Texture = fireCells.OutputTexture;
    }
}
