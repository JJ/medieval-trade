#!/usr/bin/env raku

# Remove all \rev{...} tags from the input file and print to stdout

multi sub MAIN(Str $file where *.IO.e) {
    my $content = $file.IO.slurp;

    # Recursive, balanced-brace matcher
    my regex br { '{' ~ '}' [ <-[{}]> ]* }

    # Replace \rev{ ...balanced... } with its inner balanced content
    # Allow optional whitespace between the command and the opening brace
    $content ~~ s:g/ \\ 'rev' <.ws>? <br> /{ $<br>.Str.substr(1, $<br>.chars - 2) }/;
    say $content;
}

# If no arguments provided, show usage
multi sub MAIN() {
    say "Usage: $*PROGRAM-NAME <filename>";
    say "Removes all \\rev{...} tags from the input file and prints to stdout";
}
