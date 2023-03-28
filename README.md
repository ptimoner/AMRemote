# AMRemote
Standard tool to run AccessMod analyses through the replay function. It can be run on any server with docker installed, on
any HPC (cluster) with Singularity available, or on your local machine. A Unix-like OS on your machine is required, either to run the replay or to
interact with a server/cluster. Available options are: accesssibility analysis, accessibility analysis + zonal statistics, coverage analysis (either splitting by region or not). Considering multiple maximum travel times is possible.

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

On the HPC (HPC uses singularity instead of Docker):

```txt 
$ ml GCC/9.3.0 Singularity/3.7.3-Go-1.14
$ singularity pull ~/image/accessmod.sif docker://fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted, and the path (~/image/accessmod.sif) is chosen by the user. 
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
$ git pull AMRemote
```

## Procedure

Within the AMRemote folder, you will find:

```txt 
|-- run.sh             -> to launch the replay analysis
|-- inputs.json        -> file with editable parameters
```
Open the inputs.json and modify the parameters *without changing the format*.

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
is true, the prior accessibility analysis will be run with no maximum travel time (will be set to 0)

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
the analysis on a regular server; if true it indicates that the analysis does not stop when the user 
logs out; still possible to check the progress of the analysis or to kill the process (instructions on 
how to do it are given when running the analysis).
```
Logical parameters are "splitRegion", "zonalStat" and "nohup"; they all require true/false values. If empty they are considered as 'false'. For string parameters, use double quotes. Numbers in numerical array (maxTravelTime) must be separated by commas and contained within square brackets.

Once you set the parameters, use the following command the run the replay analysis.

```txt 
$ bash run.sh
```
An output folder will be created within the input folder.

The script will detect if it is running on a cluster or not, and will use Docker or Singularity accordingly. On a cluster, progress can be checked in the '.out' file saved in folder called slum_reports in the output folder. On the cluster, use the command scancel to cancel the submitted job if required. On a regular server, when the parameter 'nohup' is set true, the user can still check the progress of the analysis or kill the process (instructions on how to do it are given when running the analysis).

## Outputs

If the analysis has been run remotely, download your results with the scp command. For instance:

```txt 
$ scp -r <username>@<serveraddress>:~/<inputFolder>/out C:/myname/replay 
```


