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
  public static int main (string[] args)
  {
    try
    {
      var file = GLib.File.new_for_path ("/home/marcos/Desktop/sample.abc");
      var stream = file.read ();
      var compiler = new Compiler ();
        compiler.feed_source (stream, file.get_basename ());
        compiler.scan_sources ();
        compiler.parse_sources ();
        compiler.profile ();
    }
    catch (GLib.Error e)
    {
      error (@"$(e.domain):$(e.code):$(e.message)");
    }
  return 0;
  }
}
