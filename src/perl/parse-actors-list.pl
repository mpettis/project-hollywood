#!/usr/bin/env perl

    ####----------------------------------------------------------------
    #### Config
    ####----------------------------------------------------------------
use Data::Dumper;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Text::CSV;


    ####----------------------------------------------------------------
    #### Declarations
    ####----------------------------------------------------------------

my $infile = '/Users/mpettis/Personal/project-hollywood/dat/actors.list.gz';


    ####----------------------------------------------------------------
    #### Process file
    ####----------------------------------------------------------------

    ### Iterator over the lines of the gzip file
my $gzfile = new IO::Uncompress::Gunzip $infile or die "gunzip failed: $GunzipError\n";


    ### Skip lines until I get to the list of actors
    ### Which is: skip to line that says 'THE ACTORS LIST'
    ### then skip 4 more lines.  That begins the table of actors
1 while ($gzfile->getline() !~ /^THE ACTORS LIST/);
$gzfile->getline() for (1..4);


    ### Get a chunk of lines that is an actor and appearances with that actor
    ### You know it is a chunk because it has a non-whitespace starting the line
    ### until you encounter a blank line.
open $fh, ">:encoding(utf8)", "/Users/mpettis/Personal/project-hollywood/dat/actors-shortlist.csv" or die "actors-shortlist.csv: $!";
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
$csv->eol ("\n");
my @csv_header = qw(actor_lnfn feature_name year is_tv is_voice character episode_info episode_season episode_number);
$csv->print ($fh, $_) for \@csv_header;



my $actor_count = 0;
while ($actor_count++ < 999) {
    my $actor_record = '';
    while (my $line = $gzfile->getline()) {
        last if($line =~ /^$/);
        $actor_record .= $line;
    }

        ### Parse the actor record (name + appearances)
    my @recs = parse_actor_record($actor_record);

    #print Dumper(\@recs), "\n";
    foreach my $actor_feature_hash (@recs) {
        #print Dumper($actor_feature_hash), "\n";
        #print Dumper($actor_feature_hash->{@csv_header}), "\n";
        #print $actor_feature_hash->{@csv_header}, "\n";
        #print $actor_feature_hash->{'is_tv'}, "\n";
        #print @{$actor_feature_hash}{@csv_header}, "\n";
        my @fields = @{$actor_feature_hash}{@csv_header};
        $csv->print ($fh, $_) for \@fields;
        #$csv->print ($fh, ["\n"]);
    }

    #print "-"x80, "\n";

    #my $actor = parse_actor($actor_record);
    #print "Actor: $actor", "\n";

    #parse_appearances($actor_record);
    #my $actor_appearances = parse_appearances($actor_record);
    #print "Appearances:\n";
    #print $actor_appearances, "\n";
}

close $fh;





    ####----------------------------------------------------------------
    #### Parsing functions
    ####----------------------------------------------------------------

    ### Parse the actor record
sub parse_actor_record {
    my $ar = shift;
    #print $ar;

        ### Separate the name from the rest of the record, which are the
        ### appearances.  Name and first appearance separated by tabs,
        ### each subsequent line is indented with tabs.
    my ($name, @appearances) = split(/\t+/, $ar);
    #print @appearances, "\n";

    my @recs;
    foreach my $app (@appearances) {
        my %feature = parse_feature($app);
        %feature = ('actor_lnfn', $name, %feature);
        #print Dumper(\%feature), "\n";
        push @recs, \%feature;
    }
    return @recs;
}


sub parse_feature {
        ### Parse apart the componenents of each appearance.
        ### Return a hash of components
    my $app = shift;
    #print $app;
    my %feature;

        ### Get feature name
    my ($feature) = $app =~ /^(.*)\s\(\d\d\d\d\)/;
    #print "Feature: $feature", "\n";
    $feature{'feature_name'} = $feature;

        ### Is it a TV appearance of not?
    my $is_tv = "false";
    if ($feature =~ /^\"/ or $app =~ / \(TV\)/) {$is_tv = "true"};
    #print "Is TV?: $is_tv", "\n";
    $feature{'is_tv'} = $is_tv;

        ### Year
    my ($year) = $app =~ /\((\d\d\d\d)\)/;
    #print "Year: $year", "\n";
    $feature{'year'} = $year;

        ### Character
    my ($character) = $app =~ /\[(.*?)\]/;
    #print "Character: $character", "\n";
    $feature{'character'} = $character;

        ### Is voice?
    my $is_voice = "false";
    if ($app =~ / \(V\)/) {$is_voice = "true"};
    #print "Is voice?: $is_voice", "\n";
    $feature{'is_voice'} = $is_voice;

        ### Episode info
    my ($episode_info) = $app =~ /{(.*?)}/;
    #print "Episode info: $episode_info", "\n";
    $feature{'episode_info'} = $episode_info;

        ### Episode season and number
    my ($episode_season, $episode_number) = ('', '');
    if ($episode_info ne "") {
        #my ($episode_season, $episode_number) = $episode_info = ~ /\(\#(\d+)\.(\d+)\)/;
        #print "Episode season: $episode_season", "\n";
        #print "Episode number: $episode_number", "\n";

        my ($enn) = $episode_info =~ /\((.*?)\)/;
        #print $enn, "\n";
        ($episode_season, $episode_number) = $enn =~ /(\d+)/g;
    }
    #print "Episode season: $episode_season", "\n";
    #print "Episode number: $episode_number", "\n";
    $feature{'episode_season'} = $episode_season;
    $feature{'episode_number'} = $episode_number;

    return %feature;
}

