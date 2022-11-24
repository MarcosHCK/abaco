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

namespace Abaco.Parse
{
  private static unowned T lookup_variable<T> (Token? token, Space? space)
    throws GLib.Error
  {
    unowned var name = token.value;
    unowned var resl = (T?) null;
    unowned Space? down;

    if ((down = space.lookup (name)) != null)
      assert (down.node is T);
    else
    {
      var locate = ParserError.locate (token);
      var message = @"$(locate): Unknown symbol '$(name)'";
      throw new ParserError.INVALID (message);
    }
  return (T) down.node;
  }

  internal static IRValue parse_assign (Walker? walker, Space? space)
    throws GLib.Error
  {
    unowned var name = walker.pop_identifier ();
    unowned var sep = walker.pop_separator ("=");
    unowned var target = lookup_variable<Variable> (name, space);
      var rvalue = parse_rvalue (walker, space);
      var assign = new Ast.Assign (target, rvalue);
      annotate_location (assign, name, walker.source);
  return assign;
  }

  internal static IRValue parse_invoke (Walker? walker, Space? space)
    throws GLib.Error
  {
    unowned var name = walker.pop_identifier ();
    unowned var sep = walker.pop_separator ("(");
    unowned var target = lookup_variable<Function> (name, space);
    unowned var token = (Token?) null;
    unowned var lastp = (Token?) null;
      var list = new Ast.List<IRValue> ();
      var queue = new Queue<unowned Token?> ();
      var balance = (int) 0;

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
          case (unichar) ',':
            if (balance == 0)
            {
              var walker2 = Walker ();
                walker2.tokens = queue;
                walker2.source = walker.source;
                walker2.last = queue.peek_tail ();
                walker2.scanning = walker.scanning;
              var rvalue = parse_rvalue (walker2, space);
                list.append ((owned) rvalue);
                queue.clear ();
            }
            break;
          case (unichar) '(':
            lastp = token;
            ++balance;
            break;
          case (unichar) ')':
            --balance;
            if (balance == -1)
            {
              if (!walker.is_empty)
              {
                var locate = ParserError.locate (token);
                var message = @"$(locate): Unbalanced ')'";
                throw new ParserError.INVALID (message);
              }
              else
              {

                var walker2 = Walker ();
                  walker2.tokens = queue;
                  walker2.source = walker.source;
                  walker2.last = queue.peek_tail ();
                  walker2.scanning = walker.scanning;
                var rvalue = parse_rvalue (walker2, space);
                  list.append ((owned) rvalue);
                  queue.clear ();
                var call = new Ast.Invoke (target, list);
                  annotate_location (call, name, walker.source);
                  return call;
              }
            }
            break;
          }
        }
      }

      queue.push_tail (token);
    }

    if (balance > 0)
    {
      var locate = ParserError.locate (token);
      var message = @"$(locate): Unbalanced '('";
      throw new ParserError.INVALID (message);
    }

    assert_not_reached ();
  }

  private static void guardvar (Token? token, Token? last)
    throws GLib.Error
  {
  }

  private static void pushcall (Queue<IRValue> rvalues, Operator? op, Token? token, string? source)
    throws GLib.Error
  {
    var args = new Ast.List<IRValue> ();
    var oper = (Ast.Operation?) null;
    var rvalue = (IRValue?) null;
    int i, nargs = op.is_unary ? 1 : 2;

    for (i = 0; i < nargs; ++i)
    {
      rvalue = rvalues.pop_head ();
      args.prepend ((owned) rvalue);
    }

    oper = new Operation (token.value, args);
    annotate_location (oper, token, source);
    rvalues.push_head ((owned) oper);
  }

  private static void pushvar (Queue<IRValue> rvalues, Space? space, Token? token)
    throws GLib.Error
  {
    unowned var val = lookup_variable<Variable> (token, space);
    if (val != null)
      rvalues.push_head (val);
    else
    {
      var location = ParserError.locate (token);
      var message = @"Undefined variable '$(token.value)'";
      throw new ParserError.FAILED (message);
    }
  }

  internal static IRValue parse_rvalue (Walker? walker, Space? space, bool embedded = false)
    throws GLib.Error
  {
    var rvalues = new Queue<IRValue> ();
    var operators = new Queue<unowned Token?> ();
    var rvalue = (IRValue?) null;
    unowned Token? token = null;
    unowned Token? last = null;

    while ((token = walker.pop ()) != null)
    {
      unowned var type = token.type;
      unowned var value = token.value;

      if (last != null)
      {
        guardvar (token, last);
      }

      switch (type)
      {
      case TokenType.IDENTIFIER:
        {
          unowned Token? next = walker.peek ();

          if (next == null)
            pushvar (rvalues, space, token);
          else
          {
            switch (next.type)
            {
            case TokenType.SEPARATOR:
              {
                unowned var t = next.value;
                unowned var c = t.get_char ();
                unowned var n = t.next_char ();

                if (n.get_char () != (unichar) 0)
                  throw ParserError.unexpected_token (token);
                else
                {
                  switch (c)
                  {
                  case (unichar) '(':
                    {
                      walker.pop ();
                      var queue = walker.collect (")");
                      var walker2 = Walker ();
                        walker2.tokens = queue;
                        walker2.source = walker.source;
                        walker2.last = queue.peek_tail ();
                        walker2.scanning = walker.scanning;
                        rvalue = parse_invoke (walker2, space);
                        rvalues.push_head (rvalue);
                    }
                    break;
                  case (unichar) ')':
                    {
                      if (last.type != TokenType.SEPARATOR
                        || last.value != "(")
                        pushvar (rvalues, space, token);
                      else
                      {
                        unowned var sep2 = walker.pop ();
                        unowned var sep1 = operators.pop_head ();
                        assert (sep1.type == TokenType.SEPARATOR);

                        rvalue = parse_rvalue (walker, space, true);
                        rvalue = new Ast.Cast (value, rvalue);
                        annotate_location (rvalue, token, walker.source);
                        rvalues.push_head (rvalue);
                      }
                    }
                    break;
                  case (unichar) '=':
                    {
                      walker.pop ();
                      rvalue = parse_rvalue (walker, space, true);
                      rvalues.push_head (rvalue);
                    }
                    break;
                  default:
                    throw ParserError.unexpected_token (token);
                  }
                }
              }
              break;
            default:
              pushvar (rvalues, space, token);
              break;
            }
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
            case (unichar) '(':
              operators.push_head (token);
              break;
            case (unichar) ')':
              {
                unowned var o2 = (Token?) null;
                unowned var op2 = (Operator?) null;

                while (true)
                {
                  o2 = operators.peek_head ();
                  if (o2 == null)
                  {
                    var location = ParserError.locate (token);
                    var message = @"$(location): Unbalanced '$(c)'";
                    throw new ParserError.FAILED (message);
                  }
                  else
                  {
                    if (o2.type == TokenType.SEPARATOR)
                      operators.pop_head ();
                    else
                    {
                      op2 = Operators.lookup (o2.value);
                      pushcall (rvalues, op2, o2, walker.source);
                      operators.pop_head ();
                      continue;
                    }
                  }

                  break;
                }
              }
              break;
            default:
              throw ParserError.unexpected_token (token);
            }
          }
        }
        break;
      case TokenType.OPERATOR:
        {
          unowned var o1 = (Token?) token;
          unowned var o2 = (Token?) null;
          unowned var op1 = Operators.lookup (o1.value);
          unowned var op2 = (Operator?) null;

          while (true)
          {
            o2 = operators.peek_head ();
            if (o2 != null && o2.type == TokenType.OPERATOR)
            {
              op2 = Operators.lookup (o2.value);
              if ((op2.precedence > op1.precedence)
                || ((op1.precedence == op2.precedence)
                  && (op1.assoc == Assoc.LEFT)))
              {
                pushcall (rvalues, op2, o2, walker.source);
                operators.pop_head ();
                continue;
              }
            }

            break;
          }

          operators.push_head (token);
        }
        break;
      case TokenType.LITERAL:
        {
          var node = new Constant (value);
          annotate_location (node, token, walker.source);
          rvalues.push_head (node);
        }
        break;
      default:
        throw ParserError.unexpected_token (token);
      }

      last = token;

      if (embedded == true 
        && operators.length == 0
        && rvalues.length == 1)
      {
        return rvalues.pop_head ();
      }
    }

    while ((token = operators.pop_head ()) != null)
    {
      unowned var o2 = (Token?) null;
      unowned var op2 = (Operator?) null;

      if (token.type == TokenType.SEPARATOR)
      {
        var location = ParserError.locate (token);
        var message = @"$(location): Unbalanced '$(token.value)'";
        throw new ParserError.FAILED (message);
      }
      else
      {
        o2 = token;
        op2 = Operators.lookup (o2.value);
        pushcall (rvalues, op2, o2, walker.source);
      }
    }

    assert (rvalues.length != 0);

    if (rvalues.length > 1)
    {
      var node = rvalues.pop_nth (1);
      var locate = ParserError.locate2 (node);
      var message = @"$(locate): Unexpected rvalue";
      throw new ParserError.FAILED (message);
    }
  return rvalues.pop_tail ();
  }
}
