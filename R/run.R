
# sccs part ---------------------------------------------------------------

#' sccs for mnd study
#' @param demo the dataset with demographic information, including id, dob, dod, sex, onset_date. Pls check the data shall.
#' @param rx the dataset with all prescription records, including id, drug name, date of prescription start and end, type of presciption (IP, OP, AE, Discharge). Pls check the data shall.
#' @param ip the dataset with all in-hospitalization records, including id, date of adminssion, date of discharge, type of records (setting, IP, OP, AE). Pls check the data shall.
#' @param target_drugs the drug name of riluzole. In hong kong, there are two type of drug names in HK： riluzole and riluteck
#' @param obst the defined study observation date. Choose the earliest avaiable date with *Riluzole* in the hospital or approved date by FDA. For instance, 2001-8-24 in Hong Kong.
#' @param obed the defined study observation date. Default : 2019-12-31
#' @return
#' @export
#'
#' @examples run_sccs()
run_sccs <- function(demo, dx, rx, ip,
                     riluzole_name='riluzole|rilutek',
                     obst="2001-08-24",
                     obed="2018-12-31",
                     icd_pneumonia="486",
                     icd_arf="^518.81|^518.82",...){
    message("Data Cleaning for SCCS")
#    message(nrow(demo)," in the cohort","\n========================\n\n")
    dt_combined <- get_DT_Exposure_Endpoint(demo=demo,rx=rx,ip=ip,riluzole_name=riluzole_name,
                                            obst=obst,obed=obed,icd_pneumonia=icd_pneumonia,icd_arf=icd_arf,...)
    dt_sccs <- get_DT_SCCS(data=dt_combined,obst=obst,obed=obed,...)
    message("\n==================\nAfter cleanning, count of participants for sccs:\n", dt_sccs[,uniqueN(id)])
    ageq <- floor(seq(20,90,10)*365)
    dt_sccs$id <- as.numeric(dt_sccs$id)
    setorder(dt_sccs,id,event,date_rx_st)
    dt_sccs$dob_dmy <- as.numeric(format(dt_sccs$dob,"%d%m%Y")) # this is for version 1.4 or above
    dob_dmy_model <- dt_sccs[,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy] # this is the dob for previous SCCS package, with version less than 1.3
    result_primary <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
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
                   # dob=dob_dmy, # for sccs version 1.5 or above
                   dob13=dob_dmy_model, # for sccs version 1.3 only
                   data = as.data.frame(dt_sccs),...)
    # ae_subgroup analysis ----------------------------------------------------
    message("\n==================\nSubgroup analysis: A&E\n")
    dob_dmy_model_ae <- dt_sccs[ae==T,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy]
    result_ae  <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
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
                        # dob=dob_dmy, # for sccs version 1.5 or above
                        dob13=dob_dmy_model_ae, # for sccs version 1.3 only
                        data = as.data.frame(dt_sccs[ae==T]),...)

    message("\n==================\nSubgroup analysis: with penumonia Dx\n")
    # adm_pneumonia_subgroup analysis ----------------------------------------------------
    dob_dmy_model_pn <- dt_sccs[adm_pneumonia==T,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy]
    result_pneumonia <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
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
                       # dob=dob_dmy, # for sccs version 1.5 or above
                       dob13=dob_dmy_model_pn, # for sccs version 1.3 only
                       data = as.data.frame(dt_sccs[adm_pneumonia==T]),...)

    message("\n==================\nSubgroup analysis: with Acute respiratory failure\n")
    # adm_acute_respiratory_failure_subgroup analysis ----------------------------------------------------
    dob_dmy_model_arf <- dt_sccs[adm_arf==T,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy]
    result_arf <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
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
                             # dob=dob_dmy, # for sccs version 1.5 or above
                             dob13=dob_dmy_model_arf, # for sccs version 1.3 only
                             data = as.data.frame(dt_sccs[adm_arf==T]),...)

    # sensitivity_collapsed ---------------------------------------------------
    message("\n==================\nSensitivity analysis: Risk period collapsed\n")
    dt_sccs_collapsed <- get_DT_SCCS_collapsed(dt_combined,obst,obed,...)
    dt_sccs_collapsed$id <- as.numeric(dt_sccs_collapsed$id)
    setorder(dt_sccs_collapsed,id,event,date_rx_st)
    dt_sccs_collapsed$dob_dmy <- as.numeric(format(dt_sccs_collapsed$dob,"%d%m%Y")) # this is for version 1.4 or above
    dob_dmy_model <- dt_sccs_collapsed[,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy] # this is the dob for previous SCCS package, with version less than 1.3

    dob_dmy_model_collapsed <- dt_sccs_collapsed[,.(id,event,dob_dmy)][,unique(.SD)][,dob_dmy]
    result_collapsed <- sccs(event ~ strx_30b + strx_0a + strx_60a + strx_120a + strx_180a +
                           age + season,
                       indiv = id,
                       astart = obst,
                       aend = obed,
                       aevent = event,
                       adrug = list(strx_30b,strx_0a, strx_60a,strx_120a,strx_180a),
                       aedrug = list(edrx_30b,edrx_0a,edrx_60a,edrx_120a,edrx_180a),
                       dataformat = "stack", agegrp = ageq, seasongrp = c(0103,0105,0109,0111),
                       # dob=dob_dmy, # for sccs version 1.5 or above
                       dob13=dob_dmy_model_collapsed, # for sccs version 1.3 only
                       data = as.data.frame(dt_sccs_collapsed),...)


    result <- list(dt_raw=dt_sccs,
                     primary=result_primary,
                     subgroup_ae=result_ae,
                     subgroup_pneumonia=result_pneumonia,
                     subgroup_arf=result_arf,
                     collapsed=result_collapsed)
    result <- structure(result,class=c("mndsccsoutput","list"))
    return(result)
}

