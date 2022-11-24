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

namespace Abaco.Parse
{
  internal static void annotate_name (Ast.Node node, Token? token)
  {
    node.set_qnote (Ast.Node.Annotations.name, token.value);
  }

  internal static void annotate_location (Ast.Node node, Token? token, string source)
  {
    node.set_qnote (Ast.Node.Annotations.source_name, source);
    node.set_qnote (Ast.Node.Annotations.line_number, token.line.to_string ());
    node.set_qnote (Ast.Node.Annotations.column_number, token.column.to_string ());
  }

  internal static void annotate_variable (Ast.Node node, Token? name, string source)
  {
    annotate_name (node, name);
    annotate_location (node, name, source);
  }
}
