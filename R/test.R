#
# # restore the development enviorment --------------------------------------
# renv::restore()
#
# demo <- demo[id %in% sample(id,500),]
#
# a <- readRDS("../MND Project/5.cleaned data/df_rx.rds")
# rx <- a[,.(id = reference_key,drug_name=drug_name,
#           codes = therapeutic_classification_bnf_principal,
#           date_rx_st = prescription_start_date,
#           date_rx_end = prescription_end_date,setting=type_of_patient_drug)][id %in% demo$id,]
#
#
# a <- readRDS("../MND Project/5.cleaned data/df_ip.rds")
# ip <- a[,.(id=reference_key,
#      date_adm=admission_date_yyyy_mm_dd,
#      date_dsg=discharge_date_yyyy_mm_dd ,
#      ae=emergency_admission_y_n=="Y"
#      )][id %in% demo$id,]
# ip
#
# a <- readRDS("../MND Project/5.cleaned data/df_dx.RDS")
# dx <- a[,.(id=reference_key,codes = all_diagnosis_code_icd9 ,
#      ref_date=reference_date ,setting=gsub("\n","",patient_type_ip_op_a_e))][id %in% demo$id,]
# dx
#
# rx <- rx[id %in% demo$id]
# ip <- ip[id %in% demo$id]
# dx <- dx[id %in% demo$id]
#
# save(demo,dx,ip,rx,file = "./data/sample_data.rda")
