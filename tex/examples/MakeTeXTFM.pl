#!/usr/local/bin/perl
#
# MakeTeXTFM.pl version 1.0, Copyright (C) 1993,94 by Norman Walsh.
# NO WARRANTY.  Distribute freely under the GNU GPL.
#
# This script attempts to make a new TeX TFM file, because one wasn't
# found.  The only argument is the name of the TFM file, such as
# `cmr10.tfm' (*NOT* just `cmr10').
#
# This script was designed with two goals in mind: to support recursive
# subdirectory searching for fonts and to provide support for PK files 
# built from both MF fonts and PS fonts.  It also supports the Sauter
# and DC fonts which can be built at any design size.
#
# This script was designed and tested with the following directory structure
# in mind: each typeface is stored in its own directory with appropriate
# subdirectories for font sources, metrics, and glyphs.  The script may not
# work exactly right if you use a different directory structure (the font
# installation, in particular, will probably be incorrect).  However,
# several other versions of MakeTeXPK exist which will handle simpler 
# directory structures, so you need not feel compelled to use the one 
# described here.
#
# For MF fonts: (... is usually something like /usr/local/lib/tex/fonts)
#
# .../typeface/src          holds the sources
#             /tfm          holds the TFM files
#             /glyphs       root for glyphs
#             /glyphs/mode  holds the PK files for "mode".
#
# For PS fonts: (... is usually something like /usr/local/lib/tex/fonts)
#
# .../typeface/afm          holds the AFM files
#             /tfm          holds the TFM files
#             /vf           holds the VF files
#             /vpl          holds the VPL files
#             /glyphs       root for glyphs
#             /glyphs/pk/999dpi  holds the PK files at 999 dpi created by ps2pk
#             /glpyhs/type1 holds the type1 PFA/PFB sources for the fonts
#
# The TFM files constructed for PostScript fonts are mapped to the Old TeX
# encoding. 
#

require "getopts.pl";
$rc = &Getopts ('v');           # Get options from the user...

$VERBOSE = $opt_v || $ENV{"DEBUG_MAKETEXPK"}; # Verbose?

chop($CWD = `pwd`);             # Where are we?
$TEMPDIR = "/tmp/mkPK.$$";      # Where do temp files go?
$MFBASE = "&plain";             # What MF base do we use by default?

# Where are fonts stored?
$TEXFONTS = $ENV{"TEXFONTS"} || ".:/usr/local/lib/fonts//";

# Define modes that should be used for base resolutions...
$DPI_MODES{300}  = "laserwriter";
$DPI_MODES{200}  = "FAX";
$DPI_MODES{360}  = "lqhires";
$DPI_MODES{400}  = "nexthi";
$DPI_MODES{600}  = "QMSmoa";
$DPI_MODES{100}  = "nextscreen";

$DPI_MODES{100}  = "videodisplayi";
$DPI_MODES{110}  = "videodisplayii";
$DPI_MODES{118}  = "videodisplayiii";
$DPI_MODES{120}  = "videodisplayiv";
$DPI_MODES{124}  = "videodisplayv";
$DPI_MODES{130}  = "videodisplayvi";
$DPI_MODES{140}  = "videodisplayvii";
$DPI_MODES{150}  = "videodisplayviii";

$DPI_MODES{72}   = "MacTrueSize";
$DPI_MODES{635}  = "linolo";
$DPI_MODES{1270} = "linohi";
$DPI_MODES{2540} = "linosuper";

# Where are the DC fonts stored and what base names can be used?
$DCR_DIR = '/usr/local/lib/fonts/free/dc/src';
@DCR_GEN = ('dcb','dcbom','dcbx','dcbxsl','dcbxti','dccsc','dcdunh','dcff',
            'dcfi','dcfib','dcitt','dcr','dcsl','dcsltt','dcss','dcssbx',
            'dcssi','dctcsc','dcti','dctt','dcu','dcvtt' );

