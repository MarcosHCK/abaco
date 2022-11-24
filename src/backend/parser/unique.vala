/* Copyright 2021-2025 MarcosHCK
 * This file is part of abaco.
 *
 * abaco is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * abaco is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with abaco. If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Abaco
{
  internal struct Uniques
  {
    const ulong full = 16;
    const ulong div = sizeof (uint8);
    const ulong divs = sizeof (uint) / div;
    const string UUID_BYTE_F = "%02x";
    const string UUID_GROUP_2 = UUID_BYTE_F + UUID_BYTE_F;
    const string UUID_GROUP_3 = UUID_BYTE_F + UUID_BYTE_F;
    const string UUID_GROUP_4 = UUID_BYTE_F + UUID_BYTE_F;
    const string UUID_GROUP_1 = UUID_GROUP_2 + UUID_GROUP_2;
    const string UUID_GROUP_5 = UUID_GROUP_1 + UUID_GROUP_2;
    const string UUID_F_1 = UUID_GROUP_1 + "-" + UUID_GROUP_2;
    const string UUID_F_2 = UUID_GROUP_3 + "-" + UUID_GROUP_4;
    const string UUID_F_3 = UUID_F_1 + "-" + UUID_F_2;
    const string UUID_F = UUID_F_3 + "-" + UUID_GROUP_5;
    public uint8 bytes [16 /* equals UniqueCount.full */];

    /* private API */

    private void inc ()
    {
      for (var i = 0; i < full; i++)
      {
        if (bytes [i] == uint8.MAX)
          continue;
        else
        {
          bytes [i]++;
          return;
        }
      }
    }

    private void dec ()
    {
      for (var i = full; i > 0; i--)
      {
        if (bytes [i - 1] == 0)
          continue;
        else
        {
          bytes [i - 1]--;
          return;
        }
      }
    }

    /* public API */

    public string next ()
    {
        inc ();
      return
        (UUID_F).printf
        (bytes [15], bytes [14], bytes [13], bytes [12],
         bytes [11], bytes [10], bytes [ 9], bytes [ 8],
         bytes [ 7], bytes [ 6], bytes [ 5], bytes [ 4],
         bytes [ 3], bytes [ 2], bytes [ 1], bytes [ 0]);
    }

    /* constructor */

    public Uniques (uint first = 0)
    {
      for (var i = 0; i < divs; i++)
      {
        var val = first >> (i * div);
          bytes [i] = (uint8) val;
      }

      for (var i = divs; i < full; i++)
      {
        bytes [i] = 0;
      }
    }
  }
}
