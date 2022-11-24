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
using Abaco.Partial.Parser;

namespace Abaco
{
  internal class Parser : GLib.Object
  {
    private UniqueCount uniques;

    [Flags]
    enum ScopeFlags
    {
      NONE = 0,
      INNER = (1 << 1),
      STOPS = (1 << 2),
    }

    /* private API */

    private void walk_namespace (Walker? walker, Token? begin)
      throws GLib.Error
    {
      unowned var name = walker.pop_identifier ();
      unowned var sep = walker.pop_separator ("{");
      walk_scope (walker, ScopeFlags.STOPS, sep);
    }

    private void walk_scope (Walker? walker, ScopeFlags flg, Token? begin = null)
      throws GLib.Error
    {
      unowned Token? token;
      while ((token = walker.pop ()) != null)
      {
        unowned var type = token.type;
        unowned var value = token.value;

        switch (type)
        {
        case TokenType.IDENTIFIER:
          if (! (ScopeFlags.INNER in flg))
            throw ParserError.unexpected_token (token, walker.source);
          else
          {
            assert_not_reached ();
          }
          break;
        case TokenType.KEYWORD:
          {
            switch (value)
            {
            case "namespace":
              if (ScopeFlags.INNER in flg)
                throw ParserError.unexpected_token (token, walker.source);
              else
                walk_namespace (walker, token);
              break;
            default:
              throw ParserError.unexpected_token (token, walker.source);
            }
          }
          break;
        case TokenType.SEPARATOR:
          {
            unowned var c = value.get_char ();
            unowned var n = value.next_char ();
            if (n.get_char () != (unichar) 0)
              throw ParserError.unexpected_token (token, walker.source);
            else
            {
              switch (c)
              {
              case (unichar) '}':
                if (ScopeFlags.STOPS in flg)
                  return;
                else
                {
                  throw ParserError.unexpected_token (token, walker.source);
                }
                break;
              default:
                throw ParserError.unexpected_token (token, walker.source);
              }
            }
          }
          break;
        default:
          throw ParserError.unexpected_token (token, walker.source);
        }
      }

      if (ScopeFlags.STOPS in flg)
      {
        unowned var last = walker.last;
        unowned var source = walker.source;
        var locate1 = ParserError.locate (last, source);
        var locate2 = ParserError.locate_no_source (begin);
        var message = @"$(locate1): Missing '{' token to close scope at $(locate2)";
        throw new ParserError.EXPECTED_TOKEN (message);
      }
    }

    /* public API */

    public void walk (Tokens tokens_, string source, bool scanning) throws GLib.Error
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

        walk_scope (walker, ScopeFlags.NONE);
    }

    /* constructors */

    public Parser ()
    {
      uniques = UniqueCount (0);
    }
  }
}
