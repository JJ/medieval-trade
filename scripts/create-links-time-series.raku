#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @links-out;
for @coin-groups -> %coin-group {
    my %link = ( hoard => %coin-group<CoinFinding_ID>,
                 mint => %coin-group<Mint_ID> );
    next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
    if %coin-group<cg_start_year> == 0 {
        if %coin-group<cg_custom_start_century> > 0 {
            %link<year> = %coin-group<cg_custom_start_century>*100-50;
        } elsif %coin-group<cg_custom_end_century> > 0 {
            %link<year> = %coin-group<cg_custom_end_century>*100-50;
        } else {
            next;
        }
    } else {
        %link<year> = %coin-group<cg_start_year> + floor( (%coin-group<cg_end_year> - %coin-group<cg_start_year>)/2 );
    }
    if %link<year> == 0 {
        say %coin-group;
    }
    @links-out.push(%link);
}

csv( in => @links-out, out => "data/links.csv", sep => ";", headers => 'auto' );
