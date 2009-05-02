#!/usr/bin/perl
use strict;
use warnings;
package IkiWiki::Plugin::highlight;
use IkiWiki '3.00';
use Syntax::Highlight::Engine::Kate;

# variables {{{
my %hl_args = (
    substitutions => {
        '<' => '&lt;',
        '>' => '&gt;',
        '&' => '&amp;',
        '[' => '&#91;', # wow is this a huge hack
    },
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
my $syntaxes;
# }}}

sub import { # {{{
    my $hl = Syntax::Highlight::Engine::Kate->new(%hl_args);
    $syntaxes = { map { +lc($_) => $hl->syntaxes->{$_} }
                      keys %{ $hl->syntaxes } };
    $syntaxes->{c}     = 'ANSI C89';
    $syntaxes->{cpp}   = 'C++';
    $syntaxes->{ocaml} = 'Objective Caml';
    hook(type => 'filter', id => __PACKAGE__, call => \&filter);
} # }}}

sub filter { # {{{
    my %args = @_;
    my $content = '';
    my $code_block = '';
    my $in_code = 0;
    my $code_re = qr/^(?: {4}|\t)/;
    my $empty_re = qr/^\s*$/;
    for my $line (split /^/m, $args{content}) {
        if ($in_code) {
            if ($line =~ $code_re || $line =~ $empty_re) {
                $line =~ s/^(?: ? ? ? ?|\t)//;
                $code_block .= $line;
            }
            else {
                $code_block =~ s/(\s*)$//;
                my $ws = $1;
                $content .= highlight($code_block);
                $in_code = 0;
                $code_block = '';
                $content .= $ws;
                $content .= $line;
            }
        }
        else {
            if ($line =~ $code_re && $line !~ $empty_re) {
                $in_code = 1;
                $line =~ s/^(?: ? ? ? ?|\t)//;
                $code_block .= $line;
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
    return $code_block unless $filetype;
    my $hl = Syntax::Highlight::Engine::Kate->new(%hl_args,
                                                  language => $filetype);
    $code_block =~ s/[^\n]*\n//s;
    $filetype =~ s/\s/_/g;
    return "<pre><code class='lang$filetype'>" .
           $hl->highlightText($code_block) .
           '</code></pre>';
} # }}}

sub guess_filetype { # {{{
    my ($code_block) = @_;
    my ($first_line) = split /\n/, $code_block;
    if ($first_line =~ m{^#!\s*(?:.+[\s/]+)*(\w+)}) {
        return $syntaxes->{$1};
    }
    elsif ($first_line =~ m{^[/(]\*\s*(\w+)\s*\*[/)]}) {
        return $syntaxes->{$1};
    }
    elsif ($first_line =~ m{^[-/]{2}\s*(\w+)}) {
        return $syntaxes->{$1};
    }
    elsif ($first_line =~ m{^<!--\s*(\w+)\s*-->}) {
        return $syntaxes->{$1};
    }
} # }}}

1;
