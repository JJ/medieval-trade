#!/usr/bin/env raku

use Text::CSV;


sub MAIN(Str $coin-group-file, Str $mint-country-file, Str $coin-findings-file, Str $out-file) {

    my @coin-groups = csv(in => $coin-group-file, headers => 'auto');

    die "No se puede leer $coin-group-file" unless @coin-groups.elems;

    my @mints = csv(in => $mint-country-file, headers => 'auto', sep=>";");
    my $mints-set = Set.new( @mints.map( { $_<ID> } ) );
    my %mint-locations = @mints.map( { $_<ID> => $_<Country> } ).flat;
    
    my @findings = csv(in => $coin-findings-file, headers => 'auto');
    my $findings = Set.new( @findings.map( { $_<ID> } ) );
    my %finding-locations = @findings.map( { $_<ID> => $_<Region>  } ).flat;

    my @links-out;
    my $unknown-hoard-id = 0;
    my $unknown-mint-id = 0;
    for @coin-groups -> %coin-group {
        next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
        next unless %coin-group<Mint_ID> ∈ $mints-set || %coin-group<CoinFinding_ID> ∈ $findings;

        my $mint;
        if (%coin-group<Mint_ID> eq "") || ( %mint-locations{ %coin-group<Mint_ID> } eq "" ) || ( ~%mint-locations{ %coin-group<Mint_ID> } eq "(Any)" ) {
            $mint = "Unknown mintner-" ~ $unknown-mint-id++;
        } else  {
            $mint = %mint-locations{ %coin-group<Mint_ID> };
        }
        my %link = ( hoard => %finding-locations{ %coin-group<CoinFinding_ID> } // "Unknown hoard-" ~ $unknown-hoard-id++,
                     mint => $mint,
                     num_coins => %coin-group<cg_num_coins>);

        say "years ", %coin-group<cg_end_year>, " - ",  %coin-group<cg_start_year>;
        if %coin-group<cg_start_year> == 0 || %coin-group<cg_start_year> eq "NA" || %coin-group<cg_end_year> eq "NA" {
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

        die "Wrong mint %link " ~ %finding-locations unless %link<mint> ~~ Str;
        @links-out.push(%link);

    }

    csv( in => @links-out, out => $out-file, sep => ";", headers => 'auto' );
}
