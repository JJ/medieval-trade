#!/usr/bin/env raku

use Text::CSV;

my @pollution = csv(in => 'data-raw/lead-pollution-from-pnas.csv', headers => 'auto', sep=>";");

my @pollution-decade;
constant DECADE = 10;
loop (my $i = 0; $i < @pollution.elems; $i+=DECADE ){
    my @filtered-values = @pollution[$i..$i+DECADE-1].grep( *.<Non-bg-lead-flux> > 0);
    my $average = sum(@filtered-values.map: *.<Non-bg-lead-flux>)/@filtered-values.elems;
    my $decade = floor(@pollution[$i]<Year>/10)*10;
    my %pollution-decade = ( decade => $decade,
                             averageNonBgLeadFlux => $average );
    @pollution-decade.push(%pollution-decade);
}

csv( in => @pollution-decade, out => "data/pollution-data.csv", sep => ";", headers => 'auto' );
