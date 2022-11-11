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
  internal enum TokenType
  {
    IDENTIFIER,
    KEYWORD,
    SEPARATOR,
    OPERATOR,
    LITERAL,
    COMMENT,
  }

  [Compact (opaque = true)]
  internal class TokenClass
  {
    public TokenType type { get; private set; }
    public GLib.Regex rexp { get; private set; }

    /* constructors */

    public TokenClass (string rexp, TokenType type)
    {
      try
      {
        this.rexp = new GLib.Regex (rexp, RegexCompileFlags.OPTIMIZE);
        this.type = type;
      }
      catch (GLib.Error e)
      {
        error (@"$(e.domain):$(e.code):$(e.message)");
      }
    }

    public TokenClass.escaped (string exp, TokenType type)
    {
      this (Regex.escape_string (exp), type);
    }
  }

  internal struct Token
  {
    public unowned TokenType type;
    public unowned string value;
    public unowned uint line;
    public unowned uint column;
  }
}
