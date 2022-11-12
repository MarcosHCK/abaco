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
    private Partial.Parser.Tree tree;

    /* private API */

    private void walk_namespace (Walk? state) throws GLib.Error
    {
      unowned var name = fetch_identifier (state);
      unowned var open = fetch_separator (state, "{");

      state.scopeflg.push_head (ScopeFlags.namespace);
      state.prefixes.push_tail (name.value);

      walk_scope (state, state.prefix ());

      state.prefixes.pop_tail ();
      state.scopeflg.pop_head ();
    }

    private void walk_scope (Walk? state, string name) throws GLib.Error
    {
      unowned var flags = state.scopeflg.peek_head ();
      unowned var source = state.source;
      unowned var token = (Token?) null;
      unowned var scope = (Scope?) null;

      if ((scope = (Scope) tree.lookup (name)) == null)
      {
        var down = new Scope ();
      assert (tree.insert (name, down));
          scope = down;
      }

      while ((token = state.tokens.pop_tail ()) != null)
      {
        unowned var type = token.type;
        unowned var value = token.value;

        switch (type)
        {
        case TokenType.KEYWORD:
          {
            switch (value)
            {
            default:
              {
                if (ScopeFlags.INNER in flags)
                {
                  switch (value)
                  {
                  default:
                    throw ParserError.unexpected_token (token, state.source);
                  }
                }
                else
                {
                  switch (value)
                  {
                  case "namespace":
                    walk_namespace (state);
                    break;
                  default:
                    throw ParserError.unexpected_token (token, state.source);
                  }
                }
              }
              break;
            }
          }
          break;
        case TokenType.SEPARATOR:
          {
            unowned var c = value.get_char ();
            unowned var n = value.next_char ();
            if (n.get_char () != (unichar) 0)
              throw ParserError.unexpected_token (token, state.source);
            else
            {
              switch (c)
              {
              case (unichar) '}':
                {
                  if (ScopeFlags.STOPS in flags)
                    return;
                  else
                    throw ParserError.unexpected_token (token, state.source);
                }
              default:
                throw ParserError.unexpected_token (token, state.source);
              }
            }
          }
          break;
        default:
          throw ParserError.unexpected_token (token, state.source);
        }
      }

      if (ScopeFlags.STOPS in flags)
      {
        throw ParserError.unexpected_eof (state.lasttoken, state.source);
      }
    }

    /* public API */

    public void walk (Tokens tokens_, string source, bool scanning) throws GLib.Error
    {
      var state = Walk ();
      var tokens = new Queue<unowned Token?> ();
      var scopeflg = new Queue<ScopeFlags> ();
      var prefixes = new Queue<unowned string> ();

      unowned var array = tokens_.tokens;
      for (int i = 0; i < array.length; i++)
      {
        unowned var ar = & array [i];
        if (ar.type != TokenType.COMMENT)
          tokens.push_head (*ar);
      }

      state.tokens = tokens;
      state.scopeflg = scopeflg;
      state.prefixes = prefixes;
      state.source = source;
      state.lasttoken = tokens.peek_head ();
      state.scanning = scanning;

      scopeflg.push_head (ScopeFlags.global);
      walk_scope (state, "");
    }

    /* constructors */

    public Parser ()
    {
      tree = new Partial.Parser.Tree (new Scope ());
      uniques = UniqueCount (0);
    }
  }
}
