#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
        SV *callback;
        SV *data;
        int has_events;
} my_cxt_t;
START_MY_CXT;




#include <mpv/client.h>

// For debugging of MPV::Simple::Pipe
#define stdout PerlIO_stdout()

typedef mpv_handle * MPV__Simple;
typedef mpv_event * MPVEvent;

static PerlInterpreter * mine;
static PerlInterpreter * perl_for_cb;
static int n = 1;



void my_init(void) {
    mine = PERL_GET_CONTEXT;
}

void callp()
{
    
    int new_perl = 0;
    
    dTHX;
    dMY_CXT;
    MY_CXT.has_events = 1;
    
    
    
}



MODULE = MPV::Simple		PACKAGE = MPV::Simple		


BOOT:
        MY_CXT_INIT;




MPV::Simple
xs_create( const char *class )
    CODE:
        mpv_handle * handle = mpv_create();
        //mpv_initialize(handle);
        //my_init();
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
    

SV*
get_property_string(MPV::Simple ctx, SV* property)
    CODE:
    {
    char *string = mpv_get_property_string( ctx, SvPV_nolen(property) );
    SV* value = newSVpv(string,0);
    mpv_free(string);
    RETVAL = value;
    }
    OUTPUT: RETVAL
    
int
observe_property_string(MPV::Simple ctx, SV* property)
    CODE:
    {
    int error = mpv_observe_property( ctx, 0, SvPV_nolen(property), 1 );
    RETVAL = error;
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
    
HV *
wait_event(MPV::Simple ctx, SV* timeout)
    PREINIT:
        HV* hash;
        mpv_event * event;
    CODE:
    {
    event = mpv_wait_event( ctx, SvIV(timeout) );
    
    hash = (HV *) sv_2mortal( (SV*) newHV() );
    
    // Copy struct contents into hash
    hv_store(hash,"id",2,newSViv(event->event_id),0);
    
    // Data for MPV_EVENT_GET_PROPERTY_REPLY
    // and MPV_EVENT_PROPERTY_CHANGE
    if (event->event_id == 3 || event->event_id == 22) {
        mpv_event_property * property = event->data;
        const char * name = property->name;
        hv_store(hash,"name",4,newSVpv(name,0),0);
        // MPV_FORMAT_NONE
        if (property->format == 0) {
            hv_store(hash,"data",4,newSV(0),0);
        }
        // MPV_FORMAT_STRING and MPV_FORMAT_OSD_STRING
        else if (property->format == 1 || property->format == 2) {
            char * data = *(char**) property->data;
            hv_store(hash,"data",4,newSVpv(data,0),0);
        }
        // TODO: The following needs tests and add mor mpv_formats
        // MPV_FORMAT_FLAG
        else if (property->format == 3) {
            int data = *(int*) property->data;
            hv_store(hash,"data",4,newSViv(data),0);
        }
        // MPV_FORMAT_DOUBLE
        else if (property->format == 5) {
            double data = *(double*) property->data;
            hv_store(hash,"data",4,newSVnv(data),0);
        }
        else {
            hv_store(hash,"data",4,newSVpv("MPV_FORMAT_NODE and MPV_FORMAT_INT64 at the moment not supported. For the latter please use MPV_FORMAT_DOUBLE.",0),0);
        }
    }
    
    // Data for MPV_EVENT_END_FILE
    else if (event->event_id == 7) {
        mpv_event_end_file * data = event->data;
        int reason = data->reason;
        hv_store(hash,"data",4,newSViv(reason),0);
    }
    else {
        hv_store(hash,"data",4,newSV(0),0);
    }
    
    RETVAL = hash;
    }
    OUTPUT: RETVAL

void
wakeup(MPV::Simple ctx)
    CODE:
    {
        mpv_wakeup(ctx);
    }

    
void
xs_set_my_callback(ctx, fn)
        MPV::Simple ctx
        SV *	fn
        PREINIT:
            dMY_CXT;
        CODE:
        /* Remember the Perl sub */
        if (MY_CXT.callback == (SV*)NULL)
            MY_CXT.callback = newSVsv(fn);
        else
            SvSetSV(MY_CXT.callback, fn);

void
xs_set_my_data(ctx, fn)
        MPV::Simple ctx
        SV *	fn
        PREINIT:
            dMY_CXT;
        CODE:
        /* Remember the Perl sub */
        if (MY_CXT.data == (SV*)NULL)
            MY_CXT.data = newSVsv(fn);
        else
            SvSetSV(MY_CXT.data, fn);
            
            
void
_xs_set_wakeup_callback(MPV::Simple ctx, SV* callback)
    CODE:
    {
    my_init();
    void (*callp_ptr)(void*);
    callp_ptr = callp;
    mpv_set_wakeup_callback(ctx,callp_ptr,NULL);
    }
