#!/usr/local/bin/perl
#
# MakeTeXPK.pl version 1.0, Copyright (C) 1993,94 by Norman Walsh.
# NO WARRANTY.  Distribute freely under the GNU GPL.
#
# This script attempts to make a new TeX PK font, because one wasn't
# found.  Parameters are:
#
# name dpi bdpi [[[magnification] mode] subdir]
#
# `name'   is the name of the font, such as `cmr10' (*NOT* cmr10.mf).  
# `dpi'    is the resolution the font is needed at.  
# `bdpi'   is the base resolution, useful for figuring out the mode to 
#          make the font in.  
# `magnification' is a string to pass to MF as the magnification.  
# `mode'   if supplied, is the mode to use.
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

require "getopts.pl";
$rc = &Getopts ('v');           # Get options from the user...

$USE_MODE_IN_DEST = 1;          # Does the destination directory name include
                                # the name of the mode?

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

# Get the command line arguments...
($NAME, $DPI, $BDPI, $MAG, $MODE, $FORCEDEST, $EXTRA) = @ARGV;

open (TTY, ">/dev/tty");              # Open the TTY (so we can print messages
select (TTY); $| = 1; select(STDOUT); # even if STDERR and STDOUT are both
                                      # redirected)

if ($VERBOSE) {
    print TTY "$0: font name: $NAME\n";
    print TTY "$0: dpi: $DPI\n";
    print TTY "$0: base dpi: $BDPI\n";
    print TTY "$0: magnification: $MAG\n" if $MAG;
    print TTY "$0: mode: $MODE\n" if $MODE;
    print TTY "$0: force destination directory: $FORCEDEST\n" if $FORCEDEST;
    print TTY "$0: extra: $EXTRA\n" if $EXTRA;
}

# Make sure we got enough arguments, but not too many...
die "$0: Invalid arguments.\n" if ($BDPI eq "" || $EXTRA ne "");

# Calculate the magnification from the requested resolutions if no
# magnification string was provided.
if (!$MAG) {
    $MAG = "$DPI/$BDPI";
    print TTY "$0: magnification: $MAG\n" if $VERBOSE;
}

# Calculate the mode if the mode was not given.  Die if we don't know
# what mode to use for the requested base resolution.
if ($MODE eq "") {
    $MODE = $DPI_MODES{$BDPI};
    die "$0: No mode for ${BDPI}dpi base resolution.\n" if $MODE eq "";
    print TTY "$0: mode: $MODE\n" if $VERBOSE;
}

########################################################################

# Really start the work...
print TTY "Attempting to build PK file for: $NAME at ${DPI}dpi.\n";

$mfFile = $NAME;
$mfFile =~ /^(.*[^0-9])(\d+)$/;
$mfBase = $1;
$mfSize = $2;

# Presumably, we got here because the PK file doesn't exist.  Let's look
# for the MF file or the PFA or PFB file...

#   ... it's more complicated than that...

# If the font is from a PFA/B file, it may have the name "rxxx" or
# "xxx0" because virtual fonts extract glyphs from the "raw" font.  
# We need to find the PFA/B file and install the font with the right name.  
# I'm not sure what the best solution would really be, but this will work.
# Luckily, it gets installed with the right name 'cause we already
# figured that out...
#
# A better solution on Unix machines might be to make "xxx0.pfa" or
# "rxxx.pfa" a symbolic link to "xxx.pfa".  But that won't work for other
# architectures...

$t1source = "";
$t1source = $1 if $mfFile =~ /^r(.*)$/;
$t1source = $1 if $mfFile =~ /^(.*)0$/ && ($t1source eq "");

if ($t1source) {
    $fontSource = &find_fonts($TEXFONTS, 
                              ("$mfFile.mf", "$mfFile.pfa", "$mfFile.pfb",
                               "$t1source.pfa", "$t1source.pfb"));
} else {
    $fontSource = &find_fonts($TEXFONTS, 
                              ("$mfFile.mf", "$mfFile.pfa", "$mfFile.pfb"));
}

