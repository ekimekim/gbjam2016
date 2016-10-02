using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace pngtoasm
{
    class Program
    {
        static int Main(string[] args)
        {
            if(args.Length < 2
                || args[1].ToLower().Contains("help")
                || args[1].ToLower().Contains("?"))
            {
                Console.WriteLine("usage pngtoasm [-o output.asm] [-src assetsdir]\n(optional)[-debug color] if more than 4 colors, outputs a *debug.png with least used pixels painted in target color\n(optional)[-ignore color] tiles that are completely this color will be ignored\n[-names tilenames.csv]");

                return 1;
            }

            //try
            {
                string outputPath;
                string srcDir;
                Color? debugColor;
                Color? ignoreColor;
                string namesPath;
                GetArgs(args, out outputPath, out srcDir, out debugColor, out ignoreColor, out namesPath);
                if (string.IsNullOrEmpty(outputPath))
                    throw new Exception("need output path");
                if (string.IsNullOrEmpty(srcDir))
                    throw new Exception("need assets directory");
                var names = ParseNames(namesPath);
                var assetFiles = Directory.GetFiles(srcDir, "*.png", SearchOption.AllDirectories).Where(f => !f.EndsWith("debug.png"));

                var outputDir = Path.GetDirectoryName(outputPath);
                if (!Directory.Exists(outputDir))
                    Directory.CreateDirectory(outputDir);

                var writer = new StreamWriter(outputPath);
                foreach (var line in assetFiles.SelectMany(t => GetTileLines(t, srcDir, debugColor, ignoreColor, names)))
                    writer.WriteLineUnix(line);
                writer.Close();
                Console.WriteLine(outputPath);
                return 0;
            }
            //catch (Exception e)
            //{
            //    Console.WriteLine(e);
            //    return 1;
            //}
        }


        static List<string> GetTileLines(string filePath, string assetDir, Color? debugColor, Color? ignoreColor, List<string[]> names)
        {
            var lines = new List<string>();

            var localPath = filePath.Substring(assetDir.Length, filePath.Length - assetDir.Length).Replace('\\', '/');

            var image = Image.FromFile(filePath) as Bitmap;

            if (image.Width % 8 != 0 || image.Height % 8 != 0)
                throw new Exception(filePath + " isn't power of 8");

            var colorPallet = image.GetAllPixels()
                                    .Select(p => Color.FromArgb(p.R, p.G, p.G)) //Alpha fix
                                    .Distinct()
                                    .Where(p => !ignoreColor.HasValue || p != ignoreColor.Value)
                                    .OrderByDescending(p => p.R + p.G + p.B)
                                    .ToArray();

            if (colorPallet.Count() > 4)
            {
                if(debugColor.HasValue)
                {
                    PaintBadPixels(image, colorPallet, filePath, debugColor.Value);
                    return lines;
                }
                else
                    throw new Exception("image has more than 4 colors");
            }

            var tileCount = (image.Width / 8) * (image.Height / 8);
            for (int yTile = 0; yTile < image.Height / 8; yTile++)
            {
                for (int xTile = 0; xTile < image.Width / 8; xTile++)
                {
                    lines.Add(";" + GetTileName(localPath, tileCount, xTile, yTile, names));

                    if (ignoreColor.HasValue)
                    {
                        var ignoreThisTile = false;
                        for (int y = 0; y < 8; y++)
                        {
                            for (int x = 0; x < 8; x++)
                            {
                                if (image.GetPixel((xTile * 8) + x, (yTile * 8) + y) == ignoreColor.Value)
                                    ignoreThisTile = true;
                            }
                        }
                        if (ignoreThisTile)
                        {
                            lines.Add("ds 16 ; skipped");
                            lines.Add("");
                            continue;
                        }
                    }

                    for (int y = 0; y < 8; y++)
                    {
                        var line = new StringBuilder(14);
                        line.Append("dw `");
                        for (int x = 0; x < 8; x++)
                        {
                            var pixel = image.GetPixel((xTile * 8) + x, (yTile * 8) + y);
                            var palletIndex = Array.IndexOf(colorPallet, Color.FromArgb(pixel.R, pixel.G, pixel.G)); //Alpha fix
                            line.Append(palletIndex);
                        }
                        lines.Add(line.ToString());
                    }
                    lines.Add("");
                }
            }

            return lines;

        }

        static string GetTileName(string localPath, int tileCount, int xTile, int yTile, List<string[]> tileNames)
        {
            if (tileCount == 1)
                return localPath;
            if (tileNames != null
                && yTile < tileNames.Count
                && xTile < tileNames[yTile].Length)
            {
                return localPath + "/" + tileNames[yTile][xTile];
            }
            else
                return localPath +  "/" + xTile + "," + yTile;
        }

        private static void PaintBadPixels(Bitmap image, Color[] pixelValues, string filePath, Color debugColor)
        {
            Console.WriteLine("bad pixels: " + filePath);
            var badPixelsImage = new Bitmap(image);
            var badColors = image.GetAllPixels().GroupBy(p => p)
                                                .Select(g => new { Pixel = g.Key, Count = g.Count() })
                                                .OrderBy(p => p.Count).Select(p => p.Pixel)
                                                .Take(pixelValues.Length - 4).ToArray();

            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    if (badColors.Contains(image.GetPixel(x, y)))
                        badPixelsImage.SetPixel(x, y, debugColor);
                }
            }

            var paintedPath = Path.Combine(Path.GetDirectoryName(filePath),
                                            Path.GetFileNameWithoutExtension(filePath) + ".debug.png");
            badPixelsImage.Save(paintedPath, ImageFormat.Png);
        }

        static void GetArgs(string[] args, out string outputPath, out string srcDir, out Color? debugColor, out Color? ignoreColor, out string namesPath)
        {
            debugColor = null;
            ignoreColor = null;
            StringBuilder outputPathBuilder = new StringBuilder();
            StringBuilder assetDirBuilder = new StringBuilder();
            StringBuilder namesPathBuilder = new StringBuilder();
            StringBuilder iArg = null;

            for (var i = 0; i < args.Length; i++)
            {
                if (args[i] == "-o")
                    iArg = outputPathBuilder;
                else if (args[i] == "-src")
                    iArg = assetDirBuilder;
                else if (args[i] == "-names")
                    iArg = namesPathBuilder;
                else if (args[i] == "-debug")
                {
                    i++;
                    debugColor = ParseColor(args, ref i);
                    iArg = null;
                }
                else if (args[i] == "-ignore")
                {
                    i++;
                    ignoreColor = ParseColor(args, ref i);
                    iArg = null;
                }
                else if (iArg != null)
                    iArg.Append(args[i]);
            }

            outputPath = Path.GetFullPath(outputPathBuilder.ToString());
            srcDir = Path.GetFullPath(assetDirBuilder.ToString());
            namesPath = Path.GetFullPath(namesPathBuilder.ToString());
        }

        static List<string[]> ParseNames(string namesPath)
        {
            if (string.IsNullOrEmpty(namesPath))
                return null;

            var splitUsing = new char[] { ';', ',' };
            var rows = new List<string[]>();
            foreach (var line in File.ReadAllLines(namesPath))
                rows.Add(line.Split(splitUsing, StringSplitOptions.None));
            return rows;
        }

        static Color ParseColor(string[] args, ref int i)
        {
            int r;
            int g;
            int b;
            if (int.TryParse(args[i], out r)
                && int.TryParse(args[i + 1], out g)
                && int.TryParse(args[i + 2], out b))
            {
                //Pulled 2 extra args out
                i += 2;
                return Color.FromArgb(r, g, b); //Alpha fix
            }
            else
            {
                foreach(var prop in typeof(Color).GetProperties().Where(p => p.GetMethod.IsStatic && p.PropertyType == typeof(Color)))
                {
                    if (prop.Name.ToLower() != args[i])
                        continue;

                    var color = (Color)prop.GetValue(null, null);
                    return Color.FromArgb(color.R, color.G, color.G); //Alpha fix
                }
            }

            var colors = typeof(Color).GetProperties()
                                    .Where(p => p.GetMethod.IsStatic && p.PropertyType == typeof(Color))
                                    .Select(p => p.Name.ToLower())
                                    .ToArray();

            throw new Exception("Can't parse color use format [255 255 255] or use " + string.Join(" or ", colors));

        }
    }
}
