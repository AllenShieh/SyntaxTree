%{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "node.h"

void yyerror(const char *str){
    fprintf(stderr,"error: %s\n", str);
}

nodeType *opr(int oper, int nops, ...);
nodeType *id(char * i);
nodeType *con(int value);
int which_operator(char * in);

int sym[26];
int temp;
FILE *yyin;
FILE *yyout;
%}

%union{
    int iValue;
    char* sIndex;
    char* oPerator;
    nodeType *nPtr;
};
%token <iValue> INT
%token <sIndex> ID 
%token <oPerator> BINARYOP UNARYOP ASSIGNOP
%token SEMI COMMA DOT TYPE LP RP LB RB LC RC STRUCT RETURN IF ELSE BREAK CONT FOR
%start PROGRAM

%type <nPtr> STMT EXP STMTS ESTMT STMTBLOCK ARGS ARRS EXTDEF EXTDEFS EXTVARS DEFS DEF DECS DEC VAR SPEC STSPEC OPTTAG INIT FUNC PARA PARAS
%%
PROGRAM     :   EXTDEFS { ex($1); } 
            ;
EXTDEFS     :   EXTDEF EXTDEFS { $$ = opr(200, 2, $1, $2); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
EXTDEF      :   SPEC EXTVARS SEMI { $$ = opr(201, 3, $1, $2, opr(SEMI,0)); }
            |   SPEC FUNC STMTBLOCK  { $$ = opr(201, 3, $1, $2, $3); }
            ;
EXTVARS     :   DEC { $$ = opr(202, 1, $1); }
            |   DEC COMMA EXTVARS { $$ = opr(202, 3, $1, opr(COMMA,0), $3); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
SPEC        :   TYPE { /*$$ = opr(TYPE, 0);*/ $$ = opr(203, 1, opr(TYPE,0)); }
            |   STSPEC { $$ = opr(203, 1, $1); }
            ;
STSPEC      :   STRUCT OPTTAG LC DEFS RC { /*$$ = opr(STRUCT, 2, $2, $4);*/ $$ = opr(204, 5, opr(STRUCT,0), $2, opr(LC,0), $4, opr(RC,0)); }
            |   STRUCT VAR { /*$$ = opr(STRUCT, 1, $2);*/ $$ = (204, 2, opr(STRUCT,0), $2); }
            ;
OPTTAG      :   VAR { $$ = opr(205, 1, $1); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
VAR         :   ID { $$ = id($1); }
            |   VAR LB INT RB { $$ = opr(206, 4, $1, opr(LB,0), con($3), opr(RB,0)); }
            ;
FUNC        :   VAR LP PARAS RP { $$ = opr(207, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            ;
PARAS       :   PARA COMMA PARAS { $$ = opr(208, 3, $1, opr(COMMA,0), $3); }
            |   PARA { $$ = opr(208, 1, $1); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
PARA        :   SPEC VAR { $$ = opr(209, 2, $1, $2); }
            ;
STMTBLOCK   :   LC DEFS STMTS RC { $$ = opr(210, 4, opr(LC,0), $2, $3, opr(RC,0)); /*last return $2 can't be a NULL*/ }
            ;
STMTS       :   STMT STMTS { $$ = opr(211, 2, $1, $2); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
STMT        :   EXP SEMI { $$ = opr(212, 2, $1, opr(SEMI,0)); }
            |   STMTBLOCK { $$ = opr(212, 1, $1); }
            |   RETURN EXP SEMI { /*$$ = opr(RETURN, 1, $2);*/ $$ = opr(212, 3, opr(RETURN,0), $2, opr(SEMI,0)); }
            |   IF LP EXP RP STMT ESTMT { /*$$ = opr(IF, 3, $3, $5, $6);*/ $$ = opr(212, 6, opr(IF,0), opr(LP,0), $3, opr(RP,0), $5, $6); }
            |   FOR LP EXP SEMI EXP SEMI EXP RP STMT { $$ = opr(212, 9, opr(FOR,0), opr(LP,0), $3, opr(SEMI,0), $5, opr(SEMI,0), $7, opr(RP,0), $9); }
            |   CONT SEMI { /*$$ = opr(CONT, 0);*/ $$ = opr(212, 2, opr(CONT,0), opr(SEMI,0)); }
            |   BREAK SEMI { /*$$ = opr(BREAK, 0);*/ $$ = opr(212, 2, opr(BREAK,0), opr(SEMI,0)); }
            ;
ESTMT       :   ELSE STMT { /*$$ = opr(ELSE, 1, $2);*/ $$ = opr(213, 2, opr(ELSE,0), $2); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
DEFS        :   DEF DEFS { $$ = opr(214, 2, $1, $2); }
            |   /* */ { /*$$ = opr('e', 0); */ $$ = NULL; }
            ;
DEF         :   SPEC DECS SEMI { $$ = opr(215, 3, $1, $2, opr(SEMI,0)); }
            ;
DECS        :   DEC COMMA DECS { $$ = opr(216, 3, $1, opr(COMMA,0), $3); }
            |   DEC { $$ = opr(216, 1, $1); }
            ;
DEC         :   VAR { $$ = opr(217, 1, $1); }
            |   VAR ASSIGNOP INIT { /*$$ = opr('=', 2, $1, $3);*/ temp = which_operator($2); $$ = opr(217, 3, $1, opr(temp,0), $3); }
            ;
INIT        :   EXP { $$ = opr(218, 1, $1); }
            |   LC ARGS RC { $$ = opr(218, 3, opr(LC,0), $2, opr(RC,0)); }
            ;
ARRS        :   LB EXP RB ARRS { $$ = opr(219, 4, opr(LB,0), $2, opr(RB,0), $4); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;
ARGS        :   EXP COMMA ARGS { $$ = opr(220, 3, $1, opr(COMMA,0), $3); }
            |   EXP { $$ = opr(220, 1, $1); }
            ;
EXP         :   EXP BINARYOP EXP { temp = which_operator($2); /*$$ = opr(temp, 2, $1, $3);*/ $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   UNARYOP EXP { temp = which_operator($1); /*$$ = opr(UNARYOP, 1, $2);*/ $$ = opr(221, 2, opr(temp,0), $2); }
            |   LP EXP RP { $$ = opr(221, 3, opr(LP,0), $2, opr(RP,0)); }
            |   VAR LP ARGS RP { $$ = opr(221, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            |   VAR ARRS { $$ = opr(221, 2, $1, $2); }
            |   EXP DOT VAR { $$ = opr(221, 3, $1, opr(DOT,0), $3); }
            |   INT { $$ = con($1); }
            |   VAR ASSIGNOP INIT { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   /* */ { $$ = NULL; /*$$ = opr('e', 0);*/ }
            ;

%%

int which_operator(char * in){
    if(in[0]=='&' && in[1]=='&') return 300;
    if(in[0]=='|' && in[1]=='|') return 301;
    if(in[0]=='+' && in[1]=='=') return 302;
    if(in[0]=='-' && in[1]=='=') return 303;
    if(in[0]=='*' && in[1]=='=') return 304;
    if(in[0]=='/' && in[1]=='=') return 305;
    if(in[0]=='&' && in[1]=='=') return 306;
    if(in[0]=='^' && in[1]=='=') return 307;
    if(in[0]=='|' && in[1]=='=') return 308;
    if(in[0]=='<' && in[1]=='<' && in[2]=='=') return 309;
    if(in[0]=='>' && in[1]=='>' && in[2]=='=') return 310;
    if(in[0]=='<' && in[1]=='<') return 311;
    if(in[0]=='>' && in[1]=='>') return 312;
    if(in[0]=='>' && in[1]=='=') return 313;
    if(in[0]=='<' && in[1]=='=') return 314;
    if(in[0]=='=' && in[1]=='=') return 315;
    if(in[0]=='!' && in[1]=='=') return 316;
    if(in[0]=='+' && in[1]=='+') return 317;
    if(in[0]=='-' && in[1]=='-') return 318;
    if(in[0]=='+') return '+';
    if(in[0]=='-') return '-';
    if(in[0]=='*') return '*';
    if(in[0]=='/') return '/';
    if(in[0]=='>') return '>';
    if(in[0]=='<') return '<';
    if(in[0]=='=') return '=';
    if(in[0]=='&') return '&';
    if(in[0]=='|') return '|';
    if(in[0]=='~') return '~';
    if(in[0]=='!') return '!';
}

#define SIZEOF_NODETYPE ((char *) &p->con - (char *)p)

nodeType *con(int value){
    nodeType *p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeCon;
    p->con.value = value;

    return p;
}

nodeType *id(char* i){
    nodeType * p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(idNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    char * xx = (char *)malloc(20*sizeof(char));
    strcpy(xx,i);
    p->type = typeId;
    p->id.i = xx;

    return p;
}

nodeType *opr(int oper, int nops, ...){
    va_list ap;
    nodeType *p;
    size_t nodeSize;
    int i;

    nodeSize = SIZEOF_NODETYPE + sizeof(oprNodeType) + (nops-1)*sizeof(nodeType *);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for(i=0;i<nops;i++) p->opr.op[i] = va_arg(ap, nodeType*);
    va_end(ap);
    return p;
}

int main(int argc, char *argv[]){
    yyin = fopen(argv[1],"r");
    yyout = freopen(argv[2],"w",stdout);
    yyparse();
    fclose(yyin);
    fclose(yyout);
    return 0;
}
