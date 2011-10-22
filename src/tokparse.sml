(* Token parsers, a simple lexer implementation based on language definitions *)

functor TokenParser (Lang : LANGUAGE_DEF) :> TOKEN_PARSER =
struct

    fun elem x = List.exists (fn y => x = y)
    fun notElem x = List.all (fn y => x <> y)

    open Parsing
    open CharParser
    infixr 4 << >>
    infixr 3 &&
    infix  2 -- ##
    infix  2 wth suchthat return guard when
    infixr 1 ||

    type 'a charParser = 'a charParser

    fun lineComment _  =  newLine || done #"\n" || (anyChar >> lineComment ())
    val bcNested       = fail "Not implemented!"
    fun bcUnnested _   = string Lang.commentEnd || (anyChar >> bcUnnested ())
    val comment        =
	(string Lang.commentLine >> lineComment () >> succeed ())
	    || (string Lang.commentStart >> bcUnnested () >> succeed ())

    val whiteSpace     = repeati ((space >> succeed ()) || comment)
    fun lexeme p       = p << whiteSpace
    fun symbol s       = lexeme (string s)

    val name           =
        Lang.identStart && repeat Lang.identLetter wth implode o op::
    val identifier     =
	lexeme (name suchthat (fn x => notElem x Lang.reservedNames))
    fun reserved kw    =
	if elem kw Lang.reservedNames then
	    lexeme (name suchthat (fn x => x = kw)) >> succeed ()
	else fail "Not a reserved name"

    val opName         =
        Lang.opStart && repeat Lang.opLetter wth implode o op::
    val operator       =
	lexeme (opName suchthat (fn x => notElem x Lang.reservedOpNames))
    fun reservedOp rop =
	if elem rop Lang.reservedOpNames then
	    lexeme (opName suchthat (fn x => x = rop)) >> succeed ()
	else fail "Not a reserved operator"

    fun parens p       = middle (symbol "(") p (symbol ")")
    fun braces p       = middle (symbol "{") p (symbol "}")
    fun brackets p     = middle (symbol "<") p (symbol ">")
    fun squares p      = middle (symbol "[") p (symbol "]")

    val semi           = symbol ";"
    val comma          = symbol ","
    val colon          = symbol ":"
    val dot            = symbol "."
    fun semiSep p      = separate0 p semi
    fun semiSep1 p     = separate p semi
    fun commaSep p     = separate0 p comma
    fun commaSep1 p    = separate p comma

    val charLit        =
	((string "\\" && (anyChar wth Char.toString) wth op^)
          when Char.fromString) || anyChar
    val charLiteral    = middle (char #"'") charLit (symbol "'")
    val stringLiteral  =
	(middle (char #"\"") (repeat charLit) (symbol "\"")) wth String.implode

    fun dig d = if Char.isDigit d then Char.ord d - Char.ord #"0"
		else Char.ord (Char.toLower d) - Char.ord #"a" + 10

    fun transnum b     = List.foldl (fn (s, d) => b*s + d) 0
    val decimal        = repeat1 digit wth transnum 10 o List.map dig
    val hexadecimal    = repeat1 hexDigit wth transnum 16 o List.map dig
    val octal          = repeat1 octDigit wth transnum 8 o List.map dig
    val positive       =
	(char #"0" >> ((char #"x" >> hexadecimal) || octal)) || decimal
    val integer        = lexeme ((char #"-" >> positive wth op~) || positive)

end