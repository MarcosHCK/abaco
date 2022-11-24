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
    EXPECTED;

    /* internal API */

    internal static string locate (Token? token, string source)
    {
      return @"$(source): $(token.line): $(token.column)";
    }

    internal static string locate_no_source (Token? token)
    {
      return @"$(token.line): $(token.column)";
    }

    /* throwers API - simple */

    internal static ParserError unexpected_eof (Token? last, string source)
    {
      return new ParserError.UNEXPECTED_EOF ("%s: Unexpected end of file", locate (last, source));
    }

    internal static ParserError unexpected_token (Token? token, string source)
    {
      return new ParserError.UNEXPECTED_TOKEN ("%s: Unexpected token '%s'", locate (token, source), token.value);
    }

    internal static ParserError expected_identifier (Token? last, string source)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected indentifier", locate (last, source));
    }

    internal static ParserError expected_literal (Token? last, string source)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected literal", locate (last, source));
    }

    internal static ParserError expected_rvalue (Token? token, string source)
    {
      return new ParserError.EXPECTED ("%s: Expected rvalue", locate (token, source));
    }

    internal static ParserError expected_token (Token? token, string source, string value)
    {
      return new ParserError.EXPECTED_TOKEN ("%s: Expected token '%s'", locate (token, source), value);
    }

    /* throwers API - verbose */

    internal static ParserError redefined_symbol_full (Token? token, string source, string name, Token? token2, string source2)
    {
      return new ParserError.REDEFINED ("%s: Redefined symbol '%s', previously defined at %s", locate (token, source), name, locate (token, source));
    }
  }
}
