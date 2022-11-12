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

namespace Abaco.Ast
{
  internal class Function : Node, IVariable, INamed, IUnique, ITyped
  {
    public string name { get; private set; }
    public string id { get; private set; }
    public string return_type { get; private set; }
    public string typename { get; private set; }
    public List<IVariable> arguments { get; private set; }

    /* debug API */

#if DEVELOPER == 1

    public virtual string debug_ext (size_t spaces, string? extra)
    {
      return
        (extra != null)
         ? ("%s, %s").printf (base.debug (spaces), extra)
         : base.debug (spaces)
      + "\r\n"
      + arguments.debug (spaces + 1);
    }

    public override string debug (size_t spaces)
    {
      return debug_ext (spaces, null);
    }

#endif // DEVELOPER

    /* constructor */

    public Function (string name, string id, string return_type, List<IVariable> arguments)
    {
      base ();
      this.name = name;
      this.id = id;
      this.return_type = return_type;
      this.arguments = arguments;

      typename = return_type + "@";
      var first = true;
      foreach (unowned var arg in arguments)
      {
        if (!first)
          typename += "&" + arg.typename;
        else
          typename += arg.typename;
      }
    }
  }
}
