#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


/* Global Data */

#define MY_CXT_KEY "MPV::_guts" XS_VERSION

typedef struct {
    /* Put Global Data in here */
    int dummy;		/* you can access this elsewhere as MY_CXT.dummy */
    SV* callback;
} my_cxt_t;

START_MY_CXT


#include <mpv/client.h>

typedef mpv_handle * MPV__Simple;
typedef mpv_event * MPVEvent;

void callp( SV* string)
{
    dTHX;
    dMY_CXT;
    dSP;
    
    // THIS WORKS! YEAH!
    
    //ENTER; SAVETMPS; 
    PUSHMARK(SP);
    
    //PUTBACK;
    
    perl_call_sv(MY_CXT.callback,G_DISCARD|G_NOARGS);
    //SPAGAIN;
    
    //PUTBACK;FREETMPS;LEAVE;
    
}

MODULE = MPV::Simple		PACKAGE = MPV::Simple		

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
     MY_CXT.callback = (SV*)NULL;
}

MPV::Simple
xs_create( const char *class )
    CODE:
        mpv_handle * handle = mpv_create();
        //const char *args[] = {"loadfile", "./summertime.ogg", NULL};
        //mpv_command((mpv_handle*) ctx, args);
        

        RETVAL = handle;
    OUTPUT: RETVAL


int
_xs_mpv_set_option_string(MPV::Simple ctx, SV* option, SV* data)
    CODE:
    {
    int ret = mpv_set_option_string( ctx, SvPV_nolen(option),SvPV_nolen(data) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL

int
_xs_mpv_set_property_string(MPV::Simple ctx, SV* option, SV* data)
    CODE:
    {
    int ret = mpv_set_option_string( ctx, SvPV_nolen(option),SvPV_nolen(data) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL
    
void
_xs_mpv_initialize(MPV::Simple ctx)
    CODE:
    {
        mpv_initialize(ctx);
    }

void
_xs_mpv_terminate_destroy(MPV::Simple ctx)
    CODE:
    {
        mpv_terminate_destroy(ctx);
    }
    
void
_xs_mpv_command(MPV::Simple ctx)
    CODE:
    {
    const char *args[] = {"loadfile", "/home/maximilian/Dokumente/perl/MPV-Simple/t/einladung2.mp4", NULL};
    mpv_command(ctx, args);
    }
    
MPVEvent
_xs_mpv_wait_event(MPV::Simple ctx, SV* timeout)
    CODE:
    {
    MPVEvent ret = mpv_wait_event( ctx, SvIV(timeout) );
    RETVAL = ret;
    }
    OUTPUT: RETVAL


void
set_my_callback(ctx, fn)
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
_xs_set_wakeup_callback(MPV::Simple ctx)
    PREINIT:
            dMY_CXT;
    CODE:
    {
    SV* data;
    void (*rechne)(void*);
    rechne = callp;
    data = get_sv("MPV::Simple::callback_data",0);
    mpv_set_wakeup_callback(ctx,rechne,MY_CXT.callback);
    }
    
char *
_xs_mpv_event_name(MPV::Simple ctx, MPVEvent event)
CODE:
    char * name = mpv_event_name(event->event_id);
    RETVAL = name;
OUTPUT: RETVAL


MODULE = MPV::Simple		PACKAGE = MPVEvent
    
int
xs_id(self, event)
    MPVEvent event
CODE:
    {
    int id = event->event_id;
    RETVAL=id;
    }
OUTPUT:
    RETVAL
