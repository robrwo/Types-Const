package Types::Const;

use v5.8;

use strict;
use warnings;

# ABSTRACT: Types that coerce references to read-only

use Type::Library
   -base,
   -declare => qw/ ConstArrayRef /;

use Const::Fast ();
use Type::Tiny;
use Type::Utils -all;
use Types::Standard -types;

# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean 0.28;

our $VERSION = 'v0.1.1';

=head1 SYNOPSIS

  use Types::Const -types;
  use Types::Standard -types;

  ...

  has bar => (
    is      => 'ro',
    isa     => ConstArrayRef,
    coerce  => 1,
  );

=head1 DESCRIPTION

The type library provides types that allow read-only attributes to be
read-only.

=type C<ConstArrayRef>

A read-only array reference.

=cut

declare "ConstArrayRef",
  as ArrayRef,
  where   { Internals::SvREADONLY(@$_) },
  message {
    return ArrayRef->get_message($_) unless ArrayRef->check($_);
    return "$_ is not readonly";
  };

coerce "ConstArrayRef",
  from ArrayRef,
  via { Const::Fast::_make_readonly( $_ => 0 ); return $_; };

=type C<ConstHashRef>

A read-only hash reference.

=cut

declare "ConstHashRef",
  as HashRef,
  where   { Internals::SvREADONLY(%$_) },
  message {
    return HashRef->get_message($_) unless HashRef->check($_);
    return "$_ is not readonly";
  };

coerce "ConstHashRef",
  from HashRef,
  via { Const::Fast::_make_readonly( $_ => 0 ); return $_; };

1;

=head1 KNOWN ISSUES

Parameterized types, e.g. C<ConstArrayRef[Int]> are not yet supported.

=head1 SEE ALSO

L<Const::Fast>

L<Type::Tiny>

=cut
