
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <mpv/client.h>

//#define stdout PerlIO_stdout()

typedef mpv_handle * MPV__Simple;
typedef mpv_event * MPVEvent;

static PerlInterpreter * mine;
static PerlInterpreter * perl_for_cb;
static int n = 1;


void my_init(void) {
    mine = PERL_GET_CONTEXT;
}

void callp( )
{
    int new_perl = 0;
    
    dTHX;
    if ( my_perl != NULL )
         printf ("my_perl == %ul\n", my_perl);
      else
      {
         printf ("my_perl was NULL\n");
         PERL_SET_CONTEXT(mine);
         perl_for_cb = perl_clone(mine, CLONEf_COPY_STACKS);
         PERL_SET_CONTEXT(perl_for_cb);
         
         //CLONE_PARAMS clone_param; clone_param.stashes = NULL; clone_param.flags = 0; clone_param.proto_perl = perl_for_cb;
         
         new_perl = 1;
      } 
    
    dSP;
    SV* callback = get_sv("MPV::Simple::callback",0);
    SV* data = get_sv("MPV::Simple::callback_data",0);
    
    ENTER; SAVETMPS; 
    PUSHMARK(SP);
    
    EXTEND(SP,1);
    PUSHs(sv_2mortal(newSVsv(data)));
    
    PUTBACK;
    
    perl_call_sv(callback,G_DISCARD);
    SPAGAIN;
    
    PUTBACK;FREETMPS;LEAVE;
    
    if ( new_perl ) {
        perl_free(my_perl);
        PERL_SET_CONTEXT(mine);
    }
}



MODULE = MPV::Simple		PACKAGE = MPV::Simple		


MPV::Simple
xs_create( const char *class )
    CODE:
        mpv_handle * handle = mpv_create();
        //mpv_initialize(handle);
        my_init();
        //mpv_handle * client = mpv_create_client(handle,"perl_handle");
        
        printf("Creating\n");
        RETVAL = handle;
    OUTPUT: RETVAL


int
set_option_string(MPV::Simple ctx, SV* option, SV* data)
    CODE:
    {
    int ret = mpv_set_option_string( ctx, SvPV_nolen(option),SvPV_nolen(data) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL

int
set_property_string(MPV::Simple ctx, SV* option, SV* data)
    CODE:
    {
    int ret = mpv_set_property_string( ctx, SvPV_nolen(option),SvPV_nolen(data) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL
    
void
initialize(MPV::Simple ctx)
    CODE:
    {
        mpv_initialize(ctx);
    }

void
terminate_destroy(MPV::Simple ctx)
    CODE:
    {
        mpv_terminate_destroy(ctx);
    }
    
AV*
command(MPV::Simple ctx, SV* command, ...)
    CODE:
    {
    int args_num = items-2;
    char *command_pv = SvPV_nolen(command);
    //const char *args[] = {command_pv, *arguments, NULL};
    const char *args[items];
    int i;
    int z =1;
    args[0] = command_pv;
    for (i=2; i <items; i += 1) {
        SV *key = ST(i);
        char *pv = SvPV_nolen(key);
        args[z] = pv;
        z = z+1;
    }
    args[z] = NULL;
    
    mpv_command(ctx, args);
    RETVAL = (AV*) args;
    }
    OUTPUT: RETVAL
    
MPVEvent
wait_event(MPV::Simple ctx, SV* timeout)
    CODE:
    {
    MPVEvent ret = mpv_wait_event( ctx, SvIV(timeout) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL

void
wakeup(MPV::Simple ctx)
    CODE:
    {
        mpv_wakeup(ctx);
    }
    
void
_xs_set_wakeup_callback(MPV::Simple ctx, SV* callback)
    CODE:
    {
    void (*callp_ptr)(void*);
    callp_ptr = callp;
    mpv_set_wakeup_callback(ctx,callp_ptr,NULL);
    }


    
const char *
event_name(MPV::Simple ctx, MPVEvent event)
CODE:
    const char * name = mpv_event_name(event->event_id);
    RETVAL = name;
OUTPUT: RETVAL


MODULE = MPV::Simple		PACKAGE = MPVEvent
    
int
id(event)
    MPVEvent event
CODE:
    {
    int id = event->event_id;
    RETVAL=id;
    }
OUTPUT:
    RETVAL
