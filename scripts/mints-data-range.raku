#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my %mint-start;
my %mint-end;

for @coin-groups -> %mint-endgroup {
    my $mint = %group<Mint_ID>;
    if %mint-start{$mint}:exists {
        %mint-start{$mint} = %group<cg_start_year>;
    } elsif %mint-start{$mint} > %group<cg_start_year> {
        %mint-start{$mint} = %group<cg_start_year>;
    }
}