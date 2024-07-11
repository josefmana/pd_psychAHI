# Imports and pre-process data to analysis-ready format

rm( list = ls() ) # clear environment

# load packages
library(here)
library(openxlsx)
library(tidyverse)

if( !dir.exists("_data") ) dir.create("_data")

# all tests in the battery
psych <- read.csv("psychs.csv", sep = ";")


# MDS-UPDRS ----

d0 <-
  read.xlsx( here("_raw","BIOPD_MDSUPDRSIII.xlsx"), startRow = 2, check.names = T ) %>%
  select( Study.ID, SUBJ, AHI.F, starts_with("MDS.UPDRS.3") ) %>%
  pivot_longer(
    cols = starts_with("MDS"),
    names_to = "item",
    values_to = "response"
  ) %>%
  mutate(
    response_num = as.numeric( gsub("\\D", "", response) ),
    item = sub("MDS.UPDRS.", "", item, fixed = T)
  )


# the primary data ----

d1 <- left_join(
  
  # read hippocampus data first
  read.xlsx( here("_raw","Tabhipposubfields_rhx.xlsx") ) %>% rename_with( ~ gsub("-", "_", .x) ),
  read.xlsx( here("_raw","Tabhipposubfields_lhx.xlsx") ) %>% rename_with( ~ gsub("-", "_", .x) ),
  by = "Study.ID",
  suffix = c("_rhx","_lhx") # add suffixes to differentiate betwen right and left sides
  
) %>%
  
  # add all other subscortical structures and cognitive data
  left_join(
    
    # start with the subcortical data as they include demography and such
    read.xlsx( here("_raw","Tabsubcortex1.xlsx") ) %>% rename_with( ~ gsub("-", "_", .x) ),
    . ,
    by = "Study.ID"
    
  ) %>%
  left_join(
    
    read.csv( here("_raw","20221120_redcap_export.csv"), sep = "," ) %>%
      mutate( Study.ID = sub("-","",study_id) ) %>%
      select( Study.ID, all_of(psych$variable) ),
    by = "Study.ID"
    
  ) %>%
  
  # correct formatting errors
  mutate( across( ends_with("_rhx"), as.numeric ) ) %>%
  
  # add MDS-UPDRS III
  left_join(
    
    d0 %>%
      select(-response, -SUBJ, -AHI.F) %>%
      pivot_wider( names_from = item, values_from = response_num, names_prefix = "MDS.UPDRS.") %>%
      mutate( mds_updrs_iii = rowSums( across( starts_with("MDS.UPDRS.3") ) ) ),
    
    by = "Study.ID"

  )


# save them ----

write.table(d0, file = here("_data","mds_updrs_iii.csv"), sep = ",", row.names = F, quote = F)
write.table(d1, file = here("_data","primary_dataset.csv"), sep = ",", row.names = F, quote = F)