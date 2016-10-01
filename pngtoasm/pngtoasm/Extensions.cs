using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace pngtoasm
{
    public static class Extensions
    {
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

        public static string ToInt4String(this int src)
        {
            if (src == 0)
                return "00";
            if (src == 1)
                return "01";
            if (src == 2)
                return "10";
            if (src == 3)
                return "11";
            throw new Exception(src + " not supported");
        }
    }
}
