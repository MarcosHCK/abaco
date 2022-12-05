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

namespace Abaco
{
  internal struct Walker
  {
    public unowned Queue<unowned Token?> tokens;
    public unowned string source;
    public unowned Token? last;
    public bool scanning;

    public bool is_empty
    {
      get
      {
        return tokens.length == 0;
      }
    }

    /* public API */

    public unowned void push (Token? token) { tokens.push_head (token); }
    public unowned Token? peek () { return tokens.peek_head (); }
    public unowned Token? pop () { return tokens.pop_head (); }

    public bool check_identifier ()
    {
      unowned var next = peek ();
      if (next == null)
        return false;
      else
      {
        var type = next.type;
        if (type != TokenType.IDENTIFIER)
          return false;
        else
          return true;
      }
    }

    public bool check_keyword (string? specific = null)
    {
      unowned var next = peek ();
      if (next == null)
        return false;
      else
      {
        var type = next.type;
        if (type != TokenType.KEYWORD)
          return false;
        else
        {
          if (specific == null)
            return true;
          else
          {
            if (specific != next.value)
              return false;
            else
              return true;
          }
        }
      }
    }

    public bool check_separator (string? specific = null)
    {
      unowned var next = peek ();
      if (next == null)
        return false;
      else
      {
        var type = next.type;
        if (type != TokenType.SEPARATOR)
          return false;
        else
        {
          if (specific == null)
            return true;
          else
          {
            if (specific != next.value)
              return false;
            else
              return true;
          }
        }
      }
    }

    public Queue<unowned Token?> collect (string terminator, bool addlast = false)
      throws GLib.Error
    {
      var queue = new Queue<unowned Token?> ();
      unowned Token? next;

      while (true)
      {
        if ((next = pop ()) == null)
        {
          throw ParserError.expected_token_eof (last, terminator);
        }

        if (next.type == TokenType.SEPARATOR
          && terminator == next.value)
        {
          if (addlast == true)
            queue.push_tail (next);
            break;
        }

        queue.push_tail (next);
      }
    return queue;
    }

    public unowned Token? pop_identifier ()
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last);
      else
      {
        var type = next.type;
        if (type != TokenType.IDENTIFIER)
          throw ParserError.expected_identifier (next);
        else
          return next;
      }
    }

    public unowned Token? pop_literal ()
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last);
      else
      {
        var type = next.type;
        if (type != TokenType.LITERAL)
          throw ParserError.expected_literal (next);
        else
          return next;
      }
    }

    public unowned Token? pop_separator (string? specific = null)
      throws GLib.Error
    {
      unowned var next = pop ();
      if (next == null)
        throw ParserError.unexpected_eof (last);
      else
      {
        var type = next.type;
        if (type != TokenType.SEPARATOR)
        {
          if (specific != null)
            throw ParserError.expected_token (next, specific);
          else
            throw ParserError.unexpected_token (next);
        }
        else
        {
          if (specific != null && next.value != specific)
            throw ParserError.expected_token (next, specific);
          else
            return next;
        }
      }
    }
  }
}
