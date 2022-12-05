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
  internal class Space
  {
    private unowned Space? parent;
    private HashTable<string, Space> children;
    public Ast.Node node { get; private set; }

    public Space? root
    {
      get
      {
        if (parent == null)
          return this;
        else
          return parent.root;
      }
    }

    /* public API */

    public unowned Space? push (string name, owned Ast.Node child)
      throws GLib.Error
    {
      if (! (node is Ast.List))
        throw new ParserError.FAILED ("invalid operation");
      else
      {
        unowned var scope = (Ast.List<Ast.Node>) node;
        unowned var space = (Space?) null;
          var SPACE = new Space.spawn ((owned) child);

        children.insert (name, (space = SPACE));
        scope.append (space.node);
        space.parent = this;
          return space;
      }
    }

    public unowned Space? insert (string name, owned Ast.Node child)
      throws GLib.Error
    {
      if (lookup_local (name) == null)
        return push (name, (owned) child);
      else
        error ("Already exists a '%s'", name);
    }

    public unowned Space? lookup_local (string name)
    {
      unowned var space = (Space?) null;
      if (children.lookup_extended (name, null, out space))
        return space;      
    return null;
    }

    public unowned Space? lookup (string name)
    {
      unowned var space = (Space?) null;
      unowned var got = children.lookup_extended (name, null, out space);

      if (got)
        return space;
      else
      {
        if (parent != null)
          return parent.lookup (name);
        else
          return null;
      }
    }

    /* constructor */

    protected Space.spawn (owned Ast.Node node)
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;

      this.parent = null;
      this.children = new HashTable<string, Space> (hash, equal);
      this.node = (owned) node;
    }

    public Space ()
    {
      this.spawn (new Ast.Scope ());
    }
  }
}