if ($fontSource) {
    if ($fontSource =~ /\.pfa$/ || $fontSource =~ /\.pfb$/) {
        print TTY "Building PK file from PostScript source.\n";
        &make_and_cd_tempdir();
        &make_from_ps($fontSource);
    } elsif ($fontSource =~ /\.mf$/) {
        local($fpath, $fname);
        print TTY "Building PK file from MF source.\n";
        &make_and_cd_tempdir();

        if ($fontSource =~ /^(.*)\/([^\/]*)$/) {
            $fpath = $1;
            $fname = $2;

            $fpath = $CWD if $fpath eq ".";
            $fpath = "$CWD/.." if $fpath eq "..";
        } else {
            $fpath = "";
            $fname = $fontSource;
        }

        &make_from_mf($fpath, $fname);
    } else {
        print TTY "$0: Cannot build PK font for $NAME.\n";
        print TTY " " x length($0), "  Unprepared for $fontSource.\n";
        die "\n";
    }
} else {
    if (grep(/^$mfBase$/, @DCR_GEN)) {

        print TTY "Building PK file from DC source.\n";

        &make_and_cd_tempdir();

        $MFBASE = "&dxbase";
        open (MFFILE, ">$mfFile.mf");
        print MFFILE "gensize:=$mfSize; generate $mfBase;\n";
        close (MFFILE);

        &make_from_mf("$DCR_DIR","$mfFile.mf");

    } elsif (grep(/^$mfBase$/, @SAUTER_GEN)) {

        print TTY "Building PK file from Sauter source.\n";

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
        print TTY "$0: Cannot build PK file.  Can't find source.\n";
        die "\n";
    }
}

&cleanup();

exit 0;

########################################################################

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
        print  TTY "$0 error : system return code: $rc\n";
        print  TTY "$0 failed: @cmd\n";
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
    local($source_path, $font, $subdir, $mode) = @_;
    local($pkdirs, @paths, $ptarget);
    local($target) = "";

    if ($VERBOSE) {
        print "Install: source_path: $source_path\n";
        print "Install: font       : $font\n";
        print "Install: subdir     : $subdir\n";
        print "Install: mode       : $mode\n";
    }

    $pkdirs = $ENV{"TEXPKS"} || $ENV{"PKFONTS"} || "";
    @paths = split(/:|;/,$pkdirs);

    # Need to find an installable target for the PK files.  Try 
    # ../glyphs/$subdir and ../$subdir then give up and use the best $pkdirs
    # path...

    if (!$target) {
        ($ptarget = $source_path) =~ s#/[^/]*$##;
        $target = "$ptarget/glyphs/$subdir" 
            if -d "$ptarget/glyphs/$subdir"
                || (-d "$ptarget/glyphs" 
                    && -w "$ptarget/glyphs" 
                    && ! -f "$ptarget/glyphs/$subdir");
    }

    if (!$target) {
        ($ptarget = $source_path) =~ s#/[^/]*$##;
        $target = "$ptarget/$subdir" 
            if -d "$ptarget/$subdir"
                || (-d $ptarget && -w $ptarget && ! -f "$ptarget/$subdir");

        # what a minute, suppose we just made a font in the current
        # directory...let's put the PK file there too...
        if (! -d "$target" && ($source_path eq $CWD)) {
            $target = $source_path;
            $USE_MODE_IN_DEST = 0;
        }
    }

    while (!$target && ($ptarget = shift @paths)) {
        $target = $ptarget if ($ptarget ne "." && $ptarget ne ".."
                               && -d $ptarget && -w $ptarget);
    }

    if ($target) {
        if (! -d $target) {
            &run ("mkdir", "$target");
            &run ("chmod", "777", "$target");
        }

        if ($USE_MODE_IN_DEST) {
            $target .= "/$mode";
            if (! -d $target) {
                &run ("mkdir", "$target");
                &run ("chmod", "777", "$target");
            }
        }

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
    local ($gfname, $pkname, $realdpi, $testdpi);
    local ($cmpath);

    print "source_path: $source_path\n" if $VERBOSE;
    print "source_file: $source_file\n" if $VERBOSE;

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

    $cmpath = "/usr/local/lib/fonts/free/cm/src";
    if (-d $cmpath && $ENV{"MFINPUTS"} !~ /$cmpath/) {
        $ENV{"MFINPUTS"} .= ":$cmpath";
    }

    $cmd = "$MFBASE \\mode:=$MODE; mag:=$MAG; scrollmode; " .
           "\\input $source_file";
    print TTY "virmf $cmd\n";

    $saveTERM = $ENV{"TERM"};
    $saveDISPLAY = $ENV{"DISPLAY"};
    delete $ENV{"DISPLAY"};
    $ENV{"TERM"} = "vt100";

    $rc = &run ("virmf", "$cmd");

    $ENV{"DISPLAY"} = $saveDISPLAY;
    $ENV{"TERM"} = $saveTERM;

    $realdpi = $DPI;
    $gfname = "./$mfFile.${realdpi}gf";

    for ($testdpi = $realdpi-2; $testdpi < $realdpi+3; $testdpi++) {
        $gfname = "./$mfFile.${testdpi}gf", $realdpi = $testdpi
            if ! -f $gfname && -f "./$mfFile.${testdpi}gf";
    }
                
    $gfname = "./$mfFile.${realdpi}gf";
    $pkname = "./$mfFile.${realdpi}pk";

    $rc = &run ("gftopk", "$gfname", "$pkname");

    &install_font($source_path, "$mfFile.${realdpi}pk", 'pk', "$MODE");
}

