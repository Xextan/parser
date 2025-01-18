//tentative Xextan PEG grammar
//Contributors: Filomena Rocca a.k.a. la Tsakap

// text level

// ================================================================== //

/*
 *  PEGJS INITIALIZATION CODE
 */

{
  var _g_zoi_delim;

  function _join(arg) {
    if (typeof(arg) == "string")
      return arg;
    else if (arg) {
      var ret = "";
      for (var v in arg) { if (arg[v]) ret += _join(arg[v]); }
      return ret;
    }
  }

  function _node_empty(label, arg) {
    var ret = [];
    if (label) ret.push(label);
    if (arg && typeof arg == "object" && typeof arg[0] == "string" && arg[0]) {
      ret.push( arg );
      return ret;
    }
    if (!arg)
    {
      return ret;
    }
    return _node_int(label, arg);
  }

  function _node_int(label, arg) {
    if (typeof arg == "string")
      return arg;
    if (!arg) arg = [];
    var ret = [];
    if (label) ret.push(label);
    for (var v in arg) {
      if (arg[v] && arg[v].length != 0)
        ret.push( _node_int( null, arg[v] ) );
    }
    return ret;
  }

  function _node2(label, arg1, arg2) {
    return [label].concat(_node_empty(arg1)).concat(_node_empty(arg2));
  }

  function _node(label, arg) {
    var _n = _node_empty(label, arg);
    return (_n.length == 1 && label) ? [] : _n;
  }
  var _node_nonempty = _node;

  // === Functions for faking left recursion === //

  function _flatten_node(a) {
    // Flatten nameless nodes
    // e.g. [Name1, [[Name2, X], [Name3, Y]]] --> [Name1, [Name2, X], [Name3, Y]]
    if (is_array(a)) {
      var i = 0;
      while (i < a.length) {
        if (!is_array(a[i])) i++;
        else if (a[i].length === 0) // Removing []s
          a = a.slice(0, i).concat(a.slice(i + 1));
        else if (is_array(a[i][0]))
          a = a.slice(0, i).concat(a[i], a.slice(i + 1));
        else i++;
      }
    }
    return a;
  }

  function _group_leftwise(arr) {
    if (!is_array(arr)) return [];
    else if (arr.length <= 2) return arr;
    else return [_group_leftwise(arr.slice(0, -1)), arr[arr.length - 1]];
  }

  // "_lg" for "Leftwise Grouping".
  function _node_lg(label, arg) {
    return _node(label, _group_leftwise(_flatten_node(arg)));
  }

  function _node_lg2(label, arg) {
    if (is_array(arg) && arg.length == 2)
      arg = arg[0].concat(arg[1]);
    return _node(label, _group_leftwise(arg));
  }

  // === ZOI functions === //

  function _assign_zoi_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: ZOI word is of type " + typeof w;
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    _g_zoi_delim = w;
    return;
  }

  function _is_zoi_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: ZOI word is of type " + typeof w;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    w = w.replace(/[.\t\n\r?!\u0020]/g, "");
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    return w === _g_zoi_delim;
  }
	
	// === Stack functions === //

  var _g_stack = [];

  function _push(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    _g_stack.push(x);
    return;
  }

  function _pop() {
    return _g_stack.pop();
  }
	
	  function _peek() {
	  if (_g_stack.length <= 0) return null;
    else return _g_stack[_g_stack.length - 1];
  }
	
	var _g_last_pred_val = null;
	
	function _pop_eq(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    x = x.replace(/[.\t\n\r?!\u0020]/g, "");
		l = _g_stack.length;
		y = _peek();
		r = x === y;
		_g_last_pred_val = r;
		if (r) _pop();
    return r;
  }
	
	function _peek_eq(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    x = x.replace(/[.\t\n\r?!\u0020]/g, "");
		l = _g_stack.length;
		y = _peek();
		r = x === y;
		_g_last_pred_val = r;
    return r;
  }

	// === MISC === //

  function join_expr(n) {
    if (!is_array(n) || n.length < 1) return "";
    var s = "";
    var i = is_array(n[0]) ? 0 : 1;
    while (i < n.length) {
      s += is_string(n[i]) ? n[i] : join_expr(n[i]);
      i++;
    }
    return s;
  }

  function is_string(v) {
    return Object.prototype.toString.call(v) === '[object String]';
  }

  function is_array(v) {
    return Object.prototype.toString.call(v) === '[object Array]';
  }
}

