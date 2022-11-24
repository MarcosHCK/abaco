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
  internal class Operation : Node, ITyped, IRValue
  {
    public string name { get; private set; }
    public List<IRValue> rvalues { get; private set; }

    public string typename
    {
      get
      {
        return rvalues.children.data.typename;
      }

      private set
      {
        assert_not_reached ();
      }
    }

#if DEVELOPER == 1

    public override string debug (size_t spaces)
    {
      return
        ("%s, name '%s'").printf (base.debug (spaces), name)
      + "\r\n"
      + rvalues.debug (spaces + 1);
    }

#endif // DEVELOPER

    /* constructor */

    public Operation (string name, List<IRValue> rvalues)
      requires (rvalues.n_children () >= 1)
    {
      base ();
      this.name = name;
      this.rvalues = rvalues;
    }
  }
}
