#!/usr/bin/env raku

use Text::CSV;

my @pollution = csv(in => 'data-raw/lead-pollution-from-pnas.csv', headers => 'auto', sep=>";");

my @annual-pollution;
loop (my $i = 0; $i < @pollution.elems; $i++ ){
    my %pollution = ( year => floor(@pollution[$i]<Year>),
                      NonBgLeadFlux => @pollution[$i]<Non-bg-lead-flux> );
    @annual-pollution.push(%pollution);
}

csv( in => @annual-pollution, out => "data/annual-pollution-data.csv", sep => ";", headers => 'auto' );
