
#' Cleaning the time periods with overlapping gaps or small gaps
#'
#' @description Merge those overlapping records or records with a small interval. For instance, the two prescription records with an small gap can be considered as a same one. Or two successive hospitalizations can be merged as one.
#' @param data the dataset with starting point and ending points, which is in yyyymmdd format
#' @param gap the gap between two prescription records which you would like to merge. For instance, n = 7 when two Rx records with interval less than 7 days may be consider as the same prescription.
#' @param st the column name for starting date
#' @param ed the column name for ending date
#' @import data.table
#'
#' @return A data table will be generate with merged interval.
#' @examples
#' data <- data.table(id=rep(1,2),
#'         date_st=lubridate::ymd(c("2021-1-1","2021-1-4")),
#'         date_end=lubridate::ymd(c("2021-1-5","2021-1-6")))
#' shrink_interval(data,"date_st","date_end",gap=2)
shrink_interval <- function(data,st,ed,gap=1){
    data <- copy(data[,na.omit(.SD)][,list(id,st=lubridate::ymd(get(st)),ed=lubridate::ymd(get(ed)))])
    setorder(data,id,st)
    output <- data[,indx:=c(0, cumsum(as.numeric(shift(st,type="lead"))>
                                          cummax(as.numeric(ed)+gap))[-.N]),id
    ][,.(st=min(st),ed=max(ed)),.(id,indx)]
    setnames(output,c("st","ed"),c(st,ed))
    return(output)
}



#' Combine the datasets with exposure and outcomes
#'
#' @description Combine the exposure (Riluzole history) and outcome (Hospitalization records) for SCCS study design.
#' @param demo the dataset with demographic information, including id, dob, dod, sex, onset_date. Pls check the data shall.
#' @param rx the dataset with all prescription records, including id, drug name, date of prescription start and end, type of presciption (IP, OP, AE, Discharge). Pls check the data shall.
#' @param ip the dataset with all in-hospitalization records, including id, date of adminssion, date of discharge, type of records (setting, IP, OP, AE). Pls check the data shall.
#' @param riluzole_name the name in your database stands for riluzole.
#' @return a combined data set in data table format. One patients may have multiple rows of records.
#' @import data.table
#' @export
#'
#' @examples get_DT_Exposure_Endpoint(demo,ip,rx)
#'             id sex        dob        dod onset_date date_rx_st date_rx_end   date_adm   date_dsg
#'    1:        1   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2015-07-21 2015-07-23
#'    2:        1   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2016-10-17 2016-10-22
#'    3:        1   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-01-24 2017-01-27
#'    4:        1   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-03-03 2017-03-31
#'    5:        1   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-04-10 2017-04-10
#' ---
#' 2663:    88888   F 1955-07-02 2018-11-28 2017-11-28 2018-05-28  2018-07-22 2018-07-30 2018-08-10
#' 2664:    88888   F 1955-07-02 2018-11-28 2017-11-28 2018-05-28  2018-07-22 2018-10-31 2018-11-02
#' 2665:    88888   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2017-11-27 2017-11-28
#' 2666:    88888   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2018-07-30 2018-08-10
#' 2667:    88888   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2018-10-31 2018-11-02
get_DT_Exposure_Endpoint <- function(demo, rx, ip,riluzole_name,obst,obed,icd_pneumonia,icd_arf,...){
    rx_riluzole<- shrink_interval(rx[grepl(riluzole_name,drug_name,ignore.case = T) &
                                         !setting %in% c("I")],"date_rx_st","date_rx_end")
    message("==================\nNumber of ppl: using Riluzole (Not IP)\n",
            rx_riluzole[,uniqueN(id)])
    rx_earliest <- rx_riluzole[,.(earliest_rx=min(date_rx_st)),id][,unique(.SD)]
    ip_riluzole <- shrink_interval(ip[id %in% demo$id & id %in% rx_riluzole$id],"date_adm","date_dsg",gap = 7)
    ip_riluzole <- merge(ip_riluzole,
                         ip[,.(id,date_adm,ae)][,.(ae=any(ae)),by=.(id,date_adm)],
                         by=c("id","date_adm"),all.x=T)
    # combine the Dx and IP
    print(obed)
    ip_riluzole <- merge(ip_riluzole[date_dsg<=ymd(obed)],
                         dx[setting=="I",.(codes=paste(sort(unique(codes)),collapse=",")),.(id,ref_date)],
                         by.x=c("id","date_dsg"),by.y=c("id","ref_date"),all.x=T)


    message("==================\nNumber of ppl: having admission records:\n",
            ip_riluzole[,uniqueN(id)])
    rx_ip <- merge(rx_riluzole[,indx:=NULL],
                   ip_riluzole[,indx:=NULL],by="id",allow.cartesian = T)
    rx_ip <- merge(rx_ip,rx_earliest,by="id",all.x=T)
    demo_rx_ip<-merge(demo,rx_ip,by="id")
    message("==================\nNumber of ppl: with Demo information\n",
            rx_ip[,uniqueN(id)])

    # create indicator for pneumonia and acf ------------------------------------------
    demo_rx_ip[,adm_pneumonia:=fifelse(grepl(icd_pneumonia,codes),T,F)]
    demo_rx_ip[,adm_arf:=fifelse(grepl(icd_arf,codes),T,F)]
    return(demo_rx_ip)
}



