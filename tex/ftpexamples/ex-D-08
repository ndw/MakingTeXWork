#!/usr/local/bin/perl
#
# txt2verb  Copyright (C) 1993 by Norm Walsh <norm@ora.com>
#           Distribute freely under the terms of the GNU Copyleft.
#
# Converts a text "screen" into a form suitable for \inputing into TeX
# and printing as a screen dump.  The original form is assumed to be
# a series of 80-byte lines with any character in the range 0-255 present
# (including CR and LF in the middle of a line).
#
# The output form is a series of lines of varying length.  There is 
# one output line for each input line.  TeX special characters and all
# characters in the ranges 0-31 and 127-255 are replaced by control
# sequences.
#
# Usage:
# 
#  txt2verb screenfile <texfile>
#
#  If texfile is not specified, stdout is assumed.
#
# Options:
#
#  -l    File of lines.  Input file contains lines of varying length, 
#        but no imbedded CR or LF chars.
#  -v    Verbose: print each input line as it's read.
#  -q    Quiet: no messages.
#  -L #  Set line length to '#' characters.
#
# To incorporate the resulting screen dump in your Plain TeX or LaTeX
# document, insert the following macro definitions before the first
# screen dump:
#
#  \font\screenfont=cr-pc8 at 8pt % use any IBM OEM encoded fixed width font!
#  
#  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  % These macros are derived from The TeXbook pg 380-381
#  \def\uncatcodespecials{\def\do##1{\catcode`##1=12 }\dospecials}
#  \def\setupverbatim{\screenfont%
#    \def\par{\leavevmode\endgraf\relax}%
#    \obeylines\uncatcodespecials%
#    \catcode`\\=0\catcode`\{=1\catcode`\}=2\obeyspaces}
#  {\obeyspaces\global\let =\ } % let active space be a control space
#  \def\screenlisting#1{\par\begingroup%
#    \def\c##1{\char##1}\setupverbatim\input{#1}%
#    \endgroup}
#  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  \def\screenbox#1{%
#    \vbox{\offinterlineskip%
#      \parskip=0pt\parindent=0pt%
#      \screenlisting{#1}}}
#  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  % Input converted file '#1' and set it inside a box with '#2' padding
#  % space around the image.
#  \def\screendump#1#2{%
#    \hbox{\vrule%
#      \vbox{\hrule%
#        \hbox{\hskip#2%
#          \vbox{\vskip#2%
#  	  \def\twentyxs{xxxxxxxxxxxxxxxxxxxx}%
#  	  \setbox0=\hbox{\screenfont\twentyxs\twentyxs\twentyxs\twentyxs}%
#  	  \hbox to \wd0{\screenbox{#1}\hss}%
#  	\vskip#2}%
#        \hskip#2}%
#      \hrule}%
#    \vrule\hss}}
#  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# To include the converted image 'screen.tex' in your document with 2pt
# of padding around the image, use:
# 
#   \screendump{screen}{2pt}
#
# in your document.  Note: since this is set as an 'hbox', you may need
# to use \leavevmode\screendump{screen}{2pt}
#
##########################################################################

require 'getopts.pl';
do Getopts('lvqL:');

die "$0: options make no sense: -l and -L $opt_L.\n" if $opt_l && $opt_L;

$FILEOFLINES = $opt_l;
$VERBOSE     = $opt_v;
$QUIET       = $opt_q;
$LINELENGTH  = $opt_L || 80;

$capturefile = @ARGV[0] || die "Usage: $0 capturefile <texfile>";
$texfile     = @ARGV[1] || "-";

select(STDERR); $| = 1; select(STDOUT); # no buffering of stderr

%badchars = ();	# These characters are illegal on input

# anything in the control character range
for ($byte = 0; $byte < 32; $byte++) {
    $char = sprintf("%c", $byte);
    $badchars{$char} = "\\c{$byte}";
}

# and anything over 126
for ($byte = 127; $byte < 256; $byte++) {
    $char = sprintf("%c", $byte);
    $badchars{$char} = "\\c{$byte}";
}

$badchars{"\%"} = '\%';
$badchars{"\$"} = '\$';
$badchars{"\&"} = '\&';
$badchars{"\#"} = '\#';
$badchars{"\{"} = '\c{123}';
$badchars{"\}"} = '\c{125}';
$badchars{"\\"} = '\c{92}';
$badchars{"\_"} = '\c{95}';
$badchars{"\^"} = '\c{94}';

open (CAPTFILE, $capturefile) 
    || die "Can't open capture file: $capturefile\n";
open (TEXFILE, ">$texfile")   
    || die "Can't open TeX file: $texfile\n";
while ($line = &get_line()) {
    print STDERR "." if $texfile ne "-" && !$VERBOSE && !$QUIET;
    print STDERR "$line\n" if $VERBOSE;

    $outputbuf = "";
    while (length($line) > 0) {
	$char = substr($line,0,1);
	$line = substr($line,1);

	if (defined($badchars{$char})) {
	    $outputbuf .= $badchars{$char};
	} else {
	    $outputbuf .= $char;
	}
    }
    print TEXFILE "$outputbuf\n";
}

close(CAPTFILE);
close(TEXFILE);

exit 0;

sub get_text_line {
    local($line);
    
    if ($line = scalar(<CAPTFILE>)) {
	chop($line);
    }

    $line;
}

sub get_data_line {
    local($datalen, $line);

    if ($datalen = read(CAPTFILE, $line, $LINELENGTH)) {
	# if we got a complete line, look to see if the next 
	# characters in the file are CR, CR/LF, or LF.  If so, remove
	# them (assume the are line breaks in the file)
	if ($datalen = $LINELENGTH) {
	    $place = tell(CAPTFILE);
	    $datalen = read(CAPTFILE, $line, 1);
	    if ($line eq "\015") {
		$place++;
		$datalen = read(CAPTFILE, $line, 1);
		if ($line ne "\012") {
		    seek(CAPTFILE, $place, 0);
		}
	    } elsif ($line ne "\012") {
		seek(CAPTFILE, $place, 0);
	    }
	}
    } else {
	return undef;
    }

    $line;
}

sub get_line {
    local($line);
    if ($FILEOFLINES) {
	$line = &get_text_line();
    } else {
	$line = &get_data_line();
    }

    $line;
}
