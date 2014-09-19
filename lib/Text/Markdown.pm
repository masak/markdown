module Text::Markdown;

class Document {
    has @.children;

    method to_html() {
        my $s;
        for self.children -> $c {
            for $c.children -> $p {
                $s ~= $p.text ~~ Match ?? $p.text.orig !! $p.text;
            }
        }
        return $s;
    }
}

class Para {
    has $.text;
    has @.children;
}

class TSpan {
    has $.text;
    has $.font-style = '';
    has $.font-weight = '';
    has $.font-family = '';
}

my %g_escape_table = <
    \\ 28d397e87306b8631f3ed80d858d35f0
    ]  0fbd1776e1ad22c59a7080d35c7fd4db
    {  f95b70fdc3088560732a5ac135644506
    #  01abfc750a0c942167651c40d088531d
    \> cedf8da05466bb54708268b3c694a78f
    *  3389dae361af79b04c9c8e7057f60cc6
    _  b14a7b8059d9c055954c92674ce60032
    +  26b17225b626fb9238849fd60eabdf60
    -  336d5ebc5436534e61d16e63ddfca327
    )  9371d7a2e3ae86a00aab4771e39d255d
    .  5058f1af8388633f609cadb75a75dc9d
    [  815417267f76f6f460a4a61f9db75fdb
    (  84c40473414caf2ed4a7b1283e48bbf4
    `  833344d5e1432da82ef02e1301477ce8
    }  cbb184dd8e05c9709e5dcaedaa0495cf
    !  9033e0e305f247c0c3c80d0c7848c8b3
>;

sub _EncodeCode($_ is copy) {
#
# Encode/escape certain characters inside Markdown code runs.
# The point is that in code, these characters are literals,
# and lose their special Markdown meanings.
#
    # Encode all ampersands; HTML entities are not
    # entities within a Markdown code span.
    s:g['&'] = '&amp';

    # Do the angle bracket song and dance:
    s:g['<'] = '&lt;';
    s:g['>'] = '&gt;';

    # Now, escape characters that are magic in Markdown:
    s:g[ '*'  ] = %g_escape_table<*>;
    s:g[ '_'  ] = %g_escape_table<_>;
    s:g[ '{'  ] = %g_escape_table<{>;
    s:g[ '}'  ] = %g_escape_table<}>;
    s:g[ '['  ] = %g_escape_table<[>;
    s:g[ ']'  ] = %g_escape_table<]>;
    s:g[ '\\' ] = %g_escape_table<\\>;

    return $_;
}

sub _DoCodeSpans($text is copy) {
#
#   *   Backtick quotes are used for <code></code> spans.
#
#   *   You can use multiple backticks as the delimiters if you want to
#       include literal backticks in the code span. So, this input:
#
#         Just type ``foo `bar` baz`` at the prompt.
#
#       Will translate to:
#
#         <p>Just type <code>foo `bar` baz</code> at the prompt.</p>
#
#       There's no arbitrary limit to the number of backticks you
#       can use as delimters. If you need three consecutive backticks
#       in your code, use four for delimiters, etc.
#
#   *   You can use spaces to get literal backticks at the edges:
#
#         ... type `` `bar` `` ...
#
#       Turns to:
#
#         ... type <code>`bar`</code> ...
#

    $text ~~ s:g/ ('`'+) (.+?) <!after '`'> $0 <!before '`'> /{
        my $c = $1.trim;
        $c = _EncodeCode($c);
        "<code>{$c}</code>"
    }/;

    return $text;
}

sub _DoItalicsAndBold($text is copy) {
    # <strong> must go first:
    $text ~~ s:g[ ('**'||'__') <?before \S> (.+?<[*_]>*) <?after \S> $0 ]
        = "<strong>{$1}</strong>";

    $text ~~ s:g[ ('*'||'_') <?before \S> (.+?) <?after \S> $0 ]
        = "<em>{$1}</em>";

    return $text;
}

sub _UnescapeSpecialChars($text) {
#
# Swap back in all the special characters we've hidden.
#
    return $text.trans( [%g_escape_table.values] => [%g_escape_table.keys] );
}

sub extract_tspans($text) {
    # XXX the below regex wouldn't work for e.g. <b><em><b>foo</b></em></b>
    gather for $text.split(/'<'(\w+)'>'.*?'</'$0'>'/, :all) -> $normal, $taggy? {
        take TSpan.new(:text($normal));
        if $taggy {
            # XXX highly specialized but works for our immediate purposes
            $taggy.Str ~~ /^ ['<'(\w+)'>']+ (.*?) ['</'\w+'>']+ $/;
            my @tags = $0».Str;
            my $contents = $1;
            my %attrs;
            if any(@tags) eq 'em' { %attrs<font-style> = 'italic' }
            if any(@tags) eq 'strong' { %attrs<font-weight> = 'bold' }
            if any(@tags) eq 'code' { %attrs<font-family> = 'monospace' }
            take TSpan.new(:text($contents), |%attrs);
        }
    }
}

grammar Markdown {
    token TOP {
        ^ <paragraph>* % [\n\n+] \n* $
        { make Document.new(:children($<paragraph>».ast)) }
    }

    token paragraph {
        [<!before \n\n> .]+
        {
            my $text = ~$/;
            $text = _DoCodeSpans($text);
            $text = _DoItalicsAndBold($text);
            $text = _UnescapeSpecialChars($text);

            my @children = extract_tspans($text);

            make Para.new(:$text, :@children);
        }
    }
}

sub parse-markdown(Cool $text) is export {
    Markdown.parse($text).ast;
}
