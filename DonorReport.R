library(tidyr)
library(ggplot2)
library(cowplot)


# loading R objects
# totals - groups total samples sizes
# sample_sizes - sizes of groups used for comparisons when comparing donor's sharing to average for different groups
# relatives.list, rel.list and pops.list contain average values for population groups. This is the same info
# but at different processing steps, the elatives.list is the one actually used here, the others are intermediates
# and won't be needed at the final step
load("DonorFeedbackBackground_v2.Rdata")

#loading data for individual, stdin when piping the query result directly or read.table for testing locally

#read.table(file("stdin")) -> individual
individual <- read.table("test.txt")

names(individual) <-  c('total','maakond','nation','maakond1','nation1', 'count', 'degree')

# the last line with count == -1 contains info about the individual
# currently we use it for testing and it is to be decided whether this info has to be
# reported to the individual. This might help the individual to realize if there was an error 
# while data handling (which is said to be around 2%)

as.character(individual[individual$count == -1,1]) -> maakond
as.character(individual[individual$count == -1,2]) -> id
as.character(individual[individual$count == -1,3]) -> rahvus
as.character(individual[individual$count == -1,4]) -> dob

#remove the final line with personal data and change datatype
individual <- individual[individual$count != -1,]
individual$total <- as.numeric(as.character(individual$total))
individual$count <- as.numeric(as.character(individual$count))

#summarizing counts - number of relatives - over different nations
#as well as over maakonds for Estonians and Russians
#at this stage the count column shows the number of relative of a certain degree (0 to 7)
#or distant relatives (-1) of the donor reported among each group

donor.list <- list()
donor.list[[1]] <- as.data.frame(aggregate(count~nation+degree,individual,sum))
donor.list[[2]] <- as.data.frame(aggregate(count~maakond+degree,individual[individual$nation=="Eestlane",],sum)) 
donor.list[[3]] <- as.data.frame(aggregate(count~maakond+degree,individual[individual$nation=="Venelane",],sum))

names(donor.list) <- c("Nations", "Est", "Rus")
donor.list <- lapply(donor.list, setNames, c('donor','degree','count'))
#removing donors with 0 meaning the nationality or the maakond is not known
donor.list <- lapply(donor.list, function(x) x[x$donor != 0,])
#tuning the donors names
donor.list$Est$donor <- paste0("Est_", donor.list$Est$donor)
donor.list$Rus$donor <- paste0("Rus_", donor.list$Rus$donor)

#here I normalize the counts per the sample size of the comparison group
#now the count column shows percentage of the individuals in each groups that
#are certain degree relatives of the donor in question
for (i in (1:length(donor.list))){
  donor.list[[i]]$total <- totals[match(donor.list[[i]]$donor, totals$nation),]$total
  donor.list[[i]]$count <- round(100*donor.list[[i]]$count/(donor.list[[i]]$total),2)
}

#here I split the donors into distant (degree == -1) and close (degree == 7 or 6) relatives 
distant.donor <- lapply(donor.list, function(x) spread(x[x$degree == -1,c(1,3)], donor, count))

close.donor <- list()

for (i in (1:length(donor.list))){
  close.donor[[i]] <- tryCatch({
    spread(aggregate(count~donor,donor.list[[i]][donor.list[[i]]$degree %in% c(6,7),],sum), donor, count)
  }, error = function(e) {
    print("no close relatives")
  })
}
  
tmp.list <- c(distant.donor, close.donor)

# if (length(tmp.list) == 6){
#   names(tmp.list) <- c("Nations.dist", "Est.dist", "Rus.dist", "Nations.close", "Est.close", "Rus.close")
# }

rm(distant.donor)
rm(close.donor)

# relatives.list is a list of 6 df c(nations, est, rus) x c(distant, close)
# each of them has the average sharing values for different groups for comparison
# for instance the 4.50 for Eestlane row Juut column in the first table means that
# an average Estonian is a distant relative of 4.5% of individuals among Biobank Jews (which is rather indicative of
# the Jews in the Biobank having some Estonian ancestry) 
# There is also a row named "you" for the reported individual
# here I add the personal values to the "you" row
for (i in (1:length(tmp.list))){
  relatives.list[[i]][1,] <- t(tmp.list[[i]])[match(colnames(relatives.list[[i]]), colnames(tmp.list[[i]])),]
  relatives.list[[i]][is.na(relatives.list[[i]])] <- 0
}

rm(tmp.list)

#this is calculating distance between "you" vector and other vectors to sort the rows according to how similar those are to you
eu.dist <- lapply(relatives.list, function(x) c(0,round(dist(x)[1:nrow(x)-1],3)))

