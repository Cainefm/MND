
#' Plot the figure of incidence
#'
#' @param data the dataset generated from run_incidence
#' @param region the site name which will be shown in the plot
#'
#' @return
#' @export
#'
#' @examples p_inci(data$std_inci)
p_inci <- function(data,region="Hong Kong"){
    ggplot(data$std_inci,aes(x=year_onset,y=est,group=1))+
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


#' Plot the figure of incidence by age
#'
#' @param data the dataset generated from run_incidence
#'
#' @return
#' @export
#'
#' @examples p_inci_sex(data)
p_inci_sex <- function(data,region="Hong Kong"){
    iw <- incidence(data$dt_raw, interval = "6 months", date_index = onset_date, groups = sex)
    plot(iw, fill = "sex", color = "white",border="grey",title = region,ylab="Number of cases")+
        theme(axis.text.x = element_text(vjust = 0, hjust=0.5,size=18),
              axis.text.y = element_text(size=18),
              plot.title = element_text(size=22),
              axis.title = element_text(size=18)
        )
}



#' Plot the figure of incidence by subgroup
#'
#' @param data the dateset generated from run_incidence
#' @param region the site name which will be shown in the plot
#'
#' @return
#' @export
#'
#' @examples p_inci_type(data)
p_inci_type<-function(data,region="Hong Kong"){
    dt_subtypes <- melt(data$dt_raw[,.(id,onset_date,
                                       subtype.als,subtype.pma,subtype.pbp,subtype.pls,subtype.others)],
                        id.vars = c("id","onset_date"))[value==TRUE]
    icd_subtypes <- as.data.table(readxl::read_excel("data/codes_mnd.xlsx",sheet = "subtype"))
    icd_subtypes$abbr <- paste0("subtype.",icd_subtypes$abbr)
    dt_subtypes <- merge(dt_subtypes,icd_subtypes[,.(Dx,variable=abbr)],by="variable")
    iw_gp <- incidence(dt_subtypes,interval="6 months", date_index = onset_date, groups=Dx)
    facet_plot(iw_gp, n_breaks = 3, color = "white",date_format = "%Y-%m",
               title=region,nrow = 2,ylab="Number of cases")+
        theme(axis.text.x = element_text(vjust = 0, hjust=0.5,size=18),
              axis.text.y = element_text(size=18),
              plot.title = element_text(size=22),
              axis.title = element_text(size=18),
              strip.text.x = element_text(size = 15))
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


#' Print only outcome for MND study
#'
#' @param x the sccs result
#'
#' @return
#' @export
print.mndsccs <- function(x){
    print(x$res)
}

#' print only std inci, not raw data
#'
#' @param x the incidence result
#'
#' @return
#' @export
print.mndinci <- function(x){
    print(x$std_inc)
}

#' Keep digits for numbers
#'
#' @param x numbers
#'
#' @return
show_digit<- function(x){
    return(sprintf(as.numeric(x),fmt="%#.2f"))
}

#' Inci Ci calculation
#'
#' @param x
#'
#' @return
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


#' Cox Ci calculation
#'
#' @param x
#'
#' @return
#' @export
get_tv_cox <- function(x){
    est <- exp(x$coefficients)
    est_95 <- exp(confint.default(x))
    est_com <- data.table(var=names(est),
                          est=show_digit(est),
                          est_l=show_digit(est_95[,1]),
                          est_h=show_digit(est_95[,2]))
    return(est_com)
}
