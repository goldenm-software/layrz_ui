import 'package:layrz_ui/src/highlight/src/grammar.dart';

/// The grammar backing [LayrzCodeLanguage.plain] — deliberately empty.
///
/// With no rules to try, `LayrzSyntaxHighlighter.tokenize`'s no-rule-matched
/// branch fires for every character, emitting each one as its own
/// [LayrzHighlightScope.text] token. The result is a fully-tokenized (every
/// character covered), unstyled pass-through: no keyword, string, number, or
/// any other scope is ever assigned for this language.
const LayrzGrammar plainGrammar = LayrzGrammar(rules: []);