# Where are the Sauter fonts stored and what base names can be used?
$SAUTER_DIR = '/usr/local/lib/fonts/free/sauter/src';
@SAUTER_GEN = ('cmb','cmbizx','cmbozx','cmbsy','cmbszx','cmbx','cmbxsl', 
               'cmbxti', 'cmbz', 'cmbzx', 'cmcsc', 'cmdszc', 'cmdunh', 
               'cmex', 'cmff', 'cmfi', 'cmfib', 'cminch', 'cmitt', 'cmmi', 
               'cmmib', 'cmr', 'cmrcz', 'cmrisz', 'cmritz', 'cmriz', 
               'cmrotz', 'cmroz', 'cmrsz', 'cmrtz', 'cmruz', 'cmrz', 
               'cmsl', 'cmsltt', 'cmss', 'cmssbx', 'cmssdc', 'cmssi', 
               'cmssq', 'cmssqi', 'cmsy', 'cmtcsc', 'cmtex', 'cmti', 
               'cmtt', 'cmu', 'cmvtt', 'czinch', 'czssq', 'czssqi', 
               'lasy', 'lasyb');

$SAUTER_ROUNDING{11} = '10.954451';
$SAUTER_ROUNDING{14} = '14.4';
$SAUTER_ROUNDING{17} = '17.28';
$SAUTER_ROUNDING{20} = '20.736';
$SAUTER_ROUNDING{25} = '24.8832';
$SAUTER_ROUNDING{30} = '29.8685984';

open (TTY, ">/dev/tty");
select (TTY); $| = 1; select(STDOUT);

$tfmFile = @ARGV[0];
if (!$tfmFile) {
    print TTY "$0 error: No TFM file specified.\n";
    die "\n";
}

print TTY "\nAttempting to build TFM file: $tfmFile.\n";

