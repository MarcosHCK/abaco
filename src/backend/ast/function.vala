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
  internal class Function : Node, IUnique, ITyped, IVariable
  {
    public string id { get; private set; }
    public string return_type { get; private set; }
    public string typename { get; private set; }
    public List<IVariable> arguments { get; private set; }

    /* public API */

    public void gen_typename ()
    {
      typename = return_type + "@";
      var first = true;
      foreach (unowned var arg in arguments)
      {
        if (!first)
          typename += "&" + arg.typename;
        else
        {
          typename += arg.typename;
          first = false;
        }
      }
    }

    /* constructor */

    public Function (string id, string return_type, List<IVariable> arguments)
    {
      base ();
      this.id = id;
      this.return_type = return_type;
      this.arguments = arguments;
        gen_typename ();
    }
  }

  internal class ConcreteFunction : Function, IConcrete
  {
    public Scope body { get; private set; }

    /* constructor */

    public ConcreteFunction (string id, string return_type, List<IVariable> arguments, Scope body)
    {
      base (id, return_type, arguments);
      this.body = body;
    }
  }
}
