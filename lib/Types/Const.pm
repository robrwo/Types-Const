package Types::Const;

use v5.8;

use strict;
use warnings;

# ABSTRACT: Types that coerce references to read-only

use Type::Library
   -base,
   -declare => qw/ ConstArrayRef ConstHashRef /;

use Const::Fast ();
use List::Util 1.33 ();
use Type::Coercion;
use Type::Tiny;
use Type::Utils -all;
use Types::Standard qw/ -types is_ArrayRef is_HashRef is_Ref /;
use Types::TypeTiny ();

# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean 0.28;

our $VERSION = 'v0.2.0';

=head1 SYNOPSIS

  use Moo;
  use Types::Const -types;
  use Types::Standard -types;

  ...

  has bar => (
    is      => 'ro',
    isa     => ConstArrayRef[Str],
    coerce  => 1,
  );

=head1 DESCRIPTION

The type library provides types that force read-only hash and array
reference attributes to be deeply read-only.

=type C<ConstArrayRef[`a]>

A read-only array reference.

=cut

declare ConstArrayRef,
  as ArrayRef,
  where   \&__is_readonly,
  message {
    return ArrayRef->get_message($_) unless ArrayRef->check($_);
    return "$_ is not readonly";
  },
  constraint_generator => \&__arrayref_constraint_generator,
  coercion_generator   => \&__coercion_generator;

coerce ConstArrayRef,
  from ArrayRef,
  via \&__coerce_constant;

=type C<ConstHashRef[`a]>

A read-only hash reference.

=cut

declare ConstHashRef,
  as HashRef,
  where   \&__is_readonly,
  message {
    return HashRef->get_message($_) unless HashRef->check($_);
    return "$_ is not readonly";
  },
  constraint_generator => \&__hashref_constraint_generator,
  coercion_generator   => \&__coercion_generator;

coerce ConstHashRef,
  from HashRef,
  via \&__coerce_constant;

sub __coerce_constant {
    my $value = @_ ? $_[0] : $_;
    Const::Fast::_make_readonly( $value => 0 );
    return $value;
}

sub __arrayref_constraint_generator {
    return ConstArrayRef unless @_;

    my $param = shift;
    Types::TypeTiny::TypeTiny->check($param)
        or _croak("Parameter to ConstArrayRef[`a] expected to be a type constraint; got $param");

    _croak("Only one parameter to ConstArrayRef[`a] expected; got @{[ 1 + @_ ]}.")
        if @_;

    my $psub = ArrayRef->parameterize($param)->constraint;

    return sub {
        return $psub->($_) && __is_readonly($_);
    };

}

sub __hashref_constraint_generator {
    return ConstHashRef unless @_;

    my $param = shift;
    Types::TypeTiny::TypeTiny->check($param)
        or _croak("Parameter to ConstHashRef[`a] expected to be a type constraint; got $param");

    my $psub = HashRef->parameterize($param)->constraint;

    return sub {
        return psub->($_) && __is_readonly($_);
    };

}

sub __is_readonly {
    if ( is_ArrayRef($_) ) {
        return Internals::SvREADONLY(@$_)
          && List::Util::all { __is_readonly($_) } @$_;
    }
    elsif ( is_HashRef($_) ) {
        &Internals::hv_clear_placeholders($_);
        return Internals::SvREADONLY(%$_)
          && List::Util::all { __is_readonly($_) } values %$_;
    }
    elsif ( is_Ref($_) ) {
        return Internals::SvREADONLY($$_);
    }
    else {
        return Internals::SvREADONLY($_);
    }
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

=head1 SEE ALSO

L<Const::Fast>

L<Type::Tiny>

L<Types::Standard>

=cut