# This is the *wierdest* bug I've ever seen.  When this script is called
# by virtex to build a TFM file, the argument (as interpreted by Perl)
# has (at least one) ASCII 16 attached to the end of the argument.  This
# loop removes all control characters from the $tfmFile name string...
$tfmFile =~ /(.)$/;
$char = ord ($1);
while ($char <= 32) {
    $tfmFile = $`;
    $tfmFile =~ /(.)$/;
    $char = ord ($1);
}

# Now we know the name of the TFM file.  Next, get the name of the MF file
# and the base name and size of the MF file.

($mfFile = $tfmFile) =~ s/\.tfm$//;
$mfFile =~ /^(.*[^0-9])(\d+)$/;
$mfBase = $1;
$mfSize = $2;

# Presumably, we got here because the TFM file doesn't exist.  Let's look
# for the MF file or the AFM file...

$tfmSource = &find_fonts($TEXFONTS, ("$mfFile.mf", "$mfFile.afm"));

if ($tfmSource) {
    if ($tfmSource =~ /\.afm$/) {
        print TTY "Building $tfmFile from AFM source.\n";
        &make_and_cd_tempdir();
        &make_from_afm($tfmSource);
    } elsif ($tfmSource =~ /\.mf$/) {
        local($fpath, $fname);
        print TTY "Building $tfmFile from MF source.\n";
        &make_and_cd_tempdir();

        if ($tfmSource =~ /^(.*)\/([^\/]*)$/) {
            $fpath = $1;
            $fname = $2;

            $fpath = $CWD if $fpath eq ".";
            $fpath = "$CWD/.." if $fpath eq "..";
        } else {
            $fpath = "";
            $fname = $tfmSource;
        }

        &make_from_mf($fpath, $fname);
    } else {
        print TTY "$0: Cannot build $tfmFile.\n";
        print TTY " " x length($0), "  Unprepared for $tfmSource.\n";
        die "\n";
    }
} else {
    if (grep(/^$mfBase$/, @DCR_GEN)) {

        print TTY "Building $tfmFile from DC source.\n";

        &make_and_cd_tempdir();

        $MFBASE = "&dxbase";
        open (MFFILE, ">$mfFile.mf");
        print MFFILE "gensize:=$mfSize; generate $mfBase;\n";
        close (MFFILE);

        &make_from_mf("$DCR_DIR","$mfFile.mf");

    } elsif (grep(/^$mfBase$/, @SAUTER_GEN)) {

        print TTY "Building $tfmFile from Sauter source.\n";

        &make_and_cd_tempdir();

        if (defined($SAUTER_ROUNDING{$mfSize})) {
            $designSize = $SAUTER_ROUNDING{$mfSize};
        } else {
            $designSize = $mfSize;
        }
            
        open (MFFILE, ">$mfFile.mf");
        print MFFILE "design_size := $designSize;\n";
        print MFFILE "input b-$mfBase;\n";
        close (MFFILE);

        &make_from_mf("$SAUTER_DIR","$mfFile.mf");

    } else {
        print TTY "$0: Cannot build $tfmFile.  Can't find source.\n";
        die "\n";
    }
}

&cleanup();

exit 0;

sub run {
    local(@cmd) = @_;
    local($rc);

    open  (SAVEOUT, ">&STDOUT");
    open  (SAVEERR, ">&STDERR");
    close (STDOUT);
    open  (STDOUT, ">&TTY");
    close (STDERR);
    open  (STDERR, ">&TTY");

    # Chdir seems to return a funny exit code.  So do it internally...
    # (this is a hack)
    if (@cmd[0] eq "chdir") {
        $rc = chdir(@cmd[1]);
        $rc = !$rc;
    } else {
        $rc = system(@cmd);
    }

    close (STDOUT);
    open  (STDOUT, ">&SAVEOUT");
    close (SAVEOUT);

    close (STDERR);
    open  (STDERR, ">&SAVEERR");
    close (SAVEERR);

    if ($rc) {
        printf TTY "%s\n", "*" x 72;
        print  TTY "MakeTeXTFM error : system return code: $rc\n";
        print  TTY "MakeTeXTFM failed: @cmd\n";
        printf TTY "%s\n", "*" x 72;
    }
    
    $rc;
}

sub make_and_cd_tempdir {
    &run ("mkdir", "$TEMPDIR");
    &run ("chdir", "$TEMPDIR");
}

sub cleanup {
    &run ("chdir", "$CWD");
    &run ("rm", "-rf", "$TEMPDIR");
}

sub install_font {
    local($source_path, $font, $subdir) = @_;
    local(@paths) = split(/:|;/,$ENV{"TEXFONTS"});
    local($target) = "";
    local($ptarget);
    
    if (!$target && $source_path =~ /\/src$/) {
        $ptarget = $source_path;
        $ptarget =~ s/(.*)\/src$/$1/;
        $ptarget .= "/$subdir";
        $target = $ptarget if (-d $ptarget && -w $ptarget);
    }

    if (!$target && $source_path =~ /\/afm$/) {
        $ptarget = $source_path;
        $ptarget =~ s/(.*)\/afm$/$1/;
        $ptarget .= "/$subdir";
        $target = $ptarget if (-d $ptarget && -w $ptarget);
    }

    if (!$target && ($source_path eq $CWD)) {
        $target = $source_path;
    }

    while (!$target && ($ptarget = shift @paths)) {
        $target = $ptarget if ($ptarget ne "." && $ptarget ne ".."
                               && -d $ptarget && -w $ptarget);
    }

    if ($target) {
        print TTY "Installing $font in $target.\n";
        &run ("cp", "$font", "$target/fonttmp.$$");
        &run ("chdir", "$target");
        &run ("mv", "fonttmp.$$", "$font");
        &run ("chmod", "a+r", "$font");
        &run ("chdir", "$TEMPDIR");
        print STDOUT "$target/$font\n";
    } else {
        print TTY "$0: Install failed: no where to put $font.\n";
    }
}

sub make_from_mf { 
    local ($source_path, $source_file) = @_;
    local ($mfsource, $mfinputs, $cmd);

    &run ("chdir", "$TEMPDIR");

    if (!$source_file) {
        $mfsource = $source_path;
        ($source_path = $mfsource) =~ s#/[^/]*$##;
        ($source_file = $mfsource) =~ s#^.*/([^/]*)$#$1#;
    }

    $mfinputs = $ENV{"MFINPUTS"};
    $mfinputs =~ s/^:*(.*):*$/$1/ if $mfinputs;
    $ENV{"MFINPUTS"} = ".:$source_path";
    $ENV{"MFINPUTS"} .= ":$mfinputs" if $mfinputs;

    print "MFINPUTS: $ENV{MFINPUTS}\n" if $VERBOSE;

    $cmd = "$MFBASE \\mode:=laserwriter; scrollmode; \\input $source_file";
    print TTY "virmf $cmd\n";

    $saveTERM = $ENV{"TERM"};
    $saveDISPLAY = $ENV{"DISPLAY"};
    delete $ENV{"DISPLAY"};
    $ENV{"TERM"} = "vt100";

    $rc = &run ("virmf", "$cmd");

    $ENV{"DISPLAY"} = $saveDISPLAY;
    $ENV{"TERM"} = $saveTERM;

    &install_font($source_path, $tfmFile, 'tfm');
}

sub make_from_afm {
    local ($afmFile) = @_;
    local ($source_path);

    print TTY "afm2tfm $afmFile -v $mfFile ${mfFile}0\n";
    $rc = &run ("afm2tfm", "$afmFile", "-v", "$mfFile", "${mfFile}0");

    print TTY "vptovf $mfFile.vpl $mfFile.vf $mfFile.tfm\n";
    $rc = &run ("vptovf", "$mfFile.vpl", "$mfFile.vf", "$mfFile.tfm");

    ($source_path = $afmFile) =~ s#/[^/]*$##;
    &install_font($source_path, "$mfFile.tfm", 'tfm');
    &install_font($source_path, "${mfFile}0.tfm", 'tfm');
    &install_font($source_path, "$mfFile.vpl", 'vpl');
    &install_font($source_path, "$mfFile.vf", 'vf');
}

sub find_fonts {
    local($path, @fonts) = @_;
    local(@dirs, $dir, $font);
    local(@matches) = ();
    local(@recursive_matches);

    print "Find fonts on path: $path\n" if $VERBOSE;

    @dirs = split(/:|;/, $path);
    while ($dir = shift @dirs) {
        print "Search: $dir\n" if $VERBOSE;
        if ($dir =~ /\/\//) {
            @recursive_matches = &recursive_search($dir, @fonts);
            push (@matches, @recursive_matches) 
                if @recursive_matches;
        } else {
            $dir =~ s/\/*$//;           # remove trailing /, if present
            foreach $font (@fonts) {
                push (@matches, "$dir/$font") 
                    if -f "$dir/$font";
            }
        }
    }

    $font = shift @matches;

    if (@matches) {
        print TTY "$0: Found more than one match.\n";
        print TTY " " x length($0), "  Using: $font\n";
    }

    $font;
}

sub recursive_search {
    local($dir, @fonts) = @_;
    local(@matches) = ();
    local(@dirstack, $rootdir, $font, $fontmask);

    $dir =~ /^(.*)\/\/(.*)$/;
    $rootdir = $1;
    $fontmask = $2;

    $rootdir =~ s/\/*$//;               # remove trailing /'s

    # Note: this perl script has to scan them all, the mask is meaningless.
    # Especially since I'm looking for the font *source* not the TFM or
    # PK file...

    $fontmask =~ s/\$MAKETEX_BASE_DPI/$BDPI/g;
    $fontmask =~ s/\$MAKETEX_MAG/$MAG/g;
    $fontmask =~ s/\$MAKETEX_MODE/$MODE/g;

    print "Search root=$rootdir\n" if $VERBOSE;
    print "Search mask=$fontmask (ignored by $0)\n" if $VERBOSE;

    @dirstack = ($rootdir);

    while ($rootdir = shift @dirstack) {
        opendir (SEARCHDIR, "$rootdir");
        while ($dir = scalar(readdir(SEARCHDIR))) {
            if ($dir ne "." && $dir ne ".." && -d "$rootdir/$dir") {
                push(@dirstack, "$rootdir/$dir");
                foreach $font (@fonts) {
                    if (-f "$rootdir/$dir/$font") {
                        print "Matched: $rootdir/$dir/$font\n" if $VERBOSE;
                        push(@matches, "$rootdir/$dir/$font");
                    }
                }
            }
        }
        closedir (SEARCHDIR);
    }

    @matches;
}
