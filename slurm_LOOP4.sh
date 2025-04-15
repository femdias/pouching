#!/bin/bash
#SBATCH --cluster=cbsueccosl01         	    # Specify the cluster name
#SBATCH --job-name=L4_poaching            	    # A descriptive name for your job
#SBATCH --output=logs/poaching_%j.out       # Standard output file (%j expands to the job ID)
#SBATCH --error=logs/poaching_%j.err        # Standard error file
#SBATCH --cpus-per-task=8                   # Request 8 cores, as stata-mp uses 8 cores
#SBATCH --mem=50G                           # Request a lot of memory

# Change to the directory containing your Stata .do file
cd /home/ecco_rais/data/interwrk/daniela_group/poaching

# Run the Stata code in batch mode. 
# The "-b do" option tells Stata to run the specified .do file in batch.
/usr/local/stata18/stata-mp -b do master_LOOP4.do /logs/slurm_LOOP4.log

