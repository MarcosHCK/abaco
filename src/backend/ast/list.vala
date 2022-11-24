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

namespace Abaco.Ast
{
  internal class List<T> : Node
  {
    public unowned GLib.List<T> children { get; private set; }

    /* type API */

    public struct ListIter<T>
    {
      public Ast.List<T> owner;
      public unowned GLib.List<T>? list;

      /* public API */

      public bool next ()
      {
        return list != null;
      }

      public unowned T @get ()
      {
        return (T) list.data;
      }

      /* constructor */

      public ListIter (List<T> owner)
      {
        this.owner = owner;
        this.list = owner.children;
      }
    }

    /* debug API */

#if DEVELOPER == 1

    public override string debug (size_t spaces)
    {
      var partial = base.debug (spaces);
      unowned var child = children;

      while (child != null)
      {
        var node = (Node) child.data;
        partial += "\r\n" + node.debug (spaces + 1);
        child = child.next;
      }
    return partial;
    }

#endif // DEVELOPER

    /* public API */

    public void append (T child) { children.append (child); }
    public void prepend (T child) { children.prepend (child); }
    public void remove (T child) { children.remove (child); }
    public uint n_children () { return children.length (); }
    public ListIter<T> iterator () { return ListIter<T> (this); }

    public void children_foreach (GLib.Func<unowned T> callback)
    {
      unowned var child = children;
      while (child != null)
      {
        callback ((T) child.data);
        child = child.next;
      }
    }

    /* constructor */

    public List ()
    {
      base ();
    }
  }
}
