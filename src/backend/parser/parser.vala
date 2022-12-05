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
using Abaco.Parse;

namespace Abaco
{
  internal class Parser : GLib.Object
  {
    private Uniques uniques;
    private Space global;

    public Types.Table types { get; construct set; }
    public Scope root { get { return (Scope) global.node; } }

    /* type API */

    [Flags]
    enum ScopeFlags
    {
      NONE = 0,
      INNER = (1 << 1),
      STOPS = (1 << 2),
    }

    [Flags]
    enum Modifiers
    {
      NONE = 0,
      GLOBAL = (1 << 0),
      CONSTANT = (1 << 1),
      STATIC = (1 << 2),
    }

    /* private API */

    private void skip_function (Walker? walker, Token? begin)
      throws GLib.Error
    {
      unowned Token? token;
      uint skip = 0;

      while ((token = walker.pop ()) != null)
      {
        if (token.type == TokenType.SEPARATOR)
        {
          unowned var t = token.value;
          unowned var c = t.get_char ();
          unowned var n = t.next_char ();

          if (n.get_char () == (unichar) 0)
          {
            switch (c)
            {
            case (unichar) '{':
              ++skip;
              break;
            case (unichar) '}':
              if (skip > 0)
                --skip;
              else
                return;
              break;
            }
          }
        }
      }

      throw ParserError.unexpected_eof (walker.last);
    }

    private void walk_arglist (Walker? walker, Space? space)
      throws GLib.Error
    {
      unowned Token? token;
      bool first = true;

      while (!walker.is_empty)
      {
        if (!first) walker.pop_separator (",");
        unowned var type = walker.pop_identifier ();
        unowned var name = walker.pop_identifier ();

        if (types.lookup (type.value) == null)
        {
          var locate = ParserError.locate (type);
          var message = @"Unknown type '$(type.value)'";
          throw new ParserError.UNKNOWN_TYPE (message);
        }

        var id = uniques.next ();
        var arg = new Ast.Variable (id, type.value);
          annotate_variable (arg, name, walker.source);
          space.insert (name.value, arg);
          first = false;
      }
    }

    private void walk_condblock (Walker? walker, Space? space)
      throws GLib.Error
    {
      if (walker.check_separator ("{"))
      {
        var sep = walker.pop_separator ("{");
        var flags = ScopeFlags.INNER | ScopeFlags.STOPS;
        walk_scope (walker, space, flags, sep);
      }
      else
      {
        var queue = walker.collect (";", true);
        var walker2 = Walker ();
          walker2.tokens = queue;
          walker2.source = walker.source;
          walker2.last = queue.peek_tail ();
          walker2.scanning = walker.scanning;

        var flags = ScopeFlags.INNER;
        walk_scope (walker2, space, flags);
      }
    }

    private void walk_conditional (Walker? walker, Space? space, Token? begin)
      throws GLib.Error
    {
      unowned var sep = walker.pop_separator ("(");

      var queue = walker.collect (")");
      var walker2 = Walker ();
        walker2.tokens = queue;
        walker2.source = walker.source;
        walker2.last = queue.peek_tail ();
        walker2.scanning = walker.scanning;
      var rvalue = parse_rvalue (walker2, space, sep);
      var n_cond = @"$(begin.value)@($(begin.line).$(begin.column))";
      var n_direct = @"direct@($(begin.line).$(begin.column))";
      var n_reverse = @"reverse@($(begin.line).$(begin.column))";

      switch (begin.value)
      {
      default:
        error ("Fix this! (%s)", begin.value);
      case "if":
        {
          var direct = new Scope ();
          var reverse = new Scope ();

          var cond = new Ifelse (rvalue, direct, reverse);
            space.insert (n_cond, cond);
          var s_direct = space.insert (n_direct, direct);
            ((Scope) space.node).remove (direct);
          var s_reverse = space.insert (n_reverse, reverse);
            ((Scope) space.node).remove (reverse);

          walk_condblock (walker, s_direct);
          if (walker.check_keyword ("else"))
          {
            var next = walker.pop ();
            walk_condblock (walker, s_reverse);
          }
        }
        break;
      case "while":
        {
          var direct = new Scope ();

          var cond = new While (rvalue, direct);
            space.insert (n_cond, cond);
          var s_direct = space.insert (n_direct, direct);
            ((Scope) space.node).remove (direct);

          walk_condblock (walker, s_direct);
        }
        break;
      }
    }

