package Types::Const;

use v5.8;

use strict;
use warnings;

# ABSTRACT: Types that coerce references to read-only

use Type::Library
   -base,
   -declare => qw/ Const /;

use Const::Fast ();
use List::Util 1.33 ();
use Storable 3.06 (); # Regexp support
use Type::Coercion;
use Type::Tiny 1.002001;
use Type::Utils -all;
use Types::Standard qw/ -types is_ArrayRef is_HashRef is_ScalarRef /;
use Types::TypeTiny ();

# RECOMMEND PREREQ: Ref::Util::XS 0.100
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean 0.28;

our $VERSION = 'v0.3.7';

=for Pod::Coverage VERSION

=cut

sub VERSION { # for older Perls
    my ( $class, $wanted ) = @_;
    require version;
    return version->parse($VERSION);
}

=head1 SYNOPSIS

  use Moo;
  use Types::Const -types;
  use Types::Standard -types;

  ...

  has bar => (
    is      => 'ro',
    isa     => Const[ArrayRef[Str]],
    coerce  => 1,
  );

=head1 DESCRIPTION

This is an I<experimental> type library that provides types that force
read-only hash and array reference attributes to be deeply read-only.

See the L<known issues|/"KNOWN ISSUES"> below for a discussion of
side-effects.

=type C<Const[`a]>

Any defined reference value that is read-only.

If parameterized, then the referred value must also pass the type
constraint, for example C<Const[HashRef[Int]]> must a a hash reference
with integer values.

It supports coercions to read-only.

This was added in v0.3.0.

=cut

declare Const,
  as Ref,
  where   \&__is_readonly,
  message {
    return "$_ is not readonly";
  },
  constraint_generator => \&__constraint_generator,
  coercion_generator   => \&__coercion_generator;

coerce Const,
  from Ref,
  via \&__coerce_constant;

sub __coerce_constant {
    my $value = @_ ? $_[0] : $_;
    Const::Fast::_make_readonly( $value => 0 );
    return $value;
}

sub __is_readonly {
    if ( is_ArrayRef( $_[0] ) ) {
        return Internals::SvREADONLY( @{ $_[0] } )
          && List::Util::all { __is_readonly($_) } @{ $_[0] };
    }
    elsif ( is_HashRef( $_[0] ) ) {
        &Internals::hv_clear_placeholders( $_[0] );
        return Internals::SvREADONLY( %{ $_[0] } )
          && List::Util::all { __is_readonly($_) } values %{ $_[0] };
    }
    elsif ( is_ScalarRef( $_[0] )  ) {
        return Internals::SvREADONLY( ${ $_[0] } );
    }

    return Internals::SvREADONLY( $_[0] );
}

sub __constraint_generator {
    return Const unless @_;

    my $param = shift;
    Types::TypeTiny::TypeTiny->check($param)
        or _croak("Parameter to Const[`a] expected to be a type constraint; got $param");

    _croak("Only one parameter to Const[`a] expected; got @{[ 1 + @_ ]}.")
        if @_;

    my $psub = $param->constraint;

    return sub {
        return $psub->($_) && __is_readonly($_);
    };
}

sub __coercion_generator {
    my ( $parent, $child, $param ) = @_;

    return $parent->coercion unless $param->has_coercion;

    my $coercion = Type::Coercion->new( type_constraint => $child );

    my $coercable_item = $param->coercion->_source_type_union;

    $coercion->add_type_coercions(
        $parent => sub {
            my $value = @_ ? $_[0] : $_;
            my @new;
            for my $item (@$value) {
                return $value unless $coercable_item->check($item);
                push @new, $param->coerce($item);
            }
            return __coerce_constant(\@new);
        },
        );

    return $coercion;
}

__PACKAGE__->meta->make_immutable;

=head1 prepend:KNOWN ISSUES

=head2 Side-effects of read-only data structures

A side-effect of read-only data structures is that an exception will
be thrown if you attempt to fetch the value of a non-existent key:

    Attempt to access disallowed key 'foo' in a restricted hash

The work around for this is to check that a key exists beforehand.

=head2 Performance issues

Validating that a complex data-structure is read-only can affect
performance.  If this is an issue, one workaround is to use
L<Devel::StrictMode> and only validate data structures during tests:

  has bar => (
    is      => 'ro',
    isa     => STRICT ? Const[ArrayRef[Str]] : ArrayRef,
    coerce  => 1,
  );

Another means of improving performance is to only check the type
once. (Since it is read-only, there is no need to re-check it.)

=head2 RegexpRefs

There may be an issue with regexp references. See
L<RT#127635|https://rt.cpan.org/Ticket/Display.html?id=127635>.

=head2 Bug reports and feature requests

=head1 ROADMAP

Support for Perl versions earlier than 5.10 will be removed sometime
in 2019.

=head1 SEE ALSO

L<Const::Fast>

L<Type::Tiny>

L<Types::Standard>

=cut
