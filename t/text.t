use v6;
use Test;
use Text::Markdown;

{
    my $doc = parse-markdown "One paragraph";

    is +$doc.children, 1, "Only one paragraph";
}

{
    my $doc = parse-markdown "One slide.\n\nTwo paragraphs.";

    is +$doc.children, 2, "The slide has two elements";
}

{
    my $doc = parse-markdown "One slide.\n\n\nTwo paragraphs and some blanks.\n\n\n\n";

    is +$doc.children, 2, "input ending with newline chars";
    is $doc.children[1].text, "Two paragraphs and some blanks.", "any number of blank lines between paragraphs";
}

{
    my $doc = parse-markdown "One slide with *italics* in it.";
    my $para = $doc.children[0];

    isa_ok $para, Text::Markdown::Para;
    is +$para.children, 3, "The text has three elements";
    is $para.children[0].text, "One slide with ", 'correct 1/3 tspan';
    is $para.children[1].text, "italics", 'correct 2/3 tspan';
    is $para.children[2].text, " in it.", 'correct 3/3 tspan';
    is $para.children[0].font-style, "", 'correct 1/3 font-style';
    is $para.children[1].font-style, "italic", 'correct 2/3 font-style';
    is $para.children[2].font-style, "", 'correct 3/3 font-style';
}

{
    my $doc = parse-markdown "One slide with **bold** in it.";
    my $para = $doc.children[0];

    isa_ok $para, Text::Markdown::Para;
    is +$para.children, 3, "The text has three elements";
    is $para.children[0].text, "One slide with ", 'correct 1/3 tspan';
    is $para.children[1].text, "bold", 'correct 2/3 tspan';
    is $para.children[2].text, " in it.", 'correct 3/3 tspan';
    is $para.children[0].font-weight, "", 'correct 1/3 font-weight';
    is $para.children[1].font-weight, "bold", 'correct 2/3 font-weight';
    is $para.children[2].font-weight, "", 'correct 3/3 font-weight';
}

{
    my $doc = parse-markdown "Both *beer* and **cheesecake**!?";
    my $para = $doc.children[0];

    is +$para.children, 5, "handles italic and bold combined";
}

{
    my $doc = parse-markdown "Now we use both *italics* and **bold** ***and*** combine them.";
    my $para = $doc.children[0];

    isa_ok $para, Text::Markdown::Para;
    is +$para.children, 7, "The text has seven elements";
    is $para.children[0].text, "Now we use both ", 'correct 1/7 tspan';
    is $para.children[1].text, "italics", 'correct 2/7 tspan';
    is $para.children[2].text, " and ", 'correct 3/7 tspan';
    is $para.children[3].text, "bold", 'correct 4/7 tspan';
    is $para.children[4].text, " ", 'correct 5/7 tspan';
    is $para.children[5].text, "and", 'correct 6/7 tspan';
    is $para.children[6].text, " combine them.", 'correct 7/7 tspan';
    is $para.children[0].font-style, "", 'correct 1/7 font-style';
    is $para.children[1].font-style, "italic", 'correct 2/7 font-style';
    is $para.children[2].font-style, "", 'correct 3/7 font-style';
    is $para.children[3].font-style, "", 'correct 4/7 font-style';
    is $para.children[4].font-style, "", 'correct 5/7 font-style';
    is $para.children[5].font-style, "italic", 'correct 6/7 font-style';
    is $para.children[6].font-style, "", 'correct 7/7 font-style';
    is $para.children[0].font-weight, "", 'correct 1/7 font-weight';
    is $para.children[1].font-weight, "", 'correct 2/7 font-weight';
    is $para.children[2].font-weight, "", 'correct 3/7 font-weight';
    is $para.children[3].font-weight, "bold", 'correct 4/7 font-weight';
    is $para.children[4].font-weight, "", 'correct 5/7 font-weight';
    is $para.children[5].font-weight, "bold", 'correct 6/7 font-weight';
    is $para.children[6].font-weight, "", 'correct 7/7 font-weight';
}

{
    my $doc = parse-markdown "This text contains `code` written in Perl 6.";
    my $para = $doc.children[0];

    isa_ok $para, Text::Markdown::Para;
    is +$para.children, 3, "The text has 3 elements.";
    is $para.children[0].text, "This text contains ", 'correct 1/3 tspan';
    is $para.children[1].text, "code", 'correct 2/3 tspan';
    is $para.children[2].text, " written in Perl 6.", 'correct 3/3 tspan';
    is $para.children[0].font-family, '', 'correct 1/3 font-family';
    is $para.children[1].font-family, 'monospace', 'correct 2/3 font-family';
    is $para.children[2].font-family, '', 'correct 3/3 font-family';
}

done;
