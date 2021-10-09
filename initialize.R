#home_dir <- '/home/stephen'
home_dir <- '/Users/stephensmith'
data_gen_file <- paste0(home_dir,'/Dropbox/Academics/Research/Code/Scripts/data_gen.R')
result_dir <- paste0(home_dir,'/Desktop')
rds_dir <- paste0(home_dir,'/Dropbox/Academics/Research/Code/Networks/rds')

source(paste0(home_dir,'/Dropbox/Academics/Research/Code/Scripts/HoffmanArray/helperfunctions.R'))
set.seed(555)

## TODO: DOWNLOAD THE MOST RECENT VERSION OF LOCALFCI HERE

alpha <- c(0.01,0.001,0.0001)
net_names <- gsub(".rds","",list.files(rds_dir))
nets_to_skip <- c("diabetes","link","munin","munin1")
net <- setdiff(net_names,nets_to_skip)
high <- c(1,2,5) # For variances
ub <- c(1,2,5,10) # For coefficients
n <- c(100,500,1000)

simulation_values <- expand.grid(alpha=alpha,net=net,high=high,ub=ub,n=n)

setwd(result_dir)
go_to_dir(paste0("Results-",format(Sys.Date(),"%m-%y")))
write.csv(simulation_values,file = "sim_vals.csv")
