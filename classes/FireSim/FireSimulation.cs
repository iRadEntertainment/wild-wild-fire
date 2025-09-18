using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;

//This script is a bit hard to read (especially in the mathy sections) due to performance optimizations...


/// <summary>
/// Manages the siumulation of a fire spreading.
/// </summary>
[GlobalClass]
public partial class FireSimulation : Node
{
    [Export]
    public Vector2 windDirection = new Vector2I(0, 0);


    //TODO: Give these Sim Settings and Rule values hint strings - Big_The


    [ExportGroup("Sim Settings")]
    [Export]
    public float simSpeed = 200.0f;
    private float StepMultipler => 0.016f * simSpeed;
    [Export]
    private Vector2I threadGroups = new Vector2I(4, 4);
    [Export]
    private bool enableDebugLogging = false;

    #region Rule Settings
    [ExportGroup("Heat Spread Rule")]
    [Export]
    private float burnThresholdToSpreadHeat = 0.1f;
    [Export]
    private float neighborHeatIncreasePerTick = 0.1f;
    [Export]
    private float highInternalMoistureHeatSpreadMultiplier = 0.1f;
    [Export]
    private float downWindHeatSpreadBias = 1.5f;
    [Export]
    private float upWindHeatSpreadBias = 0.74f;

    [ExportGroup("Burn Rule")]
    [Export]
    private float heatForBurn = 0.8f;
    [Export]
    private float burnPerTick = 0.005f;
    [Export]
    private float selfHeatPerTick = 0.05f;
    [Export]
    private float lowInternalMoistureBurnMultiplier = 2.0f;
    [Export]
    private float internalMoistureLossDurringBurn = 0.1f;

    [ExportGroup("Heat Disipation")]
    [Export]
    private float heatDispationPerTick = 0.0025f;

    [ExportGroup("ExternalMoisture")]
    [Export]
    private float sMoistureSpentPerTickCooling = 0.006f;
    [Export]
    private float sMoistureEvapPerTick = 0.00003f;
    #endregion



    private Vector2I gridSize;
    private Vector2I startingCell;

    /// <summary>
    /// Defines all the values a single cell can have
    /// </summary>
    public struct FireCell
    {
        public int x, y;
        public float heat;
        public float burntness;
        public float internalMoisture; //Twigs 0 - Leafy 1
        public float surfaceMoisture;
        public bool burnable;
    }


    // Two sets are used to keep the starting and final state seperate durring a sim tick
    private bool activeInASet = true;
    private FireCell[,] fireCellsASet;
    private FireCell[,] fireCellsBSet;

    // The A and B set are swapped around on these vars for easier use durring the sim tick
    private FireCell[,] startingCellState;
    private FireCell[,] finalCellState;


    // Updated every phys frame the sim runs
    private Image workingImage;
    public ImageTexture OutputTexture { get; private set; }

    // if false the sim has not been initialized correctly or at all
    private bool simValid = false;


    /// <summary>
    /// Initializes a sim with the specifed starting values
    /// </summary>
    /// <param name="isBurnableMap">Maps where the burnable areas are. Any value over 0.5 will be considered burnable.</param>
    /// <param name="internalMoistureMap">Maps where the plants have a high internal moisture.</param>
    /// <param name="externalMoistureMap">Maps where the plants are externaly wet, like after getting water dropped on them.</param>
    /// <param name="startingCell">The center of where the fire starts</param>
    /// <param name="preSimTickCount">The sim will run this number of ticks imediately</param>
    public void InitTexturedMap(Texture2D isBurnableMap, Texture2D internalMoistureMap, Texture2D externalMoistureMap, Vector2I startingCell, int preSimTickCount = 100)
    {
        Image burnableImage = isBurnableMap.GetImage();
        Image internalMoistureImage = internalMoistureMap.GetImage();
        Image externalMoistureImage = externalMoistureMap.GetImage();

        Vector2I gridSize = burnableImage.GetSize();
        if (internalMoistureImage.GetSize() != gridSize || externalMoistureImage.GetSize() != gridSize)
        {
            GD.PrintErr("Input map sizes do not match. Please make sure they are all the same size.");
            return;
        }
        startingCell = startingCell.Clamp(Vector2I.Zero, gridSize);

        this.gridSize = gridSize;
        this.startingCell = startingCell;

        InitGridAndTexture();

        for (int x = 0; x < gridSize.X; x++)
        {
            for (int y = 0; y < gridSize.Y; y++)
            {
                FireCell cell = new FireCell()
                {
                    x = x,
                    y = y,
                    heat = 0,
                    burntness = 0,
                    internalMoisture = internalMoistureImage.GetPixel(y, x).Luminance,
                    surfaceMoisture = externalMoistureImage.GetPixel(y, x).Luminance,
                    burnable = burnableImage.GetPixel(y, x).Luminance > 0.5f,
                };
                fireCellsASet[x, y] = cell;
            }
        }
        InitFireStartCells();

        UpdateTexture();
        CloneASetToBSet();
        simValid = true;
        RunPreSim(preSimTickCount);
    }

