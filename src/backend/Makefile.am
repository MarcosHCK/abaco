# Copyright 2021-2025 MarcosHCK
# This file is part of abaco.
#
# abaco is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# abaco is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with abaco. If not, see <http://www.gnu.org/licenses/>.
#

VOID=

#
# Binaries and libraries
# - declare
#

pkglib_LTLIBRARIES=\
  libabaco.la \
  $(VOID)

pkginclude_HEADERS=\
  $(VOID)

#
# Binaries and libraries
# - sources
#

libabaco_la_SOURCES=\
  $(VOID)
libabaco_la_CPPFLAGS=\
  $(LLVM_CFLAGS) \
  -D__LIBABACO_INSIDE__=1 \
  $(VOID)
libabaco_la_LIBADD=\
  $(LLVM_LIBS) \
  $(VOID)
libabaco_la_LDFLAGS=\
  -rpath ${pkglibdir} \
  -version-info 0:0:0 \
  $(VOID)
