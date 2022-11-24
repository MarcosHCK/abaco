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
  internal struct Walker
  {
    public unowned Queue<unowned Token?> tokens;
    public unowned string source;
    public unowned Token? last;
    public bool scanning;

    /* public API */

    public unowned Token? pop ()
      throws GLib.Error
    {
      return tokens.pop_head ();
    }

    public unowned Token? pop_identifier ()
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last, source);
      else
      {
        var type = next.type;
        if (type != TokenType.IDENTIFIER)
          throw ParserError.expected_identifier (next, source);
        else
          return next;
      }
    }

    public unowned Token? pop_literal ()
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last, source);
      else
      {
        var type = next.type;
        if (type != TokenType.LITERAL)
          throw ParserError.expected_literal (next, source);
        else
          return next;
      }
    }

    public unowned Token? pop_separator (string specific = "")
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last, source);
      else
      {
        var type = next.type;
        if (type != TokenType.SEPARATOR)
        {
          if (specific != "")
            throw ParserError.expected_token (next, source, specific);
          else
            throw ParserError.unexpected_token (next, source);
        }
        else
        {
          if (specific != "" && next.value != specific)
            throw ParserError.expected_token (next, source, specific);
          else
            return next;
        }
      }
    }
  }
}
