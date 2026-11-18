#!/bin/sh
# Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
# Research owner: Bel esprit D'accord Trust
# Lab: SnapKitty Research Lab
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
set -eu
cd "$(dirname "$0")/.."
mkdir -p bin
cc -std=c11 -Wall -Wextra -Werror -pedantic -O2 src/ingest.c -o bin/ingest
bin/ingest fixtures/observations.tsv bin/observations.ttl
if command -v swipl >/dev/null 2>&1; then
    swipl -q -s src/reason.pl -- bin/observations.ttl 0 > bin/public.txt
    swipl -q -s src/reason.pl -- bin/observations.ttl 1 > bin/restricted.txt
    if grep -q 'maintenance_required' bin/public.txt; then echo 'FAIL: unauthorized disclosure'; exit 1; fi
    grep -q 'maintenance_required' bin/restricted.txt
    grep -q 'CONFLICT' bin/restricted.txt
    if grep -q 'CONFLICT' bin/public.txt; then echo 'FAIL: high-level-derived leakage'; exit 1; fi
    echo 'PASS: clearance noninterference fixture and conflict detection'
else
    echo 'SKIP: Prolog checks (swipl not installed)'
fi
printf 'bad\tbad\tbad\tbad\tbad\tTOP_SECRET\tbad\textra\n' > bin/invalid.tsv
if bin/ingest bin/invalid.tsv bin/invalid.ttl 2>/dev/null; then echo 'FAIL: invalid input accepted'; exit 1; fi
test ! -f bin/invalid.ttl
echo 'PASS: C11 parser rejects malformed rows before output creation'