#' Genrate the dataset and Cleaning for SCCS
#'
#' @param data the dataset including exposure and endpoint information
#' @param obst the defined study observation date. Choose the earliest avaiable date with *Riluzole* in the hospital or approved date by FDA. For instance, 2001-8-24 in Hong Kong.
#'
#' @return a dataset with cutted time periods for sccs study design
#' @export
#'
#' @examples no example
get_DT_SCCS <- function(data,obst,obed,...){
    temp <- copy(data)
    df_mnd <- temp[,`:=`(obst=pmax(pmin(onset_date %m-% years(1),
                                        earliest_rx %m-% years(1),na.rm=T),
                                   lubridate::ymd(obst),na.rm = T),
                         obed=pmin(dod,
                                   pmin(onset_date ,
                                        earliest_rx,na.rm=T) %m+% years(2),obed,na.rm=T))
    ][,`:=`(obst=as.numeric(obst-dob),
            obed=as.numeric(obed-dob),
            event=as.numeric(date_adm-dob),
            endevent=as.numeric(date_dsg-dob))]

    df_mnd <- df_mnd[,`:=`(strx=as.numeric(date_rx_st-dob),
                           edrx=as.numeric(date_rx_end-dob))]

    df_mnd <- df_mnd[strx>=obst & strx<= obed & event >=obst & event <= obed]
    message("==================\nNumber of ppl: excluding ppl not in the study period\n",
            df_mnd[,uniqueN(id)])
    # for more than one rx periods:
    last_rx_time <- unique(df_mnd[,.(id,strx,edrx)])[,last_rx_ed:=as.numeric(shift(edrx,n = 1,fill = NA,type = "lag")),.(id)]

    df_mnd <- merge(df_mnd,last_rx_time,by=c("id","strx","edrx"))

    df_mnd[,`:=`(strx_30b=pmax(strx-30,last_rx_ed+1,na.rm = T),
                 edrx_30b=strx-1)]
    df_mnd[,`:=`(strx_0a=as.numeric(NA),edrx_0a = as.numeric(NA),
                 strx_30a = as.numeric(NA), edrx_30a = as.numeric(NA),
                 strx_60a = as.numeric(NA), edrx_60a = as.numeric(NA),
                 strx_90a = as.numeric(NA), edrx_90a = as.numeric(NA),
                 strx_120a = as.numeric(NA), edrx_120a = as.numeric(NA),
                 strx_150a = as.numeric(NA), edrx_150a = as.numeric(NA),
                 strx_180a = as.numeric(NA), edrx_180a = as.numeric(NA))]

    df_mnd[as.numeric(edrx-strx)<30,
           `:=`(strx_0a=strx,edrx_0a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=30 & as.numeric(edrx-strx)<60 ,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=60 & as.numeric(edrx-strx)<90 ,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = strx+59,
                strx_60a = strx+60, edrx_60a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=90 & as.numeric(edrx-strx)<120 ,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+89,
                strx_90a = strx+90, edrx_90a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=120 & as.numeric(edrx-strx)<150,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+89,
                strx_90a = strx+90, edrx_90a = strx+119,
                strx_120a = strx+120, edrx_120a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=150 & as.numeric(edrx-strx)<180,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+89,
                strx_90a = strx+90, edrx_90a = strx+119,
                strx_120a = strx+120, edrx_120a = strx+149,
                strx_150a = strx+150, edrx_150a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=180 ,
           `:=`(strx_0a=strx,edrx_0a = strx+29,
                strx_30a = strx+30, edrx_30a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+89,
                strx_90a = strx+90, edrx_90a = strx+119,
                strx_120a = strx+120, edrx_120a = strx+149,
                strx_150a = strx+150, edrx_150a = strx+179,
                strx_180a = strx+180, edrx_180a = edrx)]
    return(df_mnd)
}



#' Data created for collapsed analysis
#'
#' @param data
#' @param obst
#' @param obed
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
get_DT_SCCS_collapsed <- function(data,obst,obed,...){
    temp <- copy(data)
    df_mnd <-temp[,`:=`(obst=pmax(pmin(onset_date %m-% years(1),
                                        earliest_rx %m-% years(1),na.rm=T),
                                   lubridate::ymd(obst),na.rm = T),
                         obed=pmin(dod,
                                   pmin(onset_date ,
                                        earliest_rx,na.rm=T) %m+% years(2),obed,na.rm=T))
    ][,`:=`(obst=as.numeric(obst-dob),
            obed=as.numeric(obed-dob),
            event=as.numeric(date_adm-dob),
            endevent=as.numeric(date_dsg-dob))]

    df_mnd <- df_mnd[,`:=`(strx=as.numeric(date_rx_st-dob),
                           edrx=as.numeric(date_rx_end-dob))]

    df_mnd <- df_mnd[strx>=obst & strx<= obed & event >=obst & event <= obed]

    # for more than one rx periods:
    last_rx_time <- unique(df_mnd[,.(id,strx,edrx)])[,last_rx_ed:=as.numeric(shift(edrx,n = 1,fill = NA,type = "lag")),.(id)]

    df_mnd <- merge(df_mnd,last_rx_time,by=c("id","strx","edrx"))

    df_mnd[,`:=`(strx_30b=pmax(strx-30,last_rx_ed+1,na.rm = T),
                 edrx_30b=strx-1)]
    df_mnd[,`:=`(strx_0a=as.numeric(NA),edrx_0a = as.numeric(NA),
                 strx_60a = as.numeric(NA), edrx_60a = as.numeric(NA),
                 strx_120a = as.numeric(NA), edrx_120a = as.numeric(NA),
                 strx_180a = as.numeric(NA), edrx_180a = as.numeric(NA))]

    df_mnd[as.numeric(edrx-strx)<30,
           `:=`(strx_0a=strx,edrx_0a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=60 & as.numeric(edrx-strx)<90 ,
           `:=`(strx_0a=strx,edrx_0a = strx+59,
                strx_60a = strx+60, edrx_60a = edrx)]

    df_mnd[as.numeric(edrx-strx)>=120 & as.numeric(edrx-strx)<150,
           `:=`(strx_0a=strx,edrx_0a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+119,
                strx_120a = strx+120, edrx_120a = edrx)]


    df_mnd[as.numeric(edrx-strx)>=180 ,
           `:=`(strx_0a=strx,edrx_0a = strx+59,
                strx_60a = strx+60, edrx_60a = strx+119,
                strx_120a = strx+120, edrx_120a = strx+179,
                strx_180a = strx+180, edrx_180a = edrx)]
    return(df_mnd)
}




get_subtype <- function(data,icd_subtypes_temp){
    apply(icd_subtypes_temp,1,function(x) data[,(paste0("subtype.",x[["abbr"]])):=fifelse(grepl(x[["grepl"]],codes),T,F)])
}



#' Create a dataset for survival and incidence calculation
#'
#' @param demo the dataset with demographic information, including id, dob, dod, sex, onset_date. Pls check the data shall.
#' @param dx the dataset with all diagnosis information, including id, codes, ref_date, setting. Pls check the data shall.
#' @param rx the dataset with all prescription records, including id, drug name, date of prescription start and end, type of presciption (IP, OP, AE, Discharge). Pls check the data shall.
#' @param codes_sys can be "icd9", "icd10", or "readcodes"
#' @param riluzole_name the name in your database stands for riluzole.
#'
#' @return two dataset:1) for incidence 2) for time varing cox
#' @export
#'
#' @examples cleaning_mnd(demo, dx, rx, codes_drug_sys)
cleaning_mnd <- function(demo,dx,rx,codes_sys,codes_drug_sys,riluzole_name='riluzole|rilutek',...){

    if(codes_sys=="icd9"){
        codes_defined <- "^335.2$|^335.2[01249]"
    }else if(codes_sys=="icd10"){
        codes_defined <- "^G12.2"
    }else if(codes_sys=="readcode"){
        stop("Don't worry. Fm is working on Readcode now.")
    }

    icd_subtypes <- as.data.table(readxl::read_excel(dir_mnd_codes,sheet = "subtype"))
    icd_subtypes_temp <- icd_subtypes[,.(Dx, abbr, grepl=get(codes_sys))]

    temp_dx <- copy(dx)
    setorder(temp_dx,"id","ref_date")
    temp_dx <- temp_dx[grepl(codes_defined,codes),.SD[ref_date==min(ref_date)],id
    ][,unique(.SD)][,.(id,onset_date=ref_date,codes=codes)]
    temp_dx_codes <- dcast(temp_dx,id+onset_date~.,value.var = "codes",fun.aggregate = function(x) paste(unique(x),collapse = ","))
    setnames(temp_dx_codes,".","codes")

    get_subtype(temp_dx,icd_subtypes_temp)
    temp_dx[,codes:=NULL]
    temp_dx <- dcast(temp_dx,
                     id+onset_date~.,
                     value.var = c("subtype.als","subtype.pma","subtype.pbp","subtype.pls","subtype.others"),
                     fun.aggregate = function(x) any(x))
    temp_dx <- merge(temp_dx_codes,temp_dx,by=c("id","onset_date"))[,unique(.SD)]


    df_surv <- merge(demo[,.(id,sex,dob,dod)],
                     temp_dx,
                     by="id",all.y=T)

    df_surv[,outcome:=fifelse(!is.na(dod) & dod <= ymd("20181231"),1,0)]
    df_surv[,obs.deadline:=fifelse(is.na(dod) | dod > ymd("20181231"),ymd("20181231"),dod)]
    df_surv[,age_adm:=as.numeric((onset_date-dob)/365.25)]
    df_surv[,age_group:=cut(age_adm, breaks = c(0,6,13,20,48,65,80,Inf),
                            include.lowest = T,right=FALSE)]
    df_surv[,age_group_std:=cut(age_adm, breaks = c(seq(0,85,5),+Inf),
                                include.lowest = T,right=FALSE,labels=c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34",
                                                                        "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69",
                                                                        "70-74", "75-79", "80-84", "85+"))]
    df_surv[,year_onset:=year(onset_date)]
    df_surv[,time_to_event:=as.numeric(obs.deadline-onset_date)]
    df_surv <- df_surv[time_to_event>=0 & onset_date>=ymd("1994-01-01")]

    # get past hx
    codes_icd <- setDT(read_xlsx(dir_mnd_codes,sheet = "hx"))
    codes_icd <- codes_icd[!is.na(grepl) & !is.na(Dx),.(Description,Dx,icdcodes=get(codes_sys))]
    message("================================\nobtain past hx for the cohort\n")
    apply(codes_icd,1,function(x) get_px_dx(df_surv,dx,x))

    # get drug use within past 90 days
    drug_codes <- setDT(read_xlsx(dir_mnd_codes,sheet="rx"))
    drug_codes <- drug_codes[!is.na(Name),
                             .(Description,Name,drugcodes=get(codes_drug_sys))]
    message("================================\nobtain Rx within past 90 days for the cohort\n")
    apply(drug_codes,1,function(x) get_px_rx(df_surv,rx,x))


    # add cci
    df_surv[, score.cci := (hx.mi+hx.chf+hx.pvd+hx.cbd+hx.copd+hx.dementia+hx.paralysis+(hx.dm_com0&!hx.dm_com1)+hx.dm_com1*2+hx.crf*2+(hx.liver_mild&!hx.liver_modsev)+hx.liver_modsev*3+hx.ulcers+hx.ra+hx.aids*6+hx.cancer*2+hx.cancer_mets*6)]
    df_surv[, score.cci := (score.cci+
                                ifelse(age_adm>=50&age_adm<60,1,0)+
                                ifelse(age_adm>=60&age_adm<70,2,0)+
                                ifelse(age_adm>=70&age_adm<80,3,0)+
                                ifelse(age_adm>=80,4,0))]

    message("\n================================\nobtain riluzole indicator")
    # add prescription indicator
    rx_riluzole<- shrink_interval(rx[grepl(riluzole_name,drug_name,ignore.case = T)],"date_rx_st","date_rx_end")
    ppl_hv_riluzole <- merge(rx_riluzole,
                             df_surv[,.(id,onset_date,obs.deadline)],"id")[
                                 date_rx_st>=onset_date & date_rx_st<obs.deadline]


    ppl_hv_riluzole[,`:=`(strx=as.numeric(date_rx_st-onset_date),
                          edrx=as.numeric(date_rx_end-onset_date),
                          astart=0,
                          aend=as.numeric(obs.deadline-onset_date),
                          id=as.numeric(id))]
    df_surv[,riluzole:=fifelse(id %in% ppl_hv_riluzole$id,T,F)]

    # time varing
    df_surv$start <- 0
    df_surv$stop <- df_surv$time_to_event


    df_surv_tv <- df_surv[stop==0,stop:=1]
    df_surv_tv <- tmerge(df_surv_tv,df_surv_tv,id=id,endpt=event(stop,outcome))

    rx_status <- setDT(formatdata(indiv = id,
                                  astart=astart,
                                  aend=aend,
                                  adrug=list(strx),
                                  aedrug=list(edrx),
                                  aevent=astart,
                                  data=as.data.frame(ppl_hv_riluzole),dataformat = "stack"))[,.(id=indiv,drug=strx,lower,upper)]
    df_surv_tv <- tmerge(df_surv_tv,rx_status,id=id,drug_sta=tdc(lower,drug))
    df_surv_tv$drug_sta[is.na(df_surv_tv$drug_sta)] <- 0

    # add frequency of admission after onset
    #N.adm <- merge(df_surv[,.(id,onset_date,dod)],MND:::shrink_interval(ip,"date_adm","date_dsg",gap=7))[date_dsg>=onset_date][,.(N.adm=.N),id]
    #df_surv <- merge(df_surv,N.adm,by="id",all.x = T)[is.na(N.adm),N.adm:=0]

    output <- list(dt_raw=df_surv,dt_tv=df_surv_tv)

    return(output)
}



#' Obtain the past hx
#'
#' @param data the data after initial cleanning
#' @param dx the dataset with all diagnosis information, including id, codes, ref_date, setting. Pls check the data shall.
#' @param codes can be "icd9", "icd10", or "both"
#'
#' @return
#' @export
#'
#' @examples get_px_dx(database,dx, codes)
get_px_dx <- function(data,dx,target_icd,...){
    temp <- merge(data[,.(id,onset_date)],
                  dx[grepl(target_icd["icdcodes"],codes,ignore.case = T),
                     .(id,dx_date=ref_date)],
                  all.y = T)[dx_date<onset_date,unique(id)]
    data[,c(paste0("hx.",target_icd["Dx"])):=fifelse(id %in% temp,T,F)]
    message(target_icd["Description"],"----",length(temp))
}

get_px_rx <- function(data,rx,target_drug_code,...){
    temp <- merge(data[,.(id,onset_date)],
                  rx[grepl(target_drug_code["drugcodes"],codes,ignore.case = T),
                     .(id,date_rx_st)],
                  all.y = T)[onset_date>date_rx_st %m-% days(90) & onset_date< date_rx_st ,unique(id)]
    data[,c(paste0(target_drug_code["Name"])):=fifelse(id %in% temp,T,F)]
    message(target_drug_code["Description"],"----",length(temp))
}



#' Generate table one for the cohort
#'
#' @param x dataset including data after cleaning
#'
#' @return
#' @export
#'
#' @examples get_tableone(x)
get_tableone <- function(x){
    df_surv_table1 <- copy(x)
    codes_icd <- as.data.table(read_excel(dir_mnd_codes,sheet ="hx"))[!is.na(Description)&!is.na(Dx)]
    drug_codes <- as.data.table(read_excel(dir_mnd_codes,sheet ="rx"))[!is.na(Description)&!is.na(Name)]
    setnames(df_surv_table1,
             codes_icd[,paste0("hx.",Dx)],
             codes_icd[,Description])
    setnames(df_surv_table1,
             drug_codes[,Name],
             drug_codes[,Description])
    subtype_icd <- as.data.table(read_excel(dir_mnd_codes,sheet ="subtype"))[!is.na(Dx)&!is.na(abbr)]
    setnames(df_surv_table1,
             subtype_icd[,paste0("subtype.",abbr),],
             subtype_icd[,Dx]
             )

    vars <- c("Amyotrophic lateral sclerosis", "Progressive muscular atrophy",
              "Progressive bulbar palsy", "Primary lateral sclerosis", "Others or unclassified",
              "sex", "age_adm", "age_group", "age_group_std", "score.cci", "riluzole",
              codes_icd[,Description],drug_codes[,Description])

    catvars <- setdiff(vars,c("age_adm", "score.cci"))

    table1 <- CreateTableOne(data = as.data.frame(df_surv_table1),vars = vars,factorVars = catvars,strata = "riluzole")
    return(table1)
}
