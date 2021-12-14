
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
    data <- copy(data[,na.omit(.SD)][,list(id,st=get(st),ed=get(ed))])
#    print("stupid fm")
    setorder(data,id,st)
    output <- data[,indx:=c(0, cumsum(as.numeric(shift(st,type="lead"))>
                                          cummax(as.numeric(ed)+gap))[-.N]),id
    ][,.(st=first(st),ed=last(ed)),.(id,indx)]
    setnames(output,c("st","ed"),c(st,ed))
    return(output)
}



#' Combine the datasets with exposure and outcomes
#'
#' @description Combine the exposure (Riluzole history) and outcome (Hospitalization records) for SCCS study design.
#' @param demo the dataset with demographic information, including id, dob, dod, sex, onset_date. Pls check the data shall.
#' @param ip the dataset with all in-hospitalization records, including id, date of adminssion, date of discharge, type of records (setting, IP, OP, AE). Pls check the data shall.
#' @param rx the dataset with all prescription records, including id, drug name, date of prescription start and end, type of presciption (IP, OP, AE, Discharge). Pls check the data shall.
#' @return a combined data set in data table format. One patients may have multiple rows of records.
#' @import data.table
#' @export
#'
#' @examples get_DT_Exposure_Endpoint(demo,ip,rx)
#'             id sex        dob        dod onset_date date_rx_st date_rx_end   date_adm   date_dsg
#'    1: 10038681   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2015-07-21 2015-07-23
#'    2: 10038681   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2016-10-17 2016-10-22
#'    3: 10038681   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-01-24 2017-01-27
#'    4: 10038681   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-03-03 2017-03-31
#'    5: 10038681   M 1966-09-10 2017-06-06 2015-07-23 2013-05-31  2014-06-02 2017-04-10 2017-04-10
#' ---
#' 2663:  9903734   F 1955-07-02 2018-11-28 2017-11-28 2018-05-28  2018-07-22 2018-07-30 2018-08-10
#' 2664:  9903734   F 1955-07-02 2018-11-28 2017-11-28 2018-05-28  2018-07-22 2018-10-31 2018-11-02
#' 2665:  9903734   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2017-11-27 2017-11-28
#' 2666:  9903734   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2018-07-30 2018-08-10
#' 2667:  9903734   F 1955-07-02 2018-11-28 2017-11-28 2018-07-25  2018-11-20 2018-10-31 2018-11-02
get_DT_Exposure_Endpoint <- function(demo, ip, rx){
    rx_riluzole<- shrink_interval(rx[grepl('riluzole|riluteck',drug_name,ignore.case = T) &
                                         !setting %in% c("I")],"date_rx_st","date_rx_end")
    ip_riluzole<- shrink_interval(ip[id %in% demo$id & id %in% rx_riluzole$id],"date_adm","date_dsg",gap = 7)
    rx_ip <- merge(rx_riluzole[,indx:=NULL],
                   ip_riluzole[,indx:=NULL],by="id",allow.cartesian = T)
    demo_rx_ip<-merge(demo,rx_ip,by="id")
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
get_DT_SCCS <- function(data,obst="2001-08-24"){
    df_mnd <- data[,`:=`(obst=pmax(onset_date,ymd(obst),na.rm = T),
                                obed=pmin(dod,onset_date %m+% years(2),na.rm=T))
    ][,`:=`(obst=as.numeric(obst-dob),
            obed=as.numeric(obed-dob),
            event=as.numeric(date_adm-dob),
            endevent=as.numeric(date_dsg-dob))]

    df_mnd <- df_mnd[,`:=`(strx=as.numeric(date_rx_st-dob),
                           edrx=as.numeric(date_rx_end-dob))]

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

