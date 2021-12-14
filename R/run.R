

#' sccs for mnd study
#'
#' @return
#' @export
#'
#' @examples
run <- function(){
    message("merge exposure and outcome datasets")
    dt_combined <- get_DT_Exposure_Endpoint(demo,ip,rx)
    message("SCCS data cleanning")
    dt_sccs <- get_DT_SCCS(dt_combined)
    ageq <- floor(seq(20,90,10)*365)
    dt_sccs$id <- as.numeric(dt_sccs$id)
    dt_sccs$dob_dmy <- as.numeric(format(dt_sccs$dob,"%d%m%Y"))
#    dob_dmy_model <- dt_sccs[,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy] # this is the dob for previous SCCS package, with version less than 1.3
    result <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
                                   strx_150a +strx_180a +
                                   age + season,
                               indiv = id,
                               astart = obst,
                               aend = obed,
                               aevent = event,
                               adrug = list(strx_30b,strx_0a, strx_30a,
                                            strx_60a,strx_90a,strx_120a,
                                            strx_150a, strx_180a),
                               aedrug = list(edrx_30b,edrx_0a,edrx_30a,edrx_60a,edrx_90a,
                                             edrx_120a, edrx_150a, edrx_180a),
                               dataformat = "stack", agegrp = ageq, seasongrp = c(0103,0105,0109,0111),
                               dob=dob_dmy,
                               data = as.data.frame(dt_sccs))
    return(result)
}



#' Print with rounding, with 0 at the end if appropriate
#'
#' @param x number
#' @param n digits in round
#'
#' @return
#'
#' @examples
sxd <- function(x,n=2){
    sprintf(paste0("%.",n,"f"),round(x,n))
}

get_colnm <- function(adrug,data,...){
    call.obj <- gsub("list","cbind",deparse(substitute(adrug)))
    return(colnames(eval(parse(text=call.obj),data)))
}

#' Standardsccs with formated output
#'
#' @param fml the formula in standardsccs
#' @param ... others
#'
#' @return
#' @export
#'
#' @examples
sccs <- function(fml,...){
    out <- list()
    fit_sccs <- standardsccs(formula = fml,...)
    out$fit <- fit_sccs
    dt_sccs <- setDT(formatdata(...))
    colnm <- get_colnm(exp,...)
    dt_sccs <- dt_sccs[,lapply(.SD,function(x) as.numeric(as.character(x)))]
    fml <- update(fml,.~. - age-season)
    dt_sccs[, ctrl0 := as.numeric(eval(fml[[3]])==0)]
    out$dt <- dt_sccs
    n_py <- rbindlist(lapply(c(colnm,"ctrl0"), function(x) dt_sccs[get(x)==1,.(n_event=sum(event),PY=sxd(sum(interval)/365.25,n=2))]))
    n_py <- cbind(period=c(colnm,"ctrl0"),n_py)
    out$n_py <- n_py
    irr <- data.table(fit_sccs$conf.int, keep.rownames=T
    )[, .(period=sub("1$","",rn), adj.IRR=paste0(sxd(`exp(coef)`,n=2)," (",
                                                 sxd(`lower .95`,n=2),"-",
                                                 sxd(`upper .95`,n=2),")"))]
    out$irr <- irr
    irr <-  merge(n_py,irr,by="period",all.x = T,sort=F)
    out$res <- irr
    out <- structure(out,class=c("mndsccs","list"))
    return(out)
}


print.mndsccs <- function(x){
    print(x$res)
}
