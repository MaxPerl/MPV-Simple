package MPV::Simple::threads;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw(usleep);


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


# Wake event loop up, when a command is passed to the mpv process
our $wakeup :shared = 1;
our $process_events :shared = 1;
our $signaled :shared = 0;
$SIG{USR1} = sub {$signaled=1;lock($wakeup); $wakeup = 1};


sub new {
    my ($class,%opts) = @_;
    
    my $MainQueue = Thread::Queue->new();
    my $ChildQueue = Thread::Queue->new();
    my $EventQueue = Thread::Queue->new();
    
    
    # Kommando Schnittstelle
    my $thr = threads->create(\&mpv,$MainQueue, $ChildQueue, $EventQueue, $opts{event_handling});
    $thr->detach();
    
    # Main
    my $obj ={};
    $obj->{event_handling} = $opts{event_handling} || 1;
    $obj->{evthread} = $thr;
    $obj->{MainQueue} = $MainQueue;
    $obj->{ChildQueue} = $ChildQueue;
    $obj->{EventQueue} = $EventQueue;
    
    bless $obj, $class;
    return $obj;
    
    
    
}

sub AUTOLOAD {
    my ($obj,@args) = @_;
    our $AUTOLOAD;
    
    # trim package name
    my $func = $AUTOLOAD; 
    $func =~ s/.*:://;
    
    my $args = join('###',@args);
    my $line = "$func###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    
    chomp $ret;
    return $ret;
}


sub terminate_destroy {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "terminate_destroy###$args\n";
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    #sleep(1);
    
    #my $thr = $obj->{evthread};
    #$process_events=undef;
    #my $ret = $thr->join();
    
    threads->exit() if threads->can('exit');
}

# Child thread!
sub mpv {
    my ($MainQueue, $ChildQueue, $EventQueue, $event_handling) = @_;
    
    use MPV::Simple;
    my $ctx = MPV::Simple->new() or die "Could not create MPV instance: $!\n";
    
    #$ctx->setup_event_notification();
    
    # New implementation
    $ctx->set_wakeup_callback('MPV::Simple::threads::wakeup');
    
    
    while ($process_events) {
        
        #print "Processing events/commands\n";
        while ( my $line = $MainQueue->dequeue_nb() ) {
            last unless ($line);
            _process_command($ctx,$line,$ChildQueue);
            
       }
       
       # The following line blocks until new events occur
       # or SIG{USR2}is fired
       while ($wakeup) {
        $wakeup = 0;
        
            while (my $event = $ctx->wait_event(0)) {
                        my $id = $event->{id};
                        last if ($id == 0);
                        my $name = $event->{name} || '';
                        my $data = $event->{data} || '';
                        my $event_name = $MPV::Simple::event_names[$id];
                        $EventQueue->enqueue("$id###$name###$data###$event_name\n") if ($event_handling && $id != 0);
                    }
            }
            
        # We have to add a little sleep to save CPU!    
        usleep(100);
            
    }
    return 1;
}

sub wakeup {
    $wakeup = 1;
}

sub _process_command {
    my ($ctx,$line,$ChildQueue) = @_;
    my $return;
    chomp $line;
    my ($command, @args) = split('###',$line);
    if ($command eq "terminate_destroy" || $command eq "destroy") {
        $ctx->terminate_destroy();
        #$ChildQueue->enqueue("Shutting down\n");
    }
    elsif ($command eq "get_property_string") {
        $return = $ctx->get_property_string(@args);
        # Don't forget \n at the end!!!
        $ChildQueue->enqueue("$return\n");
    }
    else {
        
        eval{
            $return = $ctx->$command(@args);
        };
        if ($@) {
                print "FEHLER:$@\n";
        }
        
        #use Data::Dumper;
        #print "RET ". $return ."\n";
        $ChildQueue->enqueue("$return\n");
    }
}

sub get_events {
    my ($self) = @_;
    my $evreader = $self->{EventQueue};
    #my $line = $evreader->getline || undef;
    my $line = $evreader->dequeue_nb();
    
    return undef unless ($line);
    chomp $line;
    my ($event_id,$name,$data,$event_name) = split('###',$line);
    return {
        event_id => $event_id,
        event => $event_name,
        name => $name,
        data => $data,
    };
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!
 
