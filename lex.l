%{

#include <stdio.h>
#include "node.h"
#include "y.tab.h"
extern FILE *yyin;
extern char *yytext;

%}

INT         [0-9]+
SEMI        \;
COMMA       \,
DOT         \.
BINARYOP    \+
UNARYOP     [\-\+\~\!]
ASSIGNOP    \=
TYPE        int
LP          \(
RP          \)
LB          \[
RB          \]
LC          \{
RC          \}
STRUCT      struct
RETURN      return
IF          if
ELSE        else
BREAK       break
CONT        continue
FOR         for
ID          [a-zA-Z][a-zA-Z]*

%%

{INT}       {yylval.iValue = atoi(yytext); return INT;}
{SEMI}      {return SEMI;}
{COMMA}     {return COMMA;}
{DOT}       {return DOT;}
{BINARYOP}  {return BINARYOP;}
{UNARYOP}   {return UNARYOP;}
{ASSIGNOP}  {return ASSIGNOP;}
{TYPE}      {return TYPE;}
{LP}        {return LP;}
{RP}        {return RP;}
{LB}        {return LB;}
{RB}        {return RB;}
{LC}        {return LC;}
{RC}        {return RC;}
{STRUCT}    {return STRUCT;}
{RETURN}    {return RETURN;}
{IF}        {return IF;}
{ELSE}      {return ELSE;}
{BREAK}     {return BREAK;}
{CONT}      {return CONT;}
{FOR}       {return FOR;}
\n          /* ignore */
[ \t]+      /* ignore whitespace */
{ID}        {yylval.sIndex = yytext; return ID;}

%%

int yywrap(void){
    return 1;
}
