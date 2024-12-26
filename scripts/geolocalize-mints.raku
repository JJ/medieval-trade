#!/usr/bin/env raku

use Text::CSV;
use WWW;

constant GEOAPI_KEY = %*ENV<GEOAPIFY_API_KEY>;
my @mints = csv(in => 'data-raw/flame-database-last-version-mints-partial.csv', headers => 'auto', sep=>";");

my %mints-out;
for @mints -> $mint {
    %mints-out{$mint<ID>} = { name => $mint<location-title> };
    my $mint_lat = $mint<location_lat>;
    my $mint_lon = $mint<location_long>;
    my $uri = "https://api.geoapify.com/v1/geocode/reverse?lat=$mint_lat&lon=$mint_lon&apiKey={GEOAPI_KEY}";
    try {
        my $geo-data= jget $uri;
        say $geo-data<features>[0]<properties><country>;
        %mints-out{$mint<ID>}<country> = $geo-data<features>[0]<properties><country>;
    }
    if $! {
        say "Error: $! for $mint";
    }
    sleep 0.5;
}