    /// <summary>
    /// Generates a random grid of the specifed size. There is no guarantee that the fire can/will spread on this map
    /// </summary>
    /// <param name="gridSize">The size of the grid to generate</param>
    /// <param name="startingCell">The center of where the fire starts</param>
    /// <param name="preSimTickCount">The sim will run this number of ticks imediately</param>
    public void InitRandomMap(Vector2I gridSize, Vector2I startingCell, int preSimTickCount = 100)
    {
        this.gridSize = gridSize;
        this.startingCell = startingCell;

        InitGridAndTexture();

        var burnableNoise = new FastNoiseLite();
        burnableNoise.Seed = (DateTime.Now + new TimeSpan(0, 0, 10)).GetHashCode();

        var moistNoise = new FastNoiseLite();
        moistNoise.Seed = (DateTime.Now + new TimeSpan(0, 0, 5)).GetHashCode();
        //moistNoise.Seed = 4;

        var noise = new FastNoiseLite();
        noise.Seed = DateTime.Now.GetHashCode();
        //noise.Seed = 1;

        for (int x = 0; x < gridSize.X; x++)
        {
            for (int y = 0; y < gridSize.Y; y++)
            {

                FireCell cell = new FireCell()
                {
                    x = x,
                    y = y,
                    heat = 0,
                    burntness = 0,
                    internalMoisture = 1 - Mathf.Clamp((int)(Mathf.Abs(noise.GetNoise2D(x, y)) * 5), 0, 1) * 0.9f,
                    surfaceMoisture = ((moistNoise.GetNoise2D(x, y) + 1) / 2) > 0.5 ? 1f : 0,
                    burnable = noise.GetNoise2D(x, y) > -0.14f
                };
                fireCellsASet[x, y] = cell;
            }
        }

        InitFireStartCells();
        UpdateTexture();
        CloneASetToBSet();
        simValid = true;
        RunPreSim(preSimTickCount);
    }

    private void InitFireStartCells()
    {
        FireCell startingFire = new FireCell() { heat = 1, burntness = 0, internalMoisture = 0.5f, surfaceMoisture = 0, burnable = true };
        SetCellValue(fireCellsASet, startingCell.X, startingCell.Y, ref startingFire);

        SetCellValue(fireCellsASet, startingCell.X + 1, startingCell.Y, ref startingFire);
        SetCellValue(fireCellsASet, startingCell.X - 1, startingCell.Y, ref startingFire);
        SetCellValue(fireCellsASet, startingCell.X, startingCell.Y + 1, ref startingFire);
        SetCellValue(fireCellsASet, startingCell.X, startingCell.Y - 1, ref startingFire);
    }

    private void CloneASetToBSet()
    {
        for (int x = 0; x < gridSize.X; x++)
        {
            for (int y = 0; y < gridSize.Y; y++)
            {
                fireCellsBSet[x, y] = fireCellsASet[x, y];
            }
        }
    }

    private void RunPreSim(int preSimCount)
    {
        if (!simValid) { return; }
        for (int i = 0; i < preSimCount; i++)
        {
            RunSimTick();
        }
    }

    private void InitGridAndTexture()
    {
        //I'm going to use the dispose as that's the normal csharp process.
        if (OutputTexture != null)
        {
            OutputTexture.Dispose();
            OutputTexture = null;
        }
        if (workingImage != null)
        {
            workingImage.Dispose();
            workingImage = null;
        }

        workingImage = Image.CreateEmpty(gridSize.X, gridSize.Y, false, Image.Format.Rgba8);
        OutputTexture = ImageTexture.CreateFromImage(workingImage);

        fireCellsASet = new FireCell[gridSize.X, gridSize.Y];
        fireCellsBSet = new FireCell[gridSize.X, gridSize.Y];

        finalCellState = fireCellsASet;
        startingCellState = fireCellsBSet;

        activeInASet = true;
    }

