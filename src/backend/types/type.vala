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
    public string name { get; private set; }

    /* abstract API */

    public abstract bool checkliteral (string value);
    public abstract bool checkcast (Type other);

    /* constructor */

    protected Type (string name)
    {
      this.name = name;
    }
  }

  internal class ArchInt : Type
  {
    public override bool checkliteral (string value) { return true; }
    public override bool checkcast (Type other) { return false; }
    public ArchInt ()
    {
      base ("int");
    }
  }

  internal class Integer : Type
  {
    public override bool checkliteral (string value) { return true; }
    public override bool checkcast (Type other) { return false; }
    public Integer ()
    {
      base ("integer");
    }
  }

  internal class Table : GLib.Object
  {
    private HashTable<unowned string, Type> types;
    static Table? global = null;

    /* public API */

    public static void ensure ()
    {
      if (Once.init_enter ((size_t*) &global))
      {
        var table = new Table ();
        table.register (new ArchInt ());
        table.register (new Integer ());
        Once.init_leave ((size_t*) &global, (size_t) table.@ref ());
      }
    }

    public static Table spawn ()
      requires (global != null)
    {
      var table = new Table ();
      var iter = HashTableIter<unowned string, Type> (global.types);
      unowned var name = (string?) null;
      unowned var type = (Type?) null;

      while (iter.next (out name, out type))
        table.register (type);
    return table;
    }

    public void register (Type type)
    {
      types.insert (type.name, type);
    }

    public unowned Type? lookup (string name)
    {
      return types.lookup (name);
    }

    /* constructor */

    public Table ()
    {
      Object ();
    }

    construct
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      types = new HashTable<unowned string, Type> (hash, equal);
    }
  }
}