#transforming to long format and sorting the rows and colums. Rows are sorted according to the euclidean distance, 
#coumns are sorted according to percentage
make_long <-function(x){
  data_long <- cbind.data.frame(rownames(relatives.list[[x]]),
                   gather(as.data.frame(relatives.list[[x]]), donor, percentage, 1:ncol(relatives.list[[x]]), factor_key=TRUE), 
                   eu.dist[[x]])
  colnames(data_long)[1] <- "recipient"
  colnames(data_long)[4] <- "dist"
  you <- data_long[data_long$recipient == 'you',]
  data_long$recipient <- factor(data_long$recipient, data_long$recipient[order(eu.dist[[x]], decreasing = T)])
  data_long$donor <- factor(data_long$donor, you$donor[order(you$percentage, decreasing = T)])
  data_long$percentage <- as.numeric(data_long$percentage)
  return(data_long)
} 

data_long.list <- lapply(1:length(relatives.list), make_long)
names(data_long.list) <- names(relatives.list)

#removing the rows for Estonians groups by maakonds
data_long.list$Nations.dist <- data_long.list$Nations.dist[grep("Est_", data_long.list$Nations.dist$recipient, invert = T),]

#keeping only rows for Estonians groups by maakonds
data_long.list$Est.dist <- data_long.list$Est.dist[which(data_long.list$Est.dist$recipient %in% data_long.list$Est.dist$donor |
                                                     data_long.list$Est.dist$recipient == 'you'),]

#keeping only rows for Estonians groups by maakonds
data_long.list$Est.close <- data_long.list$Est.close[which(data_long.list$Est.close$recipient %in% data_long.list$Est.close$donor |
                                                           data_long.list$Est.close$recipient == 'you'),]

#the tables in the data_long.list list are being plotted


#capping the values for plotting three plots with same settings, can be changed
#data_long.list$Nations.dist[data_long.list$Nations.dist$percentage > 20,]$percentage <- 20
#data_long.list$Est.dist[data_long.list$Est.dist$percentage > 30,]$percentage <- 30

cap <- 10*max(data_long.list$Est.close[data_long.list$Est.close$recipient == 'you',]$percentage)
data_long.list$Est.close[data_long.list$Est.close$percentage > cap,]$percentage <- cap

p.list <- lapply(c(1,2,5), function(el){
 
  
  x <- data_long.list[[el]]
  x$dist[x$dist == 0] <- NA 
  top <- x[which(x$dist == min(x$dist, na.rm = T)),]$recipient[1]
  top <- as.character(top)
  x <- x[x$recipient == 'you' | x$recipient == top | as.vector(x$recipient) == as.vector(x$donor),]
  x$recipient <- as.vector(x$recipient)
  
  x[as.vector(x$recipient) == as.vector(x$donor),]$recipient <- "Avg within group"
  x$recipient <- factor(x$recipient, levels = c("you", "Avg within group", top))
  y <- x[x$recipient == "Avg within group" & x$donor == top,]
  y$recipient <- top
  x <- rbind.data.frame(x, y)
  
  capa <- as.character()
  if (names(data_long.list)[el] == "Est.close"){
    capa <- paste("\ncapped at", cap)
  }

  #N_recipients <- length(levels(data_long.list[[el]]$recipient))
  
  p <- ggplot()+ 
    #geom_rect(data = data.frame(xmin = -Inf,
    #                            xmax = Inf,
    #                            ymin = N_recipients - 0.5,
    #                            ymax = N_recipients + 0.5),
    #          aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    #          color = "black", fill = 'white', size = 1)+
    #scale_x_discrete()+
    #scale_y_discrete()+
    #geom_point(data = data_long.list[[el]], aes(x=donor, y=recipient, color=percentage, size = percentage), shape=15)+
    #scale_size(range=c(2,8))+
    #scale_color_viridis_c(values= c(0,0.05,0.15,1))+
    geom_col(data = x, aes(x=donor, y=percentage, fill = recipient), position=position_dodge())+
    scale_fill_npg()+
    theme_cowplot()+
    xlab("reference group from EBB")+
    ylab(paste0("% of relatives in the group", capa))+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1), legend.title = element_blank())+
    ggtitle(paste0(rahvus,', ',maakond,', ',dob, '\n', type))
  return(p)
})

pdf(paste0("BarPlot_", id, "_",rahvus,'_',maakond,'_',dob, '.pdf'), width = 9, height = 6)
for (i in (1:length(p.list))){
  print(p.list[[i]])
}
dev.off()