    #region Main Loop Methods
    public override void _PhysicsProcess(double delta)
    {
        if (!simValid) { return; }
        RunSimTick();
        UpdateTexture();
    }

    /// <summary>
    /// Runs a full sim on the grid
    /// </summary>
    private void RunSimTick()
    {
        Stopwatch sw = new Stopwatch();
        if (enableDebugLogging)
        {
            sw.Start();
        }

        if (activeInASet)
        {
            startingCellState = fireCellsASet;
            finalCellState = fireCellsBSet;
        }
        else
        {
            startingCellState = fireCellsBSet;
            finalCellState = fireCellsASet;
        }
        activeInASet = !activeInASet;


        List<Task> tasks = new List<Task>();
        Vector2I taskSize = new Vector2I(gridSize.X / threadGroups.X, gridSize.Y / threadGroups.Y);
        for (int segmentX = 0; segmentX < threadGroups.X; segmentX++)
        {
            for (int segmentY = 0; segmentY < threadGroups.Y; segmentY++)
            {
                int segX = segmentX;
                int segY = segmentY;
                tasks.Add(Task.Run(() =>
                {
                    UpdateCellGroup(segX * taskSize.X, segX * taskSize.X + taskSize.X,
                        segY * taskSize.Y, segY * taskSize.Y + taskSize.Y);
                }));
            }
        }

        foreach (Task task in tasks)
        {
            task.Wait();
        }

        if (enableDebugLogging)
        {
            GD.Print();
            GD.Print("Finished Sim Tick:");
            GD.Print($"Worker Thread Count: {tasks.Count}");
            GD.Print("Sim tick alone:" + sw.Elapsed.TotalMilliseconds + "ms");
            sw.Stop();
        }
    }


    /// <summary>
    /// Updates the group of cells specified
    /// </summary>
    /// <param name="startX"></param>
    /// <param name="endX"></param>
    /// <param name="startY"></param>
    /// <param name="endY"></param>
    private void UpdateCellGroup(int startX, int endX, int startY, int endY)
    {
        for (int x = startX; x < endX; x++)
        {
            for (int y = startY; y < endY; y++)
            {
                UpdateCell(x, y);
            }
        }
    }

    /// <summary>
    /// Updates a single cell
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    private void UpdateCell(int x, int y)
    {
        FireCell curCell = startingCellState[x, y];
        if (!curCell.burnable) { return; }
        //curCell.heat += 0.01f * StepMultipler;

        FireCell[] neighbors =
        {
            GetCellValue(startingCellState, x, y + 1),
            GetCellValue(startingCellState, x, y - 1),
            GetCellValue(startingCellState, x + 1, y),
            GetCellValue(startingCellState, x - 1, y),

            GetCellValue(startingCellState, x + 1, y + 1),
            GetCellValue(startingCellState, x - 1, y - 1),
            GetCellValue(startingCellState, x + 1, y - 1 ),
            GetCellValue(startingCellState, x - 1, y + 1),
        };

        //Surface Moisture Evap
        curCell.surfaceMoisture -= sMoistureEvapPerTick * StepMultipler;

        //sMoistureCooling
        if (curCell.heat > 0 && curCell.surfaceMoisture > 0)
        {
            curCell.heat = 0;
            curCell.surfaceMoisture -= sMoistureSpentPerTickCooling * StepMultipler;
        }

        //heat spread
        //float internalMoistureHeatSpreadMult = Mathf.Lerp(1, highInternalMoistureHeatSpreadMultiplier, curCell.internalMoisture);
        float internalMoistureHeatSpreadMult = 1 + (highInternalMoistureHeatSpreadMultiplier - 1) * curCell.internalMoisture;
        for (int i = 0; i < neighbors.Length; i++)
        {
            Vector2 cellDir = new Vector2(neighbors[i].x - curCell.x, neighbors[i].y - curCell.y);
            float windDirVsNeigborDir = windDirection.X * cellDir.X + windDirection.Y * cellDir.Y;//Dot product

            //float finalWindBias = Mathf.Remap(windDirVsNeigborDir, -1, 1, upWindHeatSpreadBias, downWindHeatSpreadBias);
            float finalWindBias = (downWindHeatSpreadBias + (upWindHeatSpreadBias - downWindHeatSpreadBias) * ((windDirVsNeigborDir + 1) / 2));

            if (neighbors[i].burntness > burnThresholdToSpreadHeat && neighbors[i].burntness < 1)
            {
                curCell.heat += neighborHeatIncreasePerTick * internalMoistureHeatSpreadMult * finalWindBias * StepMultipler;
            }
        }

        //burn
        if (curCell.heat > heatForBurn && curCell.burntness < 1)
        {
            //float internalMoistureMult = Mathf.Lerp(1, lowInternalMoistureBurnMultiplier, 1 - curCell.internalMoisture);
            float internalMoistureMult = 1 + (lowInternalMoistureBurnMultiplier - 1) * (1 - curCell.internalMoisture);
            curCell.heat += selfHeatPerTick * internalMoistureMult * StepMultipler;
            curCell.burntness += burnPerTick * internalMoistureMult * StepMultipler;
            curCell.internalMoisture -= internalMoistureLossDurringBurn * StepMultipler;
        }

        //heat disipation
        curCell.heat -= heatDispationPerTick * StepMultipler;



        curCell.heat = Mathf.Clamp(curCell.heat, 0, 1);
        curCell.burntness = Mathf.Clamp(curCell.burntness, 0, 1);
        curCell.internalMoisture = Mathf.Clamp(curCell.internalMoisture, 0, 1);
        curCell.surfaceMoisture = Mathf.Clamp(curCell.surfaceMoisture, 0, 1);

        finalCellState[x, y] = curCell;
    }

