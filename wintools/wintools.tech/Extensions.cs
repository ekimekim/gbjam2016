using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;

namespace wintools.tech
{
    public static class Extensions
    {
        public static string GetPath(this Dictionary<string, string> args, string key, bool throwIfMissing)
        {
            if (args.ContainsKey(key))
                return Path.GetFullPath(args[key]);

            if (throwIfMissing)
                throw new Exception("Missing arg " + key);

            return null;
        }

        public static void WriteLineUnix(this StreamWriter writer, string line)
        {
            writer.Write(line);
            writer.Write('\n');
        }

        public static IEnumerable<Color> GetAllPixels(this Bitmap image)
        {
            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    yield return image.GetPixel(x, y);
                }
            }
        }

        public static IEnumerable<KeyValuePair<Point, Color>> GetPixels(this Bitmap image)
        {
            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    yield return new KeyValuePair<Point, Color>(new Point(x, y), image.GetPixel(x, y));
                }
            }
        }

        public static Color GetPixelSolid(this Bitmap bitmap, int x, int y)
        {
            return bitmap.GetPixel(x, y).SetAlpha(255);
        }

        public static Color SetAlpha(this Color color, int a)
        {
            return Color.FromArgb(a, color.R, color.G, color.B);
        }
    }
}
