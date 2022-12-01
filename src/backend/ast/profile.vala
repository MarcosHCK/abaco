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
using Abaco.Types;

namespace Abaco.Ast
{
  public errordomain AstError
  {
    FAILED,
    UNKNOWN_TYPE,
    TYPE_MISMATCH,
    INCOMPATIBLE_LITERAL;

    /* internal API */

    internal static string locate (Ast.Node? node)
    {
      unowned var line = node.get_qnote (Ast.Node.Annotations.line_number);
      unowned var column = node.get_qnote (Ast.Node.Annotations.column_number);
      unowned var source = node.get_qnote (Ast.Node.Annotations.source_name);
      if (unlikely (source == null || line == null || column == null))
        error ("Node isn't annotated\r\n%s\r\n", node.debug (0));

      return @"$(source): $(line): $(column)";
    }
  }

  private static bool function_type (string type, out string? return_type, out string[]? argument_types)
  {
    assert_not_reached ();
  }

  private static void profile_rvalue (Node node, string expected)
    throws GLib.Error
  {
    assert_not_reached ();
  }

  private static void profile_types (Node node, Function? function = null)
    throws GLib.Error
  {
    if (node is Assign)
    {
      unowned var node_ = (Assign) node;
      unowned var target = node_.target;
      unowned var rvalue = node_.rvalue;
      profile_rvalue (rvalue, target.typename);
    } else
    if (node is Function)
    {
      unowned var node_ = (Function) node;
      if (node is IConcrete)
      {
        unowned var node__ = (IConcrete) node;
        unowned var body = node__.body;
        profile_types (body, node_);
      }
    } else
    if (node is Global)
    {
      unowned var node_ = (Global) node;
      unowned var rvalue = node_.rvalue;

      if (rvalue != null)
      {
        profile_rvalue (rvalue, node_.typename);
      }
    } else
    if (node is Invoke)
    {
      unowned var node_ = (Invoke) node;
      unowned var target = node_.target;
      unowned var arguments = node_.arguments;
      unowned var functype = target.typename;

      string return_type = null;
      string[] argument_types = null;
      if (!function_type (functype, out return_type, out argument_types))
      {
        var locate = AstError.locate (node);
        var message = @"$locate: Target variable isn't a function";
        throw new AstError.FAILED (message);
      }
      else
      {
        uint l1 = argument_types.length;
        uint l2 = arguments.n_children ();

        if (l1 != l2)
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Too $(l1 > l2 ? "few" : "many") arguments for function call";
          throw new AstError.FAILED (message);
        }
        else
        {
          int i = 0;
          foreach (unowned var arg in arguments)
            profile_rvalue (arg, argument_types [i++]);
        }
      }
    } else
    if (node is Return)
    {
      if (function == null)
      {
        var locate = AstError.locate (node);
        var message = @"$locate: Return statement out of function scope";
        throw new AstError.FAILED (message);
      }
      else
      {
        unowned var node_ = (Return) node;
        unowned var rvalue = node_.rvalue;

        if (rvalue != null && function.return_type != "void")
          profile_rvalue (rvalue, function.return_type);
        else
        if (rvalue != null && function.return_type == "void")
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Returning a value in a void function";
          throw new AstError.FAILED (message);
        } else
        if (rvalue == null && function.return_type != "void")
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Returning nothing in a not-void function";
          throw new AstError.FAILED (message);
        }
      }
    } else
    if (node is Scope)
    {
      foreach (unowned var node_ in (Scope) node)
        profile_types (node_);
    } else
    if (node is Variable)
    {
    }
    else
    {
      error ("Fix this! ('%s')", GLib.Type.from_instance (node).name ());
    }
  }

  internal static void profile (Node tree)
    throws GLib.Error
  {
    profile_types (tree);
  }
}