// ================================================================== //

text = expr:(_? ( _? discourse)*) {return _node("text", expr);}
discourse = expr:(( _? sentence)+ _? VU_elidible ( _? connective _? discourse)?) {return _node("discourse", expr);}
sentence = expr:((illocutions? _? (clause (XU _?)? / fragment (XU _?)?)+ / illocutions _? &(illocution / end_of_input / DS_terminator)) ( _? connective _? &illocution sentence)?) {return _node("sentence", expr);}

// phrase/clause level

illocutions = expr:((discursive_illocution _? modal_illocution) / (modal_illocution _? discursive_illocution) / illocution) {return _node("illocutions", expr);}
binder_phrase = expr:(( _? modifiers? binder_SS _? adverbs? (term_nucleus / ((preposition_term / adverbs) _?)* GU_elidible) / _? modifiers? binder_LS _? clause _? KU_elidible) ( _? connective _? binder_phrase)?) {return _node("binder_phrase", expr);}
tag_phrase = expr:(( _? modifiers? tag_SS _? adverbs? (term_nucleus / ((preposition_term / adverbs) _?)* GU_elidible) / _? modifiers? tag_LS _? clause _? KU_elidible) ( _? connective _? tag_phrase)?) {return _node("tag_phrase", expr);}
clause = expr:((fragment (XU _?)?)* frame+ (_? connective _? clause)?) {return _node("clause", expr);}
frame = expr:(predicate_term fragment?) {return _node("frame", expr);}
predicate = expr:(( _? modifiers? (serial / verbal)) tag_phrase* (_? connective _? predicate)?) {return _node("predicate", expr);}
serial = expr:(modifiers? _? (verbal / tag_phrase / binder_phrase) (tag_phrase / binder_phrase)* ( _? serial / _? modifiers? verbal)+) {return _node("serial", expr);}
verbal = expr:((verb_modifier _?)? (verb _? binder_phrase* / verb_N _? clause _? KU_elidible) (_? connective _? verbal)?) {return _node("verbal", expr);}
fragment = expr:((noun_terms / adverbs)+) {return _node("fragment", expr);}
noun_terms = expr:((noun_term _?)+) {return _node("noun_terms", expr);}
noun_term = expr:(preposition_term / free_nominal / connective_nominal) {return _node("noun_term", expr);}
free_nominal = expr:((free_term / free_noun) (_? connective _? free_nominal)?) {return _node("free_nominal", expr);}
connective_nominal = expr:((free_connective_noun / free_connective_term) (_? connective _? free_nominal)?) {return _node("connective_nominal", expr);}
term_nucleus = expr:(_? ((preposition_term / adverbs) _?)* (free_term / (predicate / tag_phrase / binder_phrase / modifiers? (pronoun / quote / verb_L) tag_phrase*) _? GU_elidible)) {return _node("term_nucleus", expr);}
predicate_term = expr:((_? modifiers? transmogrifier _? (term_nucleus / ((preposition_term / adverbs) _?)* GU_elidible) / (U_elidible _? (predicate / tag_phrase / binder_phrase) _? GU_elidible)) _? (connective _? predicate_term)?) {return _node("predicate_term", expr);}
preposition_term = expr:(_? modifiers? (verb_modifier _?)? (preposition_SS _? (term_nucleus / ((preposition_term / adverbs) _?)* GU_elidible) / preposition_LS _? clause _? KU_elidible / preposition_SS _? &illocution discourse) _? (connective _? preposition_term)?) {return _node("preposition_term", expr);}
free_term = expr:(_? modifiers? ((determiner_SS _?)+ (term_nucleus / ((preposition_term / adverbs) _?)* GU_elidible) / (determiner_SS _?)* determiner_LS _? clause _? KU_elidible / determiner_SS _? &illocution discourse) _? (connective _? free_term)?) {return _node("free_term", expr);}
free_connective_term = expr:(_? connective _? (preposition_term / free_term)) {return _node("free_connective_term", expr);}
free_noun = expr:(SU_elidible modifiers? (pronoun / quote) _? tag_phrase* _? GU_elidible (_? connective _? free_noun)?) {return _node("free_noun", expr);}
free_connective_noun = expr:(_? connective _? free_noun) {return _node("free_connective_noun", expr);}

