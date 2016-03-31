Rootsymbol defs_tag.
Nonterminals 
  defs_tag map_tag mapentries mapentry mapkey mapvalue 
  exprtree_tag expression literalfn_tag
  namedfn_tag literal functioncall streamname typedescr type
  typelist types generictype_tag streamdef_tag def_map_tag.
Terminals '(' ')' int string ',' '->' pos 
  intliteral stringliteral simpletype list typeascrfn defs 
  map generictype literalfn namedfn streamdef exprtree atom.

defs_tag ->
  defs '(' map_tag ')' : '$3' .

map_tag          -> map '(' ')' : #{}.
map_tag          -> map '(' mapentries ')' : '$3'.

mapentries  -> mapentry : '$1'.
mapentries  -> mapentry ',' mapentries : maps:merge('$1', '$3').

mapentry    -> mapkey '->' mapvalue : #{'$1'=> '$3'}.

mapkey      -> pos '(' int ')' : extract_value('$3').
mapkey      -> string : extract_atom('$1').

mapvalue    -> streamdef_tag : '$1'.
mapvalue    -> exprtree_tag : '$1'.

def_map_tag -> map_tag : maps:get(0, '$1').

exprtree_tag    -> exprtree '(' expression ')' : '$3'.

expression  -> functioncall : #{def => '$1'}.
expression  -> typedescr ',' def_map_tag : '$3'.

functioncall  -> namedfn_tag ',' map_tag : #{function => '$1', args => '$3'}.
functioncall  -> namedfn_tag : #{stream => '$1'}.
functioncall  -> literalfn_tag : #{literal => '$1'}.

typedescr     -> typeascrfn '(' type ')'.

type          -> generictype_tag.
type          -> simpletype '(' string ')'.

generictype_tag   -> generictype '(' string ',' typelist ')'.

typelist    -> list '(' types ')'.

types     -> type.
types     -> type ',' types.

literalfn_tag     -> literalfn '(' literal ')' : '$3'.

literal       -> intliteral '(' int ')' : extract_value('$3').
literal       -> stringliteral '(' string ')' : extract_value('$3').


namedfn_tag       -> namedfn '(' string  ')' : extract_value('$3').
namedfn_tag       -> namedfn '(' atom  ')' : extract_value('$3').


streamdef_tag     -> streamdef '(' streamname ',' exprtree_tag ')' : maps:merge(#{name => '$3'}, '$5').

streamname    -> string : extract_atom('$1') .

Erlang code.

extract_value({_tag, _Line, Value}) -> Value.
extract_atom({_tag, _Line, Value}) -> list_to_atom(Value).
