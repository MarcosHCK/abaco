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
using Abaco.Asm;

namespace Abaco.Types
{
  internal abstract class Type
  {
    public string typename { get; private set; }

    /* abstract API */

    public abstract bool checkliteral (string value);

    /* constructor */

    protected Type (string typename, Builder builder)
    {
      this.typename = typename;
    }
  }

  [Compact (opaque = true)]
  internal class Table : HashTable<unowned string, Type>
  {
    /* public API */

    public void register (Type type)
    {
      unowned var name = type.typename;
      this.insert (name, type);
    }

    /* constructor */

    public Table (Builder builder)
    {
      unowned var hash = GLib.str_hash;
      unowned var equal = GLib.str_equal;
      base (hash, equal);
    }
  }
}
