#! perl
#
# Usage: gs-eps epsfile <outputfile> <resolution> <device>
#
# Where: epsfile is the encapsulated postscript file
#        outputfile is the output file (the default name
#          is <basename epsfile>.<device>)
#        resolution is the output resolution (default=300)
#        device is the GS driver to use (default=pbm)

($epsfile,$outputfile,$res,$device) = @ARGV;

if (! $epsfile) {
  printf "Usage: gs-eps epsfile <outputfile> <resolution>";
  printf " <gsdriver>\n";
  printf "Note: parameters are positional.  To specify a";
  printf " driver, you\n";
  printf "must also specify an outputfile and resolution.\n";
  exit 1;
  }
    
$epsfile =~ tr/\\/\//; # translate \foo\bar -> /foo/bar

if (! -r $epsfile) {
  printf "Cannot read file: $epsfile\n";
  exit 1;
  }

if (! $res)         { $res = 300 }
if (! $device)      { $device = "pbm" }

if (! $outputfile ) {
  @pathname = split(/\//,$epsfile);
  $outputfile = $pathname[$#pathname];
  $outputfile =~ s/.eps$//;
  $outputfile = join(".", $outputfile, $device);
  }

printf "Converting $epsfile to $outputfile at ${res}dpi...\n";

open (EPSFILE,$epsfile);

undef $bbox;
undef $showpg;
while (<EPSFILE>) {
  $bbox = $_ if /\%\%\s*BoundingBox:\s*\d+\s+\d+\s+\d+\s+\d+/;
  $showpage = $_ if /showpage/;
  last if ($bbox && $showpage);
  }

if (! $bbox) {
  printf "Cannot find a bounding box in $epsfile";
  exit 1;
  }

$bbox =~ s/\D*//;   # remove everything preceding the digits

($llx,$lly,$urx,$ury) = split(/\s/,$bbox);

$xsize = sprintf("%d", (($urx - $llx) * $res / 72) + 0.5);
$ysize = sprintf("%d", (($ury - $lly) * $res / 72) + 0.5);

printf "$llx neg $lly neg translate > gs-eps-a.$$\n";
printf "quit > gs-eps-b.$$\n";

if (! $showpg) {
  printf "showpage > gs-eps-b.$$\n";
  printf "quit >> gs-eps-b.$$\n";
  }

# join sillyness to keep the length of lines in the
# script small enough to print in the book.
$gscmd = join(" ", "gs -sDEVICE=$device",
                   "-q -sOutputFile=$outputfile",
                   "-g${xsize}x${ysize} -r$res",
	 	   "gs-eps-a.$$ $epsfile -",
		   "< gs-eps-b.$$");

printf "$gscmd\n";

printf "rm -f gs-eps-a.$$ gs-eps-b.$$\n";