#' Standardsccs with formated output
#'
#' @param fml the formula in standardsccs
#'
#' @return
#' @export
#'
#' @examples sccs()
sccs <- function(fml,dob13,...){
    out <- list()
    fit_sccs <- standardsccs(formula = fml,dob=dob13,...)
    out$fit <- fit_sccs
    dt_sccs <- setDT(formatdata(dob=dob13,...))
    colnm <- get_colnm(exp,...)
    dt_sccs <- dt_sccs[,lapply(.SD,function(x) as.numeric(as.character(x)))]
    fml <- update(fml,.~. - age-season)
    dt_sccs[, ctrl0 := as.numeric(eval(fml[[3]])==0)]
    out$dt_formated <- dt_sccs
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



#' run analysis for incidence
#'
#' @param demo the dataset with demographic information, including id, dob, dod, sex, onset_date. Pls check the data shall.
#' @param dx the dataset with all diagnosis information, including id, codes, ref_date, setting. Pls check the data shall.
#' @param rx the dataset with all prescription records, including id, drug name, date of prescription start and end, type of presciption (IP, OP, AE, Discharge). Pls check the data shall.
#' @param region the region. "hk", "tw" or "kr"
#'
#' @return
#' @export
#'
#' @examples run_desc(demo, dx, rx)
run_desc <- function(demo, dx, rx, ip, region="hk"){
    if(region =="hk"){
        codes_sys = "icd9"
        codes_drug_sys = "BNF"
    }else if(region=="kr"){
        codes_sys = "icd10"
        codes_drug_sys = "ATC_NCS"
    }else if(region=="tw"){
        codes_sys = "icd9_icd10_nodecimal"
        codes_drug_sys = "ATC"
    }
    if(!exists("dir_mnd_codes")){stop("Pls input the directory of mnd\n eg. dir_mnd_codes<-\"./data/codes_mnd.xlsx\"")}
    if(!packageVersion("SCCS")=="1.3"){stop("SCCS version has to be 1.3")}
    dt_after_clean <- cleaning_mnd(demo=demo,dx=dx,rx = rx, codes_sys,codes_drug_sys)
    dt_inci <- dt_after_clean$dt_raw

    raw_pop <- setDT(read_xlsx(dir_mnd_codes, sheet=paste0(region,"_pop")))
    raw_pop <- melt(raw_pop,id.vars = "Age")
    setnames(raw_pop,c("variable","value"),c("year_onset","pop_raw"))

    std_pop <- setDT(read_xlsx(dir_mnd_codes,sheet="stdpop"))
    std_pop$Age<-factor(std_pop$Age)

    dt_inci[year(dod)>2018,dod:=NA] # change the dod if their death date is larger than study end date
    incident_raw <- dt_inci[,.(id,year_onset,age_group_std)][,.N,by=.(age_group_std,year_onset)]
    death_number <- dt_inci[,.(id,year_death=year(dod),age_group_std)][,.N,by=.(age_group_std,year_death)][!is.na(year_death)]
    prevalence.N <- sum(incident_raw$N)-sum(death_number$N)
    message("\n================================")
    message("Till the end of study, ",prevalence.N," ppl were found with MND.")
    poi_prev <- poisson.test(prevalence.N,sum(as.data.table(read_xlsx(dir_mnd_codes,sheet = "hk_pop"))[,`2018`]))
    message("prevalence:",paste(round(c(as.numeric(poi_prev$estimate*100000),
                          as.numeric(poi_prev$conf.int*100000)),2),collapse =" "))
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

    # death
    # cumsum(table(year(des$dt_raw$dod)))

    incident_std <- incident_raw[,std_risk:=N/pop_raw*pop_std_ratio*100000
    ][,.(std_risk=sum(std_risk),pop_raw=sum(pop_raw)),year_onset
    ][,stdN:=round(std_risk*pop_raw/100000)]

    incident_std <- cbind(incident_std,rbindlist(apply(incident_std,1,get_inci_CI)))
    incident_std[,`:=`(est=as.numeric(est),
                       est_l=as.numeric(est_l),
                       est_h=as.numeric(est_h),
                       year_onset=factor(year_onset))]
    message("================================\n")
    message("Running Cox model")
    dt_tv <- dt_after_clean$dt_tv
    fit_cox_timevaring <- coxph(Surv(tstart,tstop,endpt)~
                                    drug_sta+cluster(id)+sex+hx.htn+
                                    hx.depre+hx.pd+score.cci,dt_tv,id = id)

    dt_tv$sex <- factor(dt_tv$sex)
    dt_tv$id <- as.numeric(dt_tv$id)
    # survival package: cannot handle time -dependent covariates
    # fit_aft_timevaring <- survreg(Surv(tstop,endpt)~
    #                                   drug_sta+cluster(id)+sex+hx.htn+
    #                                   hx.depre+hx.pd+score.cci,dt_tv,dist="weibull")
    # flexsurvreg
    message("================================\n")
    message("Runging AFT model:")
    fit_aft_timevaring <- flexsurvreg(Surv(tstart, tstop, endpt) ~
                                          drug_sta+factor(sex)+factor(hx.htn)+
                                          factor(hx.depre)+factor(hx.pd)+score.cci,data=dt_tv,dist="weibull")

    output <- list(dt_raw=dt_after_clean$dt_raw,
                   dt_cox=dt_tv,
                   tableone=get_tableone(dt_after_clean$dt_raw),
                   std_inci=incident_std,
                   cox_result=fit_cox_timevaring,
                   aft_result=fit_aft_timevaring,
                   cox_est=get_tv_cox(fit_cox_timevaring),
                   aft_est=get_tv_cox(fit_aft_timevaring)[!var %in% c("shape","scale")])
    output <- structure(output,class=c("mndinci","list"))
    return(output)
}


#' Title
#'
#' @param output_desc the output from run_desc()
#' @param output_sccs the output from run_sccs()
#' @param dir_ouput the file directory that you want to use
#'
#' @return
#' @export
#'
#' @examples
saveall <- function(output_desc,output_sccs,dir_output="."){
    tableone <- print(output_desc$tableone, noSpaces = TRUE)
    tableone <- cbind(rownames(tableone),tableone[,c(1:4)])
    rownames(tableone) <- NULL
    d = list(dt_raw=output_desc$dt_raw,
         dt_cox=output_desc$dt_cox,
         tableone=tableone,
         std_inci=output_desc$std_inci,
         cox_est=output_desc$cox_est,
         aft_est=output_desc$aft_est,
         dt_sccs=output_sccs$dt_raw,
         sccs_primary=output_sccs$primary$res,
         sccs_ae = output_sccs$subgroup_ae$res,
         sccs_pneumonia = output_sccs$subgroup_pneumonia$res,
         sccs_arf = output_sccs$subgroup_arf$res,
         sccs_collapsed = output_sccs$collapsed$res)
    openxlsx::write.xlsx(d,file=paste0(dir_output,"/allresults.xlsx"))
}
