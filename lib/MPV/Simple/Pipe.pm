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
    my ($reader, $writer,$reader2, $writer2);
    
    
    # Fork
    pipe $reader, $writer;
    pipe $reader2, $writer2;
    $writer->autoflush(1);
    $writer2->autoflush(1);
    my $pid = fork();
    
    if ($pid != 0) {
        close $reader;
        close $writer2;
        my ($class) = @_;
        my $obj ={};
        $obj->{writer} = $writer;
        $obj->{reader} = $reader2;
        $obj->{pid} = $pid;
        bless $obj, $class;
        return $obj;
    }
    else {
        close $writer;
        close $reader2;
        mpv($reader,$writer2);
    }
}

sub set_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "set_property_string###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub get_property_string {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "get_property_string###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    chomp $ret;
    return $ret;
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
    my ($reader,$writer2) = @_;
    my $initialized = 0;
    my $ctx = MPV::Simple->new();
    while (1) {
        my $line =''; 
        $line = sysreadline($reader,0);
        chomp $line;
        if ( $line ne "" ) {
            #my $line = <$reader>;
            
            my ($command, @args) = split('###',$line);
            #print "ARGS @args\n";
            #print "Executing \$ctx->$command(@args)\n";
            if ($command eq "terminate_destroy") {
                print "Terminate MPV::Simple..\n";
                $ctx->terminate_destroy();
                $initialized=0;
                last;
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
                my $id = $event->id();
                #print "ID $MPV::Simple::event_names[$id] \n";
                last unless ($id);
            }
        }
        
            
    }
    close $writer2;
    close $reader;
    exit 0;
}

# Reading non blocking
# See Perl Cookbook 7.23
sub sysreadline(*;$) {
    my($handle, $timeout) = @_;
    $handle = qualify_to_ref($handle, caller( ));
    my $infinitely_patient = (@_ == 1 || $timeout < 0);
    my $start_time = time( );
    my $selector = IO::Select->new( );
    $selector->add($handle);
    my $line = "";
SLEEP:
    until (at_eol($line)) {
        unless ($infinitely_patient) {
            return $line if time( ) > ($start_time + $timeout);
        }
        # sleep only 1 second before checking again
        next SLEEP unless $selector->can_read(1.0);
INPUT_READY:
        while ($selector->can_read(0.0)) {
            my $was_blocking = $handle->blocking(0);
CHAR:       while (sysread($handle, my $nextbyte, 1)) {
                $line .= $nextbyte;
                last CHAR if $nextbyte eq "\n";
            }
            $handle->blocking($was_blocking);
            # if incomplete line, keep trying
            next SLEEP unless at_eol($line);
            last INPUT_READY;
        }
    }
    return $line;
}
sub at_eol($) { $_[0] =~ /\n\z/ }


DESTROY {
    my ($self) = @_;
    if ( my $pid=$self->{pid} ) {
            close $self->{writer};
            close $self->{reader};
            kill(9,$pid);
    }
}

1;
