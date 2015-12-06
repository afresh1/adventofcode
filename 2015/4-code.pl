#!/usr/bin/perl
use v5.20;
use warnings;

use Test::More;
use Socket;
use IO::Select;
#use IO::Handle;
use Digest::MD5 qw( md5_hex );

sub find_md5 {
    my ($str, $zeros, $start) = @_;
    $start ||= 1;

    my $count = 25;

    my $s = IO::Select->new();
    for ( 0 .. 50 ) {
        my ( $child_fh, $parent_fh );
        socketpair( $child_fh, $parent_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
            || die "socketpair: $!";

        $child_fh->autoflush(1);
        $parent_fh->autoflush(1);

        my $pid = fork() // die "cannot fork: $!";
        if ($pid) {
            close $parent_fh;
            $s->add($child_fh);
        }
        else {
            close $child_fh;
            while ( my $line = readline($parent_fh) ) {
                chomp($line);

                for my $i ($line .. $line + $count) {
                    say $parent_fh qq{MD5 ("$str$i") = } . md5_hex("$str$i");
                }
            }
            exit(0);
        }
    }

    my $iter = do { my $i = $start - $count; sub { return $i += $count } };

    while (1) {
        say $_ $iter->() for $s->can_write(250);

        foreach my $fh ( $s->can_read(500) ) {
            chomp( my $line = readline($fh) );
            #say "Parent Pid $$ just read this: '$line'";
            if ($line =~ / = 0{$zeros}/) {
                my @handles = $s->handles;
                $s->remove(@handles);
                close $_ for @handles;

                return $line;
            }
        }
    }

    return -1;
}

is find_md5("abcdef", 5, 609040),
    'MD5 ("abcdef609043") = 000001dbbfa3a5c83a2d506429c7b00e';

is find_md5("pqrstuv", 5, 1048965),
    'MD5 ("pqrstuv1048970") = 000006136ef2ff3b291c85725f17325c';

is find_md5("ckczppom", 5, 117940),
    'MD5 ("ckczppom117946") = 00000fe1c139a2c710e9a5c03ec1af03';

is find_md5("ckczppom", 6, 3938030),
    'MD5 ("ckczppom3938038") = 00000028023e3b4729684757f8dc3fbf';

done_testing;
