#include <string.h>
#include "internal.h"

ncprogbar* ncprogbar_create(ncplane* n, const ncprogbar_options* opts){
  ncprogbar_options default_opts;
  if(opts == NULL){
    memset(&default_opts, 0, sizeof(default_opts));
    opts = &default_opts;
  }
  if(opts->flags > (NCPROGBAR_OPTION_RETROGRADE << 1u)){
    logwarn(ncplane_notcurses(n), "Invalid flags %016lx\n", opts->flags);
  }
  ncprogbar* ret = malloc(sizeof(*ret));
  ret->ncp = n;
  ret->channels = opts->channels;
  ret->retrograde = opts->flags & NCPROGBAR_OPTION_RETROGRADE;
  return ret;
}

ncplane* ncprogbar_plane(ncprogbar* n){
  return n->ncp;
}

static int
progbar_redraw(ncprogbar* n){
  // get current dimensions; they might have changed
  int dimy, dimx;
  ncplane_dim_yx(ncprogbar_plane(n), &dimy, &dimx);
  const bool horizontal = dimx > dimy;
  int range, delt, pos;
  if(horizontal){
    range = dimx;
    delt = 1;
    pos = 0;
  }else{
    range = dimy;
    delt = -1;
    pos = range - 1;
  }
  ncplane_set_channels(ncprogbar_plane(n), n->channels);
  double progress = n->progress * range;
  if(n->retrograde){
    delt *= -1;
    if(pos){
      pos = 0;
    }else{
      pos = range - 1;
    }
    if(horizontal){
      progress = range - progress;
    }
  }else if(!horizontal){
    progress = range - progress;
  }
  while((delt < 0 && pos > progress) || (delt > 0 && pos < progress)){
//fprintf(stderr, "progress: %g pos: %d range: %d delt: %d\n", progress, pos, range, delt);
    if(horizontal){
      if(ncplane_putegc_yx(ncprogbar_plane(n), 0, pos, "█", NULL) <= 0){
        return -1;
      }
    }else{
      if(ncplane_putegc_yx(ncprogbar_plane(n), pos, 0, "█", NULL) <= 0){
        return -1;
      }
    }
    pos += delt;
  }
  return 0;
}

int ncprogbar_set_progress(ncprogbar* n, double p){
//fprintf(stderr, "PROGRESS: %g\n", p);
  if(p < 0 || p > 1){
    logerror(ncplane_notcurses(ncprogbar_plane(n)), "Invalid progress %g\n", p);
    return -1;
  }
  n->progress = p;
  return progbar_redraw(n);
}

double ncprogbar_progress(const ncprogbar* n){
  return n->progress;
}

void ncprogbar_destroy(ncprogbar* n){
  ncplane_destroy(n->ncp);
  free(n);
}
