package DuktapeXS;

use strict;
use warnings;
use XSLoader;
binmode STDOUT, ":encoding(utf8)";

use Exporter 5.57 'import';

our $VERSION     = '0.001';
our %EXPORT_TAGS = ( 'all' => [qw(js_eval)] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('DuktapeXS', $VERSION);

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DuktapeXS - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DuktapeXS;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for DuktapeXS, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ricardo Tomasi, E<lt>rtomasi@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ricardo Tomasi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut