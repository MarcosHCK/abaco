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
  internal abstract class Operators
  {
    static HashTable<unowned string, unowned Operator?> links;
    static Operator[] operators;

    /* public API */

    public static unowned Operator? lookup (string name)
    {
      unowned Operator? val;
      if (links.lookup_extended (name, null, out val))
        return val;
      assert_not_reached ();
    }

    /* constructor */

    static construct
    {
      operators =
      new Operator[]
      {
        Operator.binary ("+", 2, Assoc.LEFT),
        Operator.binary ("-", 2, Assoc.LEFT),
        Operator.binary ("*", 3, Assoc.LEFT),
        Operator.binary ("/", 3, Assoc.LEFT),
      };

      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      links = new HashTable<unowned string, unowned Operator?> (hash, equal);

      foreach (unowned var val in operators)
        links.insert (val.name, val);
    }
  }

  internal enum Assoc
  {
    LEFT = 0,
    RIGHT = 1,
  }

  internal struct Operator
  {
    public string name;
    public uint precedence;
    public Assoc assoc;
    public bool is_unary;

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
}
