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
        error ("Node isn't annotated\r\n%s\r\n", Ast.debug (node));

      return @"$(source): $(line): $(column)";
    }
  }

  internal class Profiler : GLib.Object
  {
    public Types.Table types { get; construct set; }

    /* private API */

    static bool function_type (string type, out string? return_type, out string[]? argument_types)
    {
      unowned string arguments;
      unowned string next;
      unowned int length = type.length;
      unowned int at;

      if ((at = type.index_of_char ((unichar) '@')) == -1)
        return false;
      if ((return_type = type [0 : at]) == null)
        return false;
      if ((arguments = type.offset (at)) == null)
        return false;

      next = arguments.next_char ();

      if (next.get_char () == (unichar) 0)
        argument_types = new string [0];
      else
        argument_types = next.split ("&");
    return true;
    }

    private void profile_rvalue (Ast.Node node, string expected)
      throws GLib.Error
    {
      if (node is Assign)
      {
          profile_types (node);
        if (((ITyped) node).typename != expected)
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Can't convert from '$(((ITyped) node).typename)' to '$expected'";
          throw new AstError.TYPE_MISMATCH (message);
        }
      } else
      if (node is Cast)
      {
        unowned var node_ = (Cast) node;
        unowned var rvalue = node_.rvalue;

        if (rvalue is Constant)
          profile_rvalue (rvalue, expected);
        else
        {
          profile_rvalue (rvalue, rvalue.typename);
          unowned var type1 = types.lookup (node_.typename);
          unowned var type2 = types.lookup (rvalue.typename);
          if (!type1.checkcast (type2))
          {
            var locate = AstError.locate (node);
            var message = @"$locate: Can't cast from '$(type2.name)' to '$(type1.name)'";
            throw new AstError.TYPE_MISMATCH (message);
          }
        }
      } else
      if (node is Constant)
      {
        unowned var node_ = (Constant) node;
        unowned var type1 = types.lookup (expected);

        if (type1.checkliteral (node_.value))
          node_.typename = expected;
        else
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Can't convert literal '$(node_.value)' to '$(type1.name)'";
          throw new AstError.TYPE_MISMATCH (message);
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
          profile_types (node);
        if (((ITyped) node).typename != expected)
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Can't convert from '$(((ITyped) node).typename)' to '$expected'";
          throw new AstError.TYPE_MISMATCH (message);
        }
      } else
      if (node is Operation)
      {
        unowned var node_ = (Operation) node;
        unowned var rvalues = node_.rvalues;
        unowned string common = null;

        foreach (unowned var rvalue in rvalues)
        {
          if ((common = rvalue.typename) != null)
            break;
        }

        if (common == null)
          common = expected;
        else
        {
          if (common != expected)
          {
            var locate = AstError.locate (node);
            var message = @"$locate: Can't convert from '$common' to '$expected'";
            throw new AstError.TYPE_MISMATCH (message);
          }
        }

        foreach (unowned var rvalue in rvalues)
          profile_rvalue (rvalue, common);
      } else
      if (node is IVariable)
      {
        unowned var node_ = (IVariable) node;
        if (node_.typename != expected)
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Can't convert from '$(node_.typename)' to '$expected'";
          throw new AstError.TYPE_MISMATCH (message);
        }
      }
      else
      {
        error ("Fix this! ('%s')", GLib.Type.from_instance (node).name ());
      }
    }

    private void profile_types (Ast.Node node, Function? function = null)
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
        unowned var arguments = node_.arguments;

        foreach (unowned var arg in arguments)
          profile_types (arg, node_);
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
            var message = @"$locate: Returning nothing in a non-void function";
            throw new AstError.FAILED (message);
          }
        }
      } else
      if (node is Scope)
      {
        foreach (unowned var node_ in (Scope) node)
          profile_types (node_, function);
      } else
      if (node is Variable)
      {
      }
      else
      {
        error ("Fix this! ('%s')", GLib.Type.from_instance (node).name ());
      }
    }

    private bool profile_path (Ast.Node node)
      throws GLib.Error
    {
      if (node is Return)
        return true;
      else
      if (node is Scope)
      {
        foreach (unowned var node_ in (Scope) node)
        {
          if (profile_path (node_))
            return true;
        }
      }
    return false;
    }

    private void profile_returns (Ast.Node node)
      throws GLib.Error
    {
      if (node is ConcreteFunction)
      {
        unowned var node_ = (IConcrete) node;
        unowned var body = node_.body;

        if (!profile_path (body))
        {
          var locate = AstError.locate (node);
          var message = @"$locate: Function reaches end of non-void function";
          throw new AstError.FAILED (message);
        }
      } else
      if (node is Scope)
      {
        foreach (unowned var node_ in (Scope) node)
          profile_returns (node_);
      }
    }

    /* public API */

    public void profile (Ast.Node tree)
      throws GLib.Error
    {
      profile_types (tree);
      profile_returns (tree);
    }

    /* constructors */

    public Profiler (Types.Table types)
    {
      Object (types : types);
    }
  }
}
