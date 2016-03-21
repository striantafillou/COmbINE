INTRODUCTION
COmbINE implements the COmbINE algorihtm, published in Triantafillou and Tsamardinos, 2015, JMLR. 



INSTALLATION
Before runnign the code, you must make sure you can run the sat solver executable. In the code directory, run the following command:
minisat_increment.exe < sat.cnf > out.txt
If the output is negative (non-zero) and out.txt is blank, MATLAB cannot run the executable.
If this happens, contact me (sof.triantafillou@gmail.com). In that case, you can compile the sat solver code and run it through cygwin.

go to sortConstraintsMR.m line 63, and if it is not already that way:
comment line 63 
comment out line 64


RUN

To run COmbINE algorithm, you need to input a structure containing the input data sets.


LICENSE 
This software is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%