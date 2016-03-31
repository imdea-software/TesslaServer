Definitions.

STRING      = [a-z0-9_:\\;/.-]*
INT         = [0-9]+

Rules.

[\s\t\n\r]+ : skip_token.
definitions       : {token, {defs, TokenLine}}.
streamdef         : {token, {streamdef, TokenLine}}.
exprtree          : {token, {exprtree, TokenLine}}.
typeascrfn        : {token, {typeascrfn, TokenLine}}.
list              : {token, {list, TokenLine}}.
namedfn           : {token, {namedfn, TokenLine}}.
literalfn         : {token, {literalfn, TokenLine}}.
stringliteral     : {token, {stringliteral, TokenLine}}.
intliteral        : {token, {intliteral, TokenLine}}.
simpletype        : {token, {simpletype, TokenLine}}.
generictype       : {token, {generictype, TokenLine}}.
"{STRING}"        : {token, {string, TokenLine, strip_quotes(TokenChars)}}.
map               : {token, {map, TokenLine}}.
pos               : {token, {pos, TokenLine}}.
{INT}             : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
->                : {token, {'->', TokenLine}}.
\(                : {token, {'(', TokenLine}}.
\)                : {token, {')', TokenLine}}.
,                 : {token, {',',  TokenLine}}.
{STRING}          : {token, {atom, TokenLine, TokenChars}}.

Erlang code.

strip_quotes(Id) ->
  string:strip(Id, both, $\").
