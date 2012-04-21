Perl 6 implementation of Markdown.

## Usage

    use Text::Markdown;

    my $doc = parse-markdown("Markdown *italics*, **bold** and `code`");
    say $doc.to_html;
