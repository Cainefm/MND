

#' sccs for mnd study
#' @param demo
#' @param rx
#' @param ip
#' @param target_drugs the drug name of riluzole. In hong kong, there are two type of drug names in HK： riluzole and riluteck
#' @param obst the defined study observation date. Choose the earliest avaiable date with *Riluzole* in the hospital or approved date by FDA. For instance, 2001-8-24 in Hong Kong.
#' @param obed the defined study observation date. Default : 2019-12-31
#' @return
#' @export
#'
#' @examples run_sccs()
run_sccs <- function(demo, rx, ip, target_drugs='riluzole|riluteck',
                     obst="2001-08-24", obed="2018-12-31", ...){
    message("merge exposure and outcome datasets")
    message(nrow(demo)," in the cohort","\n========================\n\n")
    dt_combined <- get_DT_Exposure_Endpoint(demo,rx,ip,...)
    dt_sccs <- get_DT_SCCS(dt_combined,...)
    message("After cleanning, count of participants for sccs:\n", dt_sccs[,uniqueN(id)],"\n========================\n\n")
    ageq <- floor(seq(20,90,10)*365)
    dt_sccs$id <- as.numeric(dt_sccs$id)
    setorder(dt_sccs,id,event,date_rx_st)
    dt_sccs$dob_dmy <- as.numeric(format(dt_sccs$dob,"%d%m%Y")) # this is for version 1.4 or above
    dob_dmy_model <- dt_sccs[,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy] # this is the dob for previous SCCS package, with version less than 1.3
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
                               aedrug = list(edrx_30b,edrx_0a,edrx_30a,
                                             edrx_60a,edrx_90a,edrx_120a,
                                             edrx_150a, edrx_180a),
                               dataformat = "stack", agegrp = ageq, seasongrp = c(0103,0105,0109,0111),
                               #    dob=dob_dmy, # for sccs version 1.5 or above
                               dob=dob_dmy_model, # for sccs version 1.3 only
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
#' @examples sxd(2.01999,2)
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
#'
#' @examples sccs()
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


#' Print only outcome for MND study
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
print.mndsccs <- function(x){
    print(x$res)
}

show_digit<- function(x){
    return(sprintf(as.numeric(x),fmt="%#.2f"))
}

#' Inci Ci calculation
#'
#' @param x
#'
#' @return
#'
#' @examples
get_inci_CI <- function(x){
    temp <- poisson.test(as.numeric(x[["stdN"]]),as.numeric(x[["pop_raw"]]))
    est <- temp[["estimate"]]*100000
    est_l <- temp$conf.int[2]*100000
    est_h <- temp$conf.int[1]*100000
    est_cb <- paste0(show_digit(est)," (",
                     show_digit(est_l),"-",
                     show_digit(est_h),")")
    return(data.frame(est,est_l,est_h,est_cb))
}


#' run analysis for incidence
#'
#' @param demo
#' @param dx
#' @param region
#' @param codes_sys
#'
#' @return
#' @export
#'
#' @examples
run_incidence <- function(demo, dx, region="hk",codes_sys = "icd9"){
    dx_inci <- clean_4_survival(demo=demo,dx=dx,codes_sys)

    raw_pop <- setDT(read_xlsx("./data/codes_mnd.xlsx", sheet=paste0(region,"_pop")))
    raw_pop <- melt(raw_pop,id.vars = "Age")
    setnames(raw_pop,c("variable","value"),c("year_onset","pop_raw"))

    std_pop <- setDT(read_xlsx("./data/codes_mnd.xlsx",sheet="stdpop"))
    std_pop$Age<-factor(std_pop$Age)


    incident_raw <- dx_inci[,.(id,year_onset,age_group_std)][,.N,by=.(age_group_std,year_onset)]
    setnames(incident_raw,"age_group_std","Age")
    incident_raw$year_onset <- as.factor(incident_raw$year_onset)
    setorder(incident_raw,Age,year_onset)

    incident_raw <- merge(incident_raw,
                         raw_pop,
                         by=c("Age","year_onset"),all.y=T)
    incident_raw <- merge(incident_raw,
                         std_pop[,.(Age,pop_std=`Standard For SEER*Stat`,pop_std_ratio=`WHO std pop`)],
                         by=c("Age"))
    incident_raw[is.na(N),N:=0]
    incident_std <- incident_raw[,std_risk:=N/pop_raw*pop_std_ratio*100000
                                         ][,.(std_risk=sum(std_risk),pop_raw=sum(pop_raw)),year_onset
                                           ][,stdN:=round(std_risk*pop_raw/100000)]



    incident_std <- cbind(incident_std,rbindlist(apply(incident_std,1,get_inci_CI)))
    incident_std[,`:=`(est=as.numeric(est),
                       est_l=as.numeric(est_l),
                       est_h=as.numeric(est_h),
                       year_onset=factor(year_onset))]
    return(list(std_inci=incident_std, raw_dt=dx_inci))
}

#' Plot the figure of incidence
#'
#' @param data
#' @param region
#'
#' @return
#' @export
#'
#' @examples
p_inci <- function(data,region="Hong Kong"){
    ggplot(data,aes(x=year_onset,y=est,group=1))+
        geom_line()+theme_light()+
        xlab("Onset year")+
        ylab("Age standardized MND incidence \nby year per 100,000 population")+
        ggtitle(region)+
        theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1,size=18),
              axis.text.y = element_text(size=18),
              plot.title = element_text(size=22),
              axis.title = element_text(size=18)
              )
}


p_inci_sg <- function(x){
    iw <- incidence(x, interval = "6 months", date_index = onset_date, groups = sex)
    plot(iw, fill = "sex", color = "white",border="grey",title = "Hong Kong")
}


