#!/usr/bin/env raku
#
# Reverse-geocodes mint coordinates into countries via the Geoapify API.
#
# Usage: geolocalize-mints.raku <input.csv>
#
# Resumable: on error (network hiccup, rate limit...) progress is kept in a
# hidden checkpoint file next to the output; re-running the script picks up
# right after the last mint that was successfully written.
#
# Coordinates already present in data-raw/flame-database-last-version-mints-country.csv
# are reused instead of hitting the API again.

use Text::CSV;
use WWW;

constant GEOAPI_KEY = %*ENV<GEOAPIFY_API_KEY>;
constant COORD_CACHE_FILE = 'data-raw/flame-database-last-version-mints-country.csv';

sub round-coord($x) { sprintf('%.6f', $x.Num) }

sub load-coord-cache(--> Hash) {
    return {} unless COORD_CACHE_FILE.IO.e;
    my @cached = csv(in => COORD_CACHE_FILE, headers => 'auto', sep => ';');
    my %cache;
    for @cached -> $row {
        next unless $row<location_lat> && $row<location_long> && $row<Country>;
        %cache{ round-coord($row<location_lat>) ~ ',' ~ round-coord($row<location_long>) } = $row<Country>;
    }
    return %cache;
}

sub checkpoint($checkpoint-file, $id) {
    my $tmp = "$checkpoint-file.tmp";
    spurt $tmp, $id;
    rename $tmp, $checkpoint-file;
}


sub MAIN(Str $input-file) {
    die "Set GEOAPIFY_API_KEY in the environment" unless GEOAPI_KEY;
    die "No such file: $input-file" unless $input-file.IO.e;

    my $in-path = $input-file.IO;
    my $ext = $in-path.extension;
    my $stem = $in-path.basename.subst(/ '.' $ext $ /, '');
    my $dir = $in-path.dirname;

    my $output-file = "$dir/{$stem}-country.$ext";
    my $checkpoint-file = "$dir/.{$stem}-country.checkpoint";

    my @mints = csv(in => $input-file, headers => "auto");

    say @mints.elems ~ " mints read from $input-file";
    my @header = @mints[0].keys;
    my @out-header = flat @header, "Country";
    say "Out-header is {@out-header.join(';')}";

    my $start-index = 0;
    my $resuming = False;
    if $checkpoint-file.IO.e {
        my $last-id = $checkpoint-file.IO.slurp.trim;
        my $found = @mints.first(*.<ID> eq $last-id, :k);
        if $found.defined {
            $start-index = $found + 1;
            $resuming = True;
            say "Resuming after ID $last-id (row {$start-index + 1}/{@mints.elems})";
        }
        else {
            say "Checkpoint ID $last-id not found in input, starting from the beginning";
        }
    }

    my %coord-cache = load-coord-cache();

    my $out-fh = $resuming
        ?? $output-file.IO.open(:a, :enc<utf8>)
        !! $output-file.IO.open(:w, :enc<utf8>);
    unless $resuming {
        my $header-csv = Text::CSV.new(sep => ';');
        $header-csv.combine(@out-header);
        $out-fh.say($header-csv.string);
    }

    say "Processing mints from row {$start-index + 1} to {@mints.elems}";
    for $start-index ..^ @mints.elems -> $i {
        my $mint = @mints[$i];
        my $mint-lat = $mint<location_lat>;
        my $mint-lon = $mint<location_long>;
        my $cache-key = round-coord($mint-lat) ~ ',' ~ round-coord($mint-lon);

        my $country;
        if %coord-cache{$cache-key}:exists {
            $country = %coord-cache{$cache-key};
            say "Found in cache $country";
        }
        else {
            my $uri = "https://api.geoapify.com/v1/geocode/reverse?lat=$mint-lat&lon=$mint-lon&apiKey={GEOAPI_KEY}";
            try {
                my $geo-data = jget $uri;
                $country = $geo-data<features>[0]<properties><country>;
                CATCH {
                    default {
                        say "Error: $_ for mint ID {$mint<ID>}";
                        $out-fh.close;
                        exit 1;
                    }
                }
            }
            sleep 0.5;
        }

        $country = $country || 'UNKNOWN';

        say "{$mint<ID>} {$mint<location_title>}: $country";
        my @fields = @header.map({ $mint{$_} // '' });
        @fields.push($country);
        my $row-csv = Text::CSV.new(sep => ';');
        $row-csv.combine(@fields);
        $out-fh.say($row-csv.string);
        $out-fh.flush;

        checkpoint($checkpoint-file, $mint<ID>);
    }

    $out-fh.close;
    $checkpoint-file.IO.unlink if $checkpoint-file.IO.e;
    say "Done. Wrote $output-file";
}