    /// <summary>
    /// Updates the texture on the GPU with the newest sim data
    /// </summary>
    /// <param name="cellGrid"></param>
    private void UpdateTexture()
    {
        Stopwatch sw = new Stopwatch();
        if (enableDebugLogging)
        {
            sw.Start();
        }

        //Update colors in byte buffer
        byte[] dataBuffer = workingImage.GetData();
        int bufferIndex = 0;
        for (int x = 0; x < gridSize.X; x++)
        {
            for (int y = 0; y < gridSize.Y; y++)
            {

                if (finalCellState[x, y].burnable)
                {
                    dataBuffer[bufferIndex] = (byte)(finalCellState[x, y].heat * 255);
                    dataBuffer[bufferIndex + 1] = (byte)(finalCellState[x, y].internalMoisture * 255);
                    dataBuffer[bufferIndex + 2] = (byte)(finalCellState[x, y].surfaceMoisture * 255);
                    dataBuffer[bufferIndex + 3] = (byte)((1 - finalCellState[x, y].burntness) * 255);
                }
                else
                {
                    //Non burnables are transparent black
                    dataBuffer[bufferIndex] = 0;
                    dataBuffer[bufferIndex + 1] = 0;
                    dataBuffer[bufferIndex + 2] = 0;
                    dataBuffer[bufferIndex + 3] = 0;
                }
                bufferIndex += 4;
            }
        }


        //Upload to the GPU all at once
        workingImage.SetData(gridSize.X, gridSize.Y, false, Image.Format.Rgba8, dataBuffer);

        if (enableDebugLogging) { GD.Print($"Image Update:{sw.ElapsedMilliseconds}ms"); }

        OutputTexture.Update(workingImage);

        if (enableDebugLogging)
        {
            sw.Stop();
            GD.Print($"Texture Update:{sw.ElapsedMilliseconds}ms");
        }
    }

    #endregion

    private ref FireCell GetCellValue(FireCell[,] cells, int x, int y)
    {
        x = Mathf.Clamp(x, 0, cells.GetLength(0) - 1);
        y = Mathf.Clamp(y, 0, cells.GetLength(1) - 1);

        return ref cells[x, y];
    }

    private void SetCellValue(FireCell[,] cells, int x, int y, ref FireCell setTo)
    {

        if (x < 0 || x >= cells.GetLength(0) || y < 0 || y >= cells.GetLength(1))
        {
            return;
        }
        setTo.x = x;
        setTo.y = y;
        cells[x, y] = setTo;
    }

    #region Simplified interactions for gameplay

    /// <summary>
    /// Adds external moisture to the simulation within the area specified. Use this method to simulate dropping water on the forest.
    /// </summary>
    /// <param name="center"></param>
    /// <param name="radius"></param>
    /// <param name="waterIntensity"></param>
    public void SpreadMoistureOnRadius(Vector2I center, int radius, float waterIntensity)
    {
        //TODO: This method - Big_The
    }

    //Any others?

    #endregion
}
