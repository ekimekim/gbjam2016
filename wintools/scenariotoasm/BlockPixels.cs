using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace scenariotoasm
{
    public class BlockPixels
    {
        public const int Width = 3;
        public const int Height = Width;

        Color[] _pixels;

        public BlockPixels()
        {
            _pixels = new Color[9];
        }

        public Color this[int index]
        {
            get { return _pixels[index]; }
            set { _pixels[index] = value; }
        }

        public Color this[int x, int y]
        {
            get { return _pixels[(y * Width) + x]; }
            set { _pixels[(y * Width) + x] = value; }
        }

        public override bool Equals(object obj)
        {
            if (obj is BlockPixels)
            {
                var other = obj as BlockPixels;
                for (int i = 0; i < Width * Height; i++)
                {
                    if (this[i] != other[i])
                        return false;
                }
                return true;
            }
            else
                return base.Equals(obj);
        }

        public override int GetHashCode()
        {
            var hash = 0;
            for (var i = 0; i < _pixels.Length; i++)
            {
                hash += _pixels[i].R;
                hash += _pixels[i].G;
                hash += _pixels[i].B;
            }
            return hash;
        }

        //public class EqualityComparer : IEqualityComparer<BlockPixels>
        //{
        //    public bool Equals(BlockPixels x, BlockPixels y)
        //    {
        //        return x.Equals(y);
        //    }

        //    public int GetHashCode(BlockPixels obj)
        //    {
        //        return obj.GetHashCode();
        //    }
        //}
    }
}