    private bool check_declaration (Walker? walker, Space? space, Modifiers mods, Token? token)
      throws GLib.Error
    {
      unowned Space? last = null;
      if ((last = space.lookup_local (token.value)) != null)
      {
        if (walker.scanning == true || !(Modifiers.GLOBAL in mods))
        {
          var locate = ParserError.locate (token);
          var message = (string?) null;

          if (last.node is Ast.Variable)
            message = @"$(locate): Variable '$(token.value)' already defined";
          else
          if (last.node is Ast.Function)
            message = @"$(locate): Redefining function '$(token.value)'";
          else
          if (last.node is Ast.Scope)
            message = @"$(locate): Variable '$(token.value)' obscures a named scope";
          else
            error (@"node is '$(Type.from_instance (last.node).name ())', fix this!");
          throw new ParserError.INVALID (message);
        }

        return true;
      }
    return false;
    }

    private void walk_declaration (Walker? walker, Space? space, Modifiers mods, Token? begin)
      throws GLib.Error
    {
      unowned var type = begin;
      unowned var name = walker.pop_identifier ();
      unowned var sep = walker.pop_separator ();

      if (types.lookup (type.value) == null)
      {
        var locate = ParserError.locate (type);
        var message = @"Unknown type '$(type.value)'";
        throw new ParserError.UNKNOWN_TYPE (message);
      }

      {
        unowned var t = sep.value;
        unowned var c = t.get_char ();
        unowned var n = t.next_char ();

        if (n.get_char () != (unichar) 0)
          throw ParserError.unexpected_token (sep);
        else
        {
          switch (c)
          {
          case (unichar) '(': /* function */
            {
              var n_args = @"$(name.value)@args";
              var n_body = @"$(name.value)@body";
              var queue = walker.collect (")");
              unowned var sep2 = walker.pop_separator ();
              unowned var n_func = name.value;

              if (walker.scanning == true
                || !check_declaration (walker, space, mods, name))
              {
                var args = new Ast.List<IVariable> ();
                var id = uniques.next ();

                switch (sep2.value)
                {
                case ";":
                  {
                    var func = new Function (id, type.value, args);
                    unowned var a_func = space.insert (n_func, func);
                    unowned var a_args = space.insert (n_args, args);
                      ((Ast.Scope) space.node).remove (args);
                      annotate_variable (func, name, walker.source);
                      annotate_static (func, Modifiers.STATIC in mods);
                  }
                  break;
                case "{":
                  {
                    var body = new Ast.Scope ();
                    var func = new ConcreteFunction (id, type.value, args, body);
                    unowned var a_func = space.insert (n_func, func);
                    unowned var a_args = space.insert (n_args, args);
                      ((Ast.Scope) space.node).remove (args);
                    unowned var a_body = space.insert (n_body, body);
                      ((Ast.Scope) space.node).remove (body);
                      annotate_variable (func, name, walker.source);
                      annotate_static (func, Modifiers.STATIC in mods);
                    if (walker.scanning == true)
                      skip_function (walker, sep2);
                  }
                  break;
                default:
                  throw ParserError.unexpected_token (sep2);
                }
              }

              if (walker.scanning == false)
              {
                unowned var a_func = space.lookup (n_func);
                unowned var a_args = space.lookup (n_args);
                unowned var a_body = space.lookup (n_body);
                assert (a_func != null || a_args != null);

                var walker2 = Walker ();
                  walker2.tokens = queue;
                  walker2.source = walker.source;
                  walker2.last = queue.peek_tail ();
                  walker2.scanning = walker.scanning;
                  walk_arglist (walker2, a_args);
                ((Function) a_func.node).gen_typename ();
                if (a_body == null)
                  assert (a_func.node is Function);
                else
                {
                  var args = (Ast.List<IVariable>) a_args.node;
                  foreach (unowned var arg in args)
                  {
                    var qid = Ast.Node.Annotations.name;
                    var name2 = arg.get_qnote (qid);
                      a_body.insert (name2, arg);
                  }

                  assert (a_func.node is ConcreteFunction);
                  var flags = ScopeFlags.INNER | ScopeFlags.STOPS;
                  walk_scope (walker, a_body, flags, sep2);
                }
              }
            }
            break;
          case (unichar) '=': /* initialized variable */
          case (unichar) ';': /* uninitialized variable */
            {
              Queue<unowned Token?> queue;
              Ast.Node node = null;

              if (c == (unichar) '=')
                queue = walker.collect (";");
              else
                queue = new Queue<unowned Token?> ();

              if (!check_declaration (walker, space, mods, name))
              {
                var co = Modifiers.CONSTANT in mods;
                var rvalue = (Ast.IRValue?) null;
                var id = uniques.next ();

                if (queue.length > 0)
                {
                  if (co == true)
                  {
                    var location = ParserError.locate (name);
                    var message = @"$(location): Global constant left uninitialized";
                    throw new ParserError.INVALID (message);
                  }

                  var walker2 = Walker ();
                    walker2.tokens = queue;
                    walker2.source = walker.source;
                    walker2.last = queue.peek_tail ();
                    walker2.scanning = walker.scanning;
                    rvalue = parse_rvalue (walker2, space, sep);
                }

                if (Modifiers.GLOBAL in mods)
                {
                  node = new Ast.Global (id, type.value, co, rvalue);
                  space.push (name.value, node);
                }
                else
                {
                  assert (co == false);
                  node = new Ast.Variable (id, type.value);
                  space.push (name.value, node);

                  if (rvalue != null)
                  {
                    var decl = (Variable) node;
                    var init = new Ast.Assign (decl, rvalue);
                    ((Scope) space.node).append (init);
                  }
                }

                annotate_variable (node, name, walker.source);
                annotate_static (node, Modifiers.STATIC in mods);
              }
            }
            break;
          default:
            throw ParserError.unexpected_token (sep);
          }
        }
      }
    }