adverbs = expr:((adverbial _?)+ / trans_adverb) {return _node("adverbs", expr);}
adverbial = expr:(modifiers? (adverb / onomatopoeia) (_? connective _? adverbial)?) {return _node("adverbial", expr);}
trans_adverb = expr:(_? modifiers &(connective? _? modifiers? illocution / SS_terminator / LS_terminator / DS_terminator / XU / end_of_input)) {return _node("trans_adverb", expr);}
modifiers = expr:((modifier _?)+) {return _node("modifiers", expr);}
quote = expr:(modifiers? _? quoter _? quotation_mark quoted_text quotation_mark) {return _node("quote", expr);}
quoted_text = expr:((!quotation_mark . )+) {return ["quoted_text", _join(expr)];}

U_elidible = expr:(transmogrifier?) {return (expr === "" || !expr) ? ["U"] : _node_empty("U_elidible", expr);} //&( _? term_nucleus)
SU_elidible = expr:(( s u )?) {return (expr === "" || !expr) ? ["SU"] : _node_empty("SU_elidible", expr);} //&( _? (pronoun / quote))
GU_elidible = expr:(SS_terminator?) {return (expr === "" || !expr) ? ["GU"] : _node_empty("GU_elidible", expr);} /// &((_? adverbs _?)? (connective? _? modifiers? illocution / connective? _? modifiers? pronoun / connective? _? modifiers? predicate_term / connective _? modifiers? adverbial / connective? _? modifiers? quoter / connective? _? modifiers? preposition / connective? _? modifiers? determiner / connective? _? modifiers? transmogrifier / connective _? (tag / binder) / LS_terminator / DS_terminator / ALL_terminator / end_of_input))
KU_elidible = expr:(LS_terminator?) {return (expr === "" || !expr) ? ["KU"] : _node_empty("KU_elidible", expr);} /// &(connective? _? modifiers? illocution / DS_terminator / XU / end_of_input)
VU_elidible = expr:(DS_terminator?) {return (expr === "" || !expr) ? ["VU"] : _node_empty("VU_elidible", expr);} /// &end_of_input
XU = expr:(ALL_terminator) {return _node("XU", expr);}

// word level
// verb class count: 3. root, compound, freeword
// particle class count: 21
// 1. illocution [discursive, modal, other], 2. pronoun, 3. suffix, 4. transmogrifier [elidible],
// 5. preposition (S/L), 6. determiner (S/L) [includes posessives and quantifiers], 7. tag (S/L),
// 8. binder (S/L), 9. numeral, 10. math operator, 11. general modifier,
// 12. verb modifier, 13. adverb [includes onomatopoeia], 14. adverb suffix, 15. connective, 16 quoter, 17. utility predicate (S/L),
// 18. short terminator, 19. long terminator, 20. discourse terminator, 21. multi-scope terminator

verb_N = expr:(compound_N / root_N / utility_N) {return _node("verb_N", expr);}
verb_H = expr:(compound_H / root_H) {return _node("verb_H", expr);}
verb_L = expr:(compound_L / root_L) {return _node("verb_L", expr);}
verb = expr:(compound / root / utility / freeword / verb_H / trans_verb) {return _node("verb", expr);}
compound_N = expr:(root_N morpheme+) {return _node("compound_N", expr);}
compound_H = expr:(root_H morpheme+) {return _node("compound_H", expr);}
compound_L = expr:(root_L morpheme+) {return _node("compound_L", expr);}
compound = expr:(root morpheme+) {return _node("compound", expr);}
trans_verb = expr:((((numeral / operator) _? )+ / possessive) suffix) {return _node("trans_verb", expr);}
morpheme = expr:(root / suffix glottal?) {return _node("morpheme", expr);}
root = expr:(C V !root_H F !ANY_V / CL V) {return _node("root", expr);}
root_N = expr:(C V_HN !root_H F !ANY_V / CL V_HN) {return _node("root_N", expr);}
root_H = expr:(C V_H F !ANY_V / CL V_H !(CL V F (C / _ / end_of_input))) {return _node("root_H", expr);}
root_L = expr:(C V_L F !ANY_V / CL V_L) {return _node("root_L", expr);}

