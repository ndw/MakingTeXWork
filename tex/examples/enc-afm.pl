#! /usr/local/bin/perl
#
# Usage: enc-afm afm-file enc-file > encoded-afm-file
#
# Where: afm-file is the original AFM file with an arbitrary 
#        encoding enc-file is the encoding file (in PS 
#        format, a la dvips .enc files) encoded-afm-file is 
#        the new AFM file with 'enc-file' encoding.
#

# what about .notdef?

$afmfile = @ARGV[0];
$encfile = @ARGV[1];

print STDERR "Reading encoding file: $encfile\n";
&read_encfile($encfile);
print STDERR "Reading AFM file: $afmfile\n";
&read_afmfile($afmfile);

# Assign the correct encoding position to each char 
$missing = 0;
for ($count = 0; $count < $vectorlen; $count++) {
    $missing_glyphs{@encoding[$count]} = 1, $missing = 1 
	if !defined($vectorplace{@encoding[$count]}) 
           && @encoding[$count] ne ".notdef";
    $vectorplace{@encoding[$count]} = $count;
}

&print_long_list("Note: the following glyphs are missing "
		  . "from the AFM file: ",
		 sort (keys %missing_glyphs))
	     if $missing;

# Construct the CharMetrics lines
@output_encoding = ();
foreach $name (keys %metrics) {
    push (@output_encoding, 
	  sprintf("C %3d ; %s", 
		  $vectorplace{$name}, $metrics{$name}));
}

# Sort the CharMetrics lines
@sorted_encoding = sort (@output_encoding);

# Move the unused characters to the end of the list
@output_encoding = grep(/^C\s+\d+/, @sorted_encoding);
@minusone_encoding = grep(/C\s+-1/, @sorted_encoding);
push(@output_encoding, @minusone_encoding);

# Print the new AFM file
print $line, "\n" while ($line = shift @preamble);

print "Comment Encoded with enc-afm from $encfile.\n";
print "EncodingScheme $encname\n";
printf "StartCharMetrics %d\n", $#output_encoding+1;
print $line, "\n" while ($line = shift @output_encoding);
print "EndCharMetrics\n";

print $line, "\n" while ($line = shift @postamble);

exit 0;

sub read_afmfile {
    local ($afmfile) = @_;
    local ($inpreamble, $inmetrics, $inpostamble) = (1,0);
    local ($width, $name, $bbox, $prname);

    @preamble = ();
    %metrics = ();
    %vectorplace = ();
    @postamble = ();

    open (AFM, $afmfile) 
	|| die "Can't open afm file: $afmfile\n";

    while (<AFM>) {
	chop;

	push(@postamble, $_) if $inpostamble;
	push(@preamble, $_) 
	    if $inpreamble && ! /^EncodingScheme\s/i;

	if (/^EndCharMetrics/) {
	    $inmetrics = 0;
	    $inpostamble = 1;
	}
	    
	if ($inmetrics) {
	    $width = $1 if /[;\s]+WX\s+([0-9]+)[;\s]+/;
	    $name = $1 if /[;\s]+N\s+(\w+)[;\s]+/;
	    $bbox = $1 if /[;\s]+B\s+([^;]+)[;\s]+/;
	    die "Invalid line in AFM file: $_\n"
		if ($name eq "");
	    $metrics{$name} = sprintf("WX %4d ; N %s ; B %s ;",
				      $width, $name, $bbox);
	    $vectorplace{$name} = -1;
	}

	if (/^StartCharMetrics/) {
	    $inpreamble = 0;
	    $inmetrics = 1;
	}
    }
}	

sub read_encfile {
    local ($encfile) = @_;
    local ($place, $line);

    open (ENC, $encfile) 
	|| die "Can't open encoding file: $encfile\n";

    $encname = "";
    @encoding = ();
    $#encoding = 256; # set the array length
    $vectorlen = 0;
    $done = 0;
    while (<ENC>) {
	chop;
	next if /^\s*%/;
	
	$line = $_;
	if ($encname eq "") {
	    die "Invalid line in encoding file: $_\n" 
		if ! /\s*\/(.*)\s*\[(.*)$/;
	    $encname = $1;
	    $line = $2;
	}

	$place = index($line, "%");
	$line = substr($line,$[,$place-1) if $place >= $[;
 
	$place = index($line, "]");
	if ($place >= $[) {
	    $line = substr($line,$[,$place-1);
	    $done = 1;
	}
	
	while ($line =~ /^\s*\/(\S*)\s*(.*)$/) {
	    @encoding[$vectorlen++] = $1;
	    $line = $2;
	}
	
	last if $done;
    }
}
    
############################################################
# This routine prints a message followed by a potentially 
# long list of items, seperated by spaces.  It will never 
# allow "word wrap" to occur in the middle of a word.  There 
# has to be a better way, using Perl's report generation to 
# do this, but I haven't looked yet.
#
sub print_long_list {
  local ($message,@thelist) = @_;
  local ($line) = $message;
  local ($item, $displaystring) = ("", "");

  foreach $item (@thelist) {
      if (length($line . $item) < 73) {
	  $line .= $item . ", ";
      } else {
	  $displaystring .= $line . "\n";
	  $line = $item . ", ";
      }
  }
  
  $line =~ s/(.*),\s*$/$1/;	# remove the last ", "...
  $displaystring .= $line . "\n";

  print STDERR $displaystring;
}  
