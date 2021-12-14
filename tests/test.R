library(MND)
library(data.table)
data <- data.table(id=rep(1,2),
                   date_st=lubridate::ymd(c("2021-1-1","2021-1-4")),
                   date_end=lubridate::ymd(c("2021-1-5","2021-1-6")))
shrink_interval(data,"date_st","date_end",gap=2)
MND::getDT4sccs()


library(roxygen2)
roxygenize()


# 轻量版检查
devtools::check()

test <- get_DT_Exposure_Endpoint(demo,ip,rx)
test1 <- get_DT_SCCS(test)
ageq <- floor(seq(20,90,10)*365)
test1$id <- as.numeric(test1$id)
test1$dob_dmy <- as.numeric(format(test1$dob,"%d%m%Y"))
test2 <- sccs(event ~ strx_30b + strx_0a + strx_30a + strx_60a + strx_90a+ strx_120a +
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
              data = as.data.frame(test1))