freeword_start = expr:((FWC / sibilant m / GL) (HD / ANY_H) &((CL3 / FWCL / CL / F C / sibilant m / ANY_C) ANY_V) / ANY_C ANY_H &((!F (CL3 / CL) / FWCL / sibilant m / ANY_C) ANY_V) / glottal? (HD / ANY_H) &((CL3 / FWCL / CL / F C / sibilant m / ANY_C) ANY_V) / ANY_C HD &((CL3 / FWCL / CL / F C / sibilant m / ANY_C) ANY_V)) {return _node("freeword_start", expr);}
classic_freeword = expr:(C (V / V_H) FWCL V F root*) {return _node("classic_freeword", expr);}
freeword = expr:(freeword_start ((CL3 / FWCL / CL / F C / ANY_C) (HD / ANY_H))* (CL3 / FWCL / CL / F C / sibilant m / ANY_C) (D / V / y) F? / classic_freeword) {return _node("freeword", expr);} // freeword classic(TM)

suffix = expr:(x o !ANY_V / k o !ANY_V / z i !ANY_V / s a !ANY_V / s e !ANY_V / s i !ANY_V / f u !ANY_V) {return _node("suffix", expr);}
pronoun = expr:(!(root / freeword) (n i e / n i o / t u i / b a !ANY_V / b i !ANY_V / t i !ANY_V / d i !ANY_V / d u !ANY_V / g i !ANY_V / g o !ANY_V / v i !ANY_V / v o !ANY_V / x e !ANY_V / l e !ANY_V / l i !ANY_V / n i !ANY_V)) {return _node("pronoun", expr);}
transmogrifier = expr:(!(root / freeword) (h / glottal)? u !ANY_V) {return _node("transmogrifier", expr);}
preposition = expr:(preposition_LS / preposition_SS) {return _node("preposition", expr);}
determiner = expr:(determiner_LS / determiner_SS) {return _node("determiner", expr);}
tag = expr:(tag_SS / tag_LS) {return _node("tag", expr);}
binder = expr:(binder_SS / binder_LS) {return _node("binder", expr);}

subject_marker_LS = expr:(!(root / freeword) (t u o_N / t o_N i / t o_N u / (h / glottal)? o_N i / (h / glottal)? o_N u / t o_N !ANY_V / (h / glottal)? o_N !ANY_V)) {return _node("subject_marker_LS", expr);}
object_marker_LS = expr:(!(root / freeword) (t u e_N / t e_N i / t e_N u / (h / glottal)? e_N i / (h / glottal)? e_N u / t e_N !ANY_V / (h / glottal)? e_N !ANY_V)) {return _node("object_marker_LS", expr);}
dative_marker_LS = expr:(!(root / freeword) (t u a_N / t a_N i / t a_N u / (h / glottal)? a_N i / (h / glottal)? a_N u / t a_N !ANY_V / (h / glottal)? a_N !ANY_V)) {return _node("dative_marker_LS", expr);}
preposition_LS = expr:(!(root / freeword) (subject_marker_LS / object_marker_LS / dative_marker_LS / p i o_N / k i e_N / x u e_N / p a_N i / f a_N i / v e_N i / v o_N i / x o_N i / p a_N u / p e_N u / k o_N u / f a_N u / x a_N u / n a_N u / n e_N u / g e_N i / f o_N !ANY_V / z a_N !ANY_V / f e_N !ANY_V / f i_N !ANY_V)) {return _node("preposition_LS", expr);}
determiner_LS = expr:(!(root / freeword) (b a_N u / k a_N u / l a_N i / q i_N !ANY_V / l a_N !ANY_V / l o_N !ANY_V / l u_N !ANY_V / t u_N !ANY_V / p o_N !ANY_V / q u_N !ANY_V)) {return _node("determiner_LS", expr);}

