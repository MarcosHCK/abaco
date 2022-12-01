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
  internal class Invoke : Node, ITyped, IRValue
  {
    public IVariable target { get; private set; }
    public List<IRValue> arguments { get; private set; }

    public string typename
    {
      get
      {
        if (target is Function)
          return ((Function) target).return_type;
        else
          return target.typename;
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
        base.debug (spaces)
      + "\r\n"
      + target.debug (spaces + 1)
      + "\r\n"
      + arguments.debug (spaces + 1);
    }

#endif // DEVELOPER

    /* constructors */

    public Invoke (IVariable target, List<IRValue> arguments)
    {
      base ();
      this.target = target;
      this.arguments = arguments;
    }
  }
}
