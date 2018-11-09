#!perl

use Test::Most;

use Const::Fast;
use Types::Const -types;
use Types::Standard -types;

subtest 'parameterize empty ArrayRef' => sub {

    ok my $type = ConstArrayRef [], 'parameterize';
    is $type->display_name => ConstArrayRef->display_name, 'display_name'

};

subtest 'parameterize empty HashRef' => sub {

    ok my $type = ConstHashRef [], 'parameterize';
    is $type->display_name => ConstHashRef->display_name, 'display_name'

};

subtest 'parameterize Int on ArrayRef' => sub {

    ok my $type = ConstArrayRef [Int], 'parameterize';
    is $type->display_name => "ConstArrayRef[Int]", 'display_name';

    const my @empty => ();
    const my @ints  => ( 1 .. 3 );
    const my @strs  => qw/ a b c /;

    ok $type->check( \@empty ), 'check';
    ok $type->check( \@ints ),  'check';
    ok !$type->check( \@strs ), 'check fails (not int)';

    my @vals = ( 1 .. 3 );
    ok !$type->check( \@vals ), 'check fails (not read-only)';

    is_deeply $type->coerce( \@ints ), \@ints, 'coerce on const';
    ok $type->check( $type->coerce( \@ints ) ), 'check coerce on const';

    ok $type->check( $type->parent->coerce( \@vals ) ), 'coerce via parent';

    ok my $cvals = $type->coerce( \@vals ), 'coerce';
    ok $type->check( $cvals ), 'check coerce';
    is_deeply $cvals, \@vals, 'same values';

    lives_ok { $vals[0]++ } 'original unchanged';
    dies_ok  { $cvals->[0]++ } 'coerced is readonly';

};

subtest 'parameterize Int on HashRef' => sub {

    ok my $type = ConstHashRef [Int], 'parameterize';
    is $type->display_name => "ConstHashRef[Int]", 'display_name';

    const my %empty => ();
    const my %ints  => ( A => 1, B => 2, C => 3 );
    const my %strs  => ( A => 1, B => 'bee', C => 'see' );

    ok $type->check( \%empty ), 'check';
    ok $type->check( \%ints ),  'check';
    ok !$type->check( \%strs ), 'check fails (not int)';

    my %vals = ( A => 1, B => 2, C => 3 );
    ok !$type->check( \%vals ), 'check fails (not read-only)';

    is_deeply $type->coerce( \%ints ), \%ints, 'coerce on const';
    ok $type->check( $type->coerce( \%ints ) ), 'check coerce on const';

    ok $type->check( $type->parent->coerce( \%vals ) ), 'coerce via parent';

    ok my $cvals = $type->coerce( \%vals ), 'coerce';
    ok $type->check( $cvals ), 'check coerce';
    is_deeply $cvals, \%vals, 'same values';

    lives_ok { $vals{b}++ } 'original unchanged';
    dies_ok  { $cvals->{b}++ } 'coerced is readonly';

};

done_testing;
