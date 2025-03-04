#!/usr/bin/env raku

use Text::CSV;

my %iberian-mints = csv(in => 'data-raw/flame-database-last-version-mints-iberian-peninsula.csv', headers => 'auto', sep=>";", key => "ID");

my %date-ranges = csv(in => 'data-raw/mint-dates.csv', headers => 'auto', sep=>";", key => "Mint_ID");

my %mints-decade;

for %iberian-mints.keys -> $mint {
    next unless %date-ranges{$mint}:exists;

    loop ( my $year = floor( %date-ranges{$mint}<Start>/10 )*10; $year < %date-ranges{$mint}<End>; $year +=10 ) {
        if %mints-decade{$year}:exists {
            %mints-decade{$year} ∪= $mint;
        } else {
            %mints-decade{$year} = Set.new: [$mint];
        }
    }
}

say "Year;Mints";
for %mints-decade.keys.sort: { $^a <=> $^b } -> $year {
    say "$year;", %mints-decade{$year}.elems;
}
