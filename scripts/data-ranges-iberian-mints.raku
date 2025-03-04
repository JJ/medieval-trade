#!/usr/bin/env raku

use Text::CSV;

my %iberian-mints = csv(in => 'data-raw/flame-database-last-version-mints-iberian-peninsula.csv', headers => 'auto', sep=>";", key => "ID");

my %date-ranges = csv(in => 'data-raw/mint-dates.csv', headers => 'auto', sep=>";", key => "Mint_ID");

my %mints-year;

for %iberian-mints.keys -> $mint {
    next unless %date-ranges{$mint}:exists;

    for %date-ranges{$mint}<Start>..%date-ranges{$mint}<End> -> $year {
        if %mints-year{$year}:exists {
            %mints-year{$year} ∪= $mint;
        } else {
            %mints-year{$year} = Set.new: [$mint];
        }
    }
}


say "Year;Mints";
for %mints-year.keys.sort -> $year {
    say "$year;", %mints-year{$year}.elems;
}
