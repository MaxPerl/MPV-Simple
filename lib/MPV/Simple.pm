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

sub new {
    my ($class) = shift;
    my $obj = $class->xs_create();
    
    bless $obj;
    #$obj->_set_context();
    #my $cstruct = $obj->xs_create();
    #$obj->ctx($cstruct);
    return $obj;
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

MPV::Simple - Perl extension for libmpv

=head1 SYNOPSIS

    use MPV::Simple;
    my $ctx = MPV::Simple->new();
    $ctx->initialize;
    $ctx->set_property_string('input-default-bindings','yes');
    $ctx->set_property_string('input-vo-keyboard','yes');
    $ctx->set_property_string('osc','yes');

    $ctx->command("loadfile", "/home/maximilian/Dokumente/perl/MPV-Simple/t/einladung2.mp4");
    while (my $event = $ctx->wait_event(-1)) {
            if ($event->{id} == 7){
                    $ctx->terminate_destroy();
                    last;
            }
    }

    exit 0;

=head1 DESCRIPTION

MPV::Simple is a basic and simple binding to libmpv.

=head2 EXPORT

None by default.

=head2 METHODS

The following methods exist:

=over 4

=item* my $mpv = MPV::Simple->new()
Constructs a new MPV handle

=item* $mpv->initialize();
Initialize an uninitialized mpv instance. If the mpv instance is already running, an error is retuned.
This function needs to be called to make full use of the client API if the client API handle was created with new().

=item* $mpv->set_property_string('name','value');
Set a property to a given value. Properties are essentially variables which
can be queried or set at runtime. For example, writing to the pause property
will actually pause or unpause playback.

=item* $mpv->get_property_string('name','value');
Return the value of the property with the given name as string.

=item* $mpv->observe_property_string('name');
Get a notification whenever the given property changes. You will receive
updates as MPV_EVENT_PROPERTY_CHANGE. Note that this is not very precise:
for some properties, it may not send updates even if the property changed.
This depends on the property, and it's a valid feature request to ask for
better update handling of a specific property. (For some properties, like
``clock``, which shows the wall clock, this mechanism doesn't make too
much sense anyway.)

Property changes are coalesced: the change events are returned only once the
event queue becomes empty (e.g. mpv_wait_event() would block or return
MPV_EVENT_NONE), and then only one event per changed property is returned.

Normally, change events are sent only if the property value changes according
to the requested format. mpv_event_property will contain the property value
as data member.

Warning: if a property is unavailable or retrieving it caused an error,
         MPV_FORMAT_NONE will be set in mpv_event_property, even if the
         format parameter was set to a different value. In this case, the
         mpv_event_property.data field is invalid.

If the property is observed with the format parameter set to MPV_FORMAT_NONE,
you get low-level notifications whether the property _may_ have changed, and
the data member in mpv_event_property will be unset. With this mode, you
will have to determine yourself whether the property really changd. On the
other hand, this mechanism can be faster and uses less resources.

Observing a property that doesn't exist is allowed. (Although it may still
cause some sporadic change events.)

Keep in mind that you will get change notifications even if you change a
property yourself. Try to avoid endless feedback loops, which could happen
if you react to the change notifications triggered by your own change.

Only the mpv_handle on which this was called will receive the property
change events, or can unobserve them.


=item* $mpv->command($command, @args);
Send a command to the player. Commands are the same as those used in
input.conf, except that this function takes parameters in a pre-split form.
The commands and their parameters are documented in input.rst.

=item* $mpv->wait_event($timeout)
Wait for the next event, or until the timeout expires, or if another thread
makes a call to mpv_wakeup(). Passing 0 as timeout will never wait, and
is suitable for polling.

The internal event queue has a limited size (per client handle). If you
don't empty the event queue quickly enough with mpv_wait_event(), it will
overflow and silently discard further events. If this happens, making
asynchronous requests will fail as well (with MPV_ERROR_EVENT_QUEUE_FULL).

=item* $mpv->terminate_destroy()
Brings the player and all clients down as well, and waits until all of them are destroyed.
Returns a hashref containing the event ID and other data.
 
=back


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
