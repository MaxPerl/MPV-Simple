package MPV::Simple::threads;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue;


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
    #$thr->detach();
    
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

sub set_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "set_property_string###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    
    chomp $ret;
    return $ret;
}

sub get_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "get_property_string###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    chomp $ret;
    return $ret;
}

sub observe_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "observe_property_string###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    chomp $ret;
    return $ret;
}

sub unobserve_property {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "unobserve_property_string###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    chomp $ret;
    return $ret;    
}

sub command {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "command###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    
    chomp $ret;
    return $ret;
}

sub initialize {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "initialize###$args\n";
    
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    
    chomp $ret;
    return $ret;
}

# TODO: Bis hierher ist alles gleich!!! Mach ein AUTOLOAD daraus!!!

sub terminate_destroy {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "terminate_destroy###$args\n";
    my $writer = $obj->{MainQueue};
    $writer->enqueue($line);
    
    my $thr = $obj->{evthread};
    $thr->kill('USR1');
    
    my $reader = $obj->{ChildQueue};
    my $ret = $reader->dequeue();
    
    $process_events = undef;
    $thr->join;
    #threads->exit() if threads->can('exit');
}

# Child thread!
sub mpv {
    my ($MainQueue, $ChildQueue, $EventQueue, $event_handling) = @_;
    print "WAKEUP_STATUS $wakeup\n";
    use MPV::Simple;
    my $ctx = MPV::Simple->new() or die "Could not create MPV instance: $!\n";
    
    # Process already existing commands
    # otherwise there was arbitraries deadlock.Very curious...
    #while ( my $line = <$reader> ) {
    #        last unless ($line);
    #        _process_command($ctx,$line,$writer2);
    #   }
    
    #$ctx->setup_event_notification();
    $ctx->set_my_data(threads->self);
    $ctx->set_wakeup_callback('MPV::Simple::threads::fire');
    
    
    while ($process_events) {
        
        #print "Processing events/commands\n";
        while ( my $line = $MainQueue->dequeue_nb() ) {
            last unless ($line);
            _process_command($ctx,$line,$ChildQueue);
            
       }
       
       # The following line blocks until new events occur
       # or SIG{USR2}is fired
       if ($wakeup && $process_events) {
        while (my $event = $ctx->wait_event(0)) {
                    my $id = $event->{id};
                    last if ($id ==0);
                    my $name = $event->{name} || '';
                    my $data = $event->{data} || '';
                    my $line ="$id###$name###$data\n";
                    
                    $EventQueue->enqueue($line) if ($event_handling && $id != 0);
                    #print $evwriter "$id###$name###$data\n" if ($opts{event_handling} && $id != 0);
                    #use Storable qw(store_fd);
                    #store_fd($event,$evwriter) if ($opts{event_handling} && $id != 0);
                    
                }
                # With signaled we avoid race conditions
                lock($wakeup);
                $wakeup=0 unless ($signaled);
                $signaled = 0;
        }
        
            
    }
    return 1;
}

sub fire {
    my ($thr) = @_;
    #$thr->kill('USR1');
    $signaled=1;lock($wakeup); $wakeup = 1
}

sub _process_command {
    my ($ctx,$line,$ChildQueue) = @_;
    my $return;
    chomp $line;
    my ($command, @args) = split('###',$line);
    if ($command eq "terminate_destroy") {
        $ctx->terminate_destroy();
        $ChildQueue->enqueue("Shutting down\n");
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
    my ($event_id,$name,$data) = split('###',$line);
    return {
        event_id => $event_id,
        event => $MPV::Simple::event_names[$event_id],
        name => $name,
        data => $data,
    };
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!
 