sub make_from_ps {
    local ($source_path, $source_file) = @_;
    local ($pssource, @cmd);
    local ($basename, $afmFile, $afmtest, $part);

    &run ("chdir", "$TEMPDIR");

    if (!$source_file) {
        $pssource = $source_path;
        ($source_path = $pssource) =~ s#/[^/]*$##;
        ($source_file = $pssource) =~ s#^.*/([^/]*)$#$1#;
    }

    # Need to find the AFM file...
    $afmFile = "";
    ($basename = $source_file) =~ s/\.pf[ab]$//;
    # First, look in ../afm:
    ($afmtest = $source_path) =~ s#/[^/]*$##;
    $afmtest .= "/afm/$basename.afm";
    $afmFile = $afmtest if -r $afmtest;

    # Then, look in ../../afm:
    ($afmtest = $source_path) =~ s#/[^/]*$##;
    $afmtest =~ s#/[^/]*$##;
    $afmtest .= "/afm/$basename.afm";
    $afmFile = $afmtest if !$afmFile && -r $afmtest;

    die "$0: Cannot find AFM file for $source_file.\n" if !$afmFile;
    
    @cmd = ('ps2pk', "-a$afmFile", "-X$DPI", 
            "$source_path/$source_file", "./$mfFile.${DPI}pk");

    foreach $part (@cmd) {
        print TTY "$part ";
    }
    print TTY "\n";

    $rc = &run (@cmd);

    &install_font($source_path, "$mfFile.${DPI}pk", 'pk', "${DPI}dpi");
}

sub find_fonts {
# This subroutine searches for font sources.  It looks in all the directories
# in the path specified.  Recursive searches are preformed on directories
# that end in //, !, or !!.  The emTeX directive "!", which should search
# only one level deep, is treated exactly like "!!".
#
    local($path, @fonts) = @_;
    local(@dirs, $dir, $font);
    local(@matches) = ();
    local(@recursive_matches);

    $path =~ s/!!/\/\//g;
    $path =~ s/!/\/\//g;
    $path =~ s/\\/\//g;

    print TTY "CWD: ", `pwd` if $VERBOSE;
    print TTY "Find: @fonts\n" if $VERBOSE;
    print TTY "Path: $path\n" if $VERBOSE;

    @dirs = split(/:|;/, $path);
    while (@dirs) {
        $dir = shift @dirs;
        next if !$dir;

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

    print TTY "Search root=$rootdir\n" if $VERBOSE;
    print TTY "Search mask=$fontmask (ignored by $0)\n" if $VERBOSE;

    @dirstack = ($rootdir);

    while ($rootdir = shift @dirstack) {
        opendir (SEARCHDIR, "$rootdir");
        while ($dir = scalar(readdir(SEARCHDIR))) {
            if ($dir ne "." && $dir ne ".." && -d "$rootdir/$dir") {
                push(@dirstack, "$rootdir/$dir");
                foreach $font (@fonts) {
                    if (-f "$rootdir/$dir/$font") {
                        print TTY "Matched: $rootdir/$dir/$font\n" if $VERBOSE;
                        push(@matches, "$rootdir/$dir/$font");
                    }
                }
            }
        }
        closedir (SEARCHDIR);
    }

    @matches;
}
