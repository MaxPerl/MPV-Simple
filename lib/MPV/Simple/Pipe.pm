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
use MPV::Simple;
use strict;
use warnings;

sub new {
    my ($reader, $writer);
    
    # Avoid zombies
    $SIG{CHLD} = 'IGNORE';
    
    
    # Fork
    pipe $reader, $writer;
    $writer->autoflush(1);
    my $pid = fork();
    
    if ($pid != 0) {
        close $reader;
        my ($class) = @_;
        my $obj ={};
        $obj->{writer} = $writer;
        $obj->{pid} = $pid;
        bless $obj, $class;
        return $obj;
    }
    else {
        close $writer;
        mpv($reader);
    }
}

sub set_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "set_property_string###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub command {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "command###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub initialize {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "initialize###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub terminate_destroy {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "terminate_destroy###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub mpv {
    my ($reader) = @_;
    my $initialized = 0;
    my $ctx = MPV::Simple->new();
    while (1) {
       
        if ( defined(my $line = <$reader>) ) {
            chomp $line;
            my ($command, @args) = split('###',$line);
            #print "ARGS @args\n";
            #print "Executing \$ctx->$command(@args)\n";
            if ($command eq "terminate_destroy") {
                print "Terminate MPV::Simple..\n";
                $ctx->terminate_destroy();
                $initialized=0;
                last;
            }
            else {
                eval{
                    $ctx->$command(@args)
                };
                if ($@) {
                        print "FEHLER:$@\n";
                }
                $initialized = 1 if ($command eq "initialize"); 
            }
       }

       if ($initialized) {
            while (my $event = $ctx->wait_event(0)) {
                my $id = $event->id();
                print "ID $MPV::Simple::event_names[$id] \n";
                last unless ($id);
            }
        }
        
            
    }
    close $reader;
    exit 0;
}

DESTROY {
    my ($self) = @_;
    if ( my $pid=$self->{pid} ) {
            close $self->{writer};
            kill(9,$pid);
    }
}

1;
