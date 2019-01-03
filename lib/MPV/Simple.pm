package MPV::Simple;

use 5.026001;
use strict;
use warnings;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MPV::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('MPV::Simple', $VERSION);

our $callback = undef();
our $callback_data = undef();

#sub set_my_callback {
#    my ($self, $cb) = @_;
#    $callback = $cb;
#}

sub set_callback_data {
    my ($self, $cb) = @_;
    $callback_data = $cb;
}

sub new {
    my ($class) = shift;
    my $obj = $class->xs_create();
    
    bless $obj;
    #my $cstruct = $obj->xs_create();
    #$obj->ctx($cstruct);
    return $obj;
}

sub ctx {
    my ($self, $cstruct) = @_;
    
    my $old_value = $self->{cstruct};
	#use Devel::Peek;
	#print "DEVEL: ".Dump ($old_value)."\n";
	#print "CTX ".$old_value." \n";
	$self->{cstruct} = $cstruct if (defined $cstruct);
	
	return $old_value;
}


sub set_option_string {
    my ($self,$option,$data) = @_;
    $self->_xs_mpv_set_option_string($option,$data);
}

sub set_property_string {
    my ($self,$option,$data) = @_;
    $self->_xs_mpv_set_option_string($option,$data);
}

sub initialize {
    my ($self) = @_;
    $self->_xs_mpv_initialize()
}

sub command {
    my ($self) = @_;
    $self->_xs_mpv_command();
}

sub wait_event {
    my ($self, $timeout) = @_;
    
    my $event = $self->_xs_mpv_wait_event($timeout);
    return $event;
}

sub set_wakeup_callback {
    my ($self, $callback, $userdata) = @_;
    $self->set_my_callback($callback);
    $self->set_callback_data($userdata);
    use Devel::Peek;
    Dump $callback;
    $self->_xs_set_wakeup_callback();
    use Devel::Peek;
    Dump $callback;
}

sub event_name {
    my ($self,$event) = @_;
    
    $self->_xs_mpv_event_name($event);
}

sub terminate_destroy {
    my ($self) = @_;
    $self->_xs_mpv_terminate_destroy()
}


# Preloaded methods go here.

1;

package MPVEvent;

use 5.026001;
use strict;
use warnings;

sub new {
my ($class) = shift;
    my $obj = {};
    bless $obj;
    return $obj;
}

sub cstruct {
    my ($self, $cstruct) = @_;
     
    my $old_value = $self->{cstruct};
	$self->{cstruct} = $cstruct if (defined $cstruct);
	
	return $old_value;
}

sub id {
    my ($self) = @_;
    #my $event = $self->cstruct;
    my $event = $self;
    my $id = $self->xs_id($event);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MPV::Simple - Perl extension for blah blah blah

=head1 SYNOPSIS

  use MPV::Simple;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for MPV::Simple, created by h2xs. It looks like the
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

Maximilian Lika, E<lt>maximilian@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
