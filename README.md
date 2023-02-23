# AMRemote
Standard scripts to run AccessMod analyses remotely (HPC or server) through the replay function. 

Are currently available:
- Standard replay with or without different travel times
- Replay splitting the analysis by regions (appropriate for coverage analysis in large countries).

You need to have the AccessMod image installed in the remote machine.

## Install remotely the AccessMod image on HPC

In the remote machine:

```txt 
$ singularity pull ~/image/accessmod.sif docker://fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted, and the path (~/image/accessmod.sif) is chosen by the user. 
More details here: https://docs.sylabs.io/guides/3.2/user-guide/cli/singularity_pull.html

## Install remotely the AccessMod image on server

In the remote machine:

```txt 
$ docker pull fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted

## Required files

You will always need the following files within the same input folder located remotely (hpc or server):

```txt 
|-- project.amp5       -> AccessMod project
|-- config.json        -> config file generated in AccessMod corresponding to the desired analysis
```

Let's say that you have these files locally in C:/myname/replay and that you want to copy them into your remote home directory. From your local machine:

```txt 
$ scp -r C:/myname/replay <username>@<serveraddress>:~/
```

## Required scripts

In your remote disk space, clone and pull (if already cloned) this github repository. In your remote machine:

```txt 
$ git clone https://github.com/ptimoner/AMRemote/
```

or 

```txt 
$ git pull AMRemote
```
## Procedure
In your remote machine, within the AMRemote folder, go to the folder that corresponds to your analysis. The only scripts that you will potentially run directly
are the following:

```txt 
|-- script.sh          -> when using a remote server
|-- main_hpc.sh        -> when using a HPC
```
You will have to give the permission to run them directly (only the first time).

```txt 
$ chmod +x scirpt.sh
```

or

```txt 
$ chmod +x main_hpc.sh
```

Run the script with its corresponding parameters:

In all cases the first parameter will be the path to the input folder and the second one the AccessMod image name (server) or path (HPC).

In a server:

```txt 
$ ./script.sh ~/<inputFolder> fredmoser/accessmod:5.8.0
```
In a HPC:

```txt 
$ ./script.sh ~/<inputFolder> ~/<path to the SIF file>
```
For the 'split by region' coverage analysis, you will have to provide a third parameter corresponding to the name of the column in the health facility attribute table that refers to the region.

For instance, 

```txt 
$ ./script.sh ~/<inputFolder> fredmoser/accessmod:5.8.0 admin
```
Will be created an output folder called 'out' within your input folder with all the results.

To download your results, from your local machine:

```txt 
$ scp -r <username>@<serveraddress>:~/<inputFolder>/out C:/myname/replay 
```


