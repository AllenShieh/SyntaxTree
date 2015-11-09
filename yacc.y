/*
    This source file mainly defines the grammar in use.
    Useful functions used for constructing the syntax tree
    and analyzing the operators are also defined.
*/

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

/* The precedence is decided from down to up. */
%token <iValue> INT
%token <sIndex> ID
%token SEMI COMMA TYPE LC RC STRUCT RETURN IF ELSE BREAK CONT FOR
%right <oPerator> ASSIGNOP
%left  <oPerator> BINARYOP12
%left  <oPerator> BINARYOP11
%left  <oPerator> BINARYOP10
%left  <oPerator> BINARYOP9
%left  <oPerator> BINARYOP8
%left  <oPerator> BINARYOP7
%left  <oPerator> BINARYOP6
%left  <oPerator> BINARYOP5
%left  <oPerator> BINARYOP4
%left  <oPerator> BINARYOP3
%right <oPerator> UNARYOP
%left  DOT LP RP LB RB
%start PROGRAM

%type <nPtr> STMT EXP EXPNULL STMTS ESTMT STMTBLOCK ARGS ARRS EXTDEF EXTDEFS EXTVARS DEFS DEF DECS DEC VAR SPEC STSPEC OPTTAG INIT FUNC PARA PARAS PROGRAM

/*
    Note that terminal 'ID' should be replaced by 'VAR' in some particular places.
    Otherwise, the contents of the identifier are not right because the variable
    referred is a point of char.
*/
%%
PROGRAM     :   EXTDEFS { /* Do the drawing action */ $$ = opr(199, 1, $1); ex($$); }
            ;
EXTDEFS     :   EXTDEF EXTDEFS { $$ = opr(200, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
EXTDEF      :   SPEC EXTVARS SEMI { $$ = opr(201, 3, $1, $2, opr(SEMI,0)); }
            |   SPEC FUNC STMTBLOCK  { $$ = opr(201, 3, $1, $2, $3); }
            |   STRUCT OPTTAG EXTVARS SEMI { $$ = opr(201, 4, opr(STRUCT,0), $2, $3, opr(SEMI,0)); } /* There is something wrong with the struct grammar, thus the modification. */
            ;
EXTVARS     :   DEC { $$ = opr(202, 1, $1); }
            |   DEC COMMA EXTVARS { $$ = opr(202, 3, $1, opr(COMMA,0), $3); }
            |   /* */ { $$ = NULL; }
            ;
SPEC        :   TYPE { $$ = opr(203, 1, opr(TYPE,0)); }
            |   STSPEC { $$ = opr(203, 1, $1); }
            ;
STSPEC      :   STRUCT OPTTAG LC DEFS RC { $$ = opr(204, 5, opr(STRUCT,0), $2, opr(LC,0), $4, opr(RC,0)); }
            /*|   STRUCT VAR { $$ = (204, 2, opr(STRUCT,0), $2); } */
            ;
OPTTAG      :   VAR { $$ = opr(205, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;
VAR         :   ID { $$ = id($1); }
            |   VAR LB INT RB { $$ = opr(206, 4, $1, opr(LB,0), con($3), opr(RB,0)); }
            ;
FUNC        :   VAR LP PARAS RP { $$ = opr(207, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            ;
PARAS       :   PARA COMMA PARAS { $$ = opr(208, 3, $1, opr(COMMA,0), $3); }
            |   PARA { $$ = opr(208, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;
PARA        :   SPEC VAR { $$ = opr(209, 2, $1, $2); }
            ;
STMTBLOCK   :   LC DEFS STMTS RC { $$ = opr(210, 4, opr(LC,0), $2, $3, opr(RC,0)); }
            ;
STMTS       :   STMT STMTS { $$ = opr(211, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
STMT        :   EXP SEMI { $$ = opr(212, 2, $1, opr(SEMI,0)); }
            |   STMTBLOCK { $$ = opr(212, 1, $1); }
            |   RETURN EXP SEMI { $$ = opr(212, 3, opr(RETURN,0), $2, opr(SEMI,0)); }
            |   IF LP EXP RP STMT ESTMT { $$ = opr(212, 6, opr(IF,0), opr(LP,0), $3, opr(RP,0), $5, $6); }
            |   FOR LP EXPNULL SEMI EXPNULL SEMI EXPNULL RP STMT { $$ = opr(212, 9, opr(FOR,0), opr(LP,0), $3, opr(SEMI,0), $5, opr(SEMI,0), $7, opr(RP,0), $9); }
            |   CONT SEMI { $$ = opr(212, 2, opr(CONT,0), opr(SEMI,0)); }
            |   BREAK SEMI { $$ = opr(212, 2, opr(BREAK,0), opr(SEMI,0)); }
            ;
ESTMT       :   ELSE STMT { $$ = opr(213, 2, opr(ELSE,0), $2); }
            |   /* */ { $$ = NULL; }
            ;
DEFS        :   DEF DEFS { $$ = opr(214, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
DEF         :   SPEC DECS SEMI { $$ = opr(215, 3, $1, $2, opr(SEMI,0)); }
            ;
DECS        :   DEC COMMA DECS { $$ = opr(216, 3, $1, opr(COMMA,0), $3); }
            |   DEC { $$ = opr(216, 1, $1); }
            ;
DEC         :   VAR { $$ = opr(217, 1, $1); }
            |   VAR ASSIGNOP INIT { temp = which_operator($2); $$ = opr(217, 3, $1, opr(temp,0), $3); }
            ;
INIT        :   EXP { $$ = opr(218, 1, $1); }
            |   LC ARGS RC { $$ = opr(218, 3, opr(LC,0), $2, opr(RC,0)); }
            ;
ARRS        :   LB EXP RB ARRS { $$ = opr(219, 4, opr(LB,0), $2, opr(RB,0), $4); }
            |   /* */ { $$ = NULL; }
            ;
ARGS        :   EXP COMMA ARGS { $$ = opr(220, 3, $1, opr(COMMA,0), $3); }
            |   EXP { $$ = opr(220, 1, $1); }
            ;
EXP         :   EXP BINARYOP3 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP4 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP5 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP6 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP7 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP8 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP9 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP10 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP11 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP12 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   UNARYOP EXP { temp = which_operator($1); $$ = opr(221, 2, opr(temp,0), $2); }
            |   LP EXP RP { $$ = opr(221, 3, opr(LP,0), $2, opr(RP,0)); }
            |   VAR LP ARGS RP { $$ = opr(221, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            |   VAR ARRS { $$ = opr(221, 2, $1, $2); }
            |   EXP DOT VAR { $$ = opr(221, 3, $1, opr(DOT,0), $3); }
            |   INT { $$ = con($1); }
            |   BINARYOP4 INT { temp = which_operator($1); $$ = opr(221, 2, opr(temp,0), con($2)); }
            |   EXP ASSIGNOP INIT { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); } /* Assign operation should be added. */
            ;
EXPNULL     :   EXP { $$ = opr(222, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;

%%

/* Used to return the value representing the specific operator. */
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

/* Return a node of a constant value */
nodeType *con(int value){
    nodeType *p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeCon;
    p->con.value = value;

    return p;
}

/* Return a node of an identifier. */
nodeType *id(char* i){
    nodeType * p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(idNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    char * xx = (char *)malloc(64*sizeof(char));
    strcpy(xx,i);
    p->type = typeId;
    p->id.i = xx;

    return p;
}

/* Return a node which have children listed in the parameter. */
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
