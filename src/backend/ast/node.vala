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
  internal abstract class Node
  {
    private Datalist<string?> notes;

    /* type API */

    public abstract class Annotations
    {
      public static Quark source_name;
      public static Quark line_number;
      public static Quark column_number;
      public static Quark is_static;
      public static Quark is_constant;

      /* constructor */

      static construct
      {
        source_name = Quark.from_string ("abaco-node-source-name");
        line_number = Quark.from_string ("abaco-node-line-number");
        column_number = Quark.from_string ("abaco-node-column-number");
        is_static = Quark.from_string ("abaco-node-is-static");
        is_constant = Quark.from_string ("abaco-node-is-constant");
      }
    }

    /* debug API */

#if DEVELOPER == 1

    public virtual string debug (size_t spaces)
    {
      var type = Type.from_instance (this);
      var pre = string.nfill (spaces * 2, ' ');
      return ("%s- '%s'").printf (pre, type.name ());
    }

#endif // DEVELOPER

    /* public API */

    public void set_note (string index, string content) { notes.set_data (index, content); }
    public void set_qnote (GLib.Quark index, string content) { notes.id_set_data (index, content); }
    public unowned string get_note (string index) { return notes.get_data (index); }
    public unowned string get_qnote (GLib.Quark index) { return notes.id_get_data (index); }
    public string steal_note (string index) { return notes.remove_no_notify (index); }
    public string steal_qnote (GLib.Quark index) { return notes.id_remove_no_notify (index); }

    /* constructors */

    static construct
    {
      typeof (Annotations).class_ref ();
    }

    protected Node ()
    {
      notes = Datalist<string?> ();
    }
  }
}
