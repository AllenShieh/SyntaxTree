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

int sym[26];
char temp;

%}

%union{
    int iValue;
    char* sIndex;
    nodeType *nPtr;
};
%token <iValue> INT
%token <sIndex> ID
%token SEMI COMMA DOT ASSIGNOP BINARYOP UNARYOP TYPE LP RP LB RB LC RC STRUCT RETURN IF ELSE BREAK CONT FOR
%start PROGRAM

%type <nPtr> STMT EXP STMTS ESTMT STMTBLOCK ARGS ARRS EXTDEF EXTDEFS EXTVARS DEFS DEF DECS DEC VAR SPEC STSPEC OPTTAG INIT FUNC PARA PARAS
%%
PROGRAM     :   EXTDEFS { ex($1); } 
            ;
EXTDEFS     :   EXTDEF EXTDEFS { $$ = opr('X', 2, $1, $2); }
            |   /* */ { $$ = opr('e', 0); }
            ;
EXTDEF      :   SPEC EXTVARS SEMI { $$ = opr('X', 2, $1, $2); }
            |   SPEC FUNC STMTBLOCK  { $$ = opr('F', 3, $1, $2, $3); }
            ;
EXTVARS     :   DEC { $$ = opr('D', 1, $1); }
            |   DEC COMMA EXTVARS { $$ = opr('X', 2, $1, $3); }
            |   /* */ { $$ = opr('e', 0); }
            ;
SPEC        :   TYPE { $$ = opr(TYPE, 0); }
            |   STSPEC { $$ = opr('V', 1, $1); }
            ;
STSPEC      :   STRUCT OPTTAG LC DEFS RC { $$ = opr(STRUCT, 2, $2, $4); }
            |   STRUCT ID { $2 = id($2); $$ = opr(STRUCT, 1, $2); }
            ;
OPTTAG      :   ID { $$ = id($1); }
            |   /* */ { $$ = opr('e', 0); }
            ;
VAR         :   ID { $$ = id($1); }
            |   VAR LB INT RB { $3 = con($3); $$ = opr('V', 2, $1, $3); }
            ;
FUNC        :   ID LP PARAS RP { $1 = id($1); $$ = opr('I', 2, $1, $3); }
            ;
PARAS       :   PARA COMMA PARAS { $$ = opr('P', 2, $1, $3); }
            |   PARA { $$ = opr('P', 1, $1); }
            |   /* */ { $$ = opr('e', 0); }
            ;
PARA        :   SPEC VAR { $$ = opr('V', 2, $1, $2); }
            ;
STMTBLOCK   :   LC DEFS STMTS RC { $$ = opr('S', 1, $3);}
            ;
STMTS       :   STMT STMTS { $$ = opr('S', 2, $1, $2); }
            |   /* */ { $$ = opr('e', 0); }
            ;
STMT        :   EXP SEMI { $$ = opr('E', 1, $1); }
            |   STMTBLOCK { $$ = opr('S', 1, $1); }
            |   RETURN EXP SEMI { $$ = opr(RETURN, 1, $2); }
            |   IF LP EXP RP STMT ESTMT { $$ = opr(IF, 3, $3, $5, $6); }
            |   FOR LP DEC SEMI EXP SEMI DEC RP STMT { $$ = opr(FOR, 4, $3, $5, $7, $9); }
            |   CONT SEMI { $$ = opr(CONT, 0); }
            |   BREAK SEMI { $$ = opr(BREAK, 0); }
            ;
ESTMT       :   ELSE STMT { $$ = opr(ELSE, 1, $2); }
            |   /* */ { $$ = opr('e', 0); }
            ;
DEFS        :   DEF DEFS { $$ = opr('D', 2, $1, $2); }
            |   /* */ { $$ = opr('e', 0); }
            ;
DEF         :   SPEC DECS SEMI { $$ = opr('D', 2, $1, $2); }
            ;
DECS        :   DEC COMMA DECS { $$ = opr('D', 2, $1, $3); }
            |   DEC { $$ = opr('D', 1, $1); }
            ;
DEC         :   VAR { $$ = opr('V', 1, $1); }
            |   VAR ASSIGNOP INIT { $$ = opr('=', 2, $1, $3); }
            ;
INIT        :   EXP { $$ = opr('E', 1, $1); }
            |   LC ARGS RC { $$ = opr('A', 1, $2); }
            ;
ARRS        :   LB EXP RB ARRS { $$ = opr('R', 2, $2, $4); }
            |   /* */ { $$ = opr('e', 0); }
            ;
ARGS        :   EXP COMMA ARGS { $$ = opr('A', 2, $1, $3); }
            |   EXP { $$ = opr('E', 1, $1); }
            ;
EXP         :   EXP BINARYOP EXP { $$ = opr(BINARYOP, 2, $1, $3); }
            |   UNARYOP EXP { $$ = opr(UNARYOP, 1, $2); }
            |   LP EXP RP { $$ = opr('E', 1, $2); }
            |   ID { $$ = id($1); }
            /*|   ID LP ARGS RP { $1 = id($1); $$ = opr('A', 2, $1, $3); }*/
            /*|   ID ARRS { $1 = id($1); $$ = opr('R', 2, $1, $2); }*/
            |   EXP DOT ID { $3 = id($3); $$ = opr('E', 2, $1, $3); }
            |   INT { $$ = con($1); }
            |   /* */ { $$ = opr('e', 0); }
            ;

%%

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
    printf("%s",i);
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

int main(void){
    yyparse();
    return 0;
}
