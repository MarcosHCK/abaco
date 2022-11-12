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
  internal struct Walk
  {
    public unowned Queue<unowned Token?> tokens;
    public unowned Queue<ScopeFlags> scopeflg;
    public unowned Queue<unowned string> prefixes;
    public unowned Token? lasttoken;
    public unowned string source;
    public bool scanning;

    /* public API */

    public string prefix_name (string name)
    {
      var fullname = (string?) null;
      var prefix = this.prefix ();
      if (prefix [0] != '0')
        return prefix + "." + name;
      else
        return name;
    }

    public string prefix ()
    {
      var result = "";
      unowned var first = true;
      unowned var list = prefixes.head;
      foreach (unowned var pr in list)
      {
        if (!first)
          result += "." + pr;
        else
        {
          first = false;
          result += pr;
        }
      }
    return result;
    }
  }

  internal static unowned Token? fetch_identifier (Walk? state) throws GLib.Error
  {
    unowned var next = state.tokens.pop_tail ();
    if (next == null)
      throw ParserError.unexpected_eof (state.lasttoken, state.source);
    else
    {
      var type = next.type;
      if (type != TokenType.IDENTIFIER)
        throw ParserError.expected_identifier (next, state.source);
      else
        return next;
    }
  }

  internal static unowned Token? fetch_separator (Walk? state, string? specific = null) throws GLib.Error
  {
    unowned var next = state.tokens.pop_tail ();
    if (next == null)
      throw ParserError.unexpected_eof (state.lasttoken, state.source);
    else
    {
      var type = next.type;
      if (type != TokenType.SEPARATOR)
      {
        if (specific == null)
          throw ParserError.unexpected_token (next, state.source);
        else
          throw ParserError.expected_token (next, state.source, specific);
      }
      else
      {
        if (specific == null)
          return next;
        else
        {
          unowned var value = next.value;
          if (value != specific)
            throw ParserError.expected_token (next, state.source, specific);
          else
            return next;
        }
      }
    }
  }

  internal static unowned Token? fetch_literal (Walk? state) throws GLib.Error
  {
    unowned var next = state.tokens.pop_tail ();
    if (next == null)
      throw ParserError.unexpected_eof (state.lasttoken, state.source);
    else
    {
      var type = next.type;
      if (type != TokenType.LITERAL)
        throw ParserError.expected_rvalue (next, state.source);
      else
        return next;
    }
  }
}
