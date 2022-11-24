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
    private Lexer lexer { get; set; }
    private Parser parser { get; set; }
    private List<Source?> sources;
    private Stage stage;

    /* type API */

    enum Stage
    {
      INVALID = -1,
      FEED,     /* Source are being fed into compiler */
      SCAN,     /* All sources are being scaned for declaration  */
      PARSE,    /* All sources are being parsed to construct a program tree */
      COMPILE,  /* Program tree is being compiled into intermediate code */
      OPTIMIZE, /* Intermediate code is being optimized */
    }

    struct Source
    {
      public Tokens tokens;
      public string name;

      /* constructors */

      public Source (Tokens tokens, string name)
      {
        this.tokens = tokens;
        this.name = name;
      }
    }

    /* private API */

    private bool checkstage (Stage expected, Stage previous)
    {
      if (stage == previous)
        stage = expected;
      else
      if (stage != expected)
        return false;
    return true;
    }

    /* public API */

    public void feed_source (GLib.InputStream istream, string name, GLib.Cancellable? cancellable = null) throws GLib.Error
      requires (checkstage (Stage.FEED, Stage.INVALID))
    {
      var stream = new GLib.DataInputStream (istream);
        stream.byte_order = DataStreamByteOrder.HOST_ENDIAN;
        stream.newline_type = DataStreamNewlineType.ANY;
      var tokens = lexer.tokenize (stream, cancellable);
        sources.append (Source (tokens, name));

      unowned var array = tokens.tokens;
      foreach (unowned var token in array)
      {
        print ("%u: %u: type %s, value '%s'\r\n", token.line, token.column, token.type.to_string (), token.value);
      }
    }

    public void scan_sources () throws GLib.Error
      requires (checkstage (Stage.SCAN, Stage.FEED))
    {
      foreach (unowned var source in sources)
        parser.walk (source.tokens, source.name, true);
    }

    public void parse_sources () throws GLib.Error
      requires (checkstage (Stage.PARSE, Stage.SCAN))
    {
      foreach (unowned var source in sources)
        parser.walk (source.tokens, source.name, false);
    }

    /* constructor */

    public Compiler ()
    {
      lexer = new Lexer ();
      parser = new Parser ();
      sources = new List<Source> ();
      stage = Stage.FEED;
    }
  }
}
