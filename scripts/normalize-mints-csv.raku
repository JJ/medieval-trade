#!/usr/bin/env raku

use Text::CSV;

my @mints = csv(in => 'data-raw/flame-database-last-version-mints-country.csv', headers => 'auto', sep=>";");

my @mints-out;
for @mints -> $mint {
    my $mint-out = $mint;
    for <location_modern_title location_other_title location_uncertain location_lat location_long LegendID> -> $field {
        $mint-out{$field}:delete;
    }
    @mints-out.push($mint-out);
}

csv( in => @mints-out, out => "data/mint-data.csv", sep => ";", headers => 'auto' );
