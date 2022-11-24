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
  internal interface IVariable : Node, IUnique, ITyped
  {
  }

  internal class Variable : Node, IUnique, ITyped, IRValue, IVariable
  {
    public string id { get; private set; }
    public string typename { get; private set; }

    /* debug API */

#if DEVELOPER == 1

    public override string debug (size_t spaces)
    {
      return ("%s, id '%s'").printf (base.debug (spaces), id);
    }

#endif // DEVELOPER

    /* constructor */

    public Variable (string id, string typename)
    {
      base ();
      this.id = id;
      this.typename = typename;
    }
  }
}
