#!/usr/bin/perl
use strict;
use warnings;
package IkiWiki::Plugin::highlight;
use IkiWiki '3.00';
use Syntax::Highlight::Engine::Kate;

# variables {{{
my %hl_args = (
    substitutions => { },
    format_table  => {
        Alert        => ["<span class='synAlert'>",        "</span>"],
        BaseN        => ["<span class='synBaseN'>",        "</span>"],
        BString      => ["<span class='synBString'>",      "</span>"],
        Char         => ["<span class='synChar'>",         "</span>"],
        Comment      => ["<span class='synComment'>",      "</span>"],
        DataType     => ["<span class='synDataType'>",     "</span>"],
        DecVal       => ["<span class='synDecVal'>",       "</span>"],
        Error        => ["<span class='synError'>",        "</span>"],
        Float        => ["<span class='synFloat'>",        "</span>"],
        Function     => ["<span class='synFunction'>",     "</span>"],
        IString      => ["<span class='synIString'>",      "</span>"],
        Keyword      => ["<span class='synKeyword'>",      "</span>"],
        Normal       => ["",                               ""       ],
        Operator     => ["<span class='synOperator'>",     "</span>"],
        Others       => ["<span class='synOthers'>",       "</span>"],
        RegionMarker => ["<span class='synRegionMarker'>", "</span>"],
        Reserved     => ["<span class='synReserved'>",     "</span>"],
        String       => ["<span class='synString'>",       "</span>"],
        Variable     => ["<span class='synVariable'>",     "</span>"],
        Warning      => ["<span class='synWarning'>",      "</span>"],
    },
);
my %syntaxes;
# }}}

sub import { # {{{
    hook(type => 'sanitize', id => __PACKAGE__, call => \&sanitize, first => 1);
} # }}}

sub sanitize { # {{{
    my %args = @_;
    my $content = '';
    my $in_code = 0;
    for my $line (split /^/m, $args{content}) {
        if ($in_code) {
            if ($line =~ s{(</code></pre>.*)}{}s) {
                my $rest_line = $1;
                $code_block .= $line;
                $content .= highlight($code_block) . $rest_line;
                $code_block = '';
                $in_code = 0;
            }
            else {
                $code_block .= $line;
            }
        }
        else {
            if ($line =~ s{(.*<pre><code>)}{}s) {
                $content .= $1;
                $code_block .= $line;
                $in_code = 1;
            }
            else {
                $content .= $line;
            }
        }
    }
    $content .= $code_block;
    return $content;
} # }}}

sub highlight { # {{{
    my ($code_block) = @_;
    my $filetype = guess_filetype($code_block);
    return unless $filetype;
    my $hl = Syntax::Highlight::Engine::Kate->new(
        language => $filetype, %hl_args
    );
    %syntaxes ||= map { lc($_) => $hl->syntaxes->{$_} } keys %$hl->syntaxes;
    return $hl->highlightText($code_block);
} # }}}

sub guess_filetype { # {{{
    my ($code_block) = @_;
    my ($first_line) = split /\n/, $code_block;
    if ($first_line =~ /^#!(\w+)/) {
        return $syntaxes{$1};
    }
    return;
} # }}}

1;
