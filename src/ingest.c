/*
 * Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
 * Research owner: Bel esprit D'accord Trust
 * Lab: SnapKitty Research Lab
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* Deterministic, bounded TSV-to-Turtle ingestion. Input: id,asset,property,value,source,label,time. */
#define LINE_MAX_BYTES 4096
#define FIELD_MAX_BYTES 512
static int token(const char *s) {
    size_t n = strlen(s);
    if (!n || n > 96) return 0;
    for (size_t i=0; i<n; ++i)
        if (!(isalnum((unsigned char)s[i]) || s[i]=='_' || s[i]=='-' || s[i]=='.')) return 0;
    return 1;
}
static int timestamp_ok(const char *s) {
    if (strlen(s) != 20 || s[4]!='-' || s[7]!='-' || s[10]!='T' || s[13]!=':' || s[16]!=':' || s[19]!='Z') return 0;
    for (size_t i=0; i<20; ++i) if (i!=4 && i!=7 && i!=10 && i!=13 && i!=16 && i!=19 && !isdigit((unsigned char)s[i])) return 0;
    return 1;
}
static int value_ok(const char *s) {
    size_t n = strlen(s);
    if (!n || n > FIELD_MAX_BYTES) return 0;
    for (size_t i=0;i<n;++i) if ((unsigned char)s[i] < 32 || (unsigned char)s[i] == 127) return 0;
    return 1;
}
static void quoted(FILE *out, const char *s) {
    fputc('"',out);
    for (;*s;s++) {
        if (*s=='"'||*s=='\\') fputc('\\',out);
        fputc(*s,out);
    }
    fputc('"',out);
}
static int parse(char *line, char *f[7]) {
    size_t len = strlen(line);
    if (!len || line[len-1]!='\n') return 0;
    line[--len]='\0';
    if (len && line[len-1]=='\r') line[--len]='\0';
    f[0]=line;
    int count=1;
    for (size_t i=0;i<len;i++) if(line[i]=='\t') {
        if (count==7) return 0;
        line[i]='\0'; f[count++]=line+i+1;
    }
    return count==7;
}
int main(int argc, char **argv) {
    if (argc!=3) { fprintf(stderr,"usage: ingest INPUT.tsv OUTPUT.ttl\n"); return 2; }
    FILE *in=fopen(argv[1],"rb");
    if(!in) { perror("input"); return 2; }
    /* Prevalidate fully before creating the output, so malformed input never yields partial graphs. */
    char line[LINE_MAX_BYTES]; size_t rows=0;
    while(fgets(line,sizeof line,in)) {
        char *f[7];
        if(!strchr(line,'\n') || !parse(line,f) ||
           !token(f[0]) || !token(f[1]) || !token(f[2]) || !value_ok(f[3]) ||
           !token(f[4]) || !token(f[5]) || !timestamp_ok(f[6]) ||
           !(strcmp(f[5],"PUBLIC")==0 || strcmp(f[5],"RESTRICTED")==0 || strcmp(f[5],"SECRET")==0 || strcmp(f[5],"TOP_SECRET")==0)) {
            fprintf(stderr,"REJECT line %zu\n",rows+1); fclose(in); return 3;
        }
        rows++;
    }
    if(ferror(in) || !rows || fseek(in,0,SEEK_SET)) { fclose(in);return 3; }
    FILE *out=fopen(argv[2],"wb");
    if(!out) { perror("output"); fclose(in); return 2; }
    fputs("@prefix ex: <urn:airgap:kg:> .\n@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n\n",out);
    while(fgets(line,sizeof line,in)) {
        char *f[7]; if(!parse(line,f)) { fclose(in);fclose(out);return 3; }
        fprintf(out,"ex:obs_%s a ex:Observation ;\n  ex:asset ex:asset_%s ;\n  ex:property ",f[0],f[1]);
        quoted(out,f[2]); fputs(" ;\n  ex:value ",out); quoted(out,f[3]);
        fprintf(out," ;\n  ex:source ex:source_%s ;\n  ex:classification ex:%s ;\n  ex:observedAt ",f[4],f[5]);
        quoted(out,f[6]); fputs(" .\n\n",out);
    }
    if(ferror(in) || ferror(out) || fclose(out)) { fclose(in);return 4; }
    fclose(in);
    fprintf(stderr,"ACCEPT %zu rows\n",rows);
    return 0;
}
