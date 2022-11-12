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

namespace Abaco.Partial.Parser
{
  internal class Tree
  {
    public Ast.Node branch { get; private set; }
    private HashTable<string, Tree> children;
    private uint tmpcount;

    /* private API */

    private bool insert_local (string name, Ast.Node child)
      requires (name [0] != '@')
      requires (branch is Ast.List)
    {
      ((Ast.List<Ast.Node>) branch).append (child);
      children.insert (name, new Tree (child));
    return true;
    }

    private unowned Tree? lookup_local (string name)
    {
      unowned var child = (Tree?) null;
      if (children.lookup_extended (name, null, out child))
        return child;
    return null;
    }

    /* public API */

    public string tmpnam ()
    {
        ++tmpcount;
      return
        ("%u").printf (tmpcount);
    }

    public HashTableIter<string, Tree> iterator ()
    {
      return HashTableIter<string, Tree> (children);
    }

    public bool insert (string name, Ast.Node child)
      requires (name [0] != '@')
    {
      var secs = name.split (".");
      unowned var tree = this;
      unowned var sec = (string?) null;
      for (int i = 0; i < secs.length - 1; i++)
      {
        sec = secs [i];
        if ((tree = tree.lookup_local (sec)) == null)
          return false;
      }

      sec = secs [secs.length - 1];
    return tree.insert_local (sec, child);
    }

    public unowned Ast.Node? lookup (string name)
    {
      unowned var tree = this;
      var secs = name.split (".");
      foreach (unowned var sec in secs)
      {
        if ((tree = tree.lookup_local (sec)) == null)
          return null;
      }
    return tree.branch;
    }

    /* constuctor */

    public Tree (Ast.Node branch)
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      this.children = new HashTable<string, Tree> (hash, equal);
      this.branch = branch;
      this.tmpcount = 0;
    }
  }
}