subject_marker_SS = expr:(!(root / freeword) (t u o / t o i / t o u / (h / glottal)? o i / (h / glottal)? o u / t o !ANY_V / (h / glottal)? o !ANY_V)) {return _node("subject_marker_SS", expr);}
object_marker_SS = expr:(!(root / freeword) (t u e / t e i / t e u / (h / glottal)? e i / (h / glottal)? e u / t e !ANY_V / (h / glottal)? e !ANY_V)) {return _node("object_marker_SS", expr);}
dative_marker_SS = expr:(!(root / freeword) (t u a / t a i / t a u / (h / glottal)? a i / (h / glottal)? a u / t a !ANY_V / (h / glottal)? a !ANY_V)) {return _node("dative_marker_SS", expr);}
preposition_SS = expr:(!(root / freeword) (subject_marker_SS / object_marker_SS / dative_marker_SS / p i o / k i e / x u e / p a i / f a i / v e i / v o i / x o i / p a u / p e u / k o u / f a u / x a u / n a u / n e u / g e i / f o !ANY_V / z a !ANY_V / f e !ANY_V / f i !ANY_V)) {return _node("preposition_SS", expr);}
determiner_SS = expr:(!(root / freeword) (k a u / b a u / l a i / possessive / ((numeral / operator) _? )+ / quantifier / q i !ANY_V / l a !ANY_V / l o !ANY_V / l u !ANY_V / t u !ANY_V / p o !ANY_V / q u !ANY_V)) {return _node("determiner_SS", expr);}
possessive = expr:(l i a / n i a / d u a / g u a / v u a / x u a) {return _node("possessive", expr);}
numeral = expr:((z o u / x e u / q a u / d u o / t i e / k u a / p e i / l i o / x a i / b u i / g i u / n u e / n u !ANY_V / n e !ANY_V / arabic_numeral)) {return _node("numeral", expr);}
quantifier = expr:((s a u / s u a / s u e / s u i / s u o / s u !ANY_V)) {return _node("quantifier", expr);}

illocution = expr:(discursive_illocution / modal_illocution / z o i / q a i / q e i / q o i) {return _node("illocution", expr);}
discursive_illocution = expr:((h / glottal)? i !ANY_V / j e / j u) {return _node("discursive_illocution", expr);}
modal_illocution = expr:(j a / j o / j i) {return _node("modal_illocution", expr);}
modifier = expr:(!(root / freeword) (f e i / s a i / s e i / s o i / b u !ANY_V / s o !ANY_V / n o !ANY_V)) {return _node("modifier", expr);}
verb_modifier = expr:(!(root / freeword) (g a !ANY_V / g e !ANY_V)) {return _node("verb_modifier", expr);}
adverb = expr:(!(root / freeword) (q e u / v o u / v a i / n o i / n a i / z e i / k e i / q u o / x o u / f o u / f i a / f i e / f i o / f i u / w a / w e / w i / w o / w u / n a !ANY_V / x a !ANY_V / f a !ANY_V / p a !ANY_V) adverb_suffix?) {return _node("adverb", expr);}
adverb_suffix = expr:((n i u / l u a / d i e)) {return _node("adverb_suffix", expr);}
connective = expr:(!(root / freeword) (p o i / q a !ANY_V / q e !ANY_V / q o !ANY_V / z e !ANY_V / z o !ANY_V)) {return _node("connective", expr);}
binder_SS = expr:(!(root / freeword) (d o u / d o i / d e u / d e i / d a u / d a i / d o !ANY_V / d e !ANY_V / d a !ANY_V / p i !ANY_V)) {return _node("binder_SS", expr);}
tag_SS = expr:(!(root / freeword) (k i !ANY_V / k e !ANY_V / p e !ANY_V)) {return _node("tag_SS", expr);}
binder_LS = expr:(!(root / freeword) (d o_N u / d o_N i / d e_N u / d e_N i / d a_N u / d a_N i / d o_N !ANY_V / d e_N !ANY_V / d a_N !ANY_V / p i_N !ANY_V)) {return _node("binder_LS", expr);}
tag_LS = expr:(!(root / freeword) (k i_N !ANY_V / k e_N !ANY_V / p e_N !ANY_V)) {return _node("tag_LS", expr);}
utility = expr:(!(root / freeword) (b o !ANY_V / k a !ANY_V)) {return _node("utility", expr);}
utility_N = expr:(!(root / freeword) (b o_N !ANY_V / k a_N !ANY_V)) {return _node("utility_N", expr);}
quoter = expr:((l o u / l a u)) {return _node("quoter", expr);}
operator = expr:(!(root / freeword) (x i !ANY_V / p u !ANY_V)) {return _node("operator", expr);}
onomatopoeia = expr:((CL3 / CL / ANY_C)? y ((CL3 / FWCL / CL / F C / ANY_C) y)* F?) {return _node("onomatopoeia", expr);}

SS_terminator = expr:(!(root / freeword) g u !ANY_V) {return _node("SS_terminator", expr);}
LS_terminator = expr:(!(root / freeword) k u !ANY_V) {return _node("LS_terminator", expr);}
DS_terminator = expr:(!(root / freeword) v u !ANY_V) {return _node("DS_terminator", expr);}
ALL_terminator = expr:(!(root / freeword) x u !ANY_V) {return _node("ALL_terminator", expr);}
terminator = expr:(SS_terminator / LS_terminator / DS_terminator) {return _node("terminator", expr);}

