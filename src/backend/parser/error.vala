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
  public errordomain ParserError
  {
    FAILED,
    UNEXPECTED_EOF,
    EXPECTED_TOKEN,
    UNEXPECTED_TOKEN,
    REDEFINED,
    EXPECTED,
    INVALID,
    UNKNOWN_TYPE;

    /* internal API */

    internal static string locate (Token? token)
    {
      return @"$(token.line): $(token.column)";
    }

    /* throwers API - simple */

    internal static ParserError unexpected_eof (Token? last)
    {
      return new ParserError.UNEXPECTED_EOF ("%s: Unexpected end of file", locate (last));
    }

    internal static ParserError unexpected_token (Token? token)
    {
      return new ParserError.UNEXPECTED_TOKEN ("%s: Unexpected token '%s'", locate (token), token.value);
    }

    internal static ParserError expected_identifier (Token? last)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected indentifier", locate (last));
    }

    internal static ParserError expected_literal (Token? last)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected literal", locate (last));
    }

    internal static ParserError expected_rvalue (Token? token)
    {
      return new ParserError.EXPECTED ("%s: Expected rvalue", locate (token));
    }

    internal static ParserError expected_token (Token? token, string value)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected '%s'", locate (token), value);
    }

    internal static ParserError expected_token_eof (Token? last, string value)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected '%s' before end of line", locate (last), value);
    }
  }
}
