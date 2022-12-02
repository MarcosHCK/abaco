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
using Abaco.Ast;

namespace Abaco
{
  internal enum Assoc
  {
    LEFT = 0,
    RIGHT = 1,
  }

  [Compact (opaque = true)]
  internal class Operator
  {
    public string name { get; private set; }
    public uint precedence { get; private set; }
    public bool is_unary { get; private set; }
    public Assoc assoc { get; private set; }

    /* constructor */

    public Operator.binary (string name, uint precedence, Assoc assoc)
    {
      this (name, precedence);
      this.assoc = assoc;
      this.is_unary = false;
    }

    public Operator.unary (string name, uint precedence)
    {
      this (name, precedence);
      this.is_unary = true;
    }

    public Operator (string name, uint precedence)
    {
      this.name = name;
      this.precedence = precedence;
    }
  }

  [Compact (opaque = true)]
  internal class Operators : HashTable<string, Operator?>
  {
    private static Operators global;

    /* public API */

    public static void ensure ()
    {
      global = new Operators ();
      register (new Operator.binary ("+", 2, Assoc.LEFT));
      register (new Operator.binary ("-", 2, Assoc.LEFT));
      register (new Operator.binary ("*", 3, Assoc.LEFT));
      register (new Operator.binary ("/", 3, Assoc.LEFT));
    }

    public static unowned Operator? register (owned Operator? op)
    {
      unowned var name = op.name;
      global.insert (name, (owned) op);
    return lookup (name);
    }

    public static unowned Operator? lookup (string name)
    {
      unowned Operator? val;
      if (global.lookup_extended (name, null, out val))
        return val;
      assert_not_reached ();
    }

    /* constructor */

    public Operators ()
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      base (hash, equal);
    }
  }
}
