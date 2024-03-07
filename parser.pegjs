//tentative Xextan PEG grammar
//Contributors: la Tsakap

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

text = expr:(_? ( _? sentence)*) {return _node("text", expr);}
sentence = expr:(illocutions? _? (clause / fragment) ( _? connective _? &illocution sentence)? &(illocution / end_of_input) / illocutions _? &(illocution / end_of_input)) {return _node("sentence", expr);}

// phrase/clause level

illocutions = expr:((discursive_illocution _? modal_illocution) / (modal_illocution _? discursive_illocution) / illocution) {return _node("illocutions", expr);}
binder_phrase = expr:(_? modifiers? binder _? (((predicate / noun_term / tag_phrase / binder_phrase) _? SS_terminator?) / (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / _? modifiers? binder_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) {return _node("binder_phrase", expr);}
tag_phrase = expr:(_? modifiers? tag _? (((predicate / noun_term / tag_phrase / binder_phrase) _? SS_terminator?) / (SS_terminator / &(noun_term / transmogrifier / illocution / end_of_input))) / _? modifiers? tag_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) {return _node("tag_phrase", expr);}
clause = expr:(fragment? (predicate_term fragment?)+ (_? connective _? clause)?) {return _node("clause", expr);}
predicate = expr:(_? adverbs? modifiers? (serial / verb) tag_phrase? (_? connective _? predicate)?) {return _node("predicate", expr);}
serial = expr:(modifiers? _? verb ( _? serial / _? modifiers? verb)+) {return _node("serial", expr);}
fragment = expr:((noun_terms / adverbs)+) {return _node("fragment", expr);}
noun_terms = expr:((noun_term _?)+) {return _node("noun_terms", expr);}
noun_term = expr:(subject_term / object_term / dative_term / preposition_term / free_term / free_connective_term) {return _node("noun_term", expr);}
term_nucleus = expr:(_? adverbs? _? (predicate / pronoun / quote / tag_phrase / binder_phrase / free_term / modifier) _? (tag_phrase / binder_phrase)? _? SS_terminator?) {return _node("term_nucleus", expr);}

predicate_term = expr:(_? modifiers? transmogrifier _? _? adverbs? modifiers? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input)) / _? modifiers? _? transmogrifier? term_nucleus (_? connective _? predicate_term)?) {return _node("predicate_term", expr);}
subject_term = expr:(_? modifiers? (subject_marker_SS _? adverbs? modifiers? (term_nucleus / _? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / subject_marker_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) ( _? connective _? subject_term)?) {return _node("subject_term", expr);}
object_term = expr:(_? modifiers? (object_marker_SS _? adverbs? modifiers? (term_nucleus / _? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / object_marker_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) ( _? connective _? object_term)?) {return _node("object_term", expr);}
dative_term = expr:(_? modifiers? (dative_marker_SS _? adverbs? modifiers? (term_nucleus / _? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / dative_marker_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) ( _? connective _? dative_term)?) {return _node("dative_term", expr);}
preposition_term = expr:(_? modifiers? (preposition_SS _? adverbs? modifiers? (term_nucleus / _? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / preposition_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) ( _? connective _? preposition_term)?) {return _node("preposition_term", expr);}
free_term = expr:(_? modifiers? (pronoun / quote / determiner_SS _? (term_nucleus / _? (SS_terminator / &(case_marker / preposition / transmogrifier / illocution / end_of_input))) / determiner_LS _? clause _? (LS_terminator / &(illocution / end_of_input))) (_? connective _? free_term)?) {return _node("free_term", expr);}
free_connective_term = expr:(_? connective _? (subject_term / object_term / dative_term / preposition_term / free_term)) {return _node("free_connective_term", expr);}

adverbs = expr:((modifiers? adverb _? / modifiers (SS_terminator / &(noun_term / transmogrifier / illocution / end_of_input)))+) {return _node("adverbs", expr);}
modifiers = expr:((modifier _?)+) {return _node("modifiers", expr);}
quote = expr:(modifiers? _? quoter _? quotation_mark quoted_text quotation_mark) {return _node("quote", expr);}
quoted_text = expr:((!quotation_mark . )+) {return ["quoted_text", _join(expr)];}

// word level

verb_H = expr:(compound_H / root_H) {return _node("verb_H", expr);}
verb = expr:((compound / root !ANY_V / utility_predicate / freeword / verb_H) _? binder_phrase?) {return _node("verb", expr);}
compound_H = expr:(root_H morpheme+) {return _node("compound_H", expr);}
compound = expr:(root morpheme+) {return _node("compound", expr);}
morpheme = expr:(root / suffix) {return _node("morpheme", expr);}
root_H = expr:(C V_H F &(C / _ / end_of_input) / CL V_H &(C / _ / end_of_input)) {return _node("root_H", expr);}
root = expr:(C V F / CL V) {return _node("root", expr);}
freeword_start = expr:(ANY_C? r? (HD / ANY_H) &(ANY_C ANY_C? ANY_V)) {return _node("freeword_start", expr);}
freeword = expr:(freeword_start (ANY_C ANY_C? (HD / ANY_H))* ANY_C ANY_C? (D / V / y) (F / r)? / C V &FWF CL V F root*) {return _node("freeword", expr);} // freeword classic(TM)
suffix = expr:(x o !V / k o !V / z i !V / s e !V / s i !V / transmogrifier_suffix) {return _node("suffix", expr);}
transmogrifier_suffix = expr:(f u !V) {return _node("transmogrifier_suffix", expr);}
pronoun = expr:(!verb (n i e / n i o / t u i / b a !V / b i !V / t i !V / d i !V / d u !V / g i !V / g o !V / v i !V / v o !V / x e !V / l e !V / l i !V / n i !V)) {return _node("pronoun", expr);}
transmogrifier = expr:(!verb (h / glottal)? u !V) {return _node("transmogrifier", expr);}
case_marker = expr:(case_marker_LS / case_marker_SS) {return _node("case_marker", expr);}
preposition = expr:(preposition_LS / preposition_SS) {return _node("preposition", expr);}

case_marker_LS = expr:(subject_marker_LS / object_marker_LS / dative_marker_LS) {return _node("case_marker_LS", expr);}
subject_marker_LS = expr:(!verb (t u o_N / t o_N i / t o_N u / (h / glottal)? o_N i / (h / glottal)? o_N u / t o_N !V / (h / glottal)? o_N !V)) {return _node("subject_marker_LS", expr);}
object_marker_LS = expr:(!verb (t u e_N / t e_N i / t e_N u / (h / glottal)? e_N i / (h / glottal)? e_N u / t e_N !V / (h / glottal)? e_N !V)) {return _node("object_marker_LS", expr);}
dative_marker_LS = expr:(!verb (t u a_N / t a_N i / t a_N u / (h / glottal)? a_N i / (h / glottal)? a_N u / t a_N !V / (h / glottal)? a_N !V)) {return _node("dative_marker_LS", expr);}
preposition_LS = expr:(!verb (p i o_N / k i e_N / x u e_N / p a_N i / f a_N i / v e_N i / v o_N i / x o_N i / p a_N u / p e_N u / k o_N u / f a_N u / x a_N u / n a_N u / n e_N u / f e_N !V / f i_N !V / f o_N !V / z a_N !V)) {return _node("preposition_LS", expr);}
determiner_LS = expr:(!verb (b a_N u / p o_N !V / q i_N !V / q u_N !V / l a_N !V / l o_N !V / l u_N !V / t u_N !V)) {return _node("determiner_LS", expr);}

case_marker_SS = expr:(subject_marker_SS / object_marker_SS / dative_marker_SS) {return _node("case_marker_SS", expr);}
subject_marker_SS = expr:(!verb (t u o / t o i / t o u / (h / glottal)? o i / (h / glottal)? o u / t o !V / (h / glottal)? o !V)) {return _node("subject_marker_SS", expr);}
object_marker_SS = expr:(!verb (t u e / t e i / t e u / (h / glottal)? e i / (h / glottal)? e u / t e !V / (h / glottal)? e !V)) {return _node("object_marker_SS", expr);}
dative_marker_SS = expr:(!verb (t u a / t a i / t a u / (h / glottal)? a i / (h / glottal)? a u / t a !V / (h / glottal)? a !V)) {return _node("dative_marker_SS", expr);}
preposition_SS = expr:(!verb (p i o / k i e / x u e / p a i / f a i / v e i / v o i / x o i / p a u / p e u / k o u / f a u / x a u / n a u / n e u / f e !V / f i !V / f o !V / z a !V)) {return _node("preposition_SS", expr);}
determiner_SS = expr:(!verb (b a u / possessive / (numeral/superscript)+ / p o !V / q i !V / q u !V / l a !V / l o !V / l u !V / t u !V)) {return _node("determiner_SS", expr);}
possessive = expr:(l i a / n i a / d u a / g u a / v u a) {return _node("possessive", expr);}
numeral = expr:(!verb (d u o / t i e / k u a / p e i / l i o / x a i / b u i / g i u / s u a / s u e / s u i / s u o / s u / n u e / n u !V / n e !V)) {return _node("numeral", expr);}

illocution = expr:(discursive_illocution / modal_illocution) {return _node("illocution", expr);}
discursive_illocution = expr:((h / glottal)? i !V / j e / j u) {return _node("discursive_illocution", expr);}
modal_illocution = expr:(j a / j o / j i) {return _node("modal_illocution", expr);}
modifier = expr:(!verb (f e i / s a i / s e i / s o i / b u !V / g a !V / g e !V / s o !V / n o !V)) {return _node("modifier", expr);}
adverb = expr:(!verb (q e u / v o u / n o i / n a i / l a i / z e i / k e i / q u o / w a / w e / w i / w o / w u / n a !V / x a !V / f a !V / p a !V)) {return _node("adverb", expr);}
connective = expr:(!verb (k a i / q a !V / q e !V / q o !V / z e !V)) {return _node("connective", expr);}
binder = expr:(!verb (d o !V / d e !V / d a !V / p i !V)) {return _node("binder", expr);}
tag = expr:(!verb (k i !V / k e !V / p e !V)) {return _node("tag", expr);}
binder_LS = expr:(!verb (d o_N !V / d e_N !V / d a_N !V / p i_N !V)) {return _node("binder_LS", expr);}
tag_LS = expr:(!verb (k i_N !V / k e_N !V / p e_N !V)) {return _node("tag_LS", expr);}
utility_predicate = expr:(b o !V / k a !V) {return _node("utility_predicate", expr);}
quoter = expr:((l o u / l a u)) {return _node("quoter", expr);}
superscript = expr:(!verb x i !V) {return _node("superscript", expr);}
SS_terminator = expr:(!verb g u !V) {return _node("SS_terminator", expr);}
LS_terminator = expr:(!verb k u !V) {return _node("LS_terminator", expr);}

// character level

// All letters
ANY = expr:(C / V / FWC / V_H / V_HN / y / y_H / y_HN / ['] / GL) {return _node("ANY", expr);}
// All consonants
ANY_C = expr:(C / FWC / GL / glottal) {return _node("ANY_C", expr);}
// All vowels
ANY_V = expr:(V / V_H / V_HN / y / y_H / y_HN) {return _node("ANY_V", expr);}
// All high tone
ANY_H = expr:(V_H / V_HN / y_H / y_HN) {return _node("ANY_H", expr);}
// Consonants
C = expr:(p / b / t / d / k / g / f / v / s / z / x / q / l / n) {return _node("C", expr);}
// Voiced consonants
voiced = expr:(b / d / g / v / z / q) {return _node("voiced", expr);}
// Vowels
V = expr:(a / e / i / o / u) {return _node("V", expr);}
// Glide vowels
GV = expr:(u / i) {return _node("GV", expr);}
// Finals
F = expr:(p / b &voiced / t / d &voiced / k / g &voiced / l / n) {return _node("F", expr);}
// Glides
GL = expr:(j / w) {return _node("GL", expr);}
// B Root Initial Clusters
CL = expr:(z b / z d / z g / z l / z n / s p / s t / s k / s l / s n / q b / q d / q g / q l / q n / x p / x t / x k / x l / x n / b l / p l / g l / k l / v l / f l / d q / t x / d z / t s) {return _node("CL", expr);}
// Freeword-only consonants
FWC = expr:(h / m / r) {return _node("FWC", expr);}
// Freeword finals
FWF = expr:(f / v / s / z / x / q / r) {return _node("FWF", expr);}
// High marked vowels
V_H = expr:(a_H / e_H / i_H / o_H / u_H) {return _node("V_H", expr);}
// High nasal vowels
V_HN = expr:(a_HN / e_HN / i_HN / o_HN / u_HN) {return _node("V_HN", expr);}
//Diphthongs
D = expr:(i a / i e / i o / i u / u a / u e / u i / u o / a i / e i / o i / a u / e u / o u) {return _node("D", expr);}
// High  diphthongs
HD = expr:(i (a_H / a_HN) / i (e_H / e_HN) / i (o_H / o_HN) / i (u_H / u_HN) / u (a_H / a_HN) / u (e_H / e_HN) / u (i_H / i_HN) / u (o_H / o_HN) / (a_H / a_HN) i / (e_H / e_HN) i / (o_H / o_HN) i / (a_H / a_HN) u / (e_H / e_HN) u / (o_H / o_HN) u) {return _node("HD", expr);}

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
r = expr:([rR]) {return ["r", _join(expr)];}
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

hesitation = expr:(y+) {return _node("hesitation", expr);}

punctuation = expr:([,.?!'_()":;…]) {return _node("punctuation", expr);}

_ = expr:(([ ] / hesitation / punctuation)+ / end_of_input) {return _node("_", expr);}

quotation_mark = expr:([~]+) {return ["quotation_mark", _join(expr)];}

glottal = expr:([']) {return ["glottal", _join(expr)];}

end_of_input = expr:(!.) {return _node("end_of_input", expr);}
