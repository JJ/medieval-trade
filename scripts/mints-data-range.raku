#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my %mint-start;
my %mint-end;

for @coin-groups -> %group {
    next unless %group<Mint_ID>;
    my $mint = %group<Mint_ID>;
    if %mint-start{$mint}:!exists {
        %mint-start{$mint} = %group<cg_start_year>;
    } elsif %mint-start{$mint} > %group<cg_start_year> {
        %mint-start{$mint} = %group<cg_start_year>;
    }

    if %mint-end{$mint}:!exists {
        %mint-end{$mint} = %group<cg_end_year>;
    } elsif %mint-end{$mint} < %group<cg_end_year> {
        %mint-end{$mint} = %group<cg_end_year>;
    }
}

say "Mint_ID;Start;End";
for %mint-start.keys -> $mint {
    say "$mint;%mint-start{$mint};%mint-end{$mint}";
}