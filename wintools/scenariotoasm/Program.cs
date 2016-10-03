using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using wintools.tech;

namespace scenariotoasm
{
    class Program
    {
        static int Main(string[] argsRaw)
        {
            if (argsRaw.Length < 2
               || argsRaw[1].ToLower().Contains("help")
               || argsRaw[1].ToLower().Contains("?"))
            {
                Console.WriteLine(
@"scenariotoasm [-o output.asm] [-defpng blockdefs.png] [-defcsv blockdefs.csv][-s scenario.png / scenarios dir]
(optional)[-defdefault 00 05 00] default block def to use when failing to parse (grass is 00 05 00)

scenariotoasm [-o output.csv] [-defpng blockdefs.png] [-defcsv blockdefs.csv][-s scenario.png / scenarios dir]
(optional)[-defdefault 00 05 00] default block def to use when failing to parse (grass is 00 05 00)
");
                return 1;
            }

            var args = ParseArgs(argsRaw);

            var outputPath = args.GetPath("-o", true);
            var defpngPath = args.GetPath("-defpng", true);
            var defcsvPath = args.GetPath("-defcsv", true);
            var scenarioArg = args.GetPath("-s", true);
            var defDefault = args.ContainsKey("-defdefault") ? args["-defdefault"] : null;

            if (!string.IsNullOrWhiteSpace(defDefault))
                VerifyHexValues("-defdefault", defDefault);

            var hexDefs = GetTileHexDefs(defcsvPath);
            var tileDefs = GetTilePixelDefs(defpngPath, hexDefs);

            var outputExtension = Path.GetExtension(outputPath);
            var writer = new StreamWriter(outputPath);

            foreach(var scenario in GetScenarioPaths(scenarioArg))
            {
                var scenarioVals = GetScenarioValues(scenario, tileDefs, defDefault);
                switch (outputExtension)
                {
                    case ".asm":
                        WriteScenarToAsm(writer, scenario, scenarioVals);
                        break;
                    case ".csv":
                        WriteScenarToCsv(writer, scenario, scenarioVals);
                        break;
                    default:
                        throw new NotImplementedException(outputExtension + " not supported");
                }
            }

            writer.Close();

            Console.WriteLine(outputPath);

            return 0;
        }

        static string[] GetScenarioPaths(string scenarioPath)
        {
            if (Directory.Exists(scenarioPath))
                return Directory.GetFiles(scenarioPath, "*.png");
            else if (File.Exists(scenarioPath))
                return new[] { scenarioPath };
            else
                throw new Exception("scenario " + scenarioPath + " not found!");
        }

        static void WriteScenarToCsv(StreamWriter writer, string scenarioPath, string[,] scenarioVals)
        {
            for (int yBlock = 0; yBlock < Scenario.Height; yBlock++)
            {
                var row = new string[Scenario.Width];
                for (int xBlock = 0; xBlock < Scenario.Width; xBlock++)
                    row[xBlock] = scenarioVals[xBlock, yBlock];
                writer.WriteLineUnix(string.Join(",", row));
            }
        }

        static void WriteScenarToAsm(StreamWriter writer, string scenarioPath, string[,] scenarioVals)
        {
            var scenarioName = Path.GetFileNameWithoutExtension(scenarioPath);

            writer.WriteLineUnix("Scenario" + scenarioName + ":");

            for (int yBlock = 0; yBlock < Scenario.Height; yBlock++)
            {
                for (int xBlock = 0; xBlock < Scenario.Width; xBlock++)
                {
                    var hexVals = scenarioVals[xBlock, yBlock].Split(' ');
                    if (hexVals.Length != 3)
                        throw new Exception("Invalid hex vals " + scenarioVals[xBlock, yBlock]);
                    writer.WriteLineUnix(string.Format("\tdb ${0}, ${1}, ${2}", hexVals[0], hexVals[1], hexVals[2]));
                }
            }
            writer.WriteLineUnix("");
        }

        static string[,] GetScenarioValues(string scenarioPath, Dictionary<BlockPixels, string> tileDefs, string defaultDef)
        {
            var scenarioVals = new string[Scenario.Width, Scenario.Height];

            var image = Image.FromFile(scenarioPath) as Bitmap;
            for (int yBlock = 0; yBlock < Scenario.Height; yBlock++)
            {
                for (int xBlock = 0; xBlock < Scenario.Width; xBlock++)
                {
                    var blockPixels = new BlockPixels();

                    for (int y = 0; y < BlockPixels.Height; y++)
                    {
                        for (int x = 0; x < BlockPixels.Width; x++)
                        {
                            blockPixels[x, y] = image.GetPixelSolid((xBlock * BlockPixels.Width) + x, (yBlock * BlockPixels.Height) + y);
                        }
                    }
                    if (tileDefs.ContainsKey(blockPixels))
                        scenarioVals[xBlock, yBlock] = tileDefs[blockPixels];
                    else if (!string.IsNullOrWhiteSpace(defaultDef))
                        scenarioVals[xBlock, yBlock] = defaultDef;
                    else
                        throw new Exception("no default def to use for unrecognised block " + xBlock + ", " + yBlock);
                }
            }
            return scenarioVals;
        }


        static Dictionary<BlockPixels, string> GetTilePixelDefs(string pngPath, List<string[]> hexDefs)
        {
            var tileDefs = new Dictionary<BlockPixels, string>();

            var image = Image.FromFile(pngPath) as Bitmap;
            for (int yBlock = 0; yBlock < hexDefs.Count; yBlock++)
            {
                for (int xBlock = 0; xBlock < hexDefs[yBlock].Length; xBlock++)
                {
                    var blockPixels = new BlockPixels();
                    var blockHexVals = hexDefs[yBlock][xBlock];

                    for (int y = 0; y < BlockPixels.Height; y++)
                    {
                        for (int x = 0; x < BlockPixels.Width; x++)
                        {
                            blockPixels[x, y] = image.GetPixelSolid((xBlock * BlockPixels.Width) + x, (yBlock * BlockPixels.Height) + y);
                        }
                    }
                    if (tileDefs.ContainsKey(blockPixels))
                        throw new Exception("pattern at " + xBlock + ", " + yBlock + " already used");
                    else
                        tileDefs.Add(blockPixels, blockHexVals);
                }
            }

            return tileDefs;
        }

        static List<string[]> GetTileHexDefs(string path)
        {
            var hexDefs = new List<string[]>();
            foreach (var line in File.ReadAllLines(path))
            {
                if (string.IsNullOrWhiteSpace(line) || line.Contains("//"))
                    continue;

                var cells = line.Split(',');
                foreach (var cell in cells)
                    VerifyHexValues(path, cell);

                hexDefs.Add(cells);
                
            }
            return hexDefs;
        }

        static Dictionary<string, string> ParseArgs(string[] args)
        {
            var parsedArgs = new Dictionary<string, StringBuilder>();
            StringBuilder iBuilder = null;
            foreach(var arg in args)
            {
                if (arg.StartsWith("-"))
                {
                    iBuilder = new StringBuilder();
                    parsedArgs.Add(arg, iBuilder);
                }
                else if (iBuilder != null)
                {
                    if (iBuilder.Length > 0)
                        iBuilder.Append(" ");
                    iBuilder.Append(arg);
                }
            }
            return parsedArgs.ToDictionary(p => p.Key, p => p.Value.ToString());
        }

        static void VerifyHexValues(string from, string hexValues)
        {
            if (hexValues.Split(' ').Length != 3)
                throw new Exception("hex values \"" + hexValues + "\" from " + from + " is not valid");
        }
    }
}
