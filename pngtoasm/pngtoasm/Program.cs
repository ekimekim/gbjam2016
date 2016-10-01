using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
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
                Console.WriteLine("pngtoasm -o output path -dir assets directory -paint\n(optional)-paint paints bad pixels");

                return 1;
            }

            try
            {
                string outputPath;
                string assetDir;
                bool paintBadPixels;
                GetArgs(args, out outputPath, out assetDir, out paintBadPixels);
                if (string.IsNullOrEmpty(outputPath))
                    throw new Exception("need output path");
                if (string.IsNullOrEmpty(assetDir))
                    throw new Exception("need assets directory");

                var assetFiles = Directory.GetFiles(assetDir, "*.png", SearchOption.AllDirectories).Where(f => !f.EndsWith("badpixels.png"));

                var outputDir = Path.GetDirectoryName(outputPath);
                if (!Directory.Exists(outputDir))
                    Directory.CreateDirectory(outputDir);

                var writer = new StreamWriter(outputPath);
                foreach (var line in assetFiles.SelectMany(t => GetTileLines(t, assetDir, paintBadPixels)))
                    writer.WriteLineUnix(line);
                writer.Close();
                Console.WriteLine(outputPath);
                return 0;
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                return 1;
            }
        }

        static List<string> GetTileLines(string filePath, string assetDir, bool paintBadPixels)
        {
            var lines = new List<string>();

            var localPath = filePath.Substring(assetDir.Length, filePath.Length - assetDir.Length);

            var image = Image.FromFile(filePath) as Bitmap;

            if (image.Width % 8 != 0 || image.Height % 8 != 0)
                throw new Exception(filePath + " isn't power of 8");

            var colorPallet = image.GetAllPixels().Distinct().OrderBy(p => p.R + p.G + p.B).ToArray();

            if (colorPallet.Count() > 4)
            {
                if(paintBadPixels)
                {
                    PaintBadPixels(image, colorPallet, filePath);
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
                    lines.Add(";" + localPath + (tileCount > 1 ? "/" + xTile + "," + yTile : ""));

                    for (int y = 0; y < 8; y++)
                    {
                        var line = new StringBuilder(14);
                        line.Append("word '");
                        for (int x = 0; x < 8; x++)
                        {
                            var palletIndex = Array.IndexOf(colorPallet, image.GetPixel(xTile + x, yTile + y));
                            line.Append(palletIndex);
                        }
                        lines.Add(line.ToString());
                    }
                }
            }

            return lines;

        }

        private static void PaintBadPixels(Bitmap image, Color[] pixelValues, string filePath)
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
                        badPixelsImage.SetPixel(x, y, Color.Red);
                }
            }

            var paintedPath = Path.Combine(Path.GetDirectoryName(filePath),
                                            Path.GetFileNameWithoutExtension(filePath) + ".badpixels.png");
            badPixelsImage.Save(paintedPath, ImageFormat.Png);
        }

        static void GetArgs(string[] args, out string outputPath, out string assedDir, out bool paintBadPixels)
        {
            paintBadPixels = false;
            StringBuilder outputPathBuilder = new StringBuilder();
            StringBuilder assetDirBuilder = new StringBuilder();
            StringBuilder iArg = null;
            for (var i = 0; i < args.Length; i++)
            {
                if (args[i] == "-o")
                    iArg = outputPathBuilder;
                else if (args[i] == "-dir")
                    iArg = assetDirBuilder;
                else if (args[i] == "-paint")
                {
                    paintBadPixels = true;
                    iArg = null;
                }
                else if (iArg != null)
                    iArg.Append(args[i]);
            }

            outputPath = Path.GetFullPath(outputPathBuilder.ToString());
            assedDir = Path.GetFullPath(assetDirBuilder.ToString());
        }
    }
}
