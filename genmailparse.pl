#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use autodie;           # Turns file operations into exception based programming

use File::Find;        # Your friend
use File::Copy;        # For the "move" command

my $mail = "genmail.txt";
open (FILE, $mail) || die "Cannot open file ".$mail." for read";

my $wrong;
my $right;

    my $directory   = shift;

    $directory = "." if not defined $directory;

    my @files;
    find(
        sub {
            return unless -f;        # Files only
            return unless  /\.*$/;    # Name must end in "*.*"
            push @files, $File::Find::name;
        },
        $directory
    );

#
#  Now let's go through those files and replace the contents
#

#for my $file ( @files ) {
#    print $file."\n";
#}

while (<FILE>)
{

#### Parsing wrong and right ####

    my $line = $_;
    my $tag = substr($line, 0, 2);
    if ($tag eq "Å~") {
        $wrong = substr($line, 2);
    } else {
        die "Invalid";
    }

    $line = <FILE>;
    $tag = substr($line, 0, 2);
     if ($tag eq "Åõ") {
        $right = substr($line, 2);
    } else {
        die "Invalid";
    }

    $line = <FILE>;

#    print "Wrong".$wrong;
#    print "Right".$right;

#### search and replace ####

# Usage = mungestrings.pl [<dir>]
#         Default dir is current
#
    my $from_string = $wrong;
    my $to_string   = $right;
    
    chomp($wrong);
    chomp($right);
#
#  Now let's go through those files and replace the contents
#

    for my $file ( @files ) {
#        print $file."\n";
#        print $from_string;
#        print $to_string;

        open my $input_fh, "<", $file;
        open my $output_fh, ">", "$file.tmp";
        my $modified = 0;
        for my $line ( <$input_fh> ) {
            my $oline = $line;
            $line =~ s/\Q$wrong\E/$right/g;
            if (($line eq $oline) or (not($to_string =~/^$/))) {
                print ${output_fh} $line;
            }
            if ($line ne $oline) {
                $modified = 1;
            }
        }

        #
        # Contents been replaced move temp file over original
        #
        close $input_fh;
        close $output_fh;
        if ($modified == 1) {
            move "$file.tmp", $file;
            print "modified".$file."\n"
        }
        else {
            unlink "$file.tmp";
            print "Not modified".$file."\n"
        }
    }

}
close FILE;
