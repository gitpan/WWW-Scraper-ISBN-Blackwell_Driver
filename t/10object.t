#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Blackwell';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1558607013' => [
        [ 'is',     'isbn',         '9781558607019'     ],
        [ 'is',     'isbn10',       '1558607013'        ],
        [ 'is',     'isbn13',       '9781558607019'     ],
        [ 'is',     'ean13',        '9781558607019'     ],
        [ 'is',     'title',        'Higher-Order Perl' ],
        [ 'is',     'author',       'Mark Jason Dominus'],
        [ 'is',     'publisher',    'Elsevier Science & Technology'    ],
        [ 'is',     'pubdate',      '10 Dec 2004'       ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        '602'               ],
        [ 'is',     'width',        '191'               ],
        [ 'is',     'height',       '235'               ],
        [ 'is',     'weight',       '1021'              ],
        [ 'is',     'image_link',   'http://bookshop.blackwell.co.uk/images/jackets/l/15/1558607013.jpg' ],
        [ 'is',     'thumb_link',   'http://bookshop.blackwell.co.uk/images/jackets/m/15/1558607013.jpg' ],
        [ 'like',   'description',  qr|Most Perl programmers were originally trained as C and Unix programmers,| ],
        [ 'is',     'book_link',    'http://bookshop.blackwell.co.uk/jsp/search_results.jsp?wcp=1&quicksearch=1&cntType=&searchType=keywords&searchData=9781558607019&x=10&y=10' ]
    ],
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'     ],
        [ 'is',     'isbn10',       '0571239560'        ],
        [ 'is',     'isbn13',       '9780571239566'     ],
        [ 'is',     'ean13',        '9780571239566'     ],
        [ 'is',     'title',        'Touching from a Distance'  ],
        [ 'is',     'author',       'Deborah Curtis'    ],
        [ 'like',   'publisher',    qr!Faber (&|and) Faber!     ],
        [ 'is',     'pubdate',      '04 Oct 2007'       ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        240                 ],
        [ 'is',     'width',        129                 ],
        [ 'is',     'height',       198                 ],
        [ 'is',     'weight',       200                 ],
        [ 'is',     'image_link',   'http://bookshop.blackwell.co.uk/images/jackets/l/05/0571239560.jpg' ],
        [ 'is',     'thumb_link',   'http://bookshop.blackwell.co.uk/images/jackets/m/05/0571239560.jpg' ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius| ],
        [ 'is',     'book_link',    'http://bookshop.blackwell.co.uk/jsp/search_results.jsp?wcp=1&quicksearch=1&cntType=&searchType=keywords&searchData=9780571239566&x=10&y=10' ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }

###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    # this ISBN doesn't exist
	my $isbn = "0987654321";
    my $record;
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/ || !$record->found);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $fail = 0;
            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                my $res;
                if($test->[0] eq 'ok')          { $res = ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { $res = is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { $res = isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { $res = like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { $res = unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

                $fail = 1   unless($res);
            }

            diag("book=[".Dumper($book)."]")    if($fail);
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag($@);
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}