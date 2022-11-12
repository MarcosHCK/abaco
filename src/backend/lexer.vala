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
  public errordomain LexerError
  {
    FAILED,
    UNKNOWN_TOKEN,
    UNFINISHED_COMMENT,
  }

  internal class Lexer : GLib.Object
  {
    private static TokenClass[] classes;
    private GLib.StringChunk chunk;
    const string OPERATORS1 = "\\+\\-\\*/";
    const string OPERATORS2 = "&\\^\\|~<>#";
    const string OPERATORS_S = "[" + OPERATORS1 + OPERATORS2 + "]";
    const string OPERATORS3 = "\\+=|\\-=|\\*=|/=|\\*\\*";
    const string OPERATORS4 = "&=|^=|\\|=";
    const string OPERATORS5 = "<<|>>|<<=|>>=";
    const string OPERATORS6 = "==|~=|<=|>=";
    const string OPERATORS7 = "&&|\\|\\||\\^\\^";
    const string OPERATORS_D1 = OPERATORS3 + "|" + OPERATORS4;
    const string OPERATORS_D2 = OPERATORS5 + "|" + OPERATORS6;
    const string OPERATORS_D3 = OPERATORS7;
    const string OPERATORS_D_1 = OPERATORS_D1 + "|" + OPERATORS_D2;
    const string OPERATORS_D_2 = OPERATORS_D3;
    const string OPERATORS_D = "(" + OPERATORS_D_1 + "|" + OPERATORS_D_2 + ")";

    /* private API */

    private static bool is_empty (string token, size_t length)
    {
      unowned var ptr = token;
      unowned var left = token.char_count ((ssize_t) length);

      while (left-- > 0)
      {
        if (ptr.get_char () != (unichar) ' ')
          return false;
        ptr = ptr.next_char ();
      }
    return true;
    }

    private unowned string prepare (string token, size_t length)
    {
      unowned var ptr = token;
      unowned var left = token.char_count ((ssize_t) length);
      size_t tailing = 0;
      bool tail = false;

      while (left-- > 0)
      {
        switch (ptr.get_char ())
        {
          case 0:
            assert_not_reached ();
          case ' ':
            if (tail)
              ++tailing;
            else
            {
              token = token.next_char ();
              --length;
            }
            break;
          default:
            if (tail)
              tailing = 0;
            else
              tail = true;
            break;
        }

        ptr = ptr.next_char ();
      }
    return chunk.insert_len (token, (ssize_t) (length - tailing));
    }

    private int breakdown (Array<Token> tokens, string input, size_t length, uint line, uint column, TokenClass klass, MatchInfo info) throws GLib.Error
    {
      int start, stop, last = 0;
      int added = 0;

      while (info.matches ())
      {
        info.fetch_pos (0, out start, out stop);

        if (start > last)
        {      
          added += search (tokens, input.offset (last), start - last, line, column + last);
        }

        {
          var token = Token ();
          unowned var begin = input.offset (start);
          unowned var value = prepare (begin, stop - start);
          unowned var colff = column + start;

            token.type = klass.type;
            token.value = value;
            token.line = line;
            token.column = colff;

          tokens.append_val (token);      
          ++added;
        }

        info.next ();
        last = stop;
      }

      if (length > last)
      {    
        added += search (tokens, input.offset (last), length - last, line, column + last);
      }
    return added;
    }

    private int search (Array<Token> tokens, string input, size_t length, uint line, uint column) throws GLib.Error
    {
      unowned var klass = (TokenClass) null;
      unowned var rexp = (GLib.Regex) null;
      var info = (MatchInfo?) null;
      var added = (int) 0;

      for (int i = 0; i < classes.length; ++i)
      {
        klass = classes [i];
        rexp = klass.rexp;

        if (!rexp.match_full (input, (ssize_t) length, 0, 0, out info))
          continue;
        else
        {
          added += breakdown (tokens, input, length, line, column, klass, info);
          break;
        }
      }

      if (added == 0 && !is_empty (input, length))
      {
        throw new LexerError.UNKNOWN_TOKEN ("%u: %u: unknown token '%s'", line, column, prepare (input, length));
      }
    return added;
    }

    /* public API */

    public Tokens tokenize (GLib.DataInputStream stream, GLib.Cancellable? cancellable = null) throws GLib.Error
    {
      var partial = new StringBuilder.sized (256);
      var tokens = new Array<Token> ();
      var info = (MatchInfo?) null;
      var rexp = classes [0].rexp;
      var line = (string?) null;
      var linesz = (size_t) 0;
      var cbegin = (int) 1;
      var linen = (int) 1;

      while ((line = stream.read_line_utf8 (out linesz, cancellable)) != null)
      {
        if (partial.len > 0)
        {
          partial.append_len (line, (ssize_t) linesz);
          if (rexp.match_full (partial.str, partial.len, 0, GLib.RegexMatchFlags.PARTIAL_SOFT, out info))
          {
            breakdown (tokens, partial.str, partial.len, linen, 1, classes [0], info);
            partial.truncate (0);
          }
        }
        else
        {
          if (rexp.match_full (line, (ssize_t) linesz, 0, GLib.RegexMatchFlags.PARTIAL_SOFT, out info))
            breakdown (tokens, line, linesz, linen, 1, classes [0], info);
          else
          {
            if (info == null || !info.is_partial_match ())
              search (tokens, line, linesz, linen, 1);
            else
            {
              partial.append_len (line, (ssize_t) linesz);
              cbegin = linen;
            }
          }
        }
  
        ++linen;
      }
    return new Tokens (this, tokens);
    }

    /* constructors */

    public Lexer ()
    {
      chunk = new StringChunk (256);
    }

    class construct
    {
      classes =
      {
        new TokenClass ("/\\*(.*?)\\*/", TokenType.COMMENT),
        new TokenClass ("//(.*)", TokenType.COMMENT),
        new TokenClass ("\"(.*?)\"", TokenType.LITERAL),
        new TokenClass ("\'(.*?)\'", TokenType.LITERAL),
        new TokenClass ("[\\[\\](){}:;,=]", TokenType.SEPARATOR),
        new TokenClass ("operator" + OPERATORS_D, TokenType.IDENTIFIER),
        new TokenClass ("operator" + OPERATORS_S, TokenType.IDENTIFIER),
        new TokenClass (OPERATORS_D, TokenType.OPERATOR),
        new TokenClass (OPERATORS_S, TokenType.OPERATOR),
        new TokenClass.escaped ("if", TokenType.KEYWORD),
        new TokenClass.escaped ("else", TokenType.KEYWORD),
        new TokenClass.escaped ("do", TokenType.KEYWORD),
        new TokenClass.escaped ("for", TokenType.KEYWORD),
        new TokenClass.escaped ("while", TokenType.KEYWORD),
        new TokenClass.escaped ("return", TokenType.KEYWORD),
        new TokenClass.escaped ("using", TokenType.KEYWORD),
        new TokenClass.escaped ("const", TokenType.KEYWORD),
        new TokenClass.escaped ("static", TokenType.KEYWORD),
        new TokenClass.escaped ("template", TokenType.KEYWORD),
        new TokenClass.escaped ("typename", TokenType.KEYWORD),
        new TokenClass.escaped ("namespace", TokenType.KEYWORD),
        new TokenClass ("[a-zA-Z_][a-zA-Z_0-9]*", TokenType.IDENTIFIER),
        new TokenClass ("[0-9\\.][a-zA-Z_0-9\\.]*", TokenType.LITERAL),
      };
    }
  }
}
