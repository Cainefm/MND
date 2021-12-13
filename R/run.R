


#' Generate SCCS database
#'
#' @return
#' @export
#'
#' @examples
CreateSCCSData<- function(demo,ip, rx){
    rx_riluzole<- shrink_interval(rx[grepl('riluzole|riluteck',drug_name,ignore.case = T) &
                                         !setting %in% c("I")],"date_rx_st","date_rx_end")
    ip_riluzole<- shrink_interval(ip[id %in% demo$id & id %in% rx_riluzole$id],"date_adm","date_dsg",gap = 7)
    rx_ip <- merge(rx_riluzole[,indx:=NULL],
                   ip_riluzole[,indx:=NULL],by="id",allow.cartesian = T)
    demo_rx_ip<-merge(demo,rx_ip,by="id")
    return(demo_rx_ip)
}


#' Title
#'
#' @param df_dx_rx_ip
#' @param obst
#'
#' @return
#' @export
#'
#' @examples
cleanSCCSData <- function(df_dx_rx_ip,obst="2001-08-24"){
    df_mnd <- df_dx_rx_ip[,`:=`(obst=pmax(earliest_dx_date,ymd(obst),na.rm = T),
                                obed=pmin(dod,onset_ %m+% years(2),na.rm=T))
    ][,`:=`(obst=as.numeric(obst-dob),
            obed=as.numeric(obed-dob),
            event=as.numeric(startad-dob),
            endevent=as.numeric(endad-dob))]

    df_mnd <- df_mnd[,`:=`(strx=as.numeric(strx_ymd-dob),
                           edrx=as.numeric(edrx_ymd-dob))]

    setnames(df_mnd,"reference_key","refkey")
    # for more than one rx periods:
    last_rx_time <- unique(df_mnd[,.(refkey,strx,edrx)])[,last_rx_ed:=lag(edrx),.(refkey)][]
    df_mnd <- merge(df_mnd,last_rx_time,by=c("refkey","strx","edrx"))

    df_mnd[,`:=`(strx_30b=pmax(strx-30,last_rx_ed+1,na.rm = T),edrx_30b=strx-1)]
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

}

