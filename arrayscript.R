### Timing
start <- Sys.time()

# ### Directories (Testing)
# home_dir <- '/home/stephen'
# #home_dir <- '/Users/stephensmith'
# result_dir <- paste0(home_dir,'/Desktop/','Results-',format(Sys.Date(),"%m-%y"))
# rds_dir <- paste0(home_dir,'/Dropbox/Academics/Research/Code/Networks/rds')
# data_gen_file <- paste0(home_dir,'/Dropbox/Academics/Research/Code/Scripts/data_gen.R')

### Directories (Hoffman)
home_dir <- '/u/home/s/stephens'
scratch_dir <- '/u/scratch/s/stephens'
result_dir <- paste0(scratch_dir,'/Results-',format(Sys.Date(),"%m-%y"))
rds_dir <- paste0(home_dir,'/Networks/rds')
data_gen_file <- paste0(home_dir,'/data_gen.R')

# ### Setup (Testing)
# source(paste0(home_dir,'/Dropbox/Academics/Research/Code/Scripts/HoffmanArray/helperfunctions.R'))
# array_num <- sample(1:3200,1)
# 
# cat("Simulation",array_num,file = "~/Desktop/lastSim.txt")

### Setup (Hoffman)
source(paste0(home_dir,'/hoffman/helperfunctions.R'))
array_num <- as.numeric(Sys.getenv("SGE_TASK_ID"))

source(data_gen_file)

num_trials <- 5
max_targets <- 4

data.grid <- data.frame(network = "asia",
                        data.type = "continuous",
                        n.dat = num_trials,
                        n.obs = 1000,
                        c.ratio = 0,
                        max.in.degree = Inf,
                        lb = 1e-04,  # lower bound of coefficients
                        ub = 5,  # upper bound of coefficients
                        low = 1e-04,  # lower bound of variances if continuous, of number of levels if discrete
                        high = 5,  # upper bound of variances if continuous, of number of levels if discrete
                        scale = FALSE,
                        stringsAsFactors = FALSE)


go_to_dir(result_dir)
sim_vals <- read.csv("sim_vals.csv",stringsAsFactors = FALSE)[,-1]

alpha <- sim_vals$alpha[array_num]
net <- sim_vals$net[array_num]
high <- sim_vals$high[array_num]
ub <- sim_vals$ub[array_num]
n <- sim_vals$n[array_num]

cat("This is row",array_num,"of our simulation grid.\n")
cat("Simulation Parameters:\n")
cat("Significance:",alpha,"\n")
cat("Network:",net,"\n")
cat("high:",high,"\n")
cat("ub:",ub,"\n")
cat("n:",n,"\n")

go_to_dir(paste0("alpha=",alpha))
go_to_dir(net)

# Obtain network information, including the true DAG adj. mat.
network_info <- get_network_DAG(net)

# Generate/Retrieve Targets
targets <- check_targets_defined_get_targets(network_info)

# Set up for simulated data and directory for context
data.grid$network <- net
data.grid$n.obs <- n
n <- n
ub <- ub
high <- high
data.grid$ub <- ub
data.grid$high <- high

go_to_dir(paste0("N=",data.grid$n.obs))
go_to_dir(paste0("UB=",data.grid$ub))
go_to_dir(paste0("High=",data.grid$high))

# Generate the data
simulation_data_creation()

# Grab simulated data
df_list <- lapply(1:num_trials,function(i) grab_data(i))

# Keep network directory
curr_dir <- getwd()

# Get results for each trial
results_list <- lapply(1:num_trials,function(num){
  setwd(curr_dir)
  
  # Run Global PC Algorithm
  results_pc <- run_global_pc(df_list[[num]])

  # Run Local FCI Algorithm
  results_df <- mclapply(targets,
                         run_fci_target,
                         df=df_list[[num]],
                         num,
                         results_pc,
                         curr_dir,
                         mc.preschedule = FALSE,mc.cores = 1)
  results_final_df <- data.frame(do.call(rbind,results_df))
  setwd(curr_dir)
  saveRDS(results_final_df,paste0("results_df",num,".rds"))
  return(results_final_df)
})

results_total <- data.frame(do.call(rbind,results_list))
saveRDS(results_total,"results_total.rds")


end <- Sys.time()
d <- as.numeric(difftime(end,start,units="sec"))
if (d < 300){
    cat("Program finished early. Going to sleep now.\n")
    Sys.sleep(320-d)
}

