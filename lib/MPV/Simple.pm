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

our @event_names = qw(
    MPV_EVENT_NONE 
    MPV_EVENT_SHUTDOWN
    MPV_EVENT_LOG_MESSAGE       
    MPV_EVENT_GET_PROPERTY_REPLY
    MPV_EVENT_SET_PROPERTY_REPLY
    MPV_EVENT_COMMAND_REPLY     
    MPV_EVENT_START_FILE        
    MPV_EVENT_END_FILE          
    MPV_EVENT_FILE_LOADED       
    MPV_EVENT_TRACKS_CHANGED    
    MPV_EVENT_TRACK_SWITCHED    
    MPV_EVENT_IDLE              
    MPV_EVENT_PAUSE             
    MPV_EVENT_UNPAUSE           
    MPV_EVENT_TICK              
    MPV_EVENT_SCRIPT_INPUT_DISPATCH 
    MPV_EVENT_CLIENT_MESSAGE    
    MPV_EVENT_VIDEO_RECONFIG    
    MPV_EVENT_AUDIO_RECONFIG    
    MPV_EVENT_METADATA_UPDATE   
    MPV_EVENT_SEEK              
    MPV_EVENT_PLAYBACK_RESTART  
    MPV_EVENT_PROPERTY_CHANGE   
    MPV_EVENT_CHAPTER_CHANGE 
    MPV_EVENT_QUEUE_OVERFLOW 
    MPV_EVENT_HOOK 
    );
    
our @end_file_reasons = qw(
    MPV_END_FILE_REASON_EOF
    MPV_END_FILE_REASON_STOP
    MPV_END_FILE_REASON_QUIT
    MPV_END_FILE_REASON_ERROR
    MPV_END_FILE_REASON_REDIRECT
    );

sub set_my_callback {
    my ($self, $cb) = @_;
    $callback = $cb;
}

sub set_callback_data {
    my ($self, $cb) = @_;
    $callback_data = $cb;
}

sub new {
    my ($class) = shift;
    my $obj = $class->xs_create();
    
    bless $obj;
    #$obj->_set_context();
    #my $cstruct = $obj->xs_create();
    #$obj->ctx($cstruct);
    return $obj;
}

sub set_wakeup_callback {
    my ($self, $callback, $userdata) = @_;
    $self->set_my_callback($callback);
    $self->set_callback_data($userdata);
    #use Devel::Peek;
    #Dump $callback;
    $self->_xs_set_wakeup_callback($callback);
    #use Devel::Peek;
    #Dump $callback;
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
