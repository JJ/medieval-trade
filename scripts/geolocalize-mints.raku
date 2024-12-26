#!/usr/bin/env raku

use Text::CSV;
use WWW;

constant GEOAPI_KEY = %ENV<GEOAPIFY_API_KEY>;
my @mints = csv(in => 'data-raw/flame-database-last-version-mints.csv', headers => 'auto', sep=>";");

my %mints-out;
for @mints -> $mint {
    %mints-out{$mint<id>} = { name => $mint<name> };
    my $mint_lat = $mint<latitude>;
    my $mint_lon = $mint<longitude>;
    my $geo-data= jget "https://api.geoapify.com/v1/geocode/reverse?lat=$mint_lat&lon=$mint_lon&apiKey={GEOAPI_KEY}";
    say $geo-data;
    sleep 1;
}

