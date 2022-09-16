#!/usr/bin/perl
use strict;
use warnings;

use autodie;                            # to open/close succeed or die
use File::Find;                         # to search through directory trees
use File::Copy;                         # for the move command

open (RFILE, "genreview.txt");

my $directory   = shift;                # input target directory as argument
$directory = "." if not defined $directory;

my @files;
find(                                   # collect list of target files
    sub {
        return unless -f;               # files only
        return unless  /\.c$/;          # name must end in "*.c"
        push @files, $File::Find::name;
    },
    $directory
);

#  Now let's go through those files and replace the contents

for my $file ( @files ) {

    open my $input_fh, "<", $file;
    my $content = do { local $/; <$input_fh> };
    my $ccopy = $content;

    while ( <RFILE> ) {

        # parse 'from' string
        my $from = "";
        my $line = $_;
        my $tag = substr($line, 0, 2);
        while ($tag eq "�~") {
            $from .= substr($line, 2);
            $line = <RFILE>;
            $tag = substr($line, 0, 2);
        }
        if ($tag ne "��") {
            die "End of valid comments";
        }

        # parse 'to' string
        my $to = "";
        while ($tag eq "��") {
            $to .= substr($line, 2);
            $line = <RFILE>;
            $tag = substr($line, 0, 2);
        }

        chomp($from);
        chomp($to);

        # search and replace
        $content =~ s/\Q$from\E/$to/g;
    }

    close $input_fh;
    seek RFILE, 0, 0;

    # replaced move temp file over original
    if ($content ne $ccopy) {
        open my $output_fh, ">", "$file.tmp";
        print ${output_fh} $content;
        close $output_fh;
        move "$file.tmp", $file;
        print "modified".$file."\n"
    }
}
close RFILE;
