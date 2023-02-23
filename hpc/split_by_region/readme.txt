# Split based on region name from the facility shapefile column
main_hpc runs 
first script_hpc_get_regions sbatch script which runs get_regions R script to get the regions
second script_hpc sbatch (job array) which runs script_hpc.R with region parameter