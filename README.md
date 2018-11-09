# NAME

Types::Const - Types that coerce references to read-only

# VERSION

version v0.2.2

# SYNOPSIS

```perl
use Moo;
use Types::Const -types;
use Types::Standard -types;

...

has bar => (
  is      => 'ro',
  isa     => ConstArrayRef[Str],
  coerce  => 1,
);
```

# DESCRIPTION

The type library provides types that force read-only hash and array
reference attributes to be deeply read-only.

# TYPES

## `` ConstArrayRef[`a] ``

A read-only array reference.

## `` ConstHashRef[`a] ``

A read-only hash reference.

# SEE ALSO

[Const::Fast](https://metacpan.org/pod/Const::Fast)

[Type::Tiny](https://metacpan.org/pod/Type::Tiny)

[Types::Standard](https://metacpan.org/pod/Types::Standard)

# KNOWN ISSUES

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Types-Const/issues](https://github.com/robrwo/Types-Const/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/Types-Const](https://github.com/robrwo/Types-Const)
and may be cloned from [git://github.com/robrwo/Types-Const.git](git://github.com/robrwo/Types-Const.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
