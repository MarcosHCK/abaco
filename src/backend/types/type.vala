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

namespace Abaco.Types
{
  internal abstract class Type
  {
    public string typename { get; private set; }

    /* abstract API */

    public abstract bool checkliteral (string value);
    public abstract bool checkcast (Type other);

    /* constructor */

    protected Type (string typename)
    {
      this.typename = typename;
    }
  }

  [Compact (opaque = true)]
  internal class Table : HashTable<unowned string, Type>
  {
    static Table? global = null;

    /* public API */

    public static void ensure ()
    {
      global = new Table ();
    }

    public static void register (Type type)
      requires (global != null)
    {
      global.insert (type.typename, type);
    }

    public static Type? lookup (string name)
      requires (global != null)
    {
      assert_not_reached ();
    }

    /* constructor */

    public Table ()
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      base (hash, equal);
    }
  }
}
