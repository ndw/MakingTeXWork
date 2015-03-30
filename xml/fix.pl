opendir (DIR, ".");
while ($file = readdir(DIR)) {
    next if $file !~ /\.xml$/;
    open (F, $file);
    read (F, $_, -s $file);
    close (F);

    $_ = &fix($_);

    open (F, ">$file.new");
    print F $_;
    close (F);
}

sub fix {
    local $_ = shift;

    s/\`\`/<quote>/sg;
    s/\'\'/<\/quote>/sg;

    return $_;
}
