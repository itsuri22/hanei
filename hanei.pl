#!/usr/bin/perl
use strict;                             # usage: perl hanei.pl remarks.txt C:\Software
use warnings;

use autodie;                            # to open/close succeed or die
use File::Find;                         # to search through directory trees
use File::Copy;                         # for the move command

my $rfile = shift;
$rfile = "remarks.txt" if not defined $rfile;
die "Input proper text file!" unless $rfile =~ /\.txt$/;
open (RFILE, $rfile);

my $directory   = shift;                # input target directory as argument
$directory = "." if not defined $directory;

my $tsrc = <RFILE>;
die "Specify target source in text file!" unless $tsrc =~ /^--/;
$tsrc = substr($tsrc, 2); chomp($tsrc);
<RFILE>;

my $regex = qr/$tsrc/;
my @files;
find(                                   # collect list of target files
    sub {
        return unless -f;               # files only
        return unless /$regex/;         # target source files in regex
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
        while ($tag eq "Å~") {
            $from .= substr($line, 2);
            $line = <RFILE>;
            $tag = substr($line, 0, 2);
        }
        if ($tag ne "Åõ") {
            die "End of valid comments";
        }

        # parse 'to' string
        my $to = "";
        while ($tag eq "Åõ") {
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
    seek RFILE, 0, 0;<RFILE>;<RFILE>;

    # replaced move temp file over original
    if ($content ne $ccopy) {
        open my $output_fh, ">", "$file.tmp";
        print ${output_fh} $content;
        close $output_fh;
        move "$file.tmp", $file;
        print "modified".$file."\n";
    } else {
        print "Not modified".$file."\n";
    }
}
close RFILE;