    private void walk_identifier (Walker? walker, Space? space, Token? begin)
      throws GLib.Error
    {
      unowned Token? token;
      if ((token = walker.peek ()) == null)
        throw ParserError.unexpected_eof (walker.last);
      else
      {
        unowned var type = token.type;
        unowned var value = token.value;

        switch (type)
        {
          case TokenType.IDENTIFIER:
            walk_declaration (walker, space, Modifiers.NONE, begin);
            break;
          case TokenType.SEPARATOR:
            {
              unowned var c = value.get_char ();
              unowned var n = value.next_char ();
              if (n.get_char () != (unichar) 0)
                throw ParserError.unexpected_token (token);
              else
              {
                switch (c)
                {
                case (unichar) '=':
                case (unichar) '(':
                  {
                    var queue = walker.collect (";");
                    var node = (Ast.Node?) null;
                    var walker2 = Walker ();
                      walker2.tokens = queue;
                      walker2.source = walker.source;
                      walker2.last = queue.peek_tail ();
                      walker2.scanning = walker.scanning;
                      queue.push_head (begin);

                    if (c == (unichar) '=')
                      node = parse_assign (walker2, space);
                    else
                      node = parse_invoke (walker2, space);

                      assert (space.node is Scope);
                    ((Scope) space.node).append (node);
                  }
                  break;
                default:
                  throw ParserError.unexpected_token (token);
                }
              }
            }
            break;
          default:
            throw ParserError.unexpected_token (token);
        }
      }
    }

    private void walk_namespace (Walker? walker, Space? space, Token? begin)
      throws GLib.Error
    {
      unowned var name = walker.pop_identifier ();
      unowned var sep = walker.pop_separator ("{");
      unowned var down = space.lookup (name.value);

      if (down == null)
      {
        down = space.push (name.value, new Ast.Scope ());
      }

        walk_scope (walker, down, ScopeFlags.STOPS, sep);
    }

    private void walk_return (Walker? walker, Space? space, Token? token)
      throws GLib.Error
    {
      var queue = walker.collect (";");
      var rvalue = (IRValue?) null;

      if (queue.length > 0)
      {
        var walker2 = Walker ();
          walker2.tokens = queue;
          walker2.source = walker.source;
          walker2.last = queue.peek_tail ();
          walker2.scanning = walker.scanning;
          rvalue = parse_rvalue (walker2, space, token);
      }

      var node = new Ast.Return (rvalue);
      ((Ast.Scope) space.node).append (node);
      annotate_location (node, token, walker.source);
    }

