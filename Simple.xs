
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <mpv/client.h>

// For debugging of MPV::Simple::Pipe
//#define stdout PerlIO_stdout()

typedef mpv_handle * MPV__Simple;
typedef mpv_event * MPVEvent;

static PerlInterpreter * mine;
static PerlInterpreter * perl_for_cb;
static int n = 1;

// Stolen from SDL
#ifdef USE_THREADS
PerlInterpreter *parent_perl = NULL;
extern PerlInterpreter *parent_perl;
PerlInterpreter *current_perl = NULL;
#define GET_TLS_CONTEXT eval_pv("require DynaLoader;", TRUE); \
        if(!current_perl) { \
            parent_perl = PERL_GET_CONTEXT; \
            current_perl = perl_clone(parent_perl, CLONEf_KEEP_PTR_TABLE); \
            PERL_SET_CONTEXT(parent_perl); \
        }
#define ENTER_TLS_CONTEXT { \
            if(!PERL_GET_CONTEXT) { \
                PERL_SET_CONTEXT(current_perl); \
            }
#define LEAVE_TLS_CONTEXT }
#else
PerlInterpreter *parent_perl = NULL;
extern PerlInterpreter *parent_perl;
#define GET_TLS_CONTEXT         /* TLS context not enabled */
#define ENTER_TLS_CONTEXT       /* TLS context not enabled */
#define LEAVE_TLS_CONTEXT       /* TLS context not enabled */
#endif

// Ende des Diebstahls


void my_init(void) {
    mine = PERL_GET_CONTEXT;
}

void callp()
{
    int new_perl = 0;
    
    //dTHX;
    /* Meine alte Lösung
        if ( !PERL_GET_CONTEXT )
      {
         printf ("my_perl was NULL\n");
         PERL_SET_CONTEXT(mine);
         perl_for_cb = perl_clone(mine, CLONEf_COPY_STACKS | CLONEf_KEEP_PTR_TABLE);
         PERL_SET_CONTEXT(perl_for_cb);
         printf ("my_perl == %ul\n", my_perl);
         //CLONE_PARAMS clone_param; clone_param.stashes = NULL; clone_param.flags = 0; clone_param.proto_perl = perl_for_cb;
         
         new_perl = 1;
      }
    */ 
    
    ENTER_TLS_CONTEXT;
    //dTHX;
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
    LEAVE_TLS_CONTEXT;
    
    /* Meine alte Lösung
        if ( new_perl ) {
        perl_free(my_perl);
        PERL_SET_CONTEXT(mine);
        } 
    */
}



MODULE = MPV::Simple		PACKAGE = MPV::Simple		


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
observe_property(MPV::Simple ctx, SV* property)
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
    
    if (event->event_id == 3 || event->event_id == 22) {
        mpv_event_property * property = event->data;
        const char * name = property->name;
        hv_store(hash,"name",4,newSVpv(name,0),0);
        if (property->format == 0) {
            hv_store(hash,"data",4,newSV(0),0);
        }
        else if (property->format == 1 || property->format == 2) {
            char * data = *(char**) property->data;
            hv_store(hash,"data",4,newSVpv(data,0),0);
        }
        // TODO: The following needs tests and add mor mpv_formats
        else if (property->format == 3) {
            int data = *(int*) property->data;
            hv_store(hash,"data",4,newSViv(data),0);
        }
        else {
            hv_store(hash,"data",4,newSVpv("not supported",0),0);
        }
    }
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
_xs_set_wakeup_callback(MPV::Simple ctx, SV* callback)
    CODE:
    {
    void (*callp_ptr)(void*);
    callp_ptr = callp;
    //my_init();
    GET_TLS_CONTEXT;
    mpv_set_wakeup_callback(ctx,callp_ptr,NULL);
    }
