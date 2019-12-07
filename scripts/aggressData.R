library(tidyverse)

# load
d <- read.csv("exp2aggress.csv", 
              header = FALSE, stringsAsFactors = FALSE)

# remove first two rows
d <- as.data.frame(d[-c(1),])
colnames(d)[1] <- "V1"

# add tick column
d$tick <- ifelse(grepl("tick", d$V1), as.character(d$V1), NA)
d <- d %>% fill(tick, .direction = "down")
d$tick <- as.numeric(substring(d$tick, 6))

# add type column
d$type <- ifelse(grepl("Ftype", d$V1), as.character(d$V1), NA)
d <- d %>% fill(type, .direction = "down")

# add run column
d$run <- cumsum(d$V1=="tick=0")

# remove redundant rows
d <- d %>% filter(!grepl("Ftype", d$V1))
d <- d %>% filter(!grepl("tick=", d$V1))

# V1 as numeric
d$V1 <- as.numeric(as.character(d$V1))

# add strategy column
d$strategy <- ifelse(d$type == "Ftype=0 who 0-49",
                     ifelse(d$V1 %in% 0:49, "Concealers", "Revealers"),
                     ifelse(d$V1 %in% 0:49, "Revealers", "Concealers"))

# drop type col
d <- d %>% select(-type)

# rename column 1
colnames(d)[1] <- "target"

write.csv(d, file = "data/ovulationAggressTargets.csv", row.names = FALSE)