// character level

// All letters
ANY = expr:(C / V / FWC / V_H / V_N / V_HN / y / y_H / y_HN / ['] / GL) {return _node("ANY", expr);}
// All consonants
ANY_C = expr:(C / FWC / GL / glottal / r) {return _node("ANY_C", expr);}
// All vowels
ANY_V = expr:(V / V_H / V_N / V_HN / y / y_H / y_HN / r) {return _node("ANY_V", expr);}
// All high tone
ANY_H = expr:(V_H / V_HN / y_H / y_HN) {return _node("ANY_H", expr);}
// Consonants
C = expr:(p / b / t / d / k / g / f / v / s / z / x / q / l / n) {return _node("C", expr);}
// Voiced consonants
voiced = expr:(b / d / g / v / z / q) {return _node("voiced", expr);}
// Unvoiced
unvoiced = expr:(p / t / k / f / s / x) {return _node("unvoiced", expr);}
//Sibilant
sibilant = expr:(s / x / z / q) {return _node("sibilant", expr);}
//Other fricative
fricative = expr:(f / v) {return _node("fricative", expr);}
//Stop
stop = expr:(p / t / k / b / d / g) {return _node("stop", expr);}
//Sonorant
sonorant = expr:(l / n) {return _node("sonorant", expr);}
// Vowels
V = expr:(a / e / i / o / u) {return _node("V", expr);}
//Glides off i
IG = expr:(a / e / o / u) {return _node("IG", expr);}
//Glides off u
UG = expr:(a / e / i / o) {return _node("UG", expr);}
//Glides into i/u
GV = expr:(a / e / o) {return _node("GV", expr);}
//Glides off i, high
IG_H = expr:((a_H / a_HN) / (e_H / e_HN) / (o_H / o_HN) / (u_H / u_HN)) {return _node("IG_H", expr);}
//Glides off u, high
UG_H = expr:((a_H / a_HN) / (e_H / e_HN) / (i_H / i_HN) / (o_H / o_HN)) {return _node("UG_H", expr);}
//Glides into i/u, high
GV_H = expr:((a_H / a_HN) / (e_H / e_HN) / (o_H / o_HN)) {return _node("GV_H", expr);}
// Finals
F = expr:(p / b &voiced / t / d &voiced / k / g &voiced / l / n) {return _node("F", expr);}
// Glides
GL = expr:(j / w) {return _node("GL", expr);}
// B Root Initial Clusters
CL = expr:(&voiced sibilant (&voiced stop / sonorant) / &unvoiced sibilant (&unvoiced stop / sonorant) / (!(t / d) stop / fricative) l / d &voiced sibilant / t &unvoiced sibilant) {return _node("CL", expr);}
// Freeword-only consonants
FWC = expr:(h / m) {return _node("FWC", expr);}
// Classic freeword finals
FWF = expr:(fricative / sibilant) {return _node("FWF", expr);}
// Classic freeword clusters
FWCL = expr:(!illegal_CL &(voiced voiced / unvoiced unvoiced / . sonorant) FWF C) {return _node("FWCL", expr);}
// Illegal clusters
illegal_CL = expr:(x s / s x / z q / q z) {return _node("illegal_CL", expr);}
//Freeword triples
CL3 = expr:(&(CL / FWCL) C (CL / !( . (sibilant / fricative)) FWCL) / F CL) {return _node("CL3", expr);}
// Nasal vowels
V_N = expr:(a_N / e_N / i_N / o_N / u_N) {return _node("V_N", expr);}
// High marked vowels
V_H = expr:(a_H / e_H / i_H / o_H / u_H) {return _node("V_H", expr);}
// High nasal vowels
V_HN = expr:(a_HN / e_HN / i_HN / o_HN / u_HN) {return _node("V_HN", expr);}
// Low marked vowels
V_L = expr:(a_L / e_L / i_L / o_L / u_L) {return _node("V_L", expr);}
//Diphthongs
D = expr:(i IG / u UG / GV i / GV u / r (V / y) / (V / y) r !(V / y)) {return _node("D", expr);}
// High  diphthongs
HD = expr:(i IG_H / u UG_H / GV_H i / GV_H u / r (V_H / V_HN / y_H / y_HN) / (V_H / V_HN / y_H / y_HN) r !ANY_V) {return _node("HD", expr);}

//case fixing of letters

p = expr:([pP]) {return ["p", _join(expr)];}
b = expr:([bB]) {return ["b", _join(expr)];}
t = expr:([tT]) {return ["t", _join(expr)];}
d = expr:([dD]) {return ["d", _join(expr)];}
k = expr:([kK]) {return ["k", _join(expr)];}
g = expr:([gG]) {return ["g", _join(expr)];}
f = expr:([fF]) {return ["f", _join(expr)];}
v = expr:([vV]) {return ["v", _join(expr)];}
s = expr:([sS]) {return ["s", _join(expr)];}
z = expr:([zZ]) {return ["z", _join(expr)];}
x = expr:([xX]) {return ["x", _join(expr)];}
q = expr:([qQ]) {return ["q", _join(expr)];}
l = expr:([lL]) {return ["l", _join(expr)];}
n = expr:([nN]) {return ["n", _join(expr)];}

j = expr:([jJ]) {return ["j", _join(expr)];}
w = expr:([wW]) {return ["w", _join(expr)];}

m = expr:([mM]) {return ["m", _join(expr)];}
r = expr:([rR] !r) {return ["r", _join(expr)];}
h = expr:([hH]) {return ["h", _join(expr)];}

a = expr:([aA]) {return ["a", _join(expr)];}
e = expr:([eE]) {return ["e", _join(expr)];}
i = expr:([iI]) {return ["i", _join(expr)];}
o = expr:([oO]) {return ["o", _join(expr)];}
u = expr:([uU]) {return ["u", _join(expr)];}
y = expr:([yY]) {return ["y", _join(expr)];}

// High

a_H = expr:([áÁ]) {return ["a_H", _join(expr)];}
e_H = expr:([éÉ]) {return ["e_H", _join(expr)];}
i_H = expr:([íÍ]) {return ["i_H", _join(expr)];}
o_H = expr:([óÓ]) {return ["o_H", _join(expr)];}
u_H = expr:([úÚ]) {return ["u_H", _join(expr)];}
y_H = expr:([ýÝ]) {return ["y_H", _join(expr)];}

// Low

a_L = expr:([àÀ]) {return ["a_L", _join(expr)];}
e_L = expr:([èÈ]) {return ["e_L", _join(expr)];}
i_L = expr:([ìÌ]) {return ["i_L", _join(expr)];}
o_L = expr:([òÒ]) {return ["o_L", _join(expr)];}
u_L = expr:([ùÙ]) {return ["u_L", _join(expr)];}
y_L = expr:([ỳỲ]) {return ["y_L", _join(expr)];}

// Nasal

a_N = expr:([äÄãÃ]) {return ["a_N", _join(expr)];}
e_N = expr:([ëËẽẼ]) {return ["e_N", _join(expr)];}
i_N = expr:([ïÏĩĨ]) {return ["i_N", _join(expr)];}
o_N = expr:([öÖõÕ]) {return ["o_N", _join(expr)];}
u_N = expr:([üÜũŨ]) {return ["u_N", _join(expr)];}
y_N = expr:([ÿŸỹỸ]) {return ["y_N", _join(expr)];}

// High Nasal

a_HN = expr:([âÂ]) {return ["a_HN", _join(expr)];}
e_HN = expr:([êÊ]) {return ["e_HN", _join(expr)];}
i_HN = expr:([îÎ]) {return ["i_HN", _join(expr)];}
o_HN = expr:([ôÔ]) {return ["o_HN", _join(expr)];}
u_HN = expr:([ûÛ]) {return ["u_HN", _join(expr)];}
y_HN = expr:([ŷŶ]) {return ["y_HN", _join(expr)];}

punctuation = [,.:;?!…'"_(){}]

new_line = expr:("\n") {return _node("new_line", expr);}

arabic_numeral = expr:([1234567890]) {return ["arabic_numeral", _join(expr)];}

_ = expr:(([ ] / punctuation / new_line)+ / end_of_input) {return _node("_", expr);}

quotation_mark = expr:([~]+) {return ["quotation_mark", _join(expr)];}

glottal = expr:([']) {return ["glottal", _join(expr)];}

end_of_input = expr:(!.) {return _node("end_of_input", expr);}
