
#' Periods cleaning
#'
#' @description merge the overlapping or closed records, eg.prescription records, hospitalization
#' @param data the prescription dataset
#' @param gap the gap between two prescription records which you would like to merge. For instance, the two Rx records whith interval less than 7 days may be consider as the same prescription.
#' @param st the column name for starting date
#' @param ed the column name for ending date
#' @return
#' @export
#'
#' @examples
#' data <- data.table(id=rep(1,2),
#'         date_st=lubridate::ymd(c("2021-1-1","2021-1-4")),
#'         date_end=lubridate::ymd(c("2021-1-5","2021-1-6")))
#' shrink_interval(data,"date_st","date_end",gap=2)
shrink_interval <- function(data,st,ed,gap=1){
    data <- copy(data[,na.omit(.SD)][,.(id=id,st=get(st),ed=get(ed))])
    setorder(data,id,st)
    output <- data[,indx:=c(0, cumsum(as.numeric(shift(st,type="lead"))>
                                          cummax(as.numeric(ed)+gap))[-.N]),id
    ][,.(st=first(st),ed=last(ed)),.(id,indx)]
    setnames(output,c("st","ed"),c(st,ed))
    return(output)
}
