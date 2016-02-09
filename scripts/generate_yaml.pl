#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Text::Trim;
use v5.14;

my $file;
my $table;
my $drop_first = 1;
my $cols;

GetOptions('t|table=s' => \$table,
           'f|file=s' => \$file,
           'd|drop-first' => \$drop_first,
           'c|columns=s' => \$cols,
          ) or die('Invalid parameters.');

my $intable = 0;
my $found = 0;

unless ($file and $table) {
    die('Please specify a file and a table (either label or caption)');
}

unless ($cols) {
    die('No columns specified. Do: col1,col2,col3,...');
}

sub print_yaml {
    my $ta = shift;
    my @c = split(',', $cols);

    foreach my $it (@{ $ta }) {
        my @item = @{ $it };
        my $first = 1;
        my $idx = 0;

        foreach my $col (@c) {
            if ($first) {
                print('- ');
                $first = 0;
            } else {
                print('  ');
            }
            say($col . ': ' . $item[$idx]);
            ++$idx;
        }

        say('');
    }
}

sub parse_table {
    my @table;
    my $first = 1;

    open(LATEX, $file)
      or die('Could not open file '.$file);

    while (<LATEX>) {
        chomp;

        if (m/\\begin\{table\}/ig) {
            $intable = 1;
        } elsif (m/\\end\{table\}/ig) {
            $intable = 0;
            $found = 0;
        }

        if (m/\\caption\{.*$table.*\}/ig and $intable) {
            $found = 1;
        }

        if (m/(.*?)\s+\\\\\s+\\hline$/ig && $found) {
            my $content = $1;

            my @line = split('&', $content);
            @line = trim(@line);

            if ($drop_first and $first) {
                $first = 0;
            } else {
                push(@table, \@line);
            }
        }
    }

    close(LATEX);

    return \@table;
}

my $t = parse_table();
print_yaml($t);
