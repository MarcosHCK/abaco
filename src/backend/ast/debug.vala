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
  private static void debug_node (StringBuilder builder, GenericSet<unowned Node> visited, Node node, uint spaces)
  {
    var type = Type.from_instance (node);
    var name = type.name ();
    for (uint i = 0; i < spaces * 2; ++i)
      builder.append_c (' ');
      builder.append_c ('-');
      builder.append (" '");
      builder.append (name);
      builder.append_c ('\'');

    {
      if (node is IUnique)
      {
        builder.append (", ");
        builder.append ("id = '");
        builder.append (node.id);
        builder.append_c ('\'');
      }

      if (node is ITyped)
      {
        builder.append (", ");
        builder.append ("type = '");
        builder.append (node.typename ?? "(unassigned)");
        builder.append_c ('\'');
      }
    }

    if (!visited.contains (node))
    {
      visited.add (node);

      if (node is Assign)
      {
        unowned var node_ = (Assign) node;
        unowned var target = node_.target;
        unowned var rvalue = node_.rvalue;

        builder.append ("\r\n");
        debug_node (builder, visited, target, spaces + 1);
        builder.append ("\r\n");
        debug_node (builder, visited, rvalue, spaces + 1);
      } else
      if (node is Cast)
      {
        unowned var node_ = (Cast) node;
        unowned var rvalue = node_.rvalue;

        builder.append ("\r\n");
        debug_node (builder, visited, rvalue, spaces + 1);
      } else
      if (node is Conditional)
      {
        unowned var node_ = (Conditional) node;
        unowned var direct = node_.direct;

        builder.append ("\r\n");
        debug_node (builder, visited, direct, spaces + 1);
        if (node is Ifelse)
        {
          unowned var node__ = (Ifelse) node;
          unowned var reverse = node__.reverse;

          builder.append ("\r\n");
          debug_node (builder, visited, reverse, spaces + 1);
        }
      } else
      if (node is Constant)
      {
        unowned var node_ = (Constant) node;
        builder.append (", ");
        builder.append ("value = '");
        builder.append (node_.value);
        builder.append_c ('\'');
      } else
      if (node is Function)
      {
        unowned var node_ = (Function) node;
        unowned var arguments = node_.arguments;

        builder.append ("\r\n");
        debug_node (builder, visited, arguments, spaces + 1);

        if (node is IConcrete)
        {
          unowned var node__ = (IConcrete) node;
          unowned var body = node__.body;

          builder.append ("\r\n");
          debug_node (builder, visited, body, spaces + 1);
        }
      } else
      if (node is Global)
      {
        unowned var node_ = (Global) node;
        unowned var rvalue = node_.rvalue;

        if (rvalue != null)
        {
          builder.append ("\r\n");
          debug_node (builder, visited, rvalue, spaces + 1);
        }
      } else
      if (node is Invoke)
      {
        unowned var node_ = (Invoke) node;
        unowned var target = node_.target;
        unowned var arguments = node_.arguments;

        builder.append ("\r\n");
        debug_node (builder, visited, target, spaces + 1);
        builder.append ("\r\n");
        debug_node (builder, visited, arguments, spaces + 1);
      } else
      if (node is Operation)
      {
        unowned var node_ = (Operation) node;
        unowned var rvalues = node_.rvalues;

        builder.append (", name = '");
        builder.append (node_.name);
        builder.append_c ('\'');
        builder.append ("\r\n");
        debug_node (builder, visited, rvalues, spaces + 1);
      } else
      if (node is Return)
      {
        unowned var node_ = (Return) node;
        unowned var rvalue = node_.rvalue;

        if (rvalue != null)
        {
          builder.append ("\r\n");
          debug_node (builder, visited, rvalue, spaces + 1);
        }
      } else
      if (node is List)
      {
        foreach (unowned var child in (List<Node>) node)
        {
          builder.append ("\r\n");
          debug_node (builder, visited, child, spaces + 1);
        }
      }
    }
  }

  internal static string debug (Node tree, uint spaces = 0)
  {
    var builder = new StringBuilder.sized (256);
    var visited = new GenericSet<unowned Node> (GLib.direct_hash, GLib.direct_equal);
      debug_node (builder, visited, tree, spaces);
      return builder.str;
  }
}