    private void walk_scope (Walker? walker, Space? space, ScopeFlags flg, Token? begin = null)
      throws GLib.Error
    {
      unowned Modifiers mods = 0;
      unowned uint inners = 0;
      unowned Token? token;

      while ((token = walker.pop ()) != null)
      {
        unowned var type = token.type;
        unowned var value = token.value;

        switch (type)
        {
        case TokenType.IDENTIFIER:
          if (ScopeFlags.INNER in flg)
            walk_identifier (walker, space, token);
          else
          {
            walk_declaration (walker, space, mods | Modifiers.GLOBAL, token);
              mods = Modifiers.NONE;
          }
          break;
        case TokenType.KEYWORD:
          {
            switch (value)
            {
            case "const":
              if (ScopeFlags.INNER in flg)
                throw ParserError.unexpected_token (token);
              else
              {
                if (!walker.check_identifier ())
                  throw ParserError.unexpected_token (token);
                else
                {
                  if (Modifiers.CONSTANT in mods)
                    throw ParserError.unexpected_token (token);
                  else
                    mods |= Modifiers.CONSTANT;
                }
              }
              break;
            case "if":
              if (! (ScopeFlags.INNER in flg))
                throw ParserError.unexpected_token (token);
              else
                walk_conditional (walker, space, token);
              break;
            case "namespace":
              if (ScopeFlags.INNER in flg)
                throw ParserError.unexpected_token (token);
              else
                walk_namespace (walker, space, token);
              break;
            case "return":
              if (! (ScopeFlags.INNER in flg))
                throw ParserError.unexpected_token (token);
              else
                walk_return (walker, space, token);
              break;
            case "static":
              if (ScopeFlags.INNER in flg)
                throw ParserError.unexpected_token (token);
              else
              {
                if (!walker.check_identifier () && !walker.check_keyword ("const"))
                  throw ParserError.unexpected_token (token);
                else
                {
                  if (Modifiers.STATIC in mods || Modifiers.CONSTANT in mods)
                    throw ParserError.unexpected_token (token);
                  else
                    mods |= Modifiers.STATIC;
                }
              }
              break;
            default:
              throw ParserError.unexpected_token (token);
            }
          }
          break;
        case TokenType.SEPARATOR:
          {
            unowned var c = value.get_char ();
            unowned var n = value.next_char ();
            if (n.get_char () != (unichar) 0)
              throw ParserError.unexpected_token (token);
            else
            {
              switch (c)
              {
              case (unichar) '{':
                if (! (ScopeFlags.INNER in flg))
                  throw ParserError.unexpected_token (token);
                else
                {
                  var down = space.insert (@"inners@$(++inners)", new Ast.Scope ());
                  walk_scope (walker, down, flg | ScopeFlags.STOPS, token);
                }
                break;
              case (unichar) '}':
                if (ScopeFlags.STOPS in flg)
                  return;
                else
                  throw ParserError.unexpected_token (token);
                break;
              default:
                throw ParserError.unexpected_token (token);
              }
            }
          }
          break;
        default:
          throw ParserError.unexpected_token (token);
        }
      }

      if (ScopeFlags.STOPS in flg)
      {
        unowned var last = walker.last;
        unowned var source = walker.source;
        var locate1 = ParserError.locate (last);
        var locate2 = ParserError.locate (begin);
        var message = @"$(locate1): Missing '{' token to close scope at $(locate2)";
        throw new ParserError.EXPECTED_TOKEN (message);
      }
    }

    /* public API */

    public void walk (Tokens tokens_, string source, bool scanning)
      throws GLib.Error
    {
      var walker = Walker ();
      var tokens = new Queue<unowned Token?> ();

      unowned var array = tokens_.tokens;
      for (int i = 0; i < array.length; i++)
      {
        unowned var ar = & array [i];
        if (ar.type != TokenType.COMMENT)
          tokens.push_tail (*ar);
      }

        walker.tokens = tokens;
        walker.source = source;
        walker.last = tokens.peek_tail ();
        walker.scanning = scanning;

      try
      {
        walk_scope (walker, global, ScopeFlags.NONE);
      }
      catch (ParserError e)
      {
        var r = (Error) e;
        prefix_error (ref r, @"$(source): ");
          throw r;
      }
    }

    /* constructors */

    construct
    {
      global = new Space ();
      uniques = Uniques ();
    }

    public Parser (Types.Table types)
    {
      Object (types : types);
    }
  }
}
