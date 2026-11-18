#!/usr/bin/awk -f
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
#
# Awk implementation of calendar-valid timestamp checks for AIRGAP-KG next-step #3.
# Reads TSV, validates the 7th field as a real calendar date in YYYY-MM-DDTHH:MM:SSZ form.
# Rejects invalid dates like 2026-02-30 while keeping the fixed lexical form.

BEGIN {
    FS = "\t"
    OFS = "\t"
    months[1]=31; months[2]=28; months[3]=31; months[4]=30
    months[5]=31; months[6]=30; months[7]=31; months[8]=31
    months[9]=30; months[10]=31; months[11]=30; months[12]=31
}

function is_leap(y) {
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)
}

function valid_date(y, m, d) {
    if (m < 1 || m > 12) return 0
    maxd = months[m]
    if (m == 2 && is_leap(y)) maxd = 29
    return (d >= 1 && d <= maxd)
}

function valid_time(h, mi, s) {
    return (h >= 0 && h <= 23 && mi >= 0 && mi <= 59 && s >= 0 && s <= 59)
}

{
    if (NF != 7) {
        print "REJECT: wrong field count on line", NR > "/dev/stderr"
        next
    }
    ts = $7
    if (length(ts) != 20 || substr(ts,5,1) != "-" || substr(ts,8,1) != "-" ||
        substr(ts,11,1) != "T" || substr(ts,14,1) != ":" ||
        substr(ts,17,1) != ":" || substr(ts,20,1) != "Z") {
        print "REJECT: bad lexical form on line", NR > "/dev/stderr"
        next
    }
    y = substr(ts,1,4)+0
    m = substr(ts,6,2)+0
    d = substr(ts,9,2)+0
    h = substr(ts,12,2)+0
    mi = substr(ts,15,2)+0
    s = substr(ts,18,2)+0
    if (!valid_date(y, m, d) || !valid_time(h, mi, s)) {
        print "REJECT: invalid calendar date/time on line", NR, ":", ts > "/dev/stderr"
        next
    }
    print $0
}
