# AMRemote - Looped Merged Landcover Version
This adapted version of the standard tool for running AccessMod analyses introduces a special functionality within the replay function. It uniquely allows for looping through multiple merged landcovers, a convenient feature for analyses with multiple changing barriers (e.g., floods). To utilize this functionality, users must specify all merged landcover labels in the `replay.r` function. If needed, zonal statistics can be calculated as usual. Note: All merged landcover layers must be included in the exported project from AccessMod.

```{r}
# Example in replay.r file

mergedLCLabels <- c("MLC1", "MLC2", "etc") # Provide the list of merged land cover labels to be used in the loop
```

It can be run on a your local machine, a regular server or a cluster. A Unix-like OS on your machine is required, either to run the replay or to interact with a server/cluster. Docker (server, local machine) or Singularity (cluster) is also required.

Replay is available for any kind of analysis. With accessibility analysis we can choose whether we want to run a zonal statistic analysis right after or not. For coverage analysis we can decide to split the analysis by region (recommended for very large countries and when a cluster is available so different jobs can be sent in parallel). Launching a replay considering multiple maximum travel times is also possible.

## Inputs

You will always need the following files (identical names) within the same input folder:

```txt 
|-- project.amp5       -> AccessMod project
|-- config.json        -> config file generated in AccessMod corresponding to the desired analysis
```

Let's say that you have these files locally in C:/myname/replay and that you want to run the analysis remotely. You first have to copy them into your remote directory. From your local machine, for instance:

```txt 
$ scp -r C:/myname/replay <username>@<serveraddress>:~/
```

## AccessMod image

On the cluster (cluster uses Singularity instead of Docker):

```txt 
$ singularity pull ~/image/accessmod.sif docker://fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted, and the path (~/image/accessmod.sif) is chosen by the user. It is important that both the AccessMod version used to generate config.json file and the image version used for the replay match, and it is highly recommended to use the latest version.
More details here: https://docs.sylabs.io/guides/3.2/user-guide/cli/singularity_pull.html


On a regular server or on your local machine:

```txt 
$ docker pull fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted

## Make AMRemote available

Clone or pull (if already cloned, in order to update it) the AMRemote github repository onto the machine where you'd like to run the analysis.

```txt 
$ git clone https://github.com/ptimoner/AMRemote/
```

```txt 
$ git pull
```

## Procedure

Within the AMRemote folder, you will find (among others):

```txt 
|-- run.sh             -> to launch the replay analysis
|-- inputs.json        -> file with editable replay anaylsis parameters (all users)
|-- hpc.json           -> file with editable sbatch parameters like partition name, time limit,
                          memory, etc. (advanced users)
```
These are the only files you will interact with to run the replay function.

Open the inputs.json and modify the replay analysis parameters (**do not change the format**).

```txt 
$ nano inputs.json
```
You will find the following parameters:

```txt 
|-- inputFolder                -> path to the folder that contains the project.am5p and config.json files

|-- AccessModImage             -> when using Docker (in a server or locally) 
                                  the name of the image (e.g. fredmoser/accessmod:5.8.0) or the path to the image 
                                  (e.g. ~/images/accessmod.sif) when using Singularity (cluster)

|-- maxTravelTime              -> an array of maximum travel times (e.g. [60,120]); when zonalStat 
                                  is true, the prior accessibility analysis will be run with no maximum travel 
                                  time (will be set to 0)

|-- splitRegion                -> logical parameter (true/false) to indicate if the analysis must 
                                  be splitted by region (only for coverage analysis)

|-- splitRegionAdminColName    -> when splitRegion is true, the name of the column in the facility 
                                  shapefile corresponding the name of the regions

|-- zonalStat                  -> logical parameter (true/false) to indicate if a Zonal Statistics analysis 
                                  must be run (only for accessibility analysis)

|-- zonalStatPop               -> when zonalStat is true, the label of the population layer in the 
                                  AccessMod project

|-- zonalStatZones             -> when zonalStat is true, the label of the zone layer in the AccessMod project

|-- zonalStatIDField           -> when zonalStat is true, the ID field (integer) in the zone layer

|-- zonalStatLabelField        -> when zonalStat is true, the label field in the zone layer

|-- nohup                      -> logical parameter (true/false) only considered when running 
                                  the analysis on a regular server; if true it indicates that the analysis does 
                                  not stop when the user logs out; still possible to check the progress of the 
                                  analysis or to kill the process (instructions on how to do it are given when running 
                                  the analysis).

```
Just replace the values accordingly. Logical parameters are *splitRegion*, *zonalStat* and *nohup*; they all require true/false values. If empty they are considered as 'false'. For string parameters, use double quotes. Numbers in numerical array (*maxTravelTime*) must be separated by commas and contained within square brackets. Empty values must always be provided with double quotes ("") except for the *maxTravelTime*, where empty square brackets is required ([]).

Recall that white spaces in layer labels in AccessMod are actually replaced by "_" (for *zonalStatPop* and *zonalStatZones* parameters)

Once you set the parameters, use the following command the run the replay analysis.

```txt 
$ bash run.sh
```
or if you are not within the AMRemote folder:
 
```txt 
$ bash <pathToAMRemote>/run.sh
```

An output folder will be created within the input folder.

The script will detect if it is running on a cluster or not, and will use Docker or Singularity accordingly. On a cluster you can check the Job ID and the status of the submitted job using the following command:

```txt 
$ squeue -u $USER
```

If the job has started you can check the progress of the analysis by reading the ".out" file corresponding to the job which is dynamically saved in the subfolder 'slum_reports' created within the output folder.

```txt 
$ cat <slum_report_folder>/<outfile>
```

You can cancel the job whenever is required using the command:

```txt 
$ scancel <jobid>
```
On a regular server, when the parameter 'nohup' is set true, the user can still check the progress of the analysis or kill the process (instructions on how to do it are given when the user executes the run.sh script).

## Outputs

If the analysis has been run remotely, download your results with the scp command. For instance:

```txt 
$ scp -r <username>@<serveraddress>:~/<inputFolder>/out C:/myname/replay 
```


