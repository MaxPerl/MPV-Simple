package MPV::Simple::Pipe;

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

use IO::Handle;
use IO::Select;
use Symbol qw(qualify_to_ref);
use MPV::Simple;
use strict;
use warnings;

# Avoid zombies
$SIG{CHLD} = 'IGNORE';

sub new {
    my ($class,%opts) = @_;
    
    my ($reader, $writer,$reader2, $writer2,$evreader, $evwriter);
    
    
    # Fork
    pipe $reader, $writer;
    pipe $reader2, $writer2;
    pipe $evreader, $evwriter;
    $writer->autoflush(1);
    $writer2->autoflush(1);
    $evwriter->autoflush(1);
    
    # Kommando Schnittstelle
    my $pid = fork();
    
    # Main
    my $obj ={};
    if ($pid != 0) {
        close $writer2;
        close $reader;
        $obj->{reader} = $reader2;
        $obj->{writer} = $writer;
        $obj->{pid} = $pid;
        
        close $evwriter;
        $obj->{evreader} = $evreader;
        $obj->{event_handling} = $opts{event_handling} || 0;
        bless $obj, $class;
        return $obj;
    }
    # Command Handler
    else {
        close $reader2;
        close $writer;
        mpv($reader,$writer2,$evwriter,%opts);
        exit 0;
    }
    
    
}

sub set_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "set_property_string###$args\n";
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
    my $writer = $obj->{writer};
    print $writer $line;
}

sub get_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "get_property_string###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    chomp $ret;
    return $ret;
}

sub observe_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "observe_property_string###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
}

sub command {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "command###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
}

sub initialize {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "initialize###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
}

sub terminate_destroy {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "terminate_destroy###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    #(tied @commands)->shlock;
    #push @commands,$line;
    #(tied @commands)->shunlock;
    
}

sub event_handler {
    my ($evwriter, %opts) = @_;
    sleep 5;
    while (1) {
    
    }
    exit 0;
}

sub mpv {
    my ($reader,$writer2,$evwriter,%opts) = @_;
    my $initialized = 0;
    my $ctx = MPV::Simple->new();
    while (1) {
        
        $reader->blocking(0);
        while ( my $line = <$reader> ) {
            last unless ($line);
            chomp $line;
            my ($command, @args) = split('###',$line);
            #print "ARGS @args\n";
            #print "Executing \$ctx->$command(@args)\n";
            if ($command eq "terminate_destroy") {
                print "Terminate MPV::Simple..\n";
                $ctx->terminate_destroy();
                $initialized = 0;
            }
            elsif ($command eq "get_property_string") {
                my $return = $ctx->get_property_string(@args);
                #use Devel::Peek;
                #Dump $return;
                # Don't forget \n at the end!!!
                print $writer2 "$return\n";
            }
            else {
                eval{
                    #print "COMMAND $command\n";
                    #print "ARGS @args\n";
                    $ctx->$command(@args);
                };
                if ($@) {
                        print "FEHLER:$@\n";
                }
                $initialized = 1 if ($command eq "initialize");
            }
       }
       
       if ($initialized) {
        while (my $event = $ctx->wait_event(0)) {
                    my $id = $event->{id};
                    my $name = $event->{name} || '';
                    my $data = $event->{data} || '';
                    print $evwriter "$id###$name###$data\n" if ($opts{event_handling} && $id != 0);
                    #use Storable qw(store_fd);
                    #store_fd($event,$evwriter) if ($opts{event_handling} && $id != 0);
                    last if ($id ==0);
                }
        }    
            
        last if ($initialized == 0);
    }
    close $writer2;
    close $evwriter;
    close $reader;
    exit 0;
}
        

DESTROY {
    my ($self) = @_;
    if ( my $pid=$self->{pid} ) {
            close $self->{reader};
            close $self->{evreader};
            close $self->{writer};
            kill(9,$pid);
    }
}

1;
