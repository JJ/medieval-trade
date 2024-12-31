#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @links-out;
for @coin-groups -> %coin-group {
    my %link = ( hoard => %coin-group<CoinFinding_ID>,
                 mint => %coin-group<Mint_ID> );

    %link<year> = %coin-group<cg_start_year> + floor( (%coin-group<cg_end_year> - %coin-group<cg_start_year>)/2 );
    @links-out.push(%link);
}

csv( in => @links-out, out => "data/links.csv", sep => ";", headers => 'auto' );
