# AMRemote
Standard scripts to run AccessMod analyses remotely (server or HPC) through the replay function. 

Are currently available:
- Standard replay (any module) with or without different travel times
- Replay splitting the analysis by region (appropriate for coverage analysis in large countries).

## Upload files

You will always need the following files within the same input folder located remotely (hpc or server):

```txt 
|-- project.amp5       -> AccessMod project
|-- config.json        -> config file generated in AccessMod corresponding to the desired analysis
```

Let's say that you have these files locally in C:/myname/replay and that you want to copy them into your remote home directory. From your local machine:

```txt 
$ scp -r C:/myname/replay <username>@<serveraddress>:~/
```

## AccessMod image

In the HPC (HPC uses singularity instead of Docker):

```txt 
$ ml GCC/9.3.0 Singularity/3.7.3-Go-1.14
$ singularity pull ~/image/accessmod.sif docker://fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted, and the path (~/image/accessmod.sif) is chosen by the user. 
More details here: https://docs.sylabs.io/guides/3.2/user-guide/cli/singularity_pull.html

In the server:

```txt 
$ docker pull fredmoser/accessmod:5.8.0
```
where the image (fredmoser/accessmod:5.8.0) can be adapted

## Make scripts available

In your remote disk space, clone and pull (if already cloned) this github repository.

```txt 
$ git clone https://github.com/ptimoner/AMRemote/
```

or 

```txt 
$ git pull AMRemote
```
## Procedure

In your remote machine, within the AMRemote folder, go to the subfolder that corresponds to your analysis. The only scripts that you will potentially run directly are the following:

```txt 
|-- script.sh          -> when using a remote server
|-- main_hpc.sh        -> when using a HPC
```
Change permission so you can execute them (only the first time).

```txt 
$ chmod +x script.sh
```

or

```txt 
$ chmod +x main_hpc.sh
```

Run the script with its corresponding parameters:

In all cases the first parameter will be the path to the input folder and the second one the AccessMod image name (server) or path (HPC).

In a server, for instance:

```txt 
$ ./script.sh ~/<inputFolder> fredmoser/accessmod:5.8.0
```
In a HPC:

```txt 
$ ./main_hpc.sh ~/<inputFolder> ~/image/accesmod.sif
```
For the 'split by region' coverage analysis, you will have to provide a third parameter corresponding to the name of the column in the health facility attribute table that refers to the region.

For instance, 

```txt 
$ ./script.sh ~/<inputFolder> fredmoser/accessmod:5.8.0 admin
```

For analyses using different travel times, open the inputs.json file and modify the travel times accordingly. Within the multiple_travel_times folder:

```txt 
$ nano inputs.json
```
Modify the file, and exit with CTL-X (and Y when asked if you'd like to save changes).

## Outputs

Will be created an output folder called 'out' within your input folder with all the results.

To download your results, from your local machine:

```txt 
$ scp -r <username>@<serveraddress>:~/<inputFolder>/out C:/myname/replay 
```


