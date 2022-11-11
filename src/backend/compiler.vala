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
  public class Compiler : GLib.Object
  {
    private Lexer lexer { get; private set; }

    /* public API */

    public void feed_source (GLib.InputStream istream, string name, GLib.Cancellable? cancellable = null) throws GLib.Error
    {
      var stream = new GLib.DataInputStream (istream);
        stream.newline_type = DataStreamNewlineType.ANY;
      var tokens = lexer.tokenize (stream, cancellable);

      unowned var array = tokens.tokens;
      foreach (unowned var token in array)
      {
        print ("%u: %u: type %s, value '%s'\r\n", token.line, token.column, token.type.to_string (), token.value);
      }
    }

    /* constructor */

    public Compiler ()
    {
      lexer = new Lexer ();
    }
  }
}